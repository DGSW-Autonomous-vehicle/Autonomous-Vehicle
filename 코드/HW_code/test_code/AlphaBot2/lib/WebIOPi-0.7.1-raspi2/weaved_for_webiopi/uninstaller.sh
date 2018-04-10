#!/bin/bash

#  uninstaller.sh
#  
#
#  Weaved, Inc. Copyright 2014. All rights reserved.
#

##### Settings #####
VERSION=v1.3
AUTHOR="Mike Young"
MODIFIED="January 12, 2015"
DAEMON=weavedConnectd
WEAVED_DIR=/etc/weaved/services
BIN_DIR=/usr/bin
NOTIFIER=notify.sh
INIT_DIR=/etc/init.d
PID_DIR=/var/run
filename=`basename $0`
loginURL=https://api.weaved.com/api/user/login
unregdevicelistURL=https://api.weaved.com/api/device/list/unregistered
preregdeviceURL=https://api.weaved.com/api/device/create
regdeviceURL=https://api.weaved.com/api/device/register
regdeviceURL2=http://api.weaved.com/api/device/register
deleteURL=http://api.weaved.com/api/device/delete
connectURL=http://api.weaved.com/api/device/connect
##### End Settings #####

#########  Check prior installs #########

##### Check for Bash #####
bashCheck()
{
    if [ -z $BASH_VERSION ]; then
        clear
        printf "You executed this script with dash vs bash! \n\n"
        printf "Unfortunately, not all shells are the same. \n\n"
        printf "Please execute \"chmod +x "$filename"\" and then \n"
        printf "execute \"./"$filename"\".  \n\n"
        printf "Thank you! \n"
        exit
    else
        echo "Now launching the Weaved connectd daemon installer..."
    fi
}
##### End Bash Check #####

##### Version #####
displayVersion()
{
    printf "You are running installer script Version: %s \n" "$VERSION"
    printf "Last modified on %s, by %s. \n\n" "$MODIFIED" "$AUTHOR"
}
##### End Version #####

######### Begin Portal Login #########
userLogin () #Portal login function
{
    printf "\n\n\n"
    printf "Please enter your Weaved Username (email address): \n"
    read username
    printf "\nNow, please enter your password: \n"
    read  -s password
    resp=$(curl -s -S -X GET -H "content-type:application/json" -H "apikey:WeavedDeveloperToolsWy98ayxR" "$loginURL/$username/$password")
    token=$(echo "$resp" | awk -F ":" '{print $3}' | awk -F "," '{print $1}' | sed -e 's/^"//'  -e 's/"$//')
    loginFailed=$(echo "$resp" | grep "login failed" | sed 's/"//g')
    login404=$(echo "$resp" | grep 404 | sed 's/"//g')
}
######### End Portal Login #########

######### Test Login #########
testLogin()
{
    while [[ "$loginFailed" != "" || "$login404" != "" ]]; do
        clear
        printf "You have entered either an incorrect username or password. Please try again. \n\n"
        userLogin
    done
}
######### End Test Login #########

######### Detect services #########
listWeavedServices()
{
    if [ -d $WEAVED_DIR ]; then
        services=$(find $WEAVED_DIR -name Weaved*.conf)
        echo -e "We have detected the following services: \n"
        for service in $services; do
            echo $service |xargs basename | awk -F "." {'print $1'}
        done
        echo -e "\n"
        for service in $services; do
            echo $service |xargs basename | awk -F "." {'print $1'}
            if ask "Would you like to delete this service?"; then
                uid="$(tail $service | grep UID | awk -F "UID" '{print $2}' | xargs echo -n)"
                curl -s $deleteURL -X 'POST' -d "{\"deviceaddress\":\"$uid\"}" -H “Content-Type:application/json” -H "apikey:WeavedDeveloperToolsWy98ayxR" -H "token:$token"
                printf "\n"
                if [ -f $PID_DIR/$(echo $service |xargs basename | awk -F "." {'print $1'}).pid ]; then
                    if [ -f $BIN_DIR/$(echo $service |xargs basename | awk -F "." {'print $1'}).sh ]; then
                        sudo $BIN_DIR/$(echo $service |xargs basename | awk -F "." {'print $1'}).sh stop
                        sudo rm $BIN_DIR/$(echo $service |xargs basename | awk -F "." {'print $1'}).sh
                    fi
                fi
                if [ -f $service ]; then
                    sudo rm $service
                fi
                if [ -f $BIN_DIR/notify_$(echo $service |xargs basename | awk -F "." {'print $1'}).sh ]; then
                    sudo rm $BIN_DIR/notify_$(echo $service |xargs basename | awk -F "." {'print $1'}).sh
                fi
                if [ -f $INIT_DIR/$(echo $service |xargs basename | awk -F "." {'print $1'}) ]; then
                    sudo rm $INIT_DIR/$(echo $service |xargs basename | awk -F "." {'print $1'})
                fi

            fi
        done
        services=$(find $WEAVED_DIR -name Weaved*.conf)
        if [ "$services" = "" ]; then
            printf "\n"
            echo "There no longer appears to be any installed services."
            if ask "Would you like us to uninstall the rest of the Weaved software?"; then
                if [ -n $(ps ax | grep weavedConnectd | grep -v grep) ]; then
                    sudo killall weavedConnectd
                fi
                if [ -f $BIN_DIR/$DAEMON ]; then
                    sudo rm $BIN_DIR/$DAEMON
                fi
                if [ -d $WEAVED_DIR ]; then
                    sudo rm -rf /etc/weaved
                fi
                if [ -f $BIN_DIR/startweaved.sh ]; then
                    sudo rm $BIN_DIR/startweaved.sh
                fi
            fi
        fi
    else
        echo "There doesn't appear to be any services to uninstall."
    fi
}
######### End Detect services #########

######### Ask Function #########
ask()
{
    while true; do
        if [ "${2:-}" = "Y" ]; then
            prompt="Y/n"
            default=Y
        elif [ "${2:-}" = "N" ]; then
            prompt="y/N"
            default=N
        else
            prompt="y/n"
            default=
            fi
    # Ask the question
    read -p "$1 [$prompt] " REPLY
    # Default?
    if [ -z "$REPLY" ]; then
        REPLY=$default
    fi
    # Check if the reply is valid
    case "$REPLY" in
    Y*|y*) return 0 ;;
    N*|n*) return 1 ;;
    esac
    done
}
######### End Ask Function #########
displayVersion
bashCheck
userLogin
testLogin
listWeavedServices

