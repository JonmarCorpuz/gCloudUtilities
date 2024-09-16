# About CreateVPC

```Text
 ________  ________  _______   ________  _________  _______   ___      ___ ________  ________
|\   ____\|\   __  \|\  ___ \ |\   __  \|\___   ___\\  ___ \ |\  \    /  /|\   __  \|\   ____\
\ \  \___|\ \  \|\  \ \   __/|\ \  \|\  \|___ \  \_\ \   __/|\ \  \  /  / | \  \|\  \ \  \___|
 \ \  \    \ \   _  _\ \  \_|/_\ \   __  \   \ \  \ \ \  \_|/_\ \  \/  / / \ \   ____\ \  \
  \ \  \____\ \  \\  \\ \  \_|\ \ \  \ \  \   \ \  \ \ \  \_|\ \ \    / /   \ \  \___|\ \  \____
   \ \_______\ \__\\ _\\ \_______\ \__\ \__\   \ \__\ \ \_______\ \__/ /     \ \__\    \ \_______\
    \|_______|\|__|\|__|\|_______|\|__|\|__|    \|__|  \|_______|\|__|/       \|__|     \|_______|
```
An interactive script written by Jonmar Corpuz to help GCP customers easily create and launch a basic load balanced VPC 
comprised of a MIG within a private subnet.

# To Do

- [X] Configure MIG autoscaling
- [ ] Configure MIG health checks 
- [ ] Give the option to specify specific zones
- [ ] Output a script that the user can use to recreate the same infrastructure that he created with the script without being asked to re-enter the same information again
- [ ] Convert the outputted script into a Terraform configuration file