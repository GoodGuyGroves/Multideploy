#!/usr/bin/env bash
#
# Creator: Russell Groves - rgroves@arago.de
# GitHub: https://github.com/GoodGuyGroves
# Date: 25/01/19
# Version: 0.1

# This script can make use of ~/.ssh/config to operate
# Example ~/.ssh/config file
# ##
# Host foobar
#     User someuser
#     HostName my.hostname.com
#     Port 22
#     IdentityFile ~/.ssh/rsa
# ##

# Reset the built in SECONDS variable for time keeping purposes
SECONDS=0

# A list of servers to run the scripts on. Each server must be setup in ~/.ssh/config
serv_list="myserv1 myserv2 myserv3"

# A list of scripts or linux commands to run on each server. Each script must be +x and be local to this script itself.
script_list="hostname postinstall.sh configenv.sh"

# An array to store our results in
declare -A arr

# The function that gets run on each server
run_cmd () {
    # Check if the given argument is a local file
    if [[ -f ${2} ]]
    then
        # Execute the script on the remote host since it is a local script
        # We use 'nohup' here in case if if it an especially long-running script
        ssh ${1} "nohup bash -s" < ${2} &
    # This will determine if the supplied command is a Linux command or just gibberish
    # Note: This only checks on your local machine if the command exists, it does not check on the remote host
    elif [[ -f $(command -v ${2}) ]]
    then
        # If it's not a local file we assume it's a Linux command, eval it on the remote host
        ssh ${1} "eval ${2} &"
    else
        printf "Cannot run \"${2}\" command or script not found."
    fi
}

# Loop control variables that will help us access the simulated 2-Dimensional Array to retrieve our script outputs
n=0
i=0

# Loop through each server in the server list, each time assigning the variable
# $serv to the currently selected server in $serv_list
for serv in ${serv_list}; do
    # Loop through each script in the script list, each time assigning the variable
    # $script to the currently selected script in $script_list
    for script in ${script_list}; do
        # Execute the run_cmd function on the given server and script and push it to the background
        # Assign the output to an array, using our loop control variables to place them
        # Eg. arr[0,0], arr[0,1], arr[1,3], etc.
        arr[${n},${i}]="$(run_cmd ${serv} ${script} &)"
        i=$((i+1))
    done
    n=$((n+1))
done

# Wait for all parallel commands to finish executing before printing them out
wait

# Here I used a C-style for-loop since regular Bash for-loop's don't operate as I needed
for (( x=0; x<=${n}; x++ ))
do
    for (( y=0; y<=${i}; y++ ))
    do
       printf "${arr[${x},${y}]}\n"
    done
done

# Print out how long it took for the script to run
printf "\nScript run time: ${SECONDS} seconds.\n"
