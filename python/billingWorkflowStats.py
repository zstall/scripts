#!/usr/bin/python2

# This has been written by Zachary Stall (with the help of postman...)
# Date 27 August 2020
# Description: This script will run the billingStats.xml worklfow and
#  send an email to LB containing all usage stats.

import config
import requests
# You may have to run a pip install requests, but it should already be included in pip 2.7
# sudo pip2.6 install requests==1.2.3
# sudo pip2.7 install requests
# sudo pip install requests


def help(dic):
    print('******** DEBUG MODE **********')
    print('Must change trace in script to False to turn off debug mode.')
    print('Imported Vars:')
    print('Username: ' + dic['username'])
    print('Password: ' + dic['password'])
    print('url: ' + dic['url'])
    print('****** END DEBUG MODE ******')

def main():
    # set to true for trouble shootin
    trace = True

    inputs = {}

    inputs['url'] = config.url
    inputs['username'] = config.username
    inputs['password'] = config.password

    # will show what current imported cars are
    if trace:
        help(inputs)

    else:
        # build request and execute workflows
        url = inputs['url']+"/reachengine/api/workflows/getBillingStats/run"

        payload = "{\n   \n}"
        headers = {
            'Content-Type': 'application/json',
            'auth_user': inputs['username'],
            'auth_password': inputs['password']
            }

        requests.request("POST", url, headers=headers, data = payload)


if __name__ == '__main__':
    main()
