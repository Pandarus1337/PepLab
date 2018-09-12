#!/bin/bash

# Read desired username, save value
read -p "Enter desired username: " username
echo "Desired username is:" $username		# Debug: check username value

# Read desired password, save value
printf "Enter desired password: " 
read -s passwrd
echo ""
echo "Desired password is:" $passwrd		# Debug: check password value 

# For each server, run the new_user_script
# No need to rewrite an entire script

# Find a way to search through the computer for next UID and GID
# Finds next open UID in the range specified (5030-6000)
# Using that range since mine is 5030
nextUID=$(awk -F: '{uid[$3]=1}END{for(x=5030; x<=6000; x++) {if(uid[x] != ""){}else{print x; exit;}}}' /etc/passwd)
echo "Next available UID is:" $nextUID		# Debug: check UID value

ssh jtsai@128.104.140.215 "user=username; echo $user"

# Run the script on the current computer
# Pass in appropriate values to new_user_script
(echo $username; echo $nextUID; echo panda_tester; echo passwrd) | sudo ./new_user.sh

# TO DO: cd into appropriate directory

# ssh into the next server
# Search for next UID, GID, pass in user and password to and run
# the new_user_script


# Repeat for final server

# NOTES: Password security issues? Same for ssh into other servers.
#	 Hard-code values? Seems a bit sketch and unprofessional.
