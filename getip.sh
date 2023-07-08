#!/bin/sh
#
# Usage:
# ./getip.sh [easybox address/hostname, default: 'easy.box']
#
# get you external ip address from the web interface of you easybox
# without login.
# If $1 is give its used as the hostname/ip of the router,
# otherwise 'easy.box' is used
#
# tested with Vodafone EasyBox 804 with firmware version 08.02
# date: 08.07.2023

host=${1:-'easy.box'}

sessionfile="/tmp/easysession"

curlcookies() {
    response=$(curl -Lsv "$host/main.cgi?page=login.html" 2>&1)

    # get cookie needed for request
    cookie=$(echo "$response" |  grep 'Set-Cookie' | cut -d';' -f1 | cut -d' ' -f3)
    # get 'cookie' send in payload
    dm_cookie=$(echo "$response" | grep dm_cookie | sed -e "s/.*dm_cookie='\(.*\)';.*/\1/")

    echo "$cookie" > "$sessionfile"
    echo "$dm_cookie" >> "$sessionfile"
}

curlip() {

	PAYLOAD='<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"><soapenv:Header><DMCookie>'$dm_cookie'</DMCookie></soapenv:Header><soapenv:Body><cwmp:GetParameterValues xmlns=""><ParameterNames><string>InternetGatewayDevice.WANDevice.6.WANConnectionDevice.4.WANPPPConnection.1.ExternalIPAddress</string></ParameterNames></cwmp:GetParameterValues></soapenv:Body></soapenv:Envelope>'

	response=$(curl -sX POST -H "Cookie: $cookie" -d "$PAYLOAD" "http://$host/data_model.cgi")
	EXIT="$?"
	STATUS=$(echo "$response" | grep "403 Forbidden" | wc -l )
	EXIT="$(($EXIT + $STATUS))"
	#test "$(($EXIT + $STATUS))" -gt "0" && exit 1

	ip=$(echo "$response" | grep '<Value' | sed -e 's/.*>\([0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\)<.*/\1/' 2>&1)
}


if test -f "$sessionfile"; then
    session=$(cat /tmp/easysession)
    cookie=$(echo "$session" | head -1)
    dm_cookie=$(echo "$session" | tail -1)
else
    curlcookies
fi

curlip

if test "$EXIT" -gt "0" && test -f "$sessionfile"; then
    rm "$sessionfile"
else
    echo "$ip"
fi
