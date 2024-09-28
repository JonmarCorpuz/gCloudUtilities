# TO DO
# Create log scope --> Add projects to log scope --> Add metrics
# Ops Agent for Monitoring and Logging needs to be installed on VM instance
# Create an uptime check
# Create an alerting policy

####################################### STATIC VARIABLES ########################################

# Text Color
WHITE="\033[0m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
GREEN="\033[0;32m"

# Infinte Loop
ALWAYS_TRUE=true

######################################### REQUIREMENTS ##########################################

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
gcloud config set project $MainProject

echo && echo "DONE 3" && echo ""

# Enable Cloud Monitoring API
#gcloud services enable monitoring --project=$MainProject

while read -r ProjectID; 
do

    gcloud config set project $MainProject

    echo $ProjectID

    gcloud services enable monitoring --project=$ProjectID
    gcloud services enable compute --project=$ProjectID 

    echo && echo "DONE 4" && echo ""

    # Add the specified projects to the metric scope
    gcloud beta monitoring metrics-scopes create projects/$ProjectID --project=$MainProject

    echo && echo "DONE 5" && echo ""

    #1.List all VM instances (Store output in a file maybe)
    #gcloud compute instances list --project $ProjectID > InstanceList2.txt

    echo && echo "DONE 6" && echo ""

    while read -r InstanceName; 
    do

        gcloud config set project $ProjectID

        echo $InstanceName

        #2.Add label for monitoring if it does not exist already (Prompt the user for a label name)
        gcloud compute instances update $InstanceName \
        --update-labels component=monitoring \
        --zone us-central1-c

        echo && echo "DONE 7" && echo ""

    done < InstanceList2.txt
    
done < $2

# Define a service to monitor all VM instances using labels

#2.Add label for monitoring if it does not exist already (Prompt the user for a label name)

# Define a service to monitor all containers using labels

########################################## REFERENCES ###########################################

# Resource Labels
# - https://cloud.google.com/compute/docs/labeling-resources#gcloud_1

# Metrics Scope 
# - https://cloud.google.com/monitoring/settings/manage-api
