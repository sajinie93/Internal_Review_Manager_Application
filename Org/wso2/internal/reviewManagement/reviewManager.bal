package Org.wso2.internal.reviewManagement;

import ballerina.lang.messages;
import ballerina.data.sql;
import ballerina.lang.jsons;
import ballerina.lang.strings;
import ballerina.lang.datatables;
import org.wso2.ballerina.connectors.gmail;
import ballerina.lang.errors;
import ballerina.utils.logger;
import ballerina.doc;


@doc:Description {value:"Review definition"}
@doc:Field {value:"component_id: id of the component in which the review belongs to"}
@doc:Field {value:"component_name: name of the component in which the review belongs to"}
@doc:Field {value:"component_version: version of the component in which the review belongs to"}
@doc:Field {value:"review_id: id of the review"}
@doc:Field {value:"reporter: reporter of the review"}
@doc:Field {value:"contributor: contributor of the review"}
@doc:Field {value:"review_type: type of the review"}
@doc:Field {value:"review_date: date of the review has been submitted"}
@doc:Field {value:"product_id: id of the product in which the review belongs to"}
@doc:Field {value:"product_name: name of the product in which the review belongs to"}
@doc:Field {value:"team_name: name of the team in which the review belongs to"}
@doc:Field {value:"product_version: version of the product in which the review belongs to"}
@doc:Field {value:"review_note: review notes submitted for the review"}
@doc:Field {value:"reference: references submitted for the review"}
struct Review {
    int component_id;
    string component_name;
    string component_version;
    int review_id;
    string reporter;
    string contributor;
    string review_type;
    string review_date;
    int product_id;
    string product_name;
    string team_name;
    string product_version;
    string review_note;
    string reference;
}


@doc:Description {value:"Contributor_email definition"}
@doc:Field {value:"contributor: email of the contributor"}
struct Contributor_email {
    string contributor;
}


@doc:Description {value:"save the review in the database. update the Reviews and Contributors tables"}
@doc:Param {value:"m: request message"}
@doc:Param {value:"dbConnector: sql client connector"}
@doc:Return {value:"msg: whether the success or failed"}
function recordReview(string reporterEmail, string contributors, string reviewType, string reviewDate,
                      string reviewNotes, string references, string teamName, int componentId, string componentName,
                      string componentVersion, string productName, sql:ClientConnector dbConnector)(message msg){

    message response = {};
    string responseBody = "Sorry! Unable to save the review";

    // transaction for inserting data into Reviews and Contributors tables
    transaction {

        sql:Parameter componentIdPara = {sqlType:"integer", value:componentId};
        sql:Parameter reporterEmailPara = {sqlType:"varchar", value:reporterEmail};
        sql:Parameter reviewNotesPara = {sqlType:"varchar", value:reviewNotes};
        sql:Parameter referencesPara = {sqlType:"varchar", value:references};
        sql:Parameter reviewDatePara = {sqlType:"varchar", value:reviewDate};
        sql:Parameter reviewTypePara = {sqlType:"varchar", value:reviewType};
        sql:Parameter[] params = [];
        params = [componentIdPara,reporterEmailPara,reviewNotesPara,referencesPara,reviewDatePara,reviewTypePara];

        string [] keyColumns = [];
        string [] reviewId;
        int numOfUpdatedRows;

        logger:debug("Inserting component_id:"+componentId+", reporter:"+reporterEmail+", review_note:"+reviewNotes+", " +
                     "references:"+references+" ,review_date:"+reviewDate+" ,review_type:"+reviewType+" into Reviews table");

        numOfUpdatedRows, reviewId = sql:ClientConnector.updateWithGeneratedKeys(dbConnector, insertReviewQuery , params, keyColumns);

        logger:debug("Reviews table is updated succefully");

        // create an list of contributors by splitting the string of contributor's emails separated by commas.
        string[] contributorsList = strings:split(contributors, ",");
        string contributorEmail;
        int count = contributorsList.length;

        sql:Parameter reviewIdPara = {sqlType:"integer", value:reviewId[0]};
        sql:Parameter contributorPara;

        //add contributors one by one to the contributor table"
        while (count > 0) {
            contributorEmail = contributorsList[count-1];
            contributorPara = {sqlType:"varchar", value:contributorEmail};
            params = [contributorPara, reviewIdPara];

            logger:debug("Inserting contributor:"+contributorEmail+", review_id:" + reviewId[0]+" into Contributors table");

            //insert contributor with the review id to the contrinbutor table
            numOfUpdatedRows = sql:ClientConnector.update(dbConnector, insertContributorsQuery, params);

            logger:debug("Inserted contributor:"+contributorEmail+", review_id:" + reviewId[0]+" into Contributors table");

            count = count - 1;
        }

        logger:info("Status: Review is succesfully saved in the database");

    }aborted {
        //set the response body failed when the transaction is failed.
        logger:error("unable to save the review. review details: component_id:"+componentId+", reporter:"+reporterEmail+
                     ", contributors: "+contributors+", review_note:"+reviewNotes+", " + "references:"+references+
                     " ,review_date:"+reviewDate+" ,review_type:"+reviewType);

        responseBody = "Sorry! Unable to save the review";

    }committed {

        string sender = "sajinie@wso2.com";
        string recipient = "sajiniekavindya@gmail.com";
        string subject = "["+reviewType+"] "+componentName+" :by - "+contributors ;
        string body = createEmailBody( reporterEmail,  contributors,  reviewType,  reviewDate,
                                       reviewNotes,  references,  teamName, componentName, componentVersion, productName);

        responseBody = sendEmail(sender, recipient, subject, body);

    }
    //Gets the message payload in string format
    messages:setStringPayload(response, responseBody);
    return response;
}





