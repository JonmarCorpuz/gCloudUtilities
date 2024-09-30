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

test
'''

echo "" && echo -e "${YELLOW}[REQUIRED]${WHITE} Ensure that the resources you want to monitor have Ops Agent installed and enabled." && echo ""

######################################## ARGUMENTS CHECK ########################################

# Check if the user executed the script correctly
while getopts ":f:" opt; 
do
    case $opt in
        f) file="$OPTARG"
        ;;
        \?) echo -e "${RED}[ERROR 1]${WHITE} Usage: ./gCloudMO.sh -f <TEXT_FILE>" && echo "" &&  exit 1
        ;;
        :) echo -e "${RED}[ERROR 2]${WHITE} Usage: ./gCloudMO.sh -f <TEXT_FILE>." && echo "" && exit 1
        ;;
    esac
done

echo && echo "DONE 1" && echo ""

# Verify that the projects in the provided file all exist
while read -r ProjectID; 
do

    if ! gcloud projects describe $ProjectID &> /dev/null;
    then
        echo "" && echo -e "${RED}[ERROR 1]${WHITE} ${ProjectID} dosen't exist." && echo "" && exit 1
    fi
    
done < $2

MainProject=$(head -n 1 $2)

echo && echo "DONE 2" && echo ""

echo $MainProject

########################################## MONITORING ###########################################

# Switch to the dedicated project for monitoring
gcloud config set project $MainProject &> /dev/null

echo && echo "DONE 3" && echo ""

# Enable Cloud Monitoring API
#gcloud services enable monitoring --project=$MainProject

while read -r ProjectID; 
do

    gcloud config set project $MainProject &> /dev/null

    echo $ProjectID

    gcloud services enable monitoring --project=$ProjectID &> /dev/null
    gcloud services enable compute --project=$ProjectID &> /dev/null

    echo "" && echo "DONE 4" && echo ""

    # Add the specified projects to the metric scope
    gcloud beta monitoring metrics-scopes create projects/$ProjectID --project=$MainProject &> /dev/null

    echo "" && echo "DONE 5" && echo ""

    gcloud config set project $ProjectID &> /dev/null

    echo "" && echo "DONE 000" && echo ""

    #1.List all VM instances (Store output in a file maybe)
    gcloud compute instances list --filter "STATUS=RUNNING" --limit 1 --project $ProjectID > ActiveInstances.txt
    
    if [ -s ActiveInstances.txt ];
    then

        gcloud compute instances list --format "table(NAME)" --filter "STATUS=RUNNING" --project $ProjectID > InstanceNamesRaw.txt
        gcloud compute instances list --format "table(ZONE)" --filter "STATUS=RUNNING" --project $ProjectID > InstanceZonesRaw.txt

        while read -r Name;
        do 
            echo ${Name##* } >> InstanceNames.txt
        done < InstanceNamesRaw.txt

        while read -r Zone;
        do 
            echo ${Zone##* } >> InstanceZones.txt
        done < InstanceZonesRaw.txt

        echo "" && echo "DONE 6" && echo ""

        paste -d' ' InstanceNames.txt InstanceZones.txt > InstancesInfo.txt

        while read -r Name Zone;
        do

            echo $Name
            echo $Zone

            #2.Add label for monitoring if it does not exist already (Prompt the user for a label name)
            gcloud compute instances update $Name \
            --update-labels component=monitoring \
            --zone $Zone

        done < InstancesInfo.txt

        cat ActiveInstances.txt

        rm InstanceNamesRaw.txt InstanceNames.txt InstanceZonesRaw.txt InstanceZones.txt

        echo "" && echo "DONE 6.5" && echo ""

    fi 

    echo "" && echo "DONE 7" && echo ""
    
done < $2

# Create a resource group
curl -X POST -H "Authorization: Bearer $(gcloud auth print-access-token)" -H "Content-Type: application/json" -d '{"displayName": "test40", "filter": "resource.type=gce_instance metric.labels.component=monitoring"}' https://monitoring.googleapis.com/v3/projects/$MainProject/groups

# Define a service to monitor all VM instances using labels

# Define a service to monitor all containers using labels

########################################## REFERENCES ###########################################

# Resource Labels
# - https://cloud.google.com/compute/docs/labeling-resources#gcloud_1

# Metrics Scope 
# - https://cloud.google.com/monitoring/settings/manage-api
