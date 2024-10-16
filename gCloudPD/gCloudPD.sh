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

echo '''
 ________  ________  ___       ________  ___  ___  ________  ________  ________     
|\   ____\|\   ____\|\  \     |\   __  \|\  \|\  \|\   ___ \|\   __  \|\   ___ \    
\ \  \___|\ \  \___|\ \  \    \ \  \|\  \ \  \\\  \ \  \_|\ \ \  \|\  \ \  \_|\ \   
 \ \  \  __\ \  \    \ \  \    \ \  \\\  \ \  \\\  \ \  \ \\ \ \   ____\ \  \ \\ \  
  \ \  \|\  \ \  \____\ \  \____\ \  \\\  \ \  \\\  \ \  \_\\ \ \  \___|\ \  \_\\ \ 
   \ \_______\ \_______\ \_______\ \_______\ \_______\ \_______\ \__\    \ \_______\
    \|_______|\|_______|\|_______|\|_______|\|_______|\|_______|\|__|     \|_______|
    
'''

####################################### GATHER USER INPUT #######################################

# Project ID
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

## Would you like to attach this Persistent Disk to an existing VM
while [[ $ALWAYS_TRUE=true ]];
do 
    read -p "$(echo -e ${YELLOW}[REQUIRED]${WHITE} Would you like to attach this disk to an existing VM in your project? Y or N:) " AttachDisk

    #
    if [[ ${AttachDisk,,} == "y" ]];
    then
        while [[ $ALWAYS_TRUE=true ]];
        do 
            read -p "$(echo -e ${YELLOW}[REQUIRED]${WHITE} Please enter the name of the VM instance that you want to attach this disk to:) " InstanceName
            read -p "$(echo -e ${YELLOW}[REQUIRED]${WHITE} Please enter the zone where the VM instance resides in:) " Zone

            if gcloud compute instances describe $InstanceName --zone $Zone;
            then
                break
            else
                echo -e "${RED}[ERROR 4]${WHITE} An instance called ${Zone} was not found in this project." && echo ""
            fi    
        done
        
        break

    #    
    elif [[ ${AttachDisk,,} == "n" ]];
    then
    
        while [[ $ALWAYS_TRUE=true ]];
        do 
            read -p "$(echo -e ${YELLOW}[REQUIRED]${WHITE} Please enter the zone where you want to create your disk in in:) " Zone

            if gcloud compute zones describe $Zone &> /dev/null;
            then
                break
            else
                echo -e "${RED}[ERROR 5]${WHITE} An instance called $Zone was not found in this project." && echo ""
            fi     
        done

        break
        
    else
        echo -e "${RED}[ERROR 6]${WHITE} Please enter either Y or N." && echo ""
    fi
done

#
while [[ $ALWAYS_TRUE=true ]];
do 
    DiskName="gcloudpd-disk-"${RANDOM:0:2}

    #
    if ! gcloud compute disks describe $DiskName --zone $Zone &> /dev/null;
    then
        break
    fi 
done

# Disk Type
while [[ $ALWAYS_TRUE=true ]];
do     
    read -p "$(echo -e ${YELLOW}[REQUIRED]${WHITE} Please enter the type of disk that you want to create:) " DiskType

    # Create Disk
    if [[ $DiskType == "pd-balanced" ]] || [[ $DiskType == "pd-ssd" ]] || [[ $DiskType == "pd-standard" ]] || [[ $DiskType == "pd-extreme" ]];
    then
        break
    else
        echo -e "${RED}[ERROR 7]${WHITE} Please enter a valid persistent disk type." && echo ""
    fi
done

#  Disk Size
while [[ $ALWAYS_TRUE=true ]];
do 
    read -p "$(echo -e ${YELLOW}[REQUIRED]${WHITE} Please enter how many gigabytes that you want you disk to have. The minimum disk size is 10 GB:) " DiskSize

    # 
    if [[ $DiskSize =~ $Integer ]];
    then
        #
        if [[ $DiskSize -ge 10 ]];
        then
            echo ""
            
            #
            if gcloud compute disks create $DiskName --size $DiskSize --type $DiskType --zone $Zone &> $DiskName.txt;
            then
                break

            #
            elif cat $DiskName.txt | grep -q "Quota 'SSD_TOTAL_GB' exceeded";
            then
                echo "" && cat $DiskName.txt 
                echo "" && echo -e "${RED}[ERROR 2]${WHITE} Quota exceeded." 
                echo "" && rm $DiskName.txt
                exit 1
            fi
        else
            echo -e "${RED}[ERROR 3]${WHITE} Please enter a value that's at least 10." && echo ""
        fi
    else
        echo -e "${RED}[ERROR 8]${WHITE} Please enter a valid number." && echo ""
    fi
done

echo "" && echo -e "${GREEN}[SUCCESS]${WHITE} A disk called $DiskName was successfully created in $Zone." && echo ""

# Attach disk to an existing VM if the user wanted to
if [[ ${AttachDisk,,} == "y" ]];
then
    gcloud compute instances attach-disk $InstanceName \
    --disk $DiskName \
    --device-name=$DiskName \
    --zone $Zone

    echo -e "${GREEN}[SUCCESS]${WHITE} $DiskName was successfully attached to $InstanceName." && echo ""
fi

# Cleanup
rm $DiskName.txt

# The script worked successfully
echo -e "${GREEN}[SUCCESS]${WHITE} gCloudPD has successfully finished executing." && echo ""
exit 0