@doc:Description {value:"get all the reviews in the database"}
@doc:Param {value:"dateFrom: lower bound of the reviewed date"}
@doc:Param {value:"dateTo: upper bound of the reviewed date"}
@doc:Param {value:"dbConnector: sql client connector"}
@doc:Return {value:"msg: response"}
function getAllReviews(string dateFrom, string dateTo, sql:ClientConnector dbConnector)(message msg){

    message response = {};

    sql:Parameter[] params = [];
    sql:Parameter dateFromPara = {sqlType:"varchar", value:dateFrom};
    sql:Parameter dateToPara = {sqlType:"varchar", value:dateTo};
    params = [dateFromPara, dateToPara];
    datatable dt;
    try {
        logger:debug("selecting all reviews between "+dateFrom+" and "+dateTo+" from the database");
        dt = sql:ClientConnector.select(dbConnector,
                                                  getAllReviewsQuery +
                                                  byDateQuery, params);

        logger:info("Fetched reviews from database successfully");
        //calling the function createResponse(datatable dt)(message m) -> create a formatted JSON response.
        response = createResponse(dt);

    } catch (errors:Error err) {
        logger:error(err.msg);
        //set the error message as the response.
        messages:setStringPayload(response, "request failed");
    }finally {
        datatables:close(dt);
    }
    return response;
}





@doc:Description {value:"get reviews by review id"}
@doc:Param {value:"dbConnector: sql client connector"}
@doc:Return {value:"msg: response"}
function getReviewById(string reviewID, sql:ClientConnector dbConnector)(message msg){

    message response = {};
    datatable dt;

    sql:Parameter[] params = [];
    sql:Parameter reviewIdPara = {sqlType:"integer", value:reviewID};
    params = [reviewIdPara];

    try {
        logger:debug("selecting the review which has review id: " + reviewID);

        dt = sql:ClientConnector.select(dbConnector,
                                                  getAllReviewsQuery + byReviewIdQuery, params);

        logger:info("Fetched the review from database successfully");
        //calling the function createResponse(datatable dt)(message m) -> create a formatted JSON response.
        response = createResponse(dt);

    } catch (errors:Error err) {
        logger:error(err.msg);
        //set the error message as the response.
        messages:setStringPayload(response, "request failed");
    }finally {
        datatables:close(dt);
    }
    return response;
}





