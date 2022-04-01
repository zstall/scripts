#!/usr/bin/python2

# This has been written by Zachary Stall (with the help of postman...)
# Date 27 August 2020
# Description: This script will run the billingStats.xml worklfow and
#  send an email to LB containing all usage stats.

import socket
import requests
# You may have to run a pip install requests, but it should already be included in pip 2.7
# sudo pip2.6 install requests==1.2.3
# sudo pip2.7 install requests
# sudo pip install requests


def get_ip():
    try:
        hname = socket.gethostname()
        hip = socket.gethostbyname(hname)
        print("Hostname:  ",hname)
        print("IP Address: ",hip)
        return hip
    except:
        print("Unable to get Hostname and IP")

# get user inputs for IP, username, password
def prompt_user(def_ip):

    #dictionary to store all user inputs:
    usr={}

    # get ip address from user:
    if def_ip == '':
        usr['ip'] = raw_input("Enter Application Server IP Address: (example: http://<ip address>:<port>): ")
        if usr['ip'] == '':
            print('IP Address Required - Exit')
            exit()
    else:
        usr['ip'] = 'http://' + str(def_ip) + ':8080'

    # get the username
    usr['usrname'] = raw_input("Enter Username [Default: system]: ")
    if usr['usrname'] == "":
        usr['usrname'] = "system"

    # get the password
    usr['password'] = raw_input("Enter Password [Default: password]: ")
    if usr['password'] == "":
        usr['password'] = "password"

    return usr

# ensure the user is happy with there inputs
def verify_user_input(dic):
    print("\n"+"Please verify you inputs:")
    print("ip address: " + dic['ip'])
    print("Username: " + dic['usrname'])
    print("Password: " + dic['password'])
    chg = raw_input("Would you like to change? [y] or [n]: ")
    return chg.lower() == 'y'

def main():
    # set to true for trouble shootin
    trace = False
    ip = ''

    # generate dictionary from user
    ip = get_ip()
    usr = prompt_user(ip)
    ver = True
    while ver:
        ver = verify_user_input(usr)
        if ver:
            usr = prompt_user()

    # build request url from user input
    url = usr['ip']+"/reachengine/api/workflows/getBillingStats/run"

    payload = "{\n   \n}"
    headers = {
        'Content-Type': 'application/json',
        'auth_user': usr['usrname'],
        'auth_password': usr['password']
        }

    response = requests.request("POST", url, headers=headers, data = payload)


    print("**************************************")
    print("Script Complete, Status Code:")
    print(response.text.encode('utf8'))
    print("**************************************")

if __name__ == '__main__':
    main()
