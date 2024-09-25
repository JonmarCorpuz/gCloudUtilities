#!/bin/bash

apt update
apt -y install apache2

curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
sudo bash add-google-cloud-ops-agent-repo.sh --also-install

#/var/www/html/index.html