@doc:Description {value:"get reviews by type"}
@doc:Param {value:"typeName: review type"}
@doc:Param {value:"dateFrom: lower bound of the reviewed date"}
@doc:Param {value:"dateTo: upper bound of the reviewed date"}
@doc:Param {value:"dbConnector: sql client connector"}
@doc:Return {value:"msg: response"}
function getReviewsByType(string typeName, string dateFrom, string dateTo, sql:ClientConnector dbConnector)(message msg){

    message response = {};

    sql:Parameter[] params = [];
    sql:Parameter typeNamePara = {sqlType:"varchar", value:typeName};
    sql:Parameter dateFromPara = {sqlType:"varchar", value:dateFrom};
    sql:Parameter dateToPara = {sqlType:"varchar", value:dateTo};

    datatable dt;

    try {

        params = [typeNamePara, dateFromPara, dateToPara];
        dt = sql:ClientConnector.select(dbConnector,
                                        getAllReviewsQuery + byReviewTypeAndDateQuery
                                        , params);


        logger:info("Fetched the review from database successfully");
        //calling the function createResponse(datatable dt)(message m) -> create a formatted JSON response.
        response = createResponse(dt);

    } catch (errors:Error err) {
        logger:error(err.msg);
        //set the error message as the response.
        messages:setStringPayload(response, "request failed");
    }finally {
        datatables:close(dt);
    }
    return response;
}





@doc:Description {value:"get reviews by team"}
@doc:Param {value:"teamName: name of the team"}
@doc:Param {value:"dateFrom: lower bound of the reviewed date"}
@doc:Param {value:"dateTo: upper bound of the reviewed date"}
@doc:Param {value:"contributorEmail: email of the contributor"}
@doc:Param {value:"dbConnector: sql client connector"}
@doc:Return {value:"msg: response"}
function getReviewsByTeam(string teamName, string dateFrom, string dateTo, string contributorEmail,
                          sql:ClientConnector dbConnector)(message msg){

    message response = {};

    sql:Parameter[] params = [];
    sql:Parameter teamNamePara = {sqlType:"varchar", value:teamName};
    sql:Parameter dateFromPara = {sqlType:"varchar", value:dateFrom};
    sql:Parameter dateToPara = {sqlType:"varchar", value:dateTo};
    sql:Parameter contributorEmailPara = {sqlType:"varchar", value:"%"+contributorEmail+"%"};


    datatable dt;

    try{
        //check whether the query parameter "contributor" is empty.
        if(contributorEmail == ""){

            params = [teamNamePara, dateFromPara, dateToPara];
            dt = sql:ClientConnector.select(dbConnector,
                                            getAllReviewsQuery + byReviewNameAndDateQuery
                                            , params);

            logger:info("Fetched the review from database successfully");
            //calling the function createResponse(datatable dt)(message m) -> create a formatted JSON response.
            response = createResponse(dt);

        }else{
            params = [teamNamePara, contributorEmailPara, dateFromPara, dateToPara];
            dt = sql:ClientConnector.select(dbConnector,
                                            getAllReviewsQuery + byReviewNameContributorAndDateQuery, params);

            logger:info("Fetched the review from database successfully");
            //calling the function createResponse(datatable dt)(message m) -> create a formatted JSON response.
            response = createResponseFilteredByContributor(dt, dbConnector);
        }


    } catch (errors:Error err) {
        logger:error(err.msg);
        //set the error message as the response.
        messages:setStringPayload(response, "request failed");
    }finally {
        datatables:close(dt);
    }
    return response;
}







