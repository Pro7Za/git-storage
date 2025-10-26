#!/usr/bin/env bash

# THIS SCRIPT WILL CREATE SSH KEY PAIR AND DISTRIBUTE ACROSS ALL NODES

read -p "Enter the name for the key : " KEY_NAME
ssh-keygen -b 2048 -t rsa -f /home/vagrant/.ssh/${KEY_NAME} -q -N ""

# LOOPING THROUGH AND DISTRIBUTING THE KEY

for val in controller managed1 managed2; do
  echo "-------------------- COPYING KEY TO ${val^^} NODE ------------------------------"
  sshpass -p 'vagrant' ssh-copy-id -f -i /home/vagrant/.ssh/${KEY_NAME}.pub -o "StrictHostKeyChecking=no" vagrant@$val
done
