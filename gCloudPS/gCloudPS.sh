####################################### STATIC VARIABLES ########################################

# Text Color
WHITE="\033[0m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
GREEN="\033[0;32m"

# Infinte Loop
ALWAYS_TRUE=true

# Folder Name
FolderName="PermissionSummary"
mkdir $FolderName

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

######################################## USER ACCOUNTS ##########################################

# List all users on the project

gcloud asset search-all-iam-policies --scope=projects/$ProjectID | grep "user:" > Users.txt

#echo "" && echo "pleasework" && echo ""

# Get each user's role
while read User;
do

    # Get user email only
    UserEmail=$(echo "${User##* }")

    Remove3="user:"
    TestUserEmail=${UserEmail//"$Remove3"/}
    Remove4="@gmail.com"
    Username=${TestUserEmail//"$Remove4"/}

    Filename="USER@${Username}"
    #echo $Filename

    touch ${Filename}.txt

    echo "" >> ${Filename}.txt
    echo "=== User Information ==========" >> ${Filename}.txt
    echo "- User: ${UserEmail}" >> ${Filename}.txt
    echo "" >> ${Filename}.txt

    # Fetch user's role
    UserRoleRaw=$(gcloud asset analyze-iam-policy --project=$ProjectID --identity=$UserEmail | grep "role")
    UserRole=$(echo "${UserRoleRaw##* }")

    #echo "" && echo "1" && echo ""

    Remove="projects/$ProjectID/"
    Role=${UserRole//"$Remove"/}

    #echo $UserRoleRaw
    #echo $UserRole
    #echo $Role

    #echo "" && echo "2" && echo ""
    
    # List role's permissions
    if gcloud iam roles describe $Role &> /dev/null;
    then
    
        # Predefined Role
        gcloud iam roles describe $Role >> PermissionsRaw-$UserEmail.yaml
        echo "=== Role Summary ==============" >> ${Filename}.txt
        echo "- Role type: Predefined" >> ${Filename}.txt
        echo "- Role:      ${Role}" >> ${Filename}.txt

    else
    
        # Custom Role
        Remove2="projects/$ProjectID/roles/"
        Role2=${UserRole//"$Remove2"/}

        gcloud iam roles describe $Role2 --project $ProjectID >> PermissionsRaw-$UserEmail.yaml

        echo "=== Role Summary ==============" >> ${Filename}.txt
        echo "- Role type: Custom" >> ${Filename}.txt
        echo "- Role:      ${Role}" >> ${Filename}.txt

    fi

    #echo "" && echo "3" && echo ""

    cat PermissionsRaw-$UserEmail.yaml | grep "-" > Permissions-$UserEmail.yaml

    # List the resources that the user can access
    #Create a list and append every resource that you see

    touch AllowedResources-$UserEmail.txt

    while read Permission;
    do

        # Split the permission, ex: accessapproval.requests.approve, into three parts and take the first
        FullPermission=$(echo "${Permission##* }")
        Resource=$(echo $FullPermission | tr "." "\n" | head -n 1)

        #echo $Resource

        # If file doesn't include the resource, add it, else nah
        if ! grep -Fxq "${Resource}" AllowedResources-$UserEmail.txt &> /dev/null;
        then
            echo "- ${Resource}" >> AllowedResources-$UserEmail.txt
        fi

    done < Permissions-$UserEmail.yaml

    sed -i '1d;$d' AllowedResources-$UserEmail.txt

    echo "" >> ${Filename}.txt
    echo "=== Accessible Resources ======" >> ${Filename}.txt
    cat AllowedResources-$UserEmail.txt >> ${Filename}.txt

    echo "" >> ${Filename}.txt
    echo "=== Permissions ===============" >> ${Filename}.txt
    cat Permissions-$UserEmail.yaml | grep "-" >> ${Filename}.txt
    echo "" >> ${Filename}.txt

    mv ${Filename}.txt $FolderName

    rm PermissionsRaw-$UserEmail.yaml
    rm Permissions-$UserEmail.yaml
    rm AllowedResources-$UserEmail.txt

done < Users.txt

mv Users.txt $FolderName

###################################### SERVICE ACCOUNTS #########################################

gcloud iam service-accounts list --project $ProjectID | grep "EMAIL:" > ServiceAccountsRaw.yaml

while read ServiceAccount;
do

    echo "${ServiceAccount##* }" >> ServiceAccounts.txt
    
done < ServiceAccountsRaw.yaml

while read ServiceAccount;
do
    gcloud iam service-accounts describe $ServiceAccount --project $ProjectID
    echo ""
done < ServiceAccounts.txt

### Roles

gcloud projects get-iam-policy $ProjectID | grep "role:" > Roles.txt

while read Role;
do

    if gcloud iam roles describe $Role &> /dev/null;
    then
    
        # Predefined Role
        gcloud iam roles describe $Role >> $Role.txt
        echo "=== Role Summary ==============" >> test123.txt
        echo "- Role type: Predefined" >> test123.txt
        echo "- Role:      ${Role}" >> test123.txt

    else
    
        # Custom Role
        Remove2="projects/$ProjectID/roles/"
        Role2=${Role//"$Remove2"/}

        gcloud iam roles describe $Role2 --project $ProjectID >> $Role.txt

        echo "=== Role Summary ==============" >> test123.txt
        echo "- Role type: Custom" >> test123.txt
        echo "- Role:      ${Role}" >> test123.txt

    fi

done < Roles.txt

### Let him cook

gcloud projects get-iam-policy jonmardemoproject | grep "role:" > Roles.txt

sed 's/role: $//' Roles.txt


while read Role;
do

#    Remove123="role:"
#    tmp=${Role//"Remove123"/}

#    echo $tmp

    test=$(echo "${Role##* }")
    echo $test

    Remove="projects/jonmardemoproject/"
    Role1=${test//"$Remove"/}

#    echo $Role1

    if gcloud iam roles describe $Role1 &> /dev/null;
    then
    
        # Predefined Role
        gcloud iam roles describe $Role1 >> gg123.txt
#        echo "=== Role Summary ==============" >> test123.txt
#        echo "- Role type: Predefined" >> test123.txt
#        echo "- Role:      ${Role}" >> test123.txt

    else
    
        # Custom Role
        Remove2="projects/jonmardemoproject/roles/"
        Role2=${test//"$Remove2"/}

        echo $Role2

        gcloud iam roles describe $Role2 --project jonmardemoproject >> gg456.txt

#        echo "=== Role Summary ==============" >> test456.txt
#        echo "- Role type: Custom" >> test456.txt
#        echo "- Role:      ${Role}" >> test456.txt

    fi

done < Roles.txt
