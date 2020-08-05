import os
import platform

# get_os determines the opperating system to establish the correct aliases
def get_os():
    # get the os from the server
    os_str = platform.platform()
    # list of supported os to check agains
    os_search = ["centos-6", "centos-7", "Darwin"]
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
    if os.path.isfile('/home/reachengine/.bash_aliases'):
        return '/home/reachengine/.bash_aliases'
    elif os.path.isfile('/home/reachengine/.bashrc'):
        return '/home/reachengine/.bashrc'
    elif os.path.isfile('.zshrc'):
        return '.zshrc'
    else:
        print(
            "file to save aliases (.bashrc, .bash_aliases, or .zshrc) cannot be found" +"\n"
            "Ending Script")
        return 'no file'

# get user input for script
def user_input():
    num = raw_input(
        "Enter [1] - All Aliases" + "\n" +
        "Enter [2] - Status Aliases" + "\n" +
        "Enter [3] - TwoSevenPlus Status Aliases" + "\n" +
        "Enter [4] - Useful Reach Aliases" +"\n" +
        "Enter [p] - Print Alias Groups" +"\n" +
        "Enter [help] - Help with script" +"\n" +
        "Enter [q] - Quit script" +"\n" +
        "User entry: "
        )
    return num

def aliases_loaded(al_file):
    print(
    "Aliases added" +"\n"+
    "IMPORTANT - you must run \'$ source " + str(al_file) +"\'" + "\n"+
    "OR start a new session (log out log back in) for aliases to be loaded."
    )

def main():
    # establish alias file to append aliases too
    alias_file = get_alias_file()
    if alias_file == 'no file':
        exit()

    # get operating system
    operating_system = get_os()

    # select array of aliases based on operating system (Darwin is for testing on Mac)
    if operating_system[0] == "centos-7" or operating_system[0] == "Darwin":
        status_aliases_name = "status_aliases"
        status_aliases = [
            "alias statusre='sudo systemctl status reachengine'",
            "alias statuspg='sudo systemctl status postgresql-9.6'",
            "alias statuses='sudo systemctl status elasticsearch'"
            ]

        status_twoseven_name = "twoSevenPlus_status"
        status_twoseven = [
            "alias statuswfr='sudo systemctl status wferuntime'",
            "alias statussch='sudo systemctl status wfescheduler'"
        ]

        useful_reach_alias_name = "user_reach_alias"
        useful_reach_alias = [
            "alias gcthrash=\"sudo grep \\\"Full GC\\\" /reachengine/tomcat/logs/gc.log | awk '{print \$1}' | awk -FT '{print \$1}' | uniq -c\"",
            "alias backupdir='less /etc/reachengine/backup.conf | grep BACKUP_DIR'"
            ]
    else:
        status_aliases_name = "status_aliases"
        status_aliases = [
            "alias statusre='sudo service reachengine status'",
            "alias statuspg='sudo service postgresql-9.6 status'",
            "alias statuses='sudo service elasticsearch status'"
            ]

        status_twoseven_name = "twoSevenPlus_status"
        status_twoseven = [
            "alias statuswfr='sudo system wferuntime status'",
            "alias statussch='sudo system wfescheduler status'"
        ]

        useful_reach_alias_name = "useful_reach_alias"
        useful_reach_alias = [
            "alias gcthrash=\"sudo grep \"Full GC\" /reachengine/tomcat/logs/gc.log | awk '{print \$1}' | awk -FT '{print \$1}|' uniq -c\"",
            "alias backupdir='less /etc/reachengine/backup.conf | grep BACKUP_DIR'"
            ]

    # var to allow script to run
    looper = True

    # loop to run script until user decides to quiet
    while looper:
        num = user_input()
        if num == "1":
            add_aliases(alias_file, status_aliases)
            add_aliases(alias_file, status_twoseven)
            add_aliases(alias_file, useful_reach_alias)
            aliases_loaded(alias_file)

        elif num == "2":
            add_aliases(alias_file, status_aliases)
            aliases_loaded(alias_file)

        elif num == "3":
            add_aliases(alias_file, status_twoseven)
            aliases_loaded(alias_file)

        elif num == "4":
            add_aliases(alias_file, useful_reach_alias)
            aliases_loaded(alias_file)

        elif num.lower() == "p":
            al = [status_aliases, status_twoseven, useful_reach_alias]
            al_name = [status_aliases_name, status_twoseven_name, useful_reach_alias_name]
            print_alias_groups(al, al_name)

        elif num.lower() == "help" or num.lower() == "h" or num.lower() == "man" or num.lower() == "-man":
            print('''
                This script will allow you to add a few aliases selected from a list.
                To see the groups of aliases to be added select the print option.
                This script is designed to work with Centos7, Centos6, and Amazon Linux.
            ''')

        elif num.lower() == "q":
            print("Ending Script")
            looper = False
            exit()
        else:
            print("Bad Entry: "+ num + ", please re-run script")


if __name__ == '__main__':
  main()