@doc:Description {value:"get reviews by team and type"}
@doc:Param {value:"teamName: name of the team"}
@doc:Param {value:"typeName: type of the review"}
@doc:Param {value:"dateFrom: lower bound of the reviewed date"}
@doc:Param {value:"dateTo: upper bound of the reviewed date"}
@doc:Param {value:"contributorEmail: email of the contributor"}
@doc:Param {value:"dbConnector: sql client connector"}
@doc:Return {value:"msg: response"}
function getReviewsByTeamAndType(string teamName, string typeName, string dateFrom,
                                 string dateTo, string contributorEmail, sql:ClientConnector dbConnector)(message msg){


    message response = {};

    sql:Parameter[] params = [];
    sql:Parameter teamNamePara = {sqlType:"varchar", value:teamName};
    sql:Parameter typeNamePara = {sqlType:"varchar", value:typeName};
    sql:Parameter dateFromPara = {sqlType:"varchar", value:dateFrom};
    sql:Parameter dateToPara = {sqlType:"varchar", value:dateTo};
    sql:Parameter contributorEmailPara = {sqlType:"varchar", value:"%"+contributorEmail+"%"};

    datatable dt;

    try{
        //check whether the query parameter "contributor" is empty.
        if(contributorEmail == ""){

            params = [teamNamePara, typeNamePara, dateFromPara, dateToPara];
            dt = sql:ClientConnector.select(dbConnector,
                                            getAllReviewsQuery + byReviewNameTypeAndDateQuery, params);

            logger:info("Fetched the review from database successfully");
            //calling the function createResponse(datatable dt)(message m) -> create a formatted JSON response.
            response = createResponse(dt);


        }else{
            params = [teamNamePara, typeNamePara, contributorEmailPara, dateFromPara, dateToPara];
            dt = sql:ClientConnector.select(dbConnector,
                                            getAllReviewsQuery + byReviewNameTypeContributorAndDateQuery
                                            , params);

            logger:info("Fetched the review from database successfully");
            //calling the function createResponse(datatable dt)(message m) -> create a formatted JSON response.
            response = createResponseFilteredByContributor(dt, dbConnector);

        }


    } catch (errors:Error err) {
        logger:error(err.msg);
        //set the error message as the response.
        messages:setStringPayload(response, "request failed");
    }finally {
        datatables:close(dt);
    }
    return response;
}






@doc:Description {value:"get reviews by product id"}
@doc:Param {value:"productID: id of the product"}
@doc:Param {value:"dateFrom: lower bound of the reviewed date"}
@doc:Param {value:"dateTo: upper bound of the reviewed date"}
@doc:Param {value:"contributorEmail: email of the contributor"}
@doc:Param {value:"dbConnector: sql client connector"}
@doc:Return {value:"msg: response"}
function getReviewsByProduct(string productID, string dateFrom, string dateTo, string contributorEmail,
                             sql:ClientConnector dbConnector)(message msg){

    message response = {};

    sql:Parameter[] params = [];
    sql:Parameter productIdPara = {sqlType:"integer", value:productID};
    sql:Parameter dateFromPara = {sqlType:"varchar", value:dateFrom};
    sql:Parameter dateToPara = {sqlType:"varchar", value:dateTo};
    sql:Parameter contributorEmailPara = {sqlType:"varchar", value:"%"+contributorEmail+"%"};

    datatable dt;

    try{
        //check whether the query parameter "contributor" is empty.
        if(contributorEmail == ""){

            params = [productIdPara, dateFromPara, dateToPara];
            dt = sql:ClientConnector.select(dbConnector,
                                            getAllReviewsQuery + byProductIdAndDateQuery
                                            , params);



            logger:info("Fetched the review from database successfully");
            //calling the function createResponse(datatable dt)(message m) -> create a formatted JSON response.
            response = createResponse(dt);

        }else{
            params = [productIdPara, contributorEmailPara, dateFromPara, dateToPara];
            dt = sql:ClientConnector.select(dbConnector,
                                            getAllReviewsQuery +  byProductIdContributorAndDateQuery, params);

            logger:info("Fetched the review from database successfully");

            //calling the function createResponse(datatable dt)(message m) -> create a formatted JSON response.
            response = createResponseFilteredByContributor(dt, dbConnector);
        }


    } catch (errors:Error err) {
        logger:error(err.msg);
        //set the error message as the response.
        messages:setStringPayload(response, "request failed");
    }finally {
        datatables:close(dt);
    }
    return response;
}







