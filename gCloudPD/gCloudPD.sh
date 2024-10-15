#!/bin/bash

####################################### STATIC VARIABLES ########################################

# Text Color
WHITE="\033[0m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
GREEN="\033[0;32m"

# Infinte Loop
ALWAYS_TRUE=true

# Regex
Integer='^[0-9]+$'

######################################### REQUIREMENTS ##########################################


###################################### GATHER USER INPUT ########################################

while [[ $ALWAYS_TRUE=true ]];
do 

    #
    read -p "$(echo -e ${YELLOW}[REQUIRED]${WHITE} Please enter the project ID where you want to create the persistent disk in:) " ProjectID

    #
    if gcloud projects describe $ProjectID &> /dev/null;
    then
        gcloud config set project $ProjectID
        echo "" && echo -e "${GREEN}[SUCCESS]${WHITE} The project $ProjectID was set." && echo ""
        break
    else
        echo "" && echo -e "${RED}[ERROR 1]${WHITE} A project with the ${ProjectID} project ID doesn't exists within your organization or you don't have access to it." && echo ""
    fi
done

### Let him cook

DiskName="gcloudpddisk"

while [[ $ALWAYS_TRUE=true ]];
do 
    read -p "$(echo -e ${YELLOW}[REQUIRED]${WHITE} Please enter how many gigabytes that you want you disk to have (Minimum 10):) " DiskSize

    if [[ $DiskSize =~ $Integer ]];
    then
        break
    else
        echo -e "${RED}[ERROR 2]${WHITE} Please enter a valid number." && echo ""
    fi

done

## Would you like to attach this Persistent Disk to an existing VM

while [[ $ALWAYS_TRUE=true ]];
do 

    read -p "$(echo -e ${YELLOW}[REQUIRED]${WHITE} Would you like to attach this disk to an existing VM in your project? Y or N:) " AttachDisk

    if [[ ${AttachDisk,,} == "y" ]];
    then
        break
    elif [[ ${AttachDisk,,} == "n" ]];
    then
        break
    else
        echo -e "${RED}[ERROR 3]${WHITE} Please enter either Y or N." && echo ""
    fi
    
done

while [[ $ALWAYS_TRUE=true ]];
do 
    read -p "$(echo -e ${YELLOW}[REQUIRED]${WHITE} Please enter the name of the VM instance that you want to attach this disk to:) " InstanceName
    read -p "$(echo -e ${YELLOW}[REQUIRED]${WHITE} Please enter the zone where the VM instance resides in:) " InstanceZone

    if gcloud compute instances describe $InstanceName --zone $InstanceZone;
    then
        break
    else
        echo -e "${RED}[ERROR 4]${WHITE} An instance called $InstanceName was not found in this project." && echo ""
    fi    
done

###

while [[ $ALWAYS_TRUE=true ]];
do     
   
    read -p "$(echo -e ${YELLOW}[REQUIRED]${WHITE} Please enter the persistent disk type that you want this disk to be:) " DiskType

    #CreateDisk=$(gcloud compute disks create $DiskName --size $DiskSize --type $DiskType --zone $InstanceZone)
    if gcloud compute disks create $DiskName --size $DiskSize --type $DiskType --zone $InstanceZone;
    then
        #gcloud compute disks create $DiskName --size $DiskSize --type $DiskType --zone $InstanceZone
        break
    else
        echo -e "${RED}[ERROR 5]${WHITE} Please enter a valid persistent disk type." && echo ""
    fi

done

## Would you like to attach this Persistent Disk to an existing VM

if [[ ${AttachDisk,,} == "y" ]];
then
    gcloud compute instances attach-disk $InstanceName \
    --disk $DiskName --device-name=$DiskName --zone $InstanceZone
fi

exit 0
