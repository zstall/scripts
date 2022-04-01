import groovy.json.*;
import java.io.File;
import groovy.io.FileType;

try
{
	//Get user input
	String serverAddr = System.console().readLine 'Server URL: ';
	String userName = System.console().readLine 'Username: ';
	String password = System.console().readLine 'Password: ';
	String queryLimit =  System.console().readLine 'Number of workflows to get (default=1000): ';
	String skipSystem =  System.console().readLine 'Ignore system workflows? (y or n) (default=y): ';
	String destDirectory = System.console().readLine 'Destination directory for exported workflows (NOTE: Do not escape spaces | Use full path) (default=current directory): ';
	String zipOption = System.console().readLine 'Create tar of all workflows? (y or n) (default=n): ';

    /*serverAddr = "http://192.168.206.20:8080"
    userName = "system"
    password = "password"*/

	if(serverAddr == null || serverAddr == "" || userName == null || userName == "" || password == null || password == "" ) {
		println "ERROR: Either the Server URL or Username or Password was not provided. Please provide these three inputs and try again.";
		System.exit(0);
	}

	if(queryLimit == null || queryLimit == "") {
		queryLimit = 1000;
	}
	if(zipOption != "y") {
		zipOption = "n";
	}
	if(skipSystem != "n") {
		skipSystem = "y";
	}

	String endPoint = serverAddr + "/reachengine/api/workflows?";
	def params = [fetchIndex:'0', fetchLimit:queryLimit, includeArchived:'false', includeCommon:'true', includeDisabled:'true', includeGlobal:'true', sort:'name', userCanExecuteOnly:'false'];

	// Creates a string from params where key=value for each key:value pair and joins them by an '&'
	def qs = params.collect { k,v -> "$k=$v" }.join('&');

	println "Sending the CURL call '" + "curl -i -k -X GET -H \"auth_user: " + userName +"\" -H \"auth_password: " + password +"\" \"" + endPoint+qs +"\"" + "'";

	StringBuilder sout = new StringBuilder()
	StringBuilder serr = new StringBuilder()
    newLineChar = System.getProperty("line.separator");
    // Creates the API call URL and sends it
	def allWorkflowsRequest = [ 'bash', '-c', "curl -i -k -X GET -H \"auth_user: " + userName +"\" -H \"auth_password: " + password +"\" \"" + endPoint+qs +"\"" ].execute()

	// Wait for response
	allWorkflowsRequest.waitForProcessOutput(sout, serr)
	//println sout.toString();

    httpStatus = sout.substring(0, sout.indexOf(newLineChar));
    println "HTTP STATUS: " + httpStatus;

    if (sout == null || sout.toString() == "" || !httpStatus.contains("200")) {
        println "ERROR: ";
        println serr.toString();
        println sout.toString();
        System.exit(0);
    }

	// print formatted JSON response
	//println JsonOutput.prettyPrint(sout.toString())

	def slurper = new JsonSlurper();
    def workflowsJson = slurper.parseText(sout.substring(sout.indexOf("{"), sout.lastIndexOf("}")+1));
    println "Found " + workflowsJson.get("total") + " workflows";

    // Create directory to store workflows
    File xmlPath = new File ("workflow_exports/");
    if(destDirectory != null && destDirectory != "") {
    	xmlPath = new File (destDirectory + "/workflow_exports/");
    }
    xmlPath.mkdirs();


    // Puts all returned workflow IDs into an array.
    //def wfIds = workflowsJson.workflows.collect { json -> "${json.id}" };

    // Gets array of data for each workflow returned
    def workflowsData = workflowsJson.workflows;

    // Makes API call to RE for each WF then exports to a file
    endPoint = serverAddr + "/reachengine/workflow/export?"
    String xmlTxt = "";

    for(int i = 0; i < workflowsData.size(); i++) {

    	if(skipSystem == "y" && workflowsData[i].get('systemWorkflowFlag') == true) {
    		println "Skipping system workflow: '" + workflowsData[i].get('key') + "'";
    	}
    	else {
			sout.setLength(0);
			serr.setLength(0);
		    try {
				def exportedWorkflowRequest = [ 'bash', '-c', "curl -i -k -X GET -H \"auth_user: " + userName +"\" -H \"auth_password: " + password +"\" \"" + endPoint+"workflowId="+workflowsData[i].get('id') +"\"" ].execute()

				// Wait for response
				exportedWorkflowRequest.waitForProcessOutput(sout, serr)

                httpStatus = sout.substring(0, sout.indexOf(newLineChar));
                println "HTTP STATUS: " + httpStatus;

                if (sout == null || sout.toString() == "" || !httpStatus.contains("200")) {
                    println "ERROR: ";
                    println serr.toString();
                    println sout.toString();
                    continue;
                }
                else {
                    xmlTxt = sout.substring(sout.indexOf("<workflow"), sout.lastIndexOf("</workflow>")+11);
                }
		    }
		    catch(Exception e) {
		    	println(e);
		    	continue;
		    }



		    File xmlFile = new File(xmlPath, workflowsData[i].get('key') + ".xml");
			println xmlFile.getAbsolutePath()

			xmlFile.write(xmlTxt);
		}

	}

	// Creates tar file of all exported WFs
	if(zipOption == "y") {
		def command = [ "tar", "-cvzf", "workflow_exports.tar.gz", "workflow_exports/" ];
		if(destDirectory != null && destDirectory != "") {
			command = [ "tar", "-cvzf", "workflow_exports.tar.gz", "-C", destDirectory, "./workflow_exports/" ];
		}
		println "Tarring with the command: '" + command.join(' ') + "'";
		def commandTxt = command.execute().text;
		println commandTxt;


		command = ["mv", "workflow_exports.tar.gz", xmlPath.getAbsolutePath()];
		println "Moving the tar file with the command: '" + command.join(' ') + "'";
		commandTxt = command.execute().text;
		println commandTxt;

	}

}

catch(Exception e)
{
	println(e);
}

System.exit(0);