@doc:Description {value:"get reviews by product and type"}
@doc:Param {value:"productID: id of the product as shown in the database"}
@doc:Param {value:"typeName: type of the review"}
@doc:Param {value:"dateFrom: lower bound of the reviewed date"}
@doc:Param {value:"dateTo: upper bound of the reviewed date"}
@doc:Param {value:"contributorEmail: email of the contributor"}
@doc:Param {value:"dbConnector: sql client connector"}
@doc:Return {value:"msg: response"}
function getReviewsByProductAndType(string productID, string typeName, string dateFrom,
                                    string dateTo, string contributorEmail, sql:ClientConnector dbConnector)(message msg){



    message response = {};

    sql:Parameter[] params = [];
    sql:Parameter productIdPara = {sqlType:"integer", value:productID};
    sql:Parameter typeNamePara = {sqlType:"varchar", value:typeName};
    sql:Parameter dateFromPara = {sqlType:"varchar", value:dateFrom};
    sql:Parameter dateToPara = {sqlType:"varchar", value:dateTo};
    sql:Parameter contributorEmailPara = {sqlType:"varchar", value:"%"+contributorEmail+"%"};

    datatable dt;

    try {
        //check whether the query parameter "contributor" is empty.
        if(contributorEmail == ""){

            params = [productIdPara, typeNamePara, dateFromPara, dateToPara];
            dt = sql:ClientConnector.select(dbConnector,
                                            getAllReviewsQuery + byProductIdReviewTypeAndDateQuery, params);

            logger:info("Fetched the review from database successfully");
            //calling the function createResponse(datatable dt)(message m) -> create a formatted JSON response.
            response = createResponse(dt);


        }else{
            params = [productIdPara, typeNamePara, contributorEmailPara, dateFromPara, dateToPara];
            dt = sql:ClientConnector.select(dbConnector,
                                            getAllReviewsQuery + byProductIdReviewTypeContributorAndDateQuery
                                            , params);

            logger:info("Fetched the review from database successfully");
            //calling the function createResponse(datatable dt)(message m) -> create a formatted JSON response.
            response = createResponseFilteredByContributor(dt, dbConnector);

        }


    } catch (errors:Error err) {
        logger:error(err.msg);
        //set the error message as the response.
        messages:setStringPayload(response, "request failed");
    }finally {
        datatables:close(dt);
    }
    return response;
}







@doc:Description {value:"get reviews by component"}
@doc:Param {value:"componentID: id of the component as shown in the database"}
@doc:Param {value:"dateFrom: lower bound of the reviewed date"}
@doc:Param {value:"dateTo: upper bound of the reviewed date"}
@doc:Param {value:"contributorEmail: email of the contributor"}
@doc:Param {value:"dbConnector: sql client connector"}
@doc:Return {value:"msg: response"}
function getReviewsByComponent(string componentID, string dateFrom, string dateTo, string contributorEmail,
                               sql:ClientConnector dbConnector)(message msg){

    message response = {};

    sql:Parameter[] params = [];
    sql:Parameter componentIDPara = {sqlType:"integer", value:componentID};
    sql:Parameter dateFromPara = {sqlType:"varchar", value:dateFrom};
    sql:Parameter dateToPara = {sqlType:"varchar", value:dateTo};
    sql:Parameter contributorEmailPara = {sqlType:"varchar", value:"%"+contributorEmail+"%"};

    datatable dt;

    try {
        //check whether the query parameter "contributor" is empty.
        if(contributorEmail == ""){

            params = [componentIDPara, dateFromPara, dateToPara];
            dt = sql:ClientConnector.select(dbConnector,
                                            getAllReviewsQuery + byComponentAndDateQuery
                                            , params);

            logger:info("Fetched the review from database successfully");
            //calling the function createResponse(datatable dt)(message m) -> create a formatted JSON response.
            response = createResponse(dt);


        }else{
            params = [componentIDPara, contributorEmailPara, dateFromPara, dateToPara];
            dt = sql:ClientConnector.select(dbConnector,
                                            getAllReviewsQuery + byComponentIdContributorAndDateQuery, params);

            logger:info("Fetched the review from database successfully");
            //calling the function createResponse(datatable dt)(message m) -> create a formatted JSON response.
            response = createResponseFilteredByContributor(dt, dbConnector);

        }


    } catch (errors:Error err) {
        logger:error(err.msg);
        //set the error message as the response.
        messages:setStringPayload(response, "request failed");
    }finally {
        datatables:close(dt);
    }
    return response;
}







@doc:Description {value:"get reviews by component and type"}
@doc:Param {value:"componentID: id of the component as shown in the database"}
@doc:Param {value:"typeName: type of the review"}
@doc:Param {value:"dateFrom: lower bound of the reviewed date"}
@doc:Param {value:"dateTo: upper bound of the reviewed date"}
@doc:Param {value:"contributorEmail: email of the contributor"}
@doc:Param {value:"dbConnector: sql client connector"}
@doc:Return {value:"msg: response"}
function getReviewsByComponentAndType(string componentID, string typeName, string dateFrom, string dateTo,
                                      string contributorEmail, sql:ClientConnector dbConnector)(message msg){



    message response = {};

    sql:Parameter[] params = [];
    sql:Parameter componentIDPara = {sqlType:"integer", value:componentID};
    sql:Parameter typeNamePara = {sqlType:"varchar", value:typeName};
    sql:Parameter dateFromPara = {sqlType:"varchar", value:dateFrom};
    sql:Parameter dateToPara = {sqlType:"varchar", value:dateTo};
    sql:Parameter contributorEmailPara = {sqlType:"varchar", value:"%"+contributorEmail+"%"};

    datatable dt;

    try {
        //check whether the query parameter "contributor" is empty.
        if(contributorEmail == ""){

            params = [componentIDPara, typeNamePara, dateFromPara, dateToPara];
            dt = sql:ClientConnector.select(dbConnector,
                                            getAllReviewsQuery + byComponentIdReviewTypeAndDateQuery, params);

            logger:info("Fetched the review from database successfully");
            //calling the function createResponse(datatable dt)(message m) -> create a formatted JSON response.
            response = createResponse(dt);


        }else{
            params = [componentIDPara, typeNamePara, contributorEmailPara, dateFromPara, dateToPara];

            dt = sql:ClientConnector.select(dbConnector,
                                            getAllReviewsQuery + byComponentIdReviewTypeContributorAndDateQuery
                                            , params);

            logger:info("Fetched the review from database successfully");
            //calling the function createResponse(datatable dt)(message m) -> create a formatted JSON response.
            response = createResponseFilteredByContributor(dt, dbConnector);

        }


    } catch (errors:Error err) {
        logger:error(err.msg);
        //set the error message as the response.
        messages:setStringPayload(response, "request failed");
    }finally {
        datatables:close(dt);
    }
    return response;
}






@doc:Description {value:"get reviews by contributor"}
@doc:Param {value:"contributorEmail: email of the contributor"}
@doc:Param {value:"dateFrom: lower bound of the reviewed date"}
@doc:Param {value:"dateTo: upper bound of the reviewed date"}
@doc:Param {value:"dbConnector: sql client connector"}
@doc:Return {value:"msg: response"}
function getReviewsByContributor(string contributorEmail, string dateFrom, string dateTo,
                                 sql:ClientConnector dbConnector)(message){

    message response = {};


    sql:Parameter[] params = [];
    sql:Parameter contributorEmailPara = {sqlType:"varchar", value:"%"+contributorEmail+"%"};
    sql:Parameter dateFromPara = {sqlType:"varchar", value:dateFrom};
    sql:Parameter dateToPara = {sqlType:"varchar", value:dateTo};
    params = [contributorEmailPara, dateFromPara, dateToPara];
    datatable dt;

    try{

        dt = sql:ClientConnector.select(dbConnector,
                                        getAllReviewsQuery + byContributorAndDateQuery, params);

        logger:info("Fetched the review from database successfully");
        //calling the function createResponse(datatable dt)(message m) -> create a formatted JSON response.
        response = createResponseFilteredByContributor(dt, dbConnector);

    } catch (errors:Error err) {
        logger:error(err.msg);
        //set the error message as the response.
        messages:setStringPayload(response, "request failed");
    }finally {
        datatables:close(dt);
    }
    return response;

}






@doc:Description {value:"get reviews by contributor and type"}
@doc:Param {value:"contributorEmail: email of the contributor"}
@doc:Param {value:"typeName: type of the review"}
@doc:Param {value:"dateFrom: lower bound of the reviewed date"}
@doc:Param {value:"dateTo: upper bound of the reviewed date"}
@doc:Param {value:"dbConnector: sql client connector"}
@doc:Return {value:"msg: response"}
function getReviewsByContributorAndType (string contributorEmail, string typeName, string dateFrom, string dateTo, sql:ClientConnector dbConnector) (message msg) {

    message response = {};

    sql:Parameter[] params = [];
    sql:Parameter contributorEmailPara = {sqlType:"varchar", value:"%"+contributorEmail+"%"};
    sql:Parameter typeNamePara = {sqlType:"varchar", value:typeName};
    sql:Parameter dateFromPara = {sqlType:"varchar", value:dateFrom};
    sql:Parameter dateToPara = {sqlType:"varchar", value:dateTo};
    params = [contributorEmailPara, typeNamePara, dateFromPara, dateToPara];
    datatable dt;

    try {
        dt = sql:ClientConnector.select(dbConnector,
                                        getAllReviewsQuery + byContributorReviewTypeAndDateQuery, params);


        logger:info("Fetched the review from database successfully");
        //calling the function createResponse(datatable dt)(message m) -> create a formatted JSON response.
        response = createResponseFilteredByContributor(dt, dbConnector);

    } catch (errors:Error err) {
        logger:error(err.msg);
        //set the error message as the response.
        messages:setStringPayload(response, "request failed");
    }finally {
        datatables:close(dt);
    }
    return response;
}







@doc:Description {value:"convert the datatable to a JSON object"}
@doc:Param {value:"dt: datatable instance"}
@doc:Return {value:"msg: JSON object as the response message"}
function createResponse(datatable dt)(message msg){
    message response = {};
    json jsonResponse = {reviews: []};
    json review;
    int previousReviewId = -1;

    logger:debug("Start creating the reviews json reponse");

    try{
        while (datatables:hasNext(dt)) {
            any dataStruct = datatables:next(dt);
            var rowData, _ = (Review)dataStruct;

            if (rowData.review_id != previousReviewId) {

                if (previousReviewId != -1) {
                    // add the created review json object to the "jsonResponse" json
                    jsons:addToArray(jsonResponse, "$.reviews", review);
                }

                //create the json object to represent a review.
                review = {
                             reviewId:rowData.review_id,
                             reporter:rowData.reporter,
                             contributor:[rowData.contributor],
                             reviewType:rowData.review_type,
                             reviewDate:rowData.review_date,
                             teamName:rowData.team_name,
                             product:{   productId:rowData.product_id,
                                         productName:rowData.product_name,
                                         productVersion:rowData.product_version
                                     },
                             component: {
                                            componentId:rowData.component_id,
                                            componentName:rowData.component_name,
                                            componentVersion:rowData.component_version
                                        },
                             reviewNote:rowData.review_note,
                             references:rowData.reference
                         };

                previousReviewId = rowData.review_id ;

            }else {
                jsons:addToArray(review, "$.contributor", rowData.contributor);
            }
        }
        if (previousReviewId != -1) {
            // add the last created review json object to the "jsonResponse" json
            jsons:addToArray(jsonResponse, "$.reviews", review);
        }


    }catch (errors:NullReferenceError err) {
        logger:error("failed to create the review json object");
        messages:setStringPayload(response, "Internal server error");
        return response;

    }
    logger:info("successfully created the reviews json response.");
    messages:setJsonPayload(response, jsonResponse);
    return response;

}







@doc:Description {value:"convert the datatable to a JSON object"}
@doc:Param {value:"dt: datatable instance"}
@doc:Param {value:"dbConnector: sql:ClientConnector instance"}
@doc:Return {value:"msg: JSON object as the response message"}
function createResponseFilteredByContributor(datatable dt, sql:ClientConnector dbConnector)(message msg){
    message response = {};
    json jsonResponse = {reviews: []};
    json review;

    logger:debug("start creating the reviews json reponse");

    try{
        while (datatables:hasNext(dt)) {
            any dataStruct = datatables:next(dt);
            var rowData, _ = (Review)dataStruct;

            //create the json object to represent a review.
            review = {
                         reviewId:rowData.review_id,
                         reporter:rowData.reporter,
                         contributor:[],
                         reviewType:rowData.review_type,
                         reviewDate:rowData.review_date,
                         teamName:rowData.team_name,
                         product:{   productId:rowData.product_id,
                                     productName:rowData.product_name,
                                     productVersion:rowData.product_version
                                 },
                         component: {
                                        componentId:rowData.component_id,
                                        componentName:rowData.component_name,
                                        componentVersion:rowData.component_version
                                    },
                         reviewNote:rowData.review_note,
                         references:rowData.reference
                     };

            sql:Parameter[] params = [];
            sql:Parameter reviewId = {sqlType:"integer", value:rowData.review_id};
            params = [reviewId];

            datatable contributorDatatable = sql:ClientConnector.select(dbConnector, getAllContributorsByReviewId, params);

            while (datatables:hasNext(contributorDatatable)) {
                any x = datatables:next(contributorDatatable);
                var contributorRowData, _ = (Contributor_email)x;
                jsons:addToArray(review, "$.contributor", contributorRowData.contributor);

            }

            // add the last created review json object to the "jsonResponse" json
            jsons:addToArray(jsonResponse, "$.reviews", review);
        }


    }catch (errors:NullReferenceError err) {
        logger:error("failed to create the review json object");
        messages:setStringPayload(response, "Internal server error");
        return response;

    }
    logger:info("successfully created the reviews json response.");
    messages:setJsonPayload(response, jsonResponse);
    return response;

}





@doc:Description {value:"sending an email to the given parameters"}
@doc:Param {value:"sender: sender of the email"}
@doc:Param {value:"recipient: receiver of the email"}
@doc:Param {value:"subject: subject of the email"}
@doc:Param {value:"body: msg body of the email"}
@doc:Return {value:"msg: whether succeed or failed"}

function sendEmail (string sender, string recipient, string subject, string body)(string msg){
    string responseBody;
    try {
        logger:debug("initializing gmail connector");
        gmail:ClientConnector gmailConnector = create gmail:ClientConnector(userId, accessToken, refreshToken, clientId,
                                                                            clientSecret);
        logger:debug("gmail connector is initialized ");
        logger:debug("sending the email From: "+sender+", To: " + "Subject: Review Details, Body: ");

        gmail:ClientConnector.sendMail(gmailConnector, recipient, subject, sender, body, "null",
                                       "null", "null", "null", "html");


        logger:info("Email is sent successfully");
        responseBody = "succeed";

    }catch (errors:Error err) {
        logger:error(err.msg);
        responseBody = "failed to send the email";
    }
    return responseBody;
}

function createEmailBody(string reporterEmail, string contributors, string reviewType, string reviewDate,
                         string reviewNotes, string references, string teamName, string componentName, string componentVersion, string productName)(string body){

    body = "<html><head><style>p.detail{padding-left: 1cm}</style></head>"+
           "<body>" +
           "<h4>Reporter: </h4><P class='detail'>" + reporterEmail + "</P>"+
           "<h4>Contributors: </h4><P class='detail'>" + contributors +"</P>"+
           "<h4>Review Type: </h4><P class='detail'>" + reviewType +"</P>"+
           "<h4>Review Date: </h4><P class='detail'>" + reviewDate +"</P>"+
           "<h4>Team: </h4><P class='detail'>" + teamName +"</P>"+
           "<h4>Product: </h4><P class='detail'>" + productName +"</P>"+
           "<h4>Component: </h4><P class='detail'>" + componentName + " - " + componentVersion +"</P>"+
           "<h4>Review Notes: </h4><P class='detail'>" + reviewNotes +"</P>"+
           "<h4>References: </h4><P class='detail'>" + references +"</P>"+
           "</body></html>"
    ;

    return body;
}
