#!/usr/bin/python2

# This has been written by Zachary Stall
# Date 5 August 2020
# This script will add groups of useful aliases to the .bash_aliases file for the reach user.
# The primary aliases are all status realated. You can choose from:
# 23x status aliases: statusre, statuses, statuspg. All check the status of respective services
# 27+ status aliases: statuswfr, statussch. Checks status of workflow runtime and wfescheduler
# helpful re aliases: gcthrash, backupdir. Check for gc thrashing and the backup dir.

import os
import platform

# get_os determines the opperating system to establish the correct aliases
def get_os():
    # get the os from the server
    os_str = platform.platform()
    # list of supported os to check agains
    os_search = ["centos-6", "centos-7", "amzn1", "Darwin"]
    # determines if the os from os_str and returns it to syste var
    system = [sub for sub in os_search if sub in os_str]
    return system

# add_aliases opens the file and writes the selected aliases to the aliase file
def add_aliases(file_name, alias_list):
    #open file in read and write mode
    with open(file_name, "a+") as file_object:
        # set var for if file is empty
        appendEOL = False
        # go to the start of the file
        file_object.seek(0)
        # test if there is anything in the file if ther is data, change appendEOL to add aliases to end
        data = file_object.read(100)
        if len(data) > 0:
            appendEOL = True
        # loop through array of aliases and add them to the end of the file
        for alias in alias_list:
            if appendEOL == True:
                file_object.write("\n")
            else:
                appendEOL = True
            file_object.write(alias)

# print all aliases in groups with names to review what would be added
def print_alias_groups(aliases, alias_names):
    print('\n')
    n = 0
    for i in aliases:
        print(str(alias_names[n]))
        n += 1
        for j in i:
            print(j)
        print('\n')

# get the alias file to update:
def get_alias_file():
    if os.path.isfile('~/.bash_aliases'):
        return '~/.bash_aliases'
    elif os.path.isfile('/home/ec2-user/.bashrc'):
        return '/home/ec2-user/.bashrc'
    elif os.path.isfile('/home/centos/.bashrc'):
        return '/home/centos/.bashrc'
    else:
        print(
            "file to save aliases (.bashrc, .bash_aliases, or .zshrc) cannot be found" +"\n"
            "Ending Script")
        return 'no file'

# get user input for script
def user_input_user():
    user = ''
    user = raw_input("Enter the username for alias [default: ec2-user]: ")
    if user == ''
        user = 'ec2-user'
    return user

def alias():

    ips = []
    add = True
    while add:
        ips.append(raw_input("Enter Alias Name: "))
        ips.append(raw_input("Enter Alias Value: "))
        stp = raw_input("Continue [Y]/[N]: ")
        if stp == 'N' or stp == 'n':
            add = False
    print("The aliases that will be added are: ")

    i = 0
    for i < len(ips)-1:
        print("alias " + ips[i] )
