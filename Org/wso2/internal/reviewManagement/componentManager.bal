package Org.wso2.internal.reviewManagement;

import ballerina.data.sql;
import ballerina.lang.messages;
import ballerina.lang.datatables;
import ballerina.lang.jsons;
import ballerina.lang.errors;
import ballerina.utils.logger;
import ballerina.doc;
import ballerina.lang.strings;


@doc:Description {value:"Component definition"}
@doc:Field {value:"component_id: id of the Component"}
@doc:Field {value:"component_name: name of the Component"}
@doc:Field {value:"component_version: version of the Component"}
struct Component {
    int component_id;
    string component_name;
    string component_version;
    string product_name;
}

function getComponentsByProduct(int productID, sql:ClientConnector dbConnector)(message ){

    message response = {};

    try {

        sql:Parameter[] params = [];
        sql:Parameter productIDPara = {sqlType:"integer", value:productID};
        params = [productIDPara];

        logger:debug("start fetching all the components for product "+productID+" from the database");
        datatable dt = sql:ClientConnector.select(dbConnector, getAllComponentsByProductsQuery, params);
        logger:info("Fetched all the components for product "+productID+" from database successfully");


        json jsonResponse = {components: []};
        json component;

        //Iterate through the result until hasNext() become false and retrieve the data struct corresponding
        //to each row.
        //create the component json object
        logger:debug("Start creating the teams json reponse");
        while (datatables:hasNext(dt)) {
            any dataStruct = datatables:next(dt);
            var rowData, _ = (Component)dataStruct;
            string id = strings:valueOf(rowData.component_id);

            component = {
                            componentId:id,
                            componentName:rowData.component_name,
                            componentVersion : rowData.component_version,
                            productName: rowData.product_name
                        };

            jsons:addToArray(jsonResponse, "$.components", component);
        }

        logger:info("successfully created the teams json response.");
        messages:setJsonPayload(response, jsonResponse);

    } catch (errors:NullReferenceError err) {
        logger:error("failed to create the team json object");
        messages:setStringPayload(response, "Internal server error");

    } catch (errors:Error err) {
        logger:error(err.msg);
        messages:setStringPayload(response, "request failed");

    }
    return response;
}


function getComponentsByTeam(string team, sql:ClientConnector dbConnector)(message ){

    message response = {};

    try {

        sql:Parameter[] params = [];
        sql:Parameter teamPara = {sqlType:"varchar", value:team};
        params = [teamPara];

        logger:debug("start fetching all the components for team "+team+" from the database");
        datatable dt = sql:ClientConnector.select(dbConnector, getAllComponentsByTeamsQuery, params);
        logger:info("Fetched all the components for team "+team+" from database successfully");


        json jsonResponse = {components: []};
        json component;

        //Iterate through the result until hasNext() become false and retrieve the data struct corresponding
        //to each row.
        //create the component json object
        logger:debug("Start creating the teams json reponse");
        while (datatables:hasNext(dt)) {
            any dataStruct = datatables:next(dt);
            var rowData, _ = (Component)dataStruct;
            string id = strings:valueOf(rowData.component_id);

            component = {
                            componentId:id,
                            componentName:rowData.component_name,
                            componentVersion : rowData.component_version,
                            productName: rowData.product_name
                        };

            jsons:addToArray(jsonResponse, "$.components", component);
        }

        logger:info("successfully created the teams json response.");
        messages:setJsonPayload(response, jsonResponse);

    } catch (errors:NullReferenceError err) {
        logger:error("failed to create the team json object");
        messages:setStringPayload(response, "Internal server error");

    } catch (errors:Error err) {
        logger:error(err.msg);
        messages:setStringPayload(response, "request failed");

    }
    return response;
}



function getComponents(sql:ClientConnector dbConnector)(message msg){
    message response = {};
    datatable dt;
    try {
        sql:Parameter[] params = [];
        logger:debug("start fetching all the components from the database");
        dt = sql:ClientConnector.select(dbConnector, getAllComponentsQuery, params);
        logger:info("Fetched all the components from database successfully");

        json jsonResponse = {components: []};
        json component;

        //Iterate through the result until hasNext() become false and retrieve the data struct corresponding
        //to each row.
        //create the component json object
        logger:debug("Start creating the components json reponse");
        while (datatables:hasNext(dt)) {
            any dataStruct = datatables:next(dt);
            var rowData, _ = (Component)dataStruct;
            string id = strings:valueOf(rowData.component_id);


            component = {
                            componentId:id,
                            componentName:rowData.component_name,
                            componentVersion : rowData.component_version,
                            productName: rowData.product_name
                        };

            jsons:addToArray(jsonResponse, "$.components", component);
        }

        logger:info("successfully created the components json response.");
        messages:setJsonPayload(response, jsonResponse);

    } catch (errors:NullReferenceError err) {
        logger:error("failed to create the component json object");
        messages:setStringPayload(response, "Internal server error");

    } catch (errors:Error err) {
        logger:error(err.msg);
        messages:setStringPayload(response, "request failed");

    }finally {
        datatables:close(dt);
    }
    return response;
}