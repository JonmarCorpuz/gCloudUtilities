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

echo "" && echo "pleasework" && echo ""

# Get each user's role
while read User;
do

    # Get user email only
    UserEmail=$(echo "${User##* }")

    # Fetch user's role
    UserRoleRaw=$(gcloud asset analyze-iam-policy --project=$ProjectID --identity=$UserEmail | grep "role")
    UserRole=$(echo "${UserRoleRaw##* }")

    echo "" && echo "1" && echo ""

    # Remove "projects/$ProjectID" from the UserRole

    Remove="projects/$ProjectID/"
    Role=${UserRole//"$Remove"/}

    echo $UserRoleRaw
    echo $UserRole
    echo $Role

    echo "" && echo "2" && echo ""
    
    # List role's permissions
    if gcloud iam roles describe $Role &> /dev/null;
    then
        gcloud iam roles describe $Role >> $UserEmail-Permissions.yaml
    else
        Remove2="projects/$ProjectID/roles/"
        Role2=${UserRole//"$Remove2"/}

        gcloud iam roles describe $Role2 --project $ProjectID >> $UserEmail-Permissions.yaml
    fi

    echo "" && echo "3" && echo ""

    cat $UserEmail-Permissions.yaml | grep "-" > tmp.txt

    # List the resources that the user can access
    #Create a list and append every resource that you see

    touch tmp2.txt

    while read Permission;
    do

    # Split the permission, ex: accessapproval.requests.approve, into three parts and take the first
    FullPermission=$(echo "${Permission##* }")
    Resource=$(echo $FullPermission | tr "." "\n" | head -n 1)

        # If file doesn't include the resource, add it, else nah
        if ;
        then
       
        else

        fi

    done < tmp.txt
    
done < Users.txt

# List the type of access that the user has for each resource they can access using the list generated from the previous step

# Cleanup
rm Users.txt
