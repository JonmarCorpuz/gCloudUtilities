####################################### STATIC VARIABLES ########################################

# Text Color
WHITE="\033[0m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
GREEN="\033[0;32m"

# Infinte Loop
ALWAYS_TRUE=true

######################################### REQUIREMENTS ##########################################

echo '''
 ________  ________  ___       ________  ___  ___  ________  ________  ________      
|\   ____\|\   ____\|\  \     |\   __  \|\  \|\  \|\   ___ \|\   __  \|\   ____\     
\ \  \___|\ \  \___|\ \  \    \ \  \|\  \ \  \\\  \ \  \_|\ \ \  \|\  \ \  \___|_    
 \ \  \  __\ \  \    \ \  \    \ \  \\\  \ \  \\\  \ \  \ \\ \ \   ____\ \_____  \   
  \ \  \|\  \ \  \____\ \  \____\ \  \\\  \ \  \\\  \ \  \_\\ \ \  \___|\|____|\  \  
   \ \_______\ \_______\ \_______\ \_______\ \_______\ \_______\ \__\     ____\_\  \ 
    \|_______|\|_______|\|_______|\|_______|\|_______|\|_______|\|__|    |\_________\
                                                                         \|_________|

'''

######################################## ARGUMENTS CHECK ########################################

# Check if the user provided only the required values when executing the script
if [ $OPTIND -ne 1 ]; 
then
    echo $OPTIND
    echo -e "${RED}[ERROR 3]${WHITE} Usage: ./gCloudPS.sh -p <PROJECT_ID>" && echo "" &&  exit 1
fi

###################################### GATHER USER INPUT ########################################

while [[ $ALWAYS_TRUE=true ]];
do 

    #
    read -p "$(echo -e ${YELLOW}[REQUIRED]${WHITE} Please enter the project ID where the user resides in) " ProjectID

    #
    if gcloud projects describe $ProjectID &> /dev/null;
    then
        echo "" && echo -e "${GREEN}[SUCCESS]${WHITE} The project $ProjectID was found." && echo ""
        break
    else
        echo "" && echo -e "${RED}[ERROR 1]${WHITE} A project with the ${ProjectID} project ID doesn't exists within your organization or you don't have access to it." && echo ""
    fi
done

# Ask for user or SA email
while [[ $ALWAYS_TRUE=true ]];
do 

    #
    read -p "$(echo -e ${YELLOW}[REQUIRED]${WHITE} Please enter the email address of the entity that you want to audit:) " EntityEmail

    if [[ $(gcloud asset search-all-iam-policies --scope=projects/$ProjectID | grep user:$EntityEmail | wc -c) -ne 0 ]];
    then
        echo "" && echo -e "${GREEN}[SUCCESS]${WHITE} The entity $EntityMail was found." && echo ""
        break
    else
        echo "" && echo -e "${RED}[ERROR 3]${WHITE} $EntityEmail does not exist in the specified project." && echo ""
    fi

done

################################### GATHER USER PERMISSIONS #####################################

# List all users on the project

gcloud asset search-all-iam-policies --scope=projects/$ProjectID | grep user: > Users.txt

# Get each user's role
while read User;
do

    # Get user email only
    UserEmail=$(echo "${User##* }")

    # Fetch user's role
    UserRole=$(gcloud asset analyze-iam-policy --project=$ProjectID --identity='user:'$UserEmail | grep "role")
    
    # List role's permissions
    gcloud iam roles describe $UserRole --project $ProjectID >> Test.txt
    
done < Users.txt

