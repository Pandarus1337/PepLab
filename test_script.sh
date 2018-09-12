#!/bin/bash
# Script to set up new user more easily on all three servers at once
# Last modified: 9/12/18

flag=0

# Check flag to prevent stupid infinite whatever recursion
while [[ "$1" =~ ^- && ! "$1" == "--" ]]; do case $1 in
  -f | --flag )
    flag=1
    ;; 
esac; shift; done
if [[ "$1" == '--' ]]; then shift; fi

# Read desired username, save value
read -p "Enter desired username: " username

# Read desired password, save value
printf "Enter desired password: " 
read -s passwrd
echo ""

# For each server, run the new_user_script
# No need to rewrite an entire script

# Find a way to search through the computer for next UID and GID
# Finds next open UID in the range specified (5030-6000)
# Using that range since mine is 5030
nextUID=$(awk -F: '{uid[$3]=1}END{for(x=5030; x<=6000; x++) {if(uid[x] != ""){}else{print x; exit;}}}' /etc/passwd)

#(echo $username; echo $nextUID; echo $nextUID; echo passwrd) | sudo ./new_user.sh

if [ $flag -gt 0 ]; then
	ssh jtsai@128.104.140.174 "cd server-setup-scripts/setup; (echo $username; echo $nextUID; echo $nextUID; echo $passwrd) | sudo ./new_user.sh -f"
	ssh jtsai@128.104.140.175 "cd server-setup-scripts/setup; (echo $username; echo $nextUID; echo $nextUID; echo $passwrd) | sudo ./new_user.sh -f"
fi

# Run the script on the current computer
# Pass in appropriate values to new_user_script

# TO DO: cd into appropriate directory

# ssh into the next server
# Search for next UID, GID, pass in user and password to and run
# the new_user_script


# Repeat for final server

# NOTES: Password security issues? Same for ssh into other servers.
#	 Hard-code values? Seems a bit sketch and unprofessional.
