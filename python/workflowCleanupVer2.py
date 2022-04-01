#!/usr/bin/python2

# This has been written by Zachary Stall
# Date 5 August 2020
# This script runs a http rquest to update the dynamic properties for workflow cleanup
# The user must provide the IP address and port, the day range, cron config, username,
# and password.
# NOTE: Day range: Worklfow cleanup will cleanup all workflows older than this day range.
#       example: day range 7, will cleanup anything older than seven Days

import json
import requests
# You may have to run a pip install requests, but it should already be included in pip 2.7
# sudo pip2.6 install requests==1.2.3
# sudo pip2.7 install requests
# sudo pip install requests

def check_workflow_cleanup():

    # dictionary to store all user inputs:
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

def verify_user_input_check(dic):
    print("\n"+"Please verify your inputs:")
    print("ip address: " + dic['ip'])
    print("Username: " + dic['usrname'])
    print("Password: " + dic['password'])
    chg = raw_input("Would you like to change? [y] or [n]: ")
    return chg.lower() == 'y'

def update_workflow_cleanup(dic):

    # get day range from user:
    dic['day_range'] = raw_input("Enter Days (workflow cleanup will cleanup and workflows older than this number of days)[default 21]:" )
    if dic['day_range'] == "":
         dic['day_range']= '21'

    # get the cron config
    dic['cron'] = raw_input('''
            Enter Cron Schedule (must be in standard cron syntax,
            default is on the first day of the month at midnight)
            [Default 0 0 1 * *]: ''')
    if dic['cron'] == "":
        dic['cron'] = "0 0 1 * *"
    
    return dic

def verify_user_input_update(dic):
    print("\n"+"Please verify your inputs:")
    print("ip address: " + dic['ip'])
    print("Day range: "+ dic['day_range'])
    print("cron: " + dic['cron'])
    print("Username: " + dic['usrname'])
    print("Password: " + dic['password'])
    chg = raw_input("Would you like to change? [y] or [n]: ")
    return chg.lower() == 'y'

def main():

    looper = True
    usr = {}

    while looper:

        if usr == {}:    
            print("Workflow Cleanup Script Started")
            print("\n" + "Enter the following information")
            usr = check_workflow_cleanup()
            chck = True
            while chck:
                chck = verify_user_input_check(usr)
                if chck:
                    usr = check_workflow_cleanup()
                        
        # check or update workflow cleanup?
        print("[1] Check Workflow Cleanup Settings")
        print("[2] Update Workflow Cleanup Settings")
        print("[3] Quit")
        num = raw_input()

        if num == '1':

            url = usr['ip']+"/reachengine/api/properties?auth_user="+usr['usrname']+"&auth_password="+usr['password']

            payload = {}
            headers = {
            'Content-Type': 'application/json',
            'auth_user': usr['usrname'],
            'auth_password': usr['password']
            }

            response = requests.request("GET", url, headers=headers, data = payload)
            json_array = response.json()

            print("\n"+"**************************************************************************")
            print("Reach Engine Workflow Cleanup Properties")
            print("workflow.cleanup.range: " + json_array['workflow.cleanup.range'])
            print("workflow.cleanup.schedule: " + json_array['workflow.cleanup.schedule'])
            print("\n"+"**************************************************************************")

        elif num == '2':
            usr = update_workflow_cleanup(usr)
            ver = True
            while ver:
                ver = verify_user_input_update(usr)
                if ver:
                    usr = check_workflow_cleanup()
                    usr = update_workflow_cleanup(usr) 
        
            # using the dictionary from above, build the api url
            url = usr['ip']+"/reachengine/api/properties?auth_user="+usr['usrname']+"&auth_password="+usr['password']
            payload = "{\n\t\"workflow.cleanup.schedule\":\""+usr['cron']+"\",\n\t\"workflow.cleanup.range\":\""+usr['day_range']+"\"\n}"
            headers = {
            'Content-Type': 'application/json',
            'auth_user': usr['usrname'],
            'auth_password': usr['password']
            }

            # capture the response code from the api call and print it for the user
            response = requests.request("POST", url, headers=headers, data = payload)
            print("\n"+"**************************************************************************")
            print(response.text.encode('utf8'))
            print("\n"+"**************************************************************************")

        else:
            print("Exiting Script")
            quit()

if __name__ == '__main__':
    main()
