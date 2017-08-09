package Org.wso2.internal.reviewManagement;

import ballerina.net.http;
import ballerina.lang.system;
import ballerina.data.sql;
import ballerina.lang.messages;
import ballerina.utils.logger;
import ballerina.lang.jsons;
import ballerina.lang.errors;

map propertiesMap = {"jdbcUrl":jdbcURL, "username":username, "password":password};

@http:configuration {basePath:"/internal/review-manager/v1.0/reviews"}
service<http> reviewService {

    sql:ClientConnector dbConnector = create sql:ClientConnector(propertiesMap);

    @http:POST {}
    @http:Path {value:"/"}
    resource recordReview (message m) {

        message response = {};
        json reviewBody = {};
        string responseBody = "Sorry! Unable to save the review";
        string reporterEmail;
        string contributors;
        string reviewType;
        string reviewDate;
        string reviewNotes;
        string references;
        string teamEmail;
        string componentName;
        string componentVersion;
        string stringComponentId;
        string productName;

        //get the message payload in JSON format
        reviewBody = messages:getJsonPayload(m);

        logger:debug("extracting the message ");
        try {
            reporterEmail = jsons:getString(reviewBody, "$.Reporter");
            contributors = jsons:getString(reviewBody, "$.Contributor");
            reviewType = jsons:getString(reviewBody, "$.ReviewType");
            reviewDate = jsons:getString(reviewBody, "$.ReviewDate");
            reviewNotes = jsons:getString(reviewBody, "$.ReviewNotes");
            references = jsons:getString(reviewBody, "$.Reference");
            teamEmail = jsons:getString(reviewBody, "$.TeamEmail");
            componentName = jsons:getString(reviewBody, "$.ComponentName");
            componentVersion = jsons:getString(reviewBody, "$.ComponentVersion");
            productName = jsons:getString(reviewBody, "$.ProductName");
            stringComponentId = jsons:getString(reviewBody, "$.ComponentId");

        }catch (errors:Error err) {
            logger:error(err.msg);
            messages:setStringPayload(response, responseBody);
            reply response;
        }
        logger:debug("done extracting the request message");

        var componentId,_ = <int>stringComponentId;
        response = recordReview(reporterEmail, contributors,reviewType, reviewDate, reviewNotes, references,  teamEmail,
                                componentId, componentName, componentVersion, productName, dbConnector);
        reply response;
    }

    @http:GET {}
    @http:Path {value:"/"}
    resource getAllReviews (message m,
                            @http:QueryParam {value:"dateFrom"} string dateFrom,
                            @http:QueryParam {value:"dateTo"} string dateTo) {

        message response = getAllReviews(dateFrom, dateTo, dbConnector);
        reply response;
    }

    @http:GET {}
    @http:Path {value:"/{reviewID}"}
    resource ReviewsByID (message m, @http:PathParam {value:"reviewID"} string reviewID) {
        message response = getReviewById(reviewID, dbConnector);
        reply response;
    }

    @http:GET {}
    @http:Path {value:"types/{typeName}"}
    resource getReviewsByType (message m,
                               @http:PathParam {value:"typeName"} string typeName,
                               @http:QueryParam {value:"dateFrom"} string dateFrom,
                               @http:QueryParam {value:"dateTo"} string dateTo) {

        message response = getReviewsByType(typeName, dateFrom, dateTo, dbConnector);
        reply response;
    }

    @http:GET {}
    @http:Path {value:"teams/{teamName}"}
    resource getReviewsByTeam (message m,
                               @http:PathParam {value:"teamName"} string teamName,
                               @http:QueryParam {value:"dateFrom"} string dateFrom,
                               @http:QueryParam {value:"dateTo"} string dateTo,
                               @http:QueryParam {value:"contributor"} string contributorEmail) {

        message response =getReviewsByTeam(teamName, dateFrom, dateTo, contributorEmail, dbConnector);
        reply response;
    }

    @http:GET {}
    @http:Path {value:"teams/{teamName}/{typeName}"}
    resource getReviewsByTeamAndType (message m,
                                      @http:PathParam {value:"teamName"} string teamName,
                                      @http:PathParam {value:"typeName"} string typeName,
                                      @http:QueryParam {value:"dateFrom"} string dateFrom,
                                      @http:QueryParam {value:"dateTo"} string dateTo,
                                      @http:QueryParam {value:"contributor"} string contributorEmail) {

        message response = getReviewsByTeamAndType(teamName, typeName, dateFrom, dateTo, contributorEmail, dbConnector);
        reply response;
    }

    @http:GET {}
    @http:Path {value:"/products/{productID}"}
    resource getReviewsByProduct (message m,
                                  @http:PathParam {value:"productID"} string productID,
                                  @http:QueryParam {value:"dateFrom"} string dateFrom,
                                  @http:QueryParam {value:"dateTo"} string dateTo,
                                  @http:QueryParam {value:"contributor"} string contributorEmail) {

        message response = getReviewsByProduct(productID, dateFrom, dateTo, contributorEmail, dbConnector);
        reply response;
    }

    @http:GET {}
    @http:Path {value:"/products/{productID}/{typeName}"}
    resource getReviewsByProductAndType (message m,
                                         @http:PathParam {value:"productID"} string productID,
                                         @http:PathParam {value:"typeName"} string typeName,
                                         @http:QueryParam {value:"dateFrom"} string dateFrom,
                                         @http:QueryParam {value:"dateTo"} string dateTo,
                                         @http:QueryParam {value:"contributor"} string contributorEmail) {

        message response = getReviewsByProductAndType(productID, typeName, dateFrom, dateTo, contributorEmail, dbConnector);
        reply response;
    }


    @http:GET {}
    @http:Path {value:"/components/{componentID}"}
    resource getReviewsByComponent (message m,
                                    @http:PathParam {value:"componentID"} string componentID,
                                    @http:QueryParam {value:"dateFrom"} string dateFrom,
                                    @http:QueryParam {value:"dateTo"} string dateTo,
                                    @http:QueryParam {value:"contributor"} string contributorEmail) {

        message response = getReviewsByComponent(componentID, dateFrom, dateTo, contributorEmail, dbConnector);
        reply response;
    }

    @http:GET {}
    @http:Path {value:"/components/{componentID}/{typeName}"}
    resource getReviewsByComponentAndType (message m,
                                           @http:PathParam {value:"componentID"} string componentID,
                                           @http:PathParam {value:"typeName"} string typeName,
                                           @http:QueryParam {value:"dateFrom"} string dateFrom,
                                           @http:QueryParam {value:"dateTo"} string dateTo,
                                           @http:QueryParam {value:"contributor"} string contributorEmail) {

        message response = getReviewsByComponentAndType(componentID, typeName, dateFrom, dateTo, contributorEmail, dbConnector);
        reply response;
    }


    @http:GET {}
    @http:Path {value:"/contributors/{contributor}"}
    resource getReviewsByContributor (message m,
                                      @http:PathParam {value:"contributor"} string contributorEmail,
                                      @http:QueryParam {value:"dateFrom"} string dateFrom,
                                      @http:QueryParam {value:"dateTo"} string dateTo) {

        message response = getReviewsByContributor(contributorEmail, dateFrom, dateTo, dbConnector);
        reply response;
    }

    @http:GET {}
    @http:Path {value:"/contributors/{contributor}/{typeName}"}
    resource getReviewsByContributorAndType (message m,
                                             @http:PathParam {value:"contributor"} string contributorEmail,
                                             @http:PathParam {value:"typeName"} string typeName,
                                             @http:QueryParam {value:"dateFrom"} string dateFrom,
                                             @http:QueryParam {value:"dateTo"} string dateTo) {

        message response = getReviewsByContributorAndType(contributorEmail, typeName, dateFrom, dateTo, dbConnector);
        reply response;
    }


}


