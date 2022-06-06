import requests
import re
from harbrSecrets import secrets


# Function to get flowAttemptId from Jira ticket
def jiraRequest(ham):

	api_key = secrets.get("SECRET_KEY")
	cookie = secrets.get("COOKIE")
	url = "https://harbrgroup.atlassian.net/rest/api/2/issue/"+ham+"?auth="+api_key
	payload={}
	headers = {
		'fields':'description.flowAttemptId',
		'Cookie': cookie
	}	

	response = requests.request("GET", url, headers=headers, data=payload)
	flowAttemptIdRegex = re.compile(r'\'flowAttemptId\'\: \d\d\d\d')
	flowAttemptId = flowAttemptIdRegex.search(response.text)
    
	if flowAttemptId == 'None':
		print(ham + " ticket not found")
		return("null")

        
	idRegex = re.compile(r'\d\d\d\d')
	try:
		id = idRegex.search(flowAttemptId.group())
	except AttributeError:
		print(ham +" does not have a flowAttemptId")
		return("null")

	return(id.group())


# Need to do 

# Connect to database

# Run query

# Post output JSON to jira ticket

def main():
	hamId = input("Enter HAM ticket number (ex: HAM-1234): ")
	flowAttemptId = jiraRequest(hamId)
	print("flowAttemptId: " + flowAttemptId)

if __name__ == "__main__":
	main()
