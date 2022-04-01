#!/bin/bash

        '<!--
        ~ Levels Beyond CONFIDENTIAL
        ~
        ~ Copyright 2003 - 2019 Levels Beyond Incorporated
        ~ All Rights Reserved.
        ~
        ~ NOTICE:  All information contained herein is, and remains
        ~ the property of Levels Beyond Incorporated and its suppliers,
        ~ if any.  The intellectual and technical concepts contained
        ~ herein are proprietary to Levels Beyond Incorporated
        ~ and its suppliers and may be covered by U.S. and Foreign Patents,
        ~ patents in process, and are protected by trade secret or copyright law.
        ~ from Levels Beyond Incorporated.
        ~
        -->
        <workflow xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns="http://levelsbeyond.com/schema/workflow"
                xmlns:nimbus="http://levelsbeyond.com/schema/workflow/nimbus"
                id="getAssetsJsonByRQL"
                name="Get Assets JSON by RQL"
                executionLabelExpression="Fetching assets JSON with RQL: ${rqlString}"
                subjectDOClassName=""
                showInUserInterface="false"
                resultDataDef="rqlResult"
                sdkVersion=""
        >


        <groovyStep
                name="get assets by RQL"
                executionLabelExpression="RQL: ${rqlString}"
        >
                <script>
                <!'\['CDATA'\['
                import groovy.json.JsonSlurper
                import groovy.json.JsonOutput
                import com.levelsbeyond.service.inventory.InventorySearchService
                import com.levelsbeyond.service.inventory.InventorySearchCriteria
                import com.levelsbeyond.api.inventory.InventorySearchResponse
                import com.levelsbeyond.api.inventory.InventorySearchResult
                import com.fasterxml.jackson.databind.JsonNode
                import com.routeto1.spring.ApplicationContextHolder
                import com.routeto1.data.IDataObject;
                import com.routeto1.asset.filesystem.AssetMaster
                import com.routeto1.asset.AssetCollection
                import com.levelsbeyond.service.inventory.reference.InventoryReferenceService;


                InventorySearchResponse searchResult = inventorySearchService.search(criteria)
                Collection<JsonNode> esResults = searchResult.getResults()

                final def rval = '\['
                    rql   : rqlString,
                    total : searchResult.getTotal(),
                    assets: esResults.collect {
                        "'\['${inventoryReferenceService.getDataObjectClassForKey(it.get('\''inventoryTypeName'\'').asText()).getSimpleName()}.${it.get('\''uuid'\'').asText()}.${it.get('\''id'\'').asText()}'\]'".toString()
                    }
                '\]'

                if (includeESJson) {
                        final def slurper = new JsonSlurper()
                        rval.results = esResults.collect { slurper.parseText(it.toString()) }
                }

                if (searchResult.getAggregations() != null) {
                        rval.aggregations = searchResult.getAggregations()
                }

                return JsonOutput.toJson(rval)
                '\]''\]'>
                </script>
        </groovyStep>

        <!-- ................................................... End Steps .................................................... -->
        <!-- success -->
        <noopStep name="end"/>


        <!-- ................................................... Data Defs .................................................... -->
        <!-- ............ INPUT ............. -->
        <contextDataDef name="rqlString" dataType="String"/>
        <contextDataDef name="includeESJson" dataType="Boolean" defaultDataExpression="false" />

        <!-- ......... PROCESSING ........... -->


        <!-- ........ RETURN VALUE .......... -->
        <contextDataDef name="rqlResult" dataType="JSON" />

        </workflow>
        '
        }
EOF
}

wfData=getAssetJsonByRQL
echo ${wfData}
function postGetAssetsJsonByRQL()
{
    curl -XPOST http://172.16.72.123:8080/reachengine/api/workflows/ -H 'Content-Type: application/xml' -H 'auth_user: system' -H 'auth_password: password' -d '${wfData}'
    echo "curl -XPOST http://172.16.72.123:8080/reachengine/api/workflows/ -H 'Content-Type: application/xml' -H 'auth_user: system' -H 'auth_password: password' -d ${wfData}"
}

postGetAssetsJsonByRQL