#!/bin/sh

#The weaved.conf file from which the SECRET is extracted
CONFIG_FILE=/etc/weaved/services/REPLACE.conf

#This is where notify.sh script resides
NOTIFY_DIR=/usr/bin

#notify.sh absolute path
NOTIFY_SCRIPT=/usr/bin/notify.sh

CMD_SUCCEED=0
ERR_FILE=1
INV_TYPE=2
ERR_SECRET=4

SECRET="$(cat $CONFIG_FILE | grep '\<password\>' | sed -n '2p' | cut -d ' ' -f2)"
weavedUID="$(cat $CONFIG_FILE | grep '\<UID\>' | sed -n '2p' | cut -d ' ' -f2)"

echo $SECRET
echo $weavedUID
###################################################################
#This, if other 3 values(TYPE, MSG, STATUS) are sent as arguments
###################################################################

REQ_NO_OF_ARGS=3

if [ "$#" -ne $REQ_NO_OF_ARGS ]
then
    echo "Expected Arguments : TYPE MSG STATUS "
fi

if [ "$1" ]
then
    if [ "$1" -eq 0 ] || [ "$1" -eq 1 ] || [ "$1" -eq 2 ]
    then
        TYPE=$1
    else
        echo "INVALID 'TYPE' VALUE" #(arg1)
        echo $TYPE
        exit $INV_TYPE
    fi
else
    TYPE='Unknown'
    echo $TYPE
    echo "No TYPE Value Specified"
    exit $INV_TYPE
fi

# Check for UID
if [ "$2" ]
then 
    MSG=$2
else
    MSG="NO_Message_Recorded"
fi

# Check for Status string
if [ "$3" ]
then
    STATUS=$3
else
    STATUS="NO_Status_Recorded"
fi


# check for Secret; password size is 21 bytes
if [ -z $SECRET ]
then
    echo $SECRET
    echo "Password/Secret is not found"
    SECRET='Unidentified'
    exit $ERR_SECRET
fi

###################################################################
#If args not passed, used for testing purpose
#------------for test Purpose----------------
#       TYPE=0
#       MSG="Hello World"
#       STATUS="OK"
#       SECRET="9DA1FDA695387EFC5D4709C3BB898368DBE95610"
####################################################################

#Activating notify.sh script

if [ ! -s $NOTIFY_DIR ]
then
    echo "$NOTIFY_DIR Missing"
    sudo mkdir $NOTIFY_DIR
fi

if [ ! -s $NOTIFY_SCRIPT ]
then
        echo "unable to run notify.sh"
        exit $ERR_FILE
fi

sudo chmod +x $NOTIFY_SCRIPT 

#running the notify script

sh $NOTIFY_SCRIPT $TYPE $weavedUID $SECRET "$MSG" "$STATUS"
if [ "$?" != "$CMD_SUCCEED" ]
then
        echo "Some Illegal changes were made to $NOTIFY_SCRIPT"
        exit $ERR_FILE
fi

exit
