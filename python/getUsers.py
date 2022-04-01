#!/usr/bin/python2

# This has been written by Zachary Stall
# Date 7 August 2020
# Description: This script will make an API call to build a json with all Reach Engine
# users. It then pulls username, first name, last name, and email from that list and
# writes it to a csv in the location the script is called reac_usrs.csv.

import csv
import json
import requests
import sys
# You may have to run a pip install requests, but it should already be included in pip 2.7
# sudo pip2.6 install requests==1.2.3
# sudo pip2.7 install requests
# sudo pip install requests

# get user inputs for IP, username, password
def prompt_user():

    #dictionary to store all user inputs:
    usr={}

    # get ip address from user:
    usr['ip'] = raw_input("Enter Application Server IP Address: (example: http://<ip address>:<port>): ")
    if usr['ip'] == '':
        print('IP Address Required - Exit')
        exit()

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

    # generate dictionary from user
    usr = prompt_user()
    ver = True
    while ver:
        ver = verify_user_input(usr)
        if ver:
            usr = prompt_user()

    # build request url from user input
    url = usr['ip']+"/reachengine/api/security/users"

    payload = {}
    headers = {
        'Accept': 'application/json',
        'auth_user': usr['usrname'],
        'auth_password': usr['password']
        }

    # run the request to get users and save the list to a json
    r = requests.request("GET", url, headers=headers, data = payload)
    json_array = r.json()

    # set trace to true for debuggin... will print all users in json_array
    if trace:
        print("Reachengine Users:")
        print("Total: ")+str(len(json_array))
        for i in json_array:
            print("Username: " + i['username'] + " Email: " + i['emailAddress'])

    print("*******************************************************************")
    print("Writing reach_usrs.csv")
    print("Total " + str(len(json_array))) + " users found."
    print("*******************************************************************")


    with open('reach_usrs.csv', 'w') as u:
        mywriter = csv.writer(u)
        mywriter.writerow(['username','firstName','lastName','emailAddress'])
        for i in json_array:
            if i['username'] != 'guest':
                mywriter.writerow([i['username'],i['firstName'],i['lastName'],i['emailAddress']])
    print("\n\n Done")

if __name__ == '__main__':
    main()
