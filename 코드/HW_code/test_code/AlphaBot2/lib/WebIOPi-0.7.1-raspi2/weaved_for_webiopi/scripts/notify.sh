#!/bin/sh
#
# Copyright (C) 2014 Weaved Inc
#
# This is a simple notifcation script that can send events to the weaved notification server
#
# Usage:  old_notify.sh <type> <UID> <secret> <message string> <status string>
#
# type 0 =auth only
# type 1 =arc4 encrypted
# type 3 =aes128 encrypted (TBD)
#
# Example:
#           notify.sh 0 00:00:48:02:2A:A0:32:2D BA4F204876384F921F714DD177CE12D360593CCD "this is a msg" "this is a status"
#
#
# Config curl path
CURL="curl"

#Default values
TMP="/tmp"
# Don't veryify SSL (-k) Silent (-s)
CURL_OPS=" -k -s"
DEBUG=1
#SRC=$1
#DST=$2
OUTPUT="$TMP/notification.txt"
WRITE_DB_STRING="/bin/ffdb -s -d /data/cfg/config.lua -t /data/cfg/ffdb.tmp"

NOTIFICATION_SERVER="notification.yoics.net"
#NOTIFICATION_SERVER="home.mycal.net"
NOTIFICATION_VERSION="/v2"
NOTIFICATION_SEND_URI_AUTH="${NOTIFICATION_VERSION}/send_notification_auth.php?"
NOTIFICATION_SEND_URI="${NOTIFICATION_VERSION}/send_notification.php?"
# Build API URLS GET API's
API_GET_TRANSACTION_CODE="http://$NOTIFICATION_SERVER${NOTIFICATION_VERSION}/request_code.php?uid="
API_SEND_EVENT="http://${NOTIFICATION_SERVER}${NOTIFICATION_SEND_URI}"
API_SEND_EVENT_AUTH="http://${NOTIFICATION_SERVER}${NOTIFICATION_SEND_URI_AUTH}"
#
# Default templates
#
# Load values from FFDB
#
#WEAVED_USER=$(/bin/ffdb -q -d /data/cfg/config.lua STORAGE_CFG0)

#
# Helper Functions
#
#produces a unix timestamp (seconds based) to the output
utime()
{ 
    echo $(date +%s)
}

#
# Produce a sortable timestamp that is year/month/day/timeofday
#
timestamp()
{
    echo $(date +%Y%m%d%H%M%S)
}

# produces a random number ($1 digits) to the output (supports upto 50 digits for now)
dev_random()
{
    local count=$1
    
    #defualt is 10 digits if none specified
    count=${1:-10};

    #1 to 50 digits supported
    if [ "$count" -lt 1 ] || [ "$count" -ge 50 ]; then
        count=10;
    fi

    # uses /dev/urandom
    ret=$(cat /dev/urandom | tr -cd '0-9' | dd bs=1 count=$count 2>/dev/null)
    echo $ret
}

# XML parse,: get the value from key $2 in buffer $1, this is simple no nesting allowed 
#
xmlval()
{
    temp=`echo $1 | awk '!/<.*>/' RS="<"$2">|</"$2">"`
    echo ${temp##*|}
}

#
# get value frome key $2 in buffer $1 (probably better but more work)
#
#jsonval() 
#{
#    temp=`echo $1 | sed 's/\\\\\//\//g' | sed 's/[{}]//g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | sed 's/\"\:\"/\|/g' | sed 's/[\,]/ /g' | sed 's/\"//g' | grep -w $2`
#    echo ${temp##*|}
#}

#
# JSON parse (very simplistic):  get value frome key $2 in buffer $1,  values or keys must not have the characters {}", and the key must not have : in them
#
jsonval()
{
    temp=`echo $1 | sed -e 's/[{}"]//g' -e 's/,/\n/g' | grep -w $2 | cut -d":" -f2-`
    echo ${temp##*|}
}


#
# urlencode $1
#
urlencode()
{
STR=$1

#[ ${STR}x == "x" ] && { STR="$(cat -)"; }
#[ "${STR}x" == "x" ] && { echo "i"; }

echo "${STR}" | sed -e 's| |%20|g' \
-e 's|!|%21|g' \
-e 's|#|%23|g' \
-e 's|\$|%24|g' \
-e 's|%|%25|g' \
-e 's|&|%26|g' \
-e "s|'|%27|g" \
-e 's|(|%28|g' \
-e 's|)|%29|g' \
-e 's|*|%2A|g' \
-e 's|+|%2B|g' \
-e 's|,|%2C|g' \
-e 's|/|%2F|g' \
-e 's|:|%3A|g' \
-e 's|;|%3B|g' \
-e 's|=|%3D|g' \
-e 's|?|%3F|g' \
-e 's|@|%40|g' \
-e 's|\[|%5B|g' \
-e 's|]|%5D|g'
}

#
#
#
return_code()
{
    case $resp in
        "200")
            #Good Reponse
            echo "$resp OK"
            ;;
        "400" | "401" | "403" | "404" | "405")
            #Bad input parameter. Error message should indicate which one and why.
            ret=$(jsonval "$(cat $OUTPUT)" "errorCode")
            ret2=$(jsonval "$(cat $OUTPUT)" "message" )
            echo "$resp $ret : $ret2"
            ;;
        "429")
            #Your app is making too many requests and is being rate limited. 429s can trigger on a per-app or per-user basis.
            ret=$(jsonval "$(cat $OUTPUT)" "error")
            echo "$resp $ret"
            ;;
        "503")
            #If the response includes the Retry-After header, this means your OAuth 1.0 app is being rate limited. Otherwise, this indicates a transient server error, and your app should retry its request.
            ret=$(jsonval "$(cat $OUTPUT)" "error")
            echo "$resp $ret"
            ;;
        "507")
            #User is over Dropbox storage quota.
            ret=$(jsonval "$(cat $OUTPUT)" "error")
            echo "$resp $ret"
            ;;
    esac
}


