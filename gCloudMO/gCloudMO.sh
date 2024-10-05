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
 ________  ________  ___       ________  ___  ___  ________  _____ ______   ________     
|\   ____\|\   ____\|\  \     |\   __  \|\  \|\  \|\   ___ \|\   _ \  _   \|\   __  \    
\ \  \___|\ \  \___|\ \  \    \ \  \|\  \ \  \\\  \ \  \_|\ \ \  \\\__\ \  \ \  \|\  \   
 \ \  \  __\ \  \    \ \  \    \ \  \\\  \ \  \\\  \ \  \ \\ \ \  \\|__| \  \ \  \\\  \  
  \ \  \|\  \ \  \____\ \  \____\ \  \\\  \ \  \\\  \ \  \_\\ \ \  \    \ \  \ \  \\\  \ 
   \ \_______\ \_______\ \_______\ \_______\ \_______\ \_______\ \__\    \ \__\ \_______\
    \|_______|\|_______|\|_______|\|_______|\|_______|\|_______|\|__|     \|__|\|_______|

An interactive script written by Jonmar Corpuz that allows Google Cloud customers to centrally monitor 
all their resources using a single project. 
'''

echo "" && echo -e "${YELLOW}[REQUIRED]${WHITE} Ensure that the resources you want to monitor have Ops Agent installed and enabled." && echo ""

######################################## ARGUMENTS CHECK ########################################

# Check if the user executed the script correctly
while getopts ":f:" opt; 
do
    case $opt in
        f) file="$OPTARG"
        ;;
        \?) echo -e "${RED}[ERROR 1]${WHITE} Usage: ./gCloudMO.sh -f InstanceList.txt." && echo "" &&  exit 1
        ;;
        :) echo -e "${RED}[ERROR 2]${WHITE} Usage: ./gCloudMO.sh -f InstanceList.txt." && echo "" && exit 1
        ;;
    esac
done

# Check if the user provided only the required values when executing the script
if [ $OPTIND -ne 3 ]; 
then
    echo -e "${RED}[ERROR 3]${WHITE} Usage: ./gCloudMO.sh -f ProjectList.txt" && echo "" &&  exit 1
fi

if ! cat $2 &> /dev/null;
then
    echo -e "${RED}[ERROR 4]${WHITE} Please use the provided ProjectList.txt file included in this repository." && echo "" &&  exit 1
fi

# Verify that the projects in the provided file all exist
while read -r ProjectID; 
do

    if ! gcloud projects describe $ProjectID &> /dev/null;
    then
        echo "" && echo -e "${RED}[ERROR 5]${WHITE} ${ProjectID} dosen't exist." && echo "" && exit 1
    fi
    
done < $2

########################################## MONITORING ###########################################

while [[ $ALWAYS_TRUE=true ]];
do 

    #
    read -p "$(echo -e ${YELLOW}[REQUIRED]${WHITE} Please enter the unique project ID that you would you like to give the main project that will monitor your other projects:) " MainProject

    #
    if gcloud projects describe $MainProject &> /dev/null;
    then
        echo "" && echo -e "${RED}[ERROR 1]${WHITE} A project with the ${MainProject} project ID already exists either in your own project or externally." && echo ""
    else
        if gcloud projects create $MainProject;
        then 
            #gcloud projects create $MainProject
            echo "" && echo -e "${GREEN}[SUCCESS]${WHITE} The main project has been created." && echo ""
            break
        else
            echo "" && echo -e "${RED}[ERROR 2]${WHITE} A project with the ${MainProject} project ID already exists either in your own project or externally." && echo ""
        fi 
    fi
done

# Switch to the dedicated project for monitoring
gcloud config set project $MainProject &> /dev/null

# 
while [[ $ALWAYS_TRUE=true ]];
do 

    #
    read -p "$(echo -e ${YELLOW}[REQUIRED]${WHITE} Please enter the billing account ID that you would like to link to this project:) " BillingID

    #
    ListBillingAccounts=$(gcloud billing accounts list)

    # Check if the provided billing account exists
    if echo $ListBillingAccounts | grep -q $BillingID; then 
        gcloud billing projects link $MainProject --billing-account $BillingID
        break
    else 
        echo "" && echo -e "${RED}[ERROR 3]${WHITE} A billing account with the $BillingID billing ID doesn't exist." && echo ""
    fi 

done 

# Enable the required APIs in the project that will be used for monitoring
gcloud services enable monitoring --project=$MainProject &> /dev/null
gcloud services enable compute --project=$MainProject &> /dev/null

echo "" && echo -e "${GREEN}[SUCCESS]${WHITE} The project that will be used for monitoring has been set and configured." && echo ""

#
while read -r ProjectID; 
do

    #
    gcloud config set project $MainProject &> /dev/null

    # Enable the required APIs 
    gcloud services enable monitoring --project=$ProjectID &> /dev/null
    gcloud services enable compute --project=$ProjectID &> /dev/null

    # Add the specified projects within the ProjectList.txt file to the metric scope
    gcloud beta monitoring metrics-scopes create projects/$ProjectID --project=$MainProject &> /dev/null

    #
    gcloud config set project $ProjectID &> /dev/null

    # Check if there are instances that exist in the project
    gcloud compute instances list --limit 1 --project $ProjectID > ActiveInstances.txt # --filter "STATUS=RUNNING"

    # A
    if [ -s ActiveInstances.txt ];
    then

        # Enable the required APIs
        gcloud compute instances list --format "table(NAME)" --project $ProjectID > InstanceNamesRaw.txt # --filter "STATUS=RUNNING"
        gcloud compute instances list --format "table(ZONE)" --project $ProjectID > InstanceZonesRaw.txt # --filter "STATUS=RUNNING"

        #
        while read -r Name;
        do 
            echo ${Name##* } >> InstanceNames.txt
        done < InstanceNamesRaw.txt

        #
        while read -r Zone;
        do 
            echo ${Zone##* } >> InstanceZones.txt
        done < InstanceZonesRaw.txt

        #
        paste -d' ' InstanceNames.txt InstanceZones.txt > InstancesInfo.txt

        #
        while read -r Name Zone;
        do

            # Add a label that gCloudMO will use when creating the resource group
            gcloud compute instances update $Name --update-labels component=gce_monitoring --zone=$Zone &> /dev/null

        done < InstancesInfo.txt

        # Cleanup 
        rm InstanceNamesRaw.txt InstanceNames.txt InstanceZonesRaw.txt InstanceZones.txt

    fi 
    
done < $2

# Create a resource group 
curl -X POST -H "Authorization: Bearer $(gcloud auth print-access-token)" -H "Content-Type: application/json" -d '{"displayName": "Compute Instances", "filter": "resource.type=gce_instance metric.labels.component=gce_monitoring"}' https://monitoring.googleapis.com/v3/projects/$MainProject/groups

# Cleanup again
rm InstancesInfo.txt

#
echo "" && echo -e "${GREEN}[SUCCESS]${WHITE} The resource group has been created." && echo "" && exit 0
