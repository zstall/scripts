import requests
import json

def startWorkflow(workflowId,  username, password, num):
    url = "https://bigchungus.reachengine.rocks/reachengine/api/workflows/"+str(workflowId)+"/start"

    payload = json.dumps({
            "gameId":"failTest",
            "framerate":"2997",
            "counter":num
        })
    headers = {
        'Content-Type': 'application/json',
        'auth_user': str(username),
        'auth_password': str(password)
    }

    response = requests.request("POST", url, headers=headers, data=payload)

    return(response.text)



def get_input():
    workflowId = str(input("Enter workflow id: ") or "stallTest")
    username = str(input("Enter RE username: ") or "system")
    password = str(input("Enter RE password: ") or "rawmixednuts")
    num = int(input("How many times would you like to run the workflow: ") or 1)

    return([workflowId,username,password,num])

def main():
    user_input = get_input()
    counter = 0
    n = user_input[3]
    while (n >= counter):
        print(startWorkflow(user_input[0], user_input[1], user_input[2], counter))
        counter += 1



if __name__ == '__main__':
    main()
