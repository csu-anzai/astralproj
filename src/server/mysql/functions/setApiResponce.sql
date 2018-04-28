BEGIN
	DECLARE userID, typeID INT(11);
	DECLARE responce, company JSON;
	SET responce = JSON_ARRAY();
	SELECT user_id INTO userID FROM companies WHERE company_id = companyID;
	SET typeID = IF(!success, 17, IF(applicationID = "false", 24, 16));
	UPDATE companies SET type_id = typeID, company_api_request_id = requestID, company_application_id = IF(applicationID = "false", NULL, applicationID) WHERE company_id = companyID;
	SET responce = JSON_MERGE(responce, refreshUserCompanies(userID));
	RETURN responce;
END