package Org.wso2.internal.reviewManagement;

import ballerina.lang.messages;
import ballerina.data.sql;
import ballerina.lang.datatables;
import ballerina.lang.jsons;
import ballerina.lang.errors;
import ballerina.utils.logger;
import ballerina.doc;
import ballerina.lang.strings;

@doc:Description {value:"Product definition"}
@doc:Field {value:"product_id: id of the Product"}
@doc:Field {value:"product_name: name of the Product"}
@doc:Field {value:"product_version: version of the Product"}
struct Product {
    int product_id;
    string product_name;
    string product_version;
}

function getProductsByTeam(string team, sql:ClientConnector dbConnector)(message msg){

    message response = {};

    try {
        sql:Parameter[] params = [];
        sql:Parameter teamPara = {sqlType:"varchar", value:team};
        params = [teamPara];

        logger:debug("start fetching all the products for team "+team+" from the database");
        datatable dt = sql:ClientConnector.select(dbConnector, getAllProductsByTeamQuery, params);
        logger:info("Fetched all the products for team "+team+" from database successfully");

        json jsonResponse = {products: []};
        json product;

        //Iterate through the result until hasNext() become false and retrieve the data struct corresponding
        //to each row.
        //create the product json object
        logger:debug("Start creating the products json reponse");
        while (datatables:hasNext(dt)) {
            any dataStruct = datatables:next(dt);
            var rowData, _ = (Product)dataStruct;
            string id = strings:valueOf(rowData.product_id);

            product = {
                          productId:id,
                          productName:rowData.product_name,
                          productVersion: rowData.product_version
                      };

            // add the created product json object to the "jsonResponse" json
            jsons:addToArray(jsonResponse, "$.products", product);
        }
        logger:info("successfully created the products json response.");
        messages:setJsonPayload(response, jsonResponse);


    } catch (errors:NullReferenceError err) {
        logger:error("failed to create the product json object");
        messages:setStringPayload(response, "Internal server error");

    } catch (errors:Error err) {
        logger:error(err.msg);
        messages:setStringPayload(response, "request failed");

    }
    return response;
}




function getProducts(sql:ClientConnector dbConnector)(message msg){
    message response = {};
    datatable dt;

    try {
        sql:Parameter[] params = [];
        logger:debug("start fetching all the products from the database");
        dt = sql:ClientConnector.select(dbConnector, getAllProductsQuery, params);
        logger:info("Fetched all the products from database successfully");

        json jsonResponse = {products: []};
        json product;

        //Iterate through the result until hasNext() become false and retrieve the data struct corresponding to each row.
        //create the team json object
        logger:debug("Start creating the teams json reponse");
        while (datatables:hasNext(dt)) {
            any dataStruct = datatables:next(dt);
            var rowData, _ = (Product)dataStruct;
            string id = strings:valueOf(rowData.product_id);

            product = {
                          productId:id,
                          productName:rowData.product_name,
                          productVersion: rowData.product_version
                      };

            // add the created product json object to the "jsonResponse" json
            jsons:addToArray(jsonResponse, "$.products", product);
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