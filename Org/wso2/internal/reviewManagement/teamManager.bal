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
struct Team {
    string team_name;
    string team_email;
}


function getAllTeams(sql:ClientConnector dbConnector)(message ){

    message response = {};
    datatable dt;

    try {
        sql:Parameter[] params = [];
        logger:debug("start fetching all the teams from the database");
        dt = sql:ClientConnector.select(dbConnector, getAllTeamsQuery, params);
        logger:info("Fetched all the teams from database successfully");

        json jsonResponse = {teams: []};
        json team;

        //Iterate through the result until hasNext() become false and retrieve the data struct corresponding to each row.
        //create the team json object
        logger:debug("Start creating the teams json reponse");
        while (datatables:hasNext(dt)) {
            any dataStruct = datatables:next(dt);
            var rowData, _ = (Team)dataStruct;

            team = {
                       teamName:rowData.team_name,
                       teamEmail:rowData.team_email
                   };

            // add the created team json object to the "jsonResponse" json
            jsons:addToArray(jsonResponse, "$.teams", team);
        }
        logger:info("successfully created the teams json response.");

        messages:setJsonPayload(response, jsonResponse);


    } catch (errors:NullReferenceError err) {
        logger:error("failed to create the team json object");
        messages:setStringPayload(response, "Internal server error");

    } catch (errors:Error err) {
        logger:error(err.msg);
        messages:setStringPayload(response, "request failed");

    }finally {
        datatables:close(dt);
    }
    return response;
}