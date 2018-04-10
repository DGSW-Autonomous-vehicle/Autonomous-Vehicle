#!/bin/bash

#  installer.sh
#  
#
#  Weaved, Inc. Copyright 2015. All rights reserved.
#

##### Settings #####
VERSION=v1.3
AUTHOR="Mike Young"
MODIFIED="February 3, 2015"
DAEMON=weavedConnectd
USERNAME=""
PASSWD=""
WEAVED_DIR=/etc/weaved
BIN_DIR=/usr/bin
NOTIFIER=notify.sh
INIT_DIR=/etc/init.d
PID_DIR=/var/run
filename=`basename $0`
loginURL=https://api.weaved.com/api/user/login
unregdevicelistURL=https://api.weaved.com/api/device/list/unregistered
preregdeviceURL=https://api.weaved.com/v6/api/device/create
regdeviceURL=https://api.weaved.com/api/device/register
regdeviceURL2=http://api.weaved.com/v6/api/device/register
deleteURL=http://api.weaved.com/v6/api/device/delete
connectURL=http://api.weaved.com/v6/api/device/connect
PLATFORM=pi
##### End Settings #####

##### Check Requirements #####
checkRequirements()
{
    FILE="/usr/bin/curl"

    if [ -f $FILE ];
    then
       echo "."
    else
       echo "$FILE command is not installed."
       echo "Please run this command then try again:"
       echo "sudo apt-get install curl"
       echo ""
       EXIT="1"
    fi

    if [ "$EXIT" = "1" ]; then exit; fi
}
##### End Check Requirements #####

##### Version #####
displayVersion()
{
    printf "You are running installer script Version: %s \n" "$VERSION"
    printf "Last modified on %s, by %s. \n\n" "$MODIFIED" "$AUTHOR"
}
##### End Version #####

##### Compatibility checker #####
weavedCompatitbility()
{
    ./bin/"$DAEMON"."$PLATFORM" -n | grep OK > .networkDump
    printf "Checking for compatibility with Weaved's network... \n\n"
    number=$(cat .networkDump | wc -l)
    for i in $(seq 1 $number); do
        awk "NR==$i" .networkDump
        printf "\n"
        sleep 1
    done
    if [ "$number" -ge 3 ]; then
        printf "Congratulations! Your network is compatible with Weaved services.\n\n"
        sleep 5
    elif [ "$(cat .networkDump | grep "Send to" | grep "OK" | wc -l)" -lt 1 ]; then
        printf "Unfortunately, it appears your network may not currently be compatible with Weaved services\n."
        printf "Please visit https://forum.weaved.com for more support.\n\n"
        exit
    fi
}
##### End Compatibility checker #####

##### Check for existing services #####
checkforServices()
{
    if [ -e "/etc/weaved/services" ]; then
        ls /etc/weaved/services/* > ./.legacy_instances
        instanceNumber=$(cat .legacy_instances | wc -l)
        if [ -f ./.instances ]; then
            rm ./.instances
        fi
        echo -n "" > .instances
        printf "We have detected the following Weaved services already installed: \n\n"
        for i in $(seq 1 $instanceNumber); do
            instanceName=$(awk "NR==$i" .legacy_instances | xargs basename | awk -F "." {'print $1'})
            echo $instanceName >> .instances
        done 
        legacyInstances=$(cat .instances)
        echo $legacyInstances
        if ask "Do you wish to continue?"; then
            echo "Continuing installation..."
        else
            echo "Now exiting..."
            exit
        fi
    fi
}
##### End Check for existing services #####

##### Platform detection #####
platformDetection()
{
    machineType="$(uname -m)"
    osName="$(uname -s)"
    if [ -f "/etc/os-release" ]; then
        distributionName=$(cat /etc/os-release | grep ID= | grep -v VERSION | awk -F "=" {'print $2'})
    fi
    if [ "$machineType" = "armv6l" ]; then
        PLATFORM=pi
        SYSLOG=/var/log/syslog
    else
        printf "Sorry, you are running this installer on an unsupported platform. But if you go to \n"
        printf "http://forum.weaved.com we'll be happy to help you get your platform up and running. \n\n"
        printf "Thanks! \n"
        exit
    fi

   printf "Detected platform type: %s \n" "$PLATFORM"
   printf "Using %s for your log file \n\n" "$SYSLOG"
}
##### End Syslog type #####

##### Protocol selection #####
protocolSelection()
{
    clear
    WEAVED_PORT=""
    CUSTOM=0
    if [ "$PLATFORM" = "pi" ]; then
        get_num=1
        printf "We are installing Weaved for WebIOPI.\n\n"
        if [ "$get_num" = 1 ]; then
           PROTOCOL=webiopi
           printf "The default port for WebIOPi is 8000.\n"
	       if ask "Would you like to continue with the default port assignment?"; then
                PORT=8000
           else
                CUSTOM=2
                while [[ ! "${get_port}" =~ ^[0-9]+$ ]]; do
                    printf "Please enter your desired port number (1-65536):"
                    read get_port
                    ! [[ "${get_port}" -ge 1 && "${get_port}" -le 65536 ]] && unset get_port
                done
                PORT="$get_port"
            fi
            WEAVED_PORT=Weaved"$PROTOCOL""$PORT"
        fi
        printf "We will install Weaved services for the following:\n\n"
        if [ "$CUSTOM" = 1 ]; then
            printf "Protocol: %s \n" "$CUSTOM_PROTOCOL"
        else
            printf "Protocol: %s \n" "$PROTOCOL"
        fi
        printf "Port #: %s \n" "$PORT"
        printf "Service name: %s \n" "$WEAVED_PORT"

    fi
    if [ $(echo $legacyInstances | grep $WEAVED_PORT | wc -l) -gt 0 ]; then
        printf "You've selected to install %s, which is already installed. \n" "$WEAVED_PORT."
        if ask "Do you wish to overwrite your previous settings?"; then
            userLogin
            testLogin
            deleteDevice
            if [ -f $PID_DIR/$WEAVED_PORT.pid ]; then
                if [ -f $BIN_DIR/$WEAVED_PORT.sh ]; then
                    sudo $BIN_DIR/$WEAVED_PORT.sh stop
                else
                    if ask "The start/stop mechanism has changed in this installer version. May we stop all Weaved services to continue?"; then
                        sudo killall weavedConnectd
                    fi
                    if [ -f $PID_DIR/$WEAVED_PORT.pid ]; then
                        sudo rm $PID_DIR/$WEAVED_PORT.pid
                    fi
                fi
            fi
        else 
            printf "We will allow you to re-select your desired service to install... \n\n"
            protocolSelection
        fi
    else
        userLogin
        testLogin
    fi
}
##### End Protocol selection #####


##### Check for Bash #####
bashCheck()
{
    if [ "$BASH_VERSION" = '' ]; then
        clear
        printf "You executed this script with dash vs bash! \n\n"
        printf "Unfortunately, not all shells are the same. \n\n"
        printf "Please execute \"chmod +x "$filename"\" and then \n"
        printf "execute \"./"$filename"\".  \n\n"
        printf "Thank you! \n"
        exit
    else
        #clear
        echo "Now launching the Weaved connectd daemon installer..."
    fi
    #clear
}
##### End Bash Check #####

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

######### Begin Portal Login #########
userLogin () #Portal login function
{
    if [ "$USERNAME" != "" ]; then 
        username="$USERNAME"
    else	
        printf "\n\n\n"
        printf "Sign-up for free at http://developer.weaved.com then enter your Weaved login: \n"
        read username
    fi
    if [ "$PASSWD" != "" ]; then
        password="$PASSWD"
    else
        printf "\nNow, please enter your password: \n"
        read  -s password
    fi
    resp=$(curl -s -S -X GET -H "content-type:application/json" -H "apikey:WeavedDeveloperToolsWy98ayxR" "$loginURL/$username/$password")
    token=$(echo "$resp" | awk -F ":" '{print $3}' | awk -F "," '{print $1}' | sed -e 's/^"//'  -e 's/"$//')
    loginFailed=$(echo "$resp" | grep "login failed" | sed 's/"//g')
    login404=$(echo "$resp" | grep 404 | sed 's/"//g')
    date +"%s" > ./.lastlogin
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

######### Install Enablement #########
installEnablement()
{
    if [ ! -d "WEAVED_DIR" ]; then
       sudo mkdir -p "$WEAVED_DIR"/services
    fi

    cat ./enablements/"$PROTOCOL"."$PLATFORM" > ./"$WEAVED_PORT".conf
}
######### End Install Enablement #########

######### Install Notifier #########
installNotifier()
{
    sudo chmod +x ./scripts/"$NOTIFIER"
    if [ ! -f "$BIN_DIR"/"$NOTIFIER" ]; then
        sudo cp ./scripts/"$NOTIFIER" "$BIN_DIR"
        printf "Copied %s to %s \n" "$NOTIFIER" "$BIN_DIR"
    fi
}
######### End Install Notifier #########

######### Install Send Notification #########
installSendNotification()
{
    sed s/REPLACE/"$WEAVED_PORT"/ < ./scripts/send_notification.sh > ./send_notification.sh
    chmod +x ./send_notification.sh
    sudo mv ./send_notification.sh $BIN_DIR/notify_$WEAVED_PORT.sh
    printf "Copied notify_%s.sh to %s \n" "$WEAVED_PORT" "$BIN_DIR"
}
######### End Install Send Notification #########

######### Service Install #########
installWeavedConnectd()
{
    if [ -f "$BIN_DIR/$DAEMON" ]; then
        installedVersion="$($BIN_DIR/$DAEMON | grep "Weaved, Inc." | awk {'print $2'} | awk -F "." {'print $1"."$2'})"
        newVersion="$(./bin/$DAEMON.$PLATFORM | grep "Weaved, Inc." | awk {'print $2'} | awk -F "." {'print $1"."$2'})"
        if [ "$newVersion" != "$installedVersion" ]; then
            echo "We need to update $DAEMON from v$installedVersion to v$newVersion."
            if [ -n "$(ps ax | grep weaved | grep -v grep)" ]; then
                echo "We need to shut down all Weaved services to update the Weaved daemon."
                echo "We will restart them once installation is complete."
                if ask "May we continue?"; then
                    sudo killall weavedConnectd
                else
                    echo "We are exiting the installer..."
                    exit
                fi
            fi
            sudo chmod +x ./bin/"$DAEMON"."$PLATFORM"
            sudo cp ./bin/"$DAEMON"."$PLATFORM" "$BIN_DIR"/"$DAEMON"
            printf "Copied %s to %s \n" "$DAEMON" "$BIN_DIR"
        fi
    fi
    if [ ! -f "$BIN_DIR/$DAEMON" ]; then
            sudo chmod +x ./bin/"$DAEMON"."$PLATFORM"
            sudo cp ./bin/"$DAEMON"."$PLATFORM" "$BIN_DIR"/"$DAEMON"
            printf "Copied %s to %s \n" "$DAEMON" "$BIN_DIR"
    fi
       
}
######### End Service Install #########

######### Install Start/Stop Scripts #########
installStartStop()
{
    sed s/WEAVED_PORT=/WEAVED_PORT="$WEAVED_PORT"/ < ./scripts/launchweaved.sh > ./"$WEAVED_PORT".sh
    sudo mv ./"$WEAVED_PORT".sh $BIN_DIR/$WEAVED_PORT.sh
    sudo chmod +x $BIN_DIR/$WEAVED_PORT.sh
    if [ ! -f /usr/bin/startweaved.sh ]; then
        sudo cp ./scripts/startweaved.sh "$BIN_DIR"
        printf "startweaved.sh copied to %s\n" "$BIN_DIR"
    fi
    checkCron=$(sudo crontab -l | grep startweaved.sh | wc -l)
    if [ $checkCron = 0 ]; then
        sudo crontab -l 2> /dev/null; echo "@reboot /usr/bin/startweaved.sh" | sudo crontab
    fi
    checkStartWeaved=$(cat "$BIN_DIR"/startweaved.sh | grep "$WEAVED_PORT.sh" | wc -l)
    if [ $checkStartWeaved = 0 ]; then
        sed s/REPLACE_TEXT/"$WEAVED_PORT"/ < ./scripts/startweaved_macosx.add > ./startweaved_macosx.add
        sudo sh -c "cat startweaved_macosx.add >> /usr/bin/startweaved.sh"
        #rm ./startweaved_macosx.add
    fi
    printf "\n\n"
}
######### End Start/Stop Scripts #########

######### Fetch UID #########
fetchUID()
{
    sudo "$BIN_DIR"/"$DAEMON" -life -1 -f ./"$WEAVED_PORT".conf > .DeviceTypeSting
    DEVICETYPE="$(cat .DeviceTypeSting | grep DeviceType | awk -F "=" '{print $2}')"
    rm .DeviceTypeSting
}
######### End Fetch UID #########

######### Check for UID #########
checkUID()
{
    checkforUID="$(tail $WEAVED_PORT.conf | grep UID | wc -l)"
    if [ $checkforUID = 2 ]; then
        sudo cp ./"$WEAVED_PORT".conf /"$WEAVED_DIR"/services/
        uid=$(tail $WEAVED_DIR/services/$WEAVED_PORT.conf | grep UID | awk -F "UID" '{print $2}' | xargs echo -n)
        printf "\n\nYour device UID has been successfully provisioned as: %s. \n\n" "$uid"
    else
        retryFetchUID
    fi
}
######### Check for UID #########

######### Retry Fetch UID ##########
retryFetchUID()
{
    for run in {1..5}
    do
        fetchUID
        checkforUID="$(tail $WEAVED_PORT.conf | grep UID | wc -l)"
        if [ "$checkforUID" = 2 ]; then
            sudo cp ./"$WEAVED_PORT".conf /"$WEAVED_DIR"/services/
            uid="$(tail $WEAVED_DIR/services/$WEAVED_PORT.conf | grep UID | awk -F "UID" '{print $2}' | xargs echo -n)"
            printf "\n\nYour device UID has been successfully provisioned as: %s. \n\n" "$uid"
            break
        fi
    done
    checkforUID="$(tail $WEAVED_PORT.conf | grep UID | wc -l)"
    if [ "$checkforUID" != 2 ]; then
        printf "We have unsuccessfully retried to obtain a UID. Please contact Weaved Support at http://forum.weaved.com for more support.\n\n"
    fi
}
######### Retry Fetch UID ##########

######### Pre-register Device #########
preregisterUID()
{
    preregUID="$(curl -s $preregdeviceURL -X 'POST' -d "{\"deviceaddress\":\"$uid\", \"devicetype\":\"$DEVICETYPE\"}" -H “Content-Type:application/json” -H "apikey:WeavedDeveloperToolsWy98ayxR" -H "token:$token")"
    test1="$(echo $preregUID | grep "true" | wc -l)"
    test2="$(echo $preregUID | grep -E "missing api token|api token missing" | wc -l)"
    test3="$(echo $preregUID | grep "false" | wc -l)"
    if [ "$test1" = 1 ]; then
        printf "Pre-registration of UID: %s successful. \n\n" "$uid"
    elif [ "$test2" = 1 ]; then
        printf "You are missing a valid session token and must be logged back in. \n"
        userLogin
        preregisterUID
    elif [ "$test3" = 1 ]; then
        printf "Sorry, but for some reason, the pre-registration of UID: %s is failing. While we are working to resolve this problem, you can \n" "$uid"
        printf "finish your registration process manually via the following steps: \n\n"
        printf "1) From the same network as your device (e.g., Cannot have device on LAN and Client on LTE), please log into https://weaved.com \n"
        printf "2) Once logged in, please visit the following URL https://developer.weaved.com/portal/members/registerDevice.php \n"
        printf "3) Enter an alias for your device or service \n"
        printf "4) Please contact us at http://forum.weaved.com and let us know about this issue, including the version of installer, and whether \n"
        printf "the manual registration worked for you. Sorry for the inconvenience. \n\n"
        overridePort
        startService
        installYo
        exit
    fi
}
######### End Pre-register Device #########

######### Pre-register Device #########
getSecret()
{
    secretCall="$(curl -s $regdeviceURL2 -X 'POST' -d "{\"deviceaddress\":\"$uid\", \"devicealias\":\"$alias\", \"skipsecret\":\"true\"}" -H “Content-Type:application/json” -H "apikey:WeavedDeveloperToolsWy98ayxR" -H "token:$token")"
    test1="$(echo $secretCall | grep "true" | wc -l)"
    test2="$(echo $secretCall | grep -E "missing api token|api token missing" | wc -l)"
    test3="$(echo $secretCall | grep "false" | wc -l)"
    if [ $test1 = 1 ]; then
        secret="$(echo $secretCall | awk -F "," '{print $2}' | awk -F "\"" '{print $4}' | sed s/://g)"
        echo "# password - erase this line to unregister the device" >> ./"$WEAVED_PORT".conf
        echo "password $secret" >> ./"$WEAVED_PORT".conf
        sudo mv ./"$WEAVED_PORT".conf "$WEAVED_DIR"/services/"$WEAVED_PORT".conf
    elif [ $test2 = 1 ]; then
        printf "You are missing a valid session token and must be logged back in. \n"
        userLogin
        getSecret
    fi
}
######### End Pre-register Device #########

######### Reg Message #########
regMsg()
{
    clear
    printf "************************************************************************** \n"
    printf "CONGRATULATIONS! You are now registered with Weaved. \n"
    printf "Your registration information is as follows: \n\n"
    printf "Device alias: \n"
    printf "%s \n\n" "$alias"
    printf "Device UID: \n"
    printf "%s \n\n" "$uid"
    printf "Device secret: \n"
    printf "%s \n\n" "$secret"
    printf "The alias, Device UID and Device secret are kept in the License File: \n"
    printf "%s/services/%s.conf \n\n" "$WEAVED_DIR" "$WEAVED_PORT"
    printf "If you delete this License File, you will have to re-run the installer. \n\n"
    printf "************************************************************************** \n\n\n"
    printf "Starting and stopping your service can be done by typing:\n\"sudo %s/%s.sh start|stop|restart\" \n" "$BIN_DIR" "$WEAVED_PORT"
    
}
######### End Reg Message #########

######### Register Device #########
registerDevice()
{
    clear
    printf "We will now register your device with the Weaved backend services. \n"
    printf "Please provide an alias for your device: \n"
    read alias
    if [ "$alias" != "" ]; then
        printf "Your device will be called %s.\n\n" "$alias"
#        echo "You can rename it later in the Weaved Portal." 
    else
        alias="$uid"
        printf "For some reason, we're having problems using your desired alias. We will instead \n"
        printf "use %s as your device alias, but you may change it via the web portal. \n\n" "$uid"
    fi
}
######### End Register Device #########

######### Start Service #########
startService()
{
    echo -n "Registering Weaved services for $WEAVED_PORT ";sleep 1;echo -n ".";sleep 1;echo -n ".";sleep 1;echo -n ".";sleep 1;echo -n ".";sleep 1;echo -n ".";sleep 1;echo -n ".";sleep 1;echo -n ".";sleep 1;echo -n ".";sleep 1;echo -n ".";sleep 1;echo -n ".";sleep 1;echo -n ".";sleep 1;echo -n ".";sleep 1;echo -n ".";sleep 1;echo -n ".";sleep 1;echo -n ".";sleep 1;echo -n ".";sleep 1;echo -e "\n\n"
    if [ -e "$PID_DIR"/"$WEAVED_PORT.pid" ]; then
        sudo $BIN_DIR/$WEAVED_PORT.sh stop
        if [ -e "$PID_DIR"/"$WEAVED_PORT.pid" ]; then
            sudo rm "$PID_DIR"/"$WEAVED_PORT".pid
        fi
    fi
    sudo $BIN_DIR/$WEAVED_PORT.sh start
}
######### End Start Service #########

######### Check for services #########
checkforServices()
{
    if [ -e "/etc/weaved/services" ]; then
        ls /etc/weaved/services/* > ./.legacy_instances
        instanceNumber=$(cat .legacy_instances | wc -l)
        if [ -f ./.instances ]; then
            rm ./.instances
        fi
        echo -n "" > .instances
        printf "We have detected the following Weaved services already installed: \n\n"
        for i in $(seq 1 $instanceNumber); do
            instanceName=$(awk "NR==$i" .legacy_instances | xargs basename | awk -F "." {'print $1'})
            echo $instanceName >> .instances
        done 
        legacyInstances=$(cat .instances)
        echo $legacyInstances
        if ask "Do you wish to continue?"; then
            echo "Continuing installation..."
        else
            echo "Now exiting..."
            exit
        fi
    fi
}
######### End Check for services #########

######### Install Yo #########
installYo()
{
    sudo cp ./Yo "$BIN_DIR"
}
######### End Install Yo #########

######### Port Override #########
overridePort()
{
    if [ "$CUSTOM" = 1 ]; then
        cp "$WEAVED_DIR"/services/"$WEAVED_PORT".conf ./
        echo "proxy_dest_port $PORT" >> ./"$WEAVED_PORT".conf
        sudo mv ./"$WEAVED_PORT".conf "$WEAVED_DIR"/services/
    elif [[ "$CUSTOM" = 2 ]]; then
        cp "$WEAVED_DIR"/services/"$WEAVED_PORT".conf ./
        echo "proxy_dest_port $PORT" >> ./"$WEAVED_PORT".conf
        sudo mv ./"$WEAVED_PORT".conf "$WEAVED_DIR"/services/
    fi
}
######### End Port Override #########

######### Delete device #########
deleteDevice()
{
    uid=$(tail $WEAVED_DIR/services/$WEAVED_PORT.conf | grep UID | awk -F "UID" '{print $2}' | xargs echo -n)
    curl -s $deleteURL -X 'POST' -d "{\"deviceaddress\":\"$uid\"}" -H “Content-Type:application/json” -H "apikey:WeavedDeveloperToolsWy98ayxR" -H "token:$token"
    printf "\n\n"
}
######### End Delete device #########

######### Main Program #########
main()
{
     clear
     displayVersion
     bashCheck
     checkRequirements
     platformDetection
     weavedCompatitbility
     checkforServices
     protocolSelection
     installEnablement
     installNotifier
     installSendNotification
     installWeavedConnectd
     installStartStop
     fetchUID
     checkUID
     preregisterUID
     registerDevice
     getSecret
     overridePort
     startService
     installYo
     regMsg
     exit
}
######### End Main Program #########
main



