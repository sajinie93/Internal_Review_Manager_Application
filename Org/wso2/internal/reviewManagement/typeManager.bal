package Org.wso2.internal.reviewManagement;

import ballerina.lang.messages;
import ballerina.data.sql;
import ballerina.lang.datatables;
import ballerina.lang.jsons;
import ballerina.lang.errors;
import ballerina.utils.logger;
import ballerina.doc;

@doc:Description {value:"Team definition"}
@doc:Field {value:"team_name: name of the team"}
@doc:Field {value:"team_email: email of the team"}
struct Type {
    string reviewType;

}


function getAllTypes(sql:ClientConnector dbConnector)(message msg){

    message response = {};
    datatable dt;

    try {
        sql:Parameter[] params = [];
        logger:debug("start fetching all types from the database");
        dt = sql:ClientConnector.select(dbConnector, getAllTypesQuery, params);
        logger:info("Fetched all types from database successfully");

        json jsonResponse = {types: []};


        //Iterate through the result until hasNext() become false and retrieve the data struct corresponding to each row.
        //create the team json object
        logger:debug("Start creating the teams json reponse");
        while (datatables:hasNext(dt)) {
            any dataStruct = datatables:next(dt);
            var rowData, _ = (Type)dataStruct;

            // add the created team json object to the "jsonResponse" json
            jsons:addToArray(jsonResponse, "$.types", rowData.reviewType);
        }
        logger:info("successfully created the type json response.");

        messages:setJsonPayload(response, jsonResponse);


    } catch (errors:NullReferenceError err) {
        logger:error("failed to create the type json object");
        messages:setStringPayload(response, "Internal server error");

    } catch (errors:Error err) {
        logger:error(err.msg);
        messages:setStringPayload(response, "request failed");

    }finally {
        datatables:close(dt);
    }
    return response;
}