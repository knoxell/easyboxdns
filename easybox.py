#!/usr/bin/env python

import requests as re

class easybox:
    def __init__(self, host:str = 'easy.box'):
        self.session = re.Session()
        self.host = host

        r = self.session.get('http://' + host + '/main.cgi?page=login.html')
        cookie = r.headers['Set-Cookie']
        self.cookie = cookie[:cookie.find(';')] # + '; basic_expert_mode="Expert"'

        i1 = r.text.find('dm_cookie') + 11
        i2 = i1 + r.text[i1:].find("'")

        self.dm = r.text[i1:i2]
        #self.keepalive()


    def keepalive(self):
        # I first though this had to be send first, but it's not needed! :)
        payload = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"><soapenv:Header><DMCookie>' + self.dm + '</DMCookie><SessionNotRefresh>1</SessionNotRefresh></soapenv:Header><soapenv:Body><cwmp:SessionKeepAlive xmlns=""><SessionKeepAlive></SessionKeepAlive></cwmp:SessionKeepAlive></soapenv:Body></soapenv:Envelope>'

        assert(len(payload) == 343)

        r = self.post(payload)
        return r

    def getheaders(self, payload):
        headers = {
                'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/115.0',
                'Accept': 'application/xml, text/xml, */*; q=0.01',
                'Accept-Language': 'en-US,en;q=0.5',
                'Content-Type': 'text/xml; charset="utf-8"',
                'Cookie': self.cookie,
                'SOAPServer': '' ,
                'SOAPAction': 'cwmp:SessionKeepAlive',
                'X-Requested-With': 'XMLHttpRequest',
                'Content-Length': str(len(payload)),
                'Origin': 'http://easy.box',
                'DNT': '1',
                'Connection': 'keep-alive',
                'Referer': 'http://easy.box/main.cgi?page=login.html',
                'Sec-GPC': '1',
                'Pragma': 'no-cache',
                'Cache-Control': 'no-cache',
            }
        return headers


    def getip(self):
        payload = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"><soapenv:Header><DMCookie>' + self.dm + '</DMCookie></soapenv:Header><soapenv:Body><cwmp:GetParameterValues xmlns=""><ParameterNames><string>InternetGatewayDevice.WANDevice.6.WANConnectionDevice.4.WANPPPConnection.1.ExternalIPAddress</string></ParameterNames></cwmp:GetParameterValues></soapenv:Body></soapenv:Envelope>'

        r = self.post(payload)

        idx1 = r.text.find('ExternalIPAddress')
        idx2 = r.text[idx1:].find('>') + idx1 + 1
        idx3 = r.text[idx2:].find('>') + idx2 + 1
        idx4 = r.text[idx2:].find('<') + idx3
        ip = r.text[idx3:idx4]
        return ip



    def post(self, payload):
        r = self.session.post('http://' + self.host + '/data_model.cgi', headers=self.getheaders(payload), data=payload)
        assert(r.status_code == 200)
        return r


if __name__ == '__main__':
    import sys
    if len(sys.argv) > 1:
        box = easybox(sys.argv[1])
    else:
        box = easybox()

    print(box.getip())