#
# hash_hmac "sha1" "value" "key"
# raw output by adding the "-binary" flag
# other algos also work: hash_hmac "md5"  "value" "key"
#
#echo -n '952dd27cd1c9369ea091e67e7c3a766700:00:48:02:2A:A0:32:2D00:13:00:10:00:07:00:02:04:21:00:00status20140711190851test' | openssl dgst -binary -sha1 -hmac 'BA4F204876384F921F714DD177CE12D360593CCE' | openssl base64

hash_hmac() 
{
    digest="$1"
    data="$2"
    key="$3"
    shift 3
    echo -n "$data" | openssl dgst -binary "-$digest" -hmac "$key" "$@" | openssl base64
}

hash_hmac_key()
{
    digest="$1"
    data="$2"
    key="$3"
    shift 3
    echo -n "$data" | openssl dgst "-$digest" -hmac "$key" "$@" | sed 's/^.* //'
}

#
# Encrypt RC4 with key, base 64 the output
#
encrypt_rc4()
{
    tkey="$1"
    data="$2"
   
#    echo "encrpte rc4-->echo -n $data | openssl rc4 -K $tkey -nosalt -e -nopad -p | openssl base64"

    echo -n "$data" | openssl rc4 -K $tkey -nosalt -e -nopad -a -A
}

logger "[Weaved Notification Called $1 $2 $3 $4 $5 ]"

type=$1
uid=$2
secret=$3
msg=$(echo "$4" | openssl base64)
status=$(echo "$5" | openssl base64)

#could verify inputs here

#
# always get transaction code
#
URL="$API_GET_TRANSACTION_CODE$2"
resp=$($CURL $CURL_OPS -w "%{http_code}\\n" -X GET -o "$OUTPUT" "$URL")

if [ "$resp" -eq 200 ]; then
    # echo URL "return USERID"
    ret=$(xmlval "$(cat $OUTPUT)" "status")
    # ret has status
    if [ "$ret"="ok" ]; then
        # extract transaction code and fall through
        transaction_code=$(xmlval "$(cat $OUTPUT)" "code")
    else
        echo "could not get transaction code (code $ret)"
        exit -2
    fi
else
    echo "failed on transaction code get (code $resp)"
    exit -1
fi

#
# We have a good transaction code, let build the rest of the message and authentication
#
#
# Get current timestamp
#
tstamp=$(timestamp)
#
# event type  (we fix this example to status, could be video,audio,pir, or others
#
eventtype="status"
#
# devicetype, set to all zeros for now
#
devicetype="00:00:00:00:00:00:00:00:00"
#
# calculate transaction hash
#
transaction_hash=$(hash_hmac sha1 "${transaction_code}${uid}${devicetype}${eventtype}${tstamp}${msg}${status}" "$secret")
#
# Calculate Encryption Key
#
encryption_key=$(hash_hmac_key md5 "${transaction_code}" "${secret}")
#
# (0) send notification (1) get token (2) send notification with token
#
case $type in
    "0")
        #
        # No Encryption, just send authenticated notificaiton
        #
        URL="${API_SEND_EVENT}transaction_code=${transaction_code}&uid=${uid}&device_type=${devicetype}&event_type=${eventtype}&timestamp=${tstamp}&message=${msg}&status=${status}&transaction_hash=${transaction_hash}"
        resp=$($CURL $CURL_OPS -w "%{http_code}\\n" -X GET -o "$OUTPUT" $URL)
        ret=$(xmlval "$(cat $OUTPUT)" "status")
        echo "$resp $ret"
    ;;

    "1")
        #
        # Send RC4 Encrypted notification
        #
        #
        # Calculate encryption key
        #
        encryption_key=$(hash_hmac_key md5 "${transaction_code}" "${secret}")
        #echo "encryption key = $encryption_key"

        #
        # Calculate encrypted string, use ~ instead of = so server side can parse easier (base64 can contain =)
        #
        edata=$(encrypt_rc4 "$encryption_key" "uid~${uid}&device_type~${devicetype}&event_type~${eventtype}&timestamp~${tstamp}&message~${msg}&status~${status}&transaction_hash~${transaction_hash}");
        #echo "ecrypypted string $edata"
        edata=$(urlencode "$edata")
        #echo "ecrypypted string $edata"
        #
        # Send unencrypted notificaiton
        #
        URL="${API_SEND_EVENT_AUTH}transaction_code=${transaction_code}&uid=${uid}&rc4=${edata}"
        resp=$($CURL $CURL_OPS -w "%{http_code}\\n" -X GET -o "$OUTPUT" $URL)
        ret=$(xmlval "$(cat $OUTPUT)" "status")
        echo "$resp $ret"
    ;;

    "2")

    ;;

esac
rm $OUTPUT

# flush multiple returns
echo
