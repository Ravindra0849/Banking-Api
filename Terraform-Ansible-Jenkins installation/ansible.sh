#!/bin/bash

# Update the system
sudo apt-get update

# Install software-properties-common
sudo apt install software-properties-common

# Add ansible PPA
sudo add-apt-repository --yes --update ppa:ansible/ansible

# Install ansible
sudo apt-get install ansible -y


