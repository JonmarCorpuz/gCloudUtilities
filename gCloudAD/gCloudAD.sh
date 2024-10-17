#!/bin/bash

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
|\   ____\|\   ____\|\  \     |\   __  \|\  \|\  \|\   ___ \|\   __  \|\   ___ \    
\ \  \___|\ \  \___|\ \  \    \ \  \|\  \ \  \\\  \ \  \_|\ \ \  \|\  \ \  \_|\ \   
 \ \  \  __\ \  \    \ \  \    \ \  \\\  \ \  \\\  \ \  \ \\ \ \   __  \ \  \ \\ \  
  \ \  \|\  \ \  \____\ \  \____\ \  \\\  \ \  \\\  \ \  \_\\ \ \  \ \  \ \  \_\\ \ 
   \ \_______\ \_______\ \_______\ \_______\ \_______\ \_______\ \__\ \__\ \_______\
    \|_______|\|_______|\|_______|\|_______|\|_______|\|_______|\|__|\|__|\|_______|

gCloudAD is an interactive tool that allows users to automatically create a managed AD service
'''

####################################### GATHER USER INPUT #######################################

while [[ $ALWAYS_TRUE=true ]];
do 

    read -p "$(echo -e ${YELLOW}[REQUIRED]${WHITE} Please enter the region where you want :) " Region
            
    if gcloud compute regions describe $Region;
    then
        break
    else
        echo -e "${RED}[ERROR 4]${WHITE} An instance called ${Zone} was not found in this project." && echo ""
    fi    
    
done

####################################### ACTIVE DIRECTORY ########################################

# Ensure that the API is enabled
if ! gcloud services list | grep "managedidentities.googleapis.com";
then
    gcloud services enable managedidentities.googleapis.com
fi

# Create AD domain

gcloud active-directory domains create <FQDN> \
    --reserved-ip-range=<CIDR_RANGE> --region=<REGION> \
    --authorized-networks=projects/<PROJECT_ID>/global/networks/<VPC_NETWORK_NAME>

# Join Linux VM to domain (Execute commands through SSH)
