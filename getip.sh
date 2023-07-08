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

request=$(curl -Lsv "$host/main.cgi?page=login.html" 2>&1)

# get cookie needed for request
cookie=$(echo "$request" |  grep 'Set-Cookie' | cut -d';' -f1 | cut -d' ' -f3)
# get 'cookie' send in payload
dm_cookie=$(echo "$request" | grep dm_cookie | sed -e "s/.*dm_cookie='\(.*\)';.*/\1/")

PAYLOAD='<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"><soapenv:Header><DMCookie>'$dm_cookie'</DMCookie></soapenv:Header><soapenv:Body><cwmp:GetParameterValues xmlns=""><ParameterNames><string>InternetGatewayDevice.WANDevice.6.WANConnectionDevice.4.WANPPPConnection.1.ExternalIPAddress</string></ParameterNames></cwmp:GetParameterValues></soapenv:Body></soapenv:Envelope>'

response=$(curl -sX POST -H "Cookie: $cookie" -H 'Content-Type: text/xml; charset="utf-8"' -H 'X-Requested-With: XMLHttpRequest' -H 'Accept:application/xml, text/xml, */*; q=0.01 ' -d "$PAYLOAD" "http://$host/data_model.cgi" | grep '<Value' | sed -e 's/.*>\([0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\)<.*/\1/' 2>&1)

echo "$response"
