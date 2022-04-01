#!/usr/bin/python2

# This has been written by Zachary Stall
# Date 5 August 2020
# This script runs a http rquest to update the dynamic properties for workflow cleanup
# The user must provide the IP address and port, the day range, cron config, username,
# and password.
# NOTE: Day range: Worklfow cleanup will cleanup all workflows older than this day range.
#       example: day range 7, will cleanup anything older than seven Days


import requests
# You may have to run a pip install requests, but it should already be included in pip 2.7
# sudo pip2.6 install requests==1.2.3
# sudo pip2.7 install requests
# sudo pip install requests

def prompt_user():

    #dictionary to store all user inputs:
    usr={}

    # get ip address from user:
    usr['ip'] = raw_input("Enter Application Server IP Address: (example: http://<ip address>:<port>): ")
    if usr['ip'] == '':
        print('IP Address Required - Exit')
        exit()
    # get day range from user:
    usr['day_range'] = raw_input("Enter Days (workflow cleanup will cleanup and workflows older than this number of days)[default 21]:" )
    if usr['day_range'] == "":
         usr['day_range']= '25'

    # get the cron config
    usr['cron'] = raw_input('''
            Enter Cron Schedule (must be in standard cron syntax,
            default is on the first day of the month at midnight)
            [Default 0 0 1 * *]: ''')
    if usr['cron'] == "":
        usr['cron'] = "0 0 1 * *"

    # get the username
    usr['usrname'] = raw_input("Enter Username [Default: system]: ")
    if usr['usrname'] == "":
        usr['usrname'] = "system"

    # get the password
    usr['password'] = raw_input("Enter Password [Default: password]: ")
    if usr['password'] == "":
        usr['password'] = "password"

    return usr

def verify_user_input(dic):
    print("\n"+"Please verify your inputs:")
    print("ip address: " + dic['ip'])
    print("Day range: "+ dic['day_range'])
    print("cron: " + dic['cron'])
    print("Username: " + dic['usrname'])
    print("Password: " + dic['password'])
    chg = raw_input("Would you like to change? [y] or [n]: ")
    return chg.lower() == 'y'

def main():

    # generate dictionary from user
    usr = prompt_user()
    ver = True
    while ver:
        ver = verify_user_input(usr)
        if ver:
            usr = prompt_user()


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
    print("**************************************************************************")

if __name__ == '__main__':
    main()
