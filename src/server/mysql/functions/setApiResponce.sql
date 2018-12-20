BEGIN
	DECLARE userID, bankStatusID INT(11);
	DECLARE responce JSON;
	SET responce = JSON_ARRAY();
	SELECT user_id INTO userID FROM companies WHERE company_id = companyID;
	CALL checkBanksStatuses(JSON_ARRAY(bankID), JSON_ARRAY(statusText));
	SELECT bank_status_id INTO bankStatusID FROM bank_statuses WHERE bank_id = bankID AND bank_status_text = statusText LIMIT 1;
	UPDATE company_banks SET bank_status_id = bankStatusID, company_bank_application_id = applicationID, company_bank_request_id = requestID WHERE company_id = companyID AND bank_id = bankID;
	SET responce = JSON_MERGE(responce, refreshUserCompanies(userID));
	RETURN responce;
END