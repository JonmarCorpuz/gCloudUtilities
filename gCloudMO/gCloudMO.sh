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
while getopts ":f:" opt; do
    case $opt in
        f) file="$OPTARG"
        ;;
        \?) echo -e "${RED}[ERROR 1]${WHITE} Usage: ./CreateVPC.sh -p <TEXT_FILE>$" && echo "" &&  exit 1
        ;;
        :) echo -e "${RED}[ERROR 2]${WHITE} Usage: ./CreateVPC.sh -p <TEXT_FILE>." && echo "" && exit 1
        ;;
    esac
done

# Verify that the projects in the provided file all exist

########################################## MONITORING ###########################################

# Switch to the dedicated project for monitoring

# Enable Cloud Monitoring API
gcloud services enable monitoring --project=PROJECT_ID

# Add the specified projects to the metric scope

for n of specified projects
do
  gcloud beta monitoring metrics-scopes create proejcts/<PROJECT ID OF THE PROJECT TO ADD> --project=<MONITORING PROEJCT ID>
done

# Define a service to monitor all VM instances using labels

# Define a service to monitor all containers using labels

########################################## REFERENCES ###########################################

# Metrics Scope 
# - https://cloud.google.com/monitoring/settings/manage-api