@http:configuration {basePath:"/internal/review-manager/v1.0/products"}
service<http> productService {

    sql:ClientConnector dbConnector = create sql:ClientConnector(propertiesMap);

    @http:GET {}
    @http:Path {value:"/"}
    resource getProducts (message m) {
        system:println("inside the resource");
        message response = getProducts(dbConnector);
        reply response;
    }


    @http:GET {}
    @http:Path {value:"/{team}"}
    resource getProductsByTeam (message m, @http:PathParam {value:"team"} string team) {
        message response = getProductsByTeam(team, dbConnector);
        reply response;
    }
}


@http:configuration {basePath:"/internal/review-manager/v1.0/teams"}
service<http> teamService {

    sql:ClientConnector dbConnector = create sql:ClientConnector(propertiesMap);

    @http:GET {}
    @http:Path {value:"/"}
    resource getAllTeams (message m) {
        message response = getAllTeams(dbConnector);
        reply response;
    }

}


@http:configuration {basePath:"/internal/review-manager/v1.0/components"}
service<http> componentService {

    sql:ClientConnector dbConnector = create sql:ClientConnector(propertiesMap);

    @http:GET {}
    @http:Path {value:"/"}
    resource getComponents (message m) {
        system:println("inside the resource");
        message response = getComponents(dbConnector);
        reply response;
    }

    @http:GET {}
    @http:Path {value:"/product/{productID}"}
    resource getComponentsByProduct (message m, @http:PathParam {value:"productID"} string productID) {
        system:println("inside the resource");
        var productId,_ = <int>productID;
        message response = getComponentsByProduct(productId, dbConnector);
        reply response;
    }

    @http:GET {}
    @http:Path {value:"/team/{team}"}
    resource getComponentsByTeam (message m, @http:PathParam {value:"team"} string team) {
        system:println("inside the resource");
        message response = getComponentsByTeam(team, dbConnector);
        reply response;
    }

}


@http:configuration {basePath:"/internal/review-manager/v1.0/types"}
service<http> typeService {

    sql:ClientConnector dbConnector = create sql:ClientConnector(propertiesMap);

    @http:GET {}
    @http:Path {value:"/"}
    resource getAllTypes (message m) {
        message response = getAllTypes(dbConnector);
        reply response;
    }

}



