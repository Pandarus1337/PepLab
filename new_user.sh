#!/usr/bin/env bash

#test for root permissions
if [ "$(whoami)" != "root" ]; then
    echo 'No root permissions, run again using "sudo !!"'
    exit 1
fi


#create subvolumes for backing up
system_mount="/mnt/external_system"
files_mount="/mnt/external_files"
google_infile="/etc/google-backups/backup_dirs.in"
#backup_dir_name="backups"
#btrbk_files="/etc/btrbk/btrbk-files.conf"
#btrbk_system="/etc/btrbk/btrbk-system.conf"

regular="false"
sudoer="false"
group="Core"
sudo_group="sudo"
backup_regular_home="false"
skip_full="false"
skip_google="false"

#echo $HOME
#echo $user_id
#echo $group_id

read -p "Username: " username

if [ -z "$user_id" ];then
        user_id=-1
fi

if [ -z "$group_id" ]; then
        group_id=-1
fi

#user_id="$(printenv user_id)"
#group_id="$(printenv group_id)"

backup_dir="backups-$username"
temp_dir="temp-$username"
subvols=("/home/$username" "/home/$username/$backup_dir" "/home/$username/$temp_dir")


script_help () {
echo "Usage: ./new_user.sh [options] --user username" 
exit 0
}

del_user () 
{
rem='n'
read -p "This will delete $username and all files in their home directory, continue? [y/N] " rem

if [[ "$rem" == 'n' || "$rem" == 'N' ]]; then
    echo "Keeping $username..."
    exit 0
    exit 0
fi

echo "Removing user $username..."
userdel $username

if [[ $? != 0 ]]; then
        echo "Failed to delete $username..."
        exit 1
fi

echo "Removing $username's home directory and subvolumes..."
find "/home/$username/" -mindepth 1 -delete
for sub in ${subvols[@]}; do
        btrfs subvolume del $sub
done
#make sure to delete the /home/username subvolume
btrfs subvolume delete "/home/$username"
#btrfs subvolume del $external_files/$username
#btrfs subvolume del $external_system/$username

echo "Removing $username from Google backups..."
cp $google_infile $google_infile.bak
sed -i -e "/$username/d" $google_infile

echo "Removing $username from files backup..."
cp $btrbk_files $btrbk_files.bak
sed -i -e "/$username/d" $btrbk_files

echo "Removing $username from system backup..."
cp $btrbk_system $btrbk_system.bak
sed -i -e "/$username/d" $btrbk_system

echo "Done!"
exit 0
}



for opt in "$@"; do
    case "$opt" in
        --username)
            shift
            username=${1}
            ;;
        --help)
            script_help
            shift
            exit 0
            ;;
     --sudo)
         sudoer="true"
         shift
         ;;
     --regular)
         regular="true"
         shift
         ;;
        --snapshot)
            backup_regular_home="true"
            shift
            ;;
        --skip-full)
            skip_full="true"
            shift
            ;;
        --skip-google)
            er
            shift
            ;;
	--remove)
	    del_user
	    shift
            ;;
    --uid=*)
        user_id="$1"
        shift
        ;;
    --gid=*)
        group_id="$1"
        shift
        ;;
        *)
            ;;
    esac
done

if [ $user_id -eq "-1"  ];then
        read -p "UID: " user_id
fi
if [ $group_id -eq "-1" ]; then
        read -p "GID: " group_id
fi

#echo "read $user_id and $group_id from environment!"
#exit 0

echo "Adding group $username with GID $group_id"
groupadd -g "$group_id" "$username"

echo "Adding $username with UID $user_id and GID $group_id"
useradd -M -s /bin/bash "-u $user_id" "-g $group_id" "$username"

if [ $? -ne 0 ]; then
    echo "Failed to add user"
    exit 1
fi

if [[ "$regular" == "false" ]]; then
    for sub in ${subvols[@]}; do
        btrfs subvolume create "$sub"
        #btrfs quota enable "$sub"
        chown -R "$username:$username" "$sub"
    done
fi

cp  /etc/skel/{.profile,.bash_logout,.bashrc} "/home/$username/"
chown -R "$username":"$username" "/home/$username"

#chsh -s /bin/bash "$username"

if [[ "$regular" == "true" ]]; then
    subvols=${subvols[@]:1}
    for sub in ${subvols[@]}; do
        btrfs subvolume create "$sub"
        #btrfs quota enable "$sub"
        chown -R "$username:$username" "$sub"
    done
fi
chown -R "$username:$username" "/home/$username"

echo "Adding $username to group $group..."
usermod -a -G "$group" "$username"

if [[ "$sudoer" == "true" || "$regular" == "false" ]]; then
    usermod -a -G "$sudo_group" "$username"
fi

echo "Setting password for $username..."
passwd "$username"

#if [[ "$regular" == "false" || "$backup_regular_home" == "true" ]]; then
#       echo "Adding /home/$username to be backed up"
#       btrfs subvolume create "$files_mount/$username"
#       printf "\tsubvolume @home/$username\n" >> /etc/btrbk/btrbk-files.conf
#       printf "\t\ttarget send-receive $files_mount/$username\n" >> /etc/btrbk/btrbk-files.conf
#fi

#if [[ "$skip_full" == "false" ]]; then
#       echo "Adding $username to full system backups"
#       btrfs subvolume create "$system_mount/home/$username"   
#       printf "\tsubvolume @home/$username\n" >> /etc/btrbk/btrbk-system.conf
#       printf "\t\ttarget send-receive $system_mount/home/$username\n" >> /etc/btrbk/btrbk-system.conf
#
#       printf "\tsubvolume @home/$username/backups-$username\n" >> /etc/btrbk/btrbk-system.conf
#       printf "\t\ttarget send-receive $system_mount/home/$username\n" >> /etc/btrbk/btrbk-system.conf
#fi

if [[ "$skip_google" == "false" ]]; then
        echo "Adding $username to backups on Google."
        printf "$username cp /home/$username/$backup_dir\n" >> $google_infile
fi

exit 0
                                                                                                               224,1         Bot

