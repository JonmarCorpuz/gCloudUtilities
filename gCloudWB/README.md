# About CreateVPC

```Text
 ________  ________  ___       ________  ___  ___  ________  ___       __   ________     
|\   ____\|\   ____\|\  \     |\   __  \|\  \|\  \|\   ___ \|\  \     |\  \|\   __  \    
\ \  \___|\ \  \___|\ \  \    \ \  \|\  \ \  \\\  \ \  \_|\ \ \  \    \ \  \ \  \|\ /_   
 \ \  \  __\ \  \    \ \  \    \ \  \\\  \ \  \\\  \ \  \ \\ \ \  \  __\ \  \ \   __  \  
  \ \  \|\  \ \  \____\ \  \____\ \  \\\  \ \  \\\  \ \  \_\\ \ \  \|\__\_\  \ \  \|\  \ 
   \ \_______\ \_______\ \_______\ \_______\ \_______\ \_______\ \____________\ \_______\
    \|_______|\|_______|\|_______|\|_______|\|_______|\|_______|\|____________|\|_______|
 ```                                                                                                                                                                                       
gCloud Web Balancer is an interactive script written by Jonmar Corpuz to help GCP customers easily create and launch a redundant web application using a simple network architecture.

* Current version: 1.0

# Infrastructure Components

* Managed Instance Group
* Firewall Rules
* Health Checks
* External Application Load Balancer

# Upcoming Features

- [ ] Configure a preemptible and very cheap resource architecture
- [ ] Insert a timer and after time automatically delete resources
- [X] Configure MIG autoscaling
- [X] Configure MIG health checks
- [ ] Configure MIG health checks to use VM private addresses
- [X] Install Ops Agent on VM instances
- [ ] Monitor VPC traffic
- [ ] Remove public IP addresses from VM instances
- [ ] Output a script that the user can use to recreate the same infrastructure that he created with the script without being asked to re-enter the same information again
- [ ] Convert the outputted script into a Terraform configuration file
- [ ] A function to delete the created resources if the script return an exit code 1
- [ ] Optionally provided resource monitoring using gCloudMO.sh
- [ ] Add option --service-acount
- [ ] Add option --create-disk
