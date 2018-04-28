BEGIN
	DECLARE interator, companiesLength, userID, typeID, companyID INT(11);
	DECLARE applicationID VARCHAR(128);
	DECLARE responce, company JSON;
	SET responce = JSON_ARRAY();
	SET companiesLength = JSON_LENGTH(companies);
	SET interator = 0;
	companiesLoop: LOOP
		IF interator >= companiesLength
			THEN LEAVE companiesLoop;
		END IF;
		SET company = JSON_EXTRACT(companies, CONCAT("$[", interator, "]"));
		SET typeID = JSON_UNQUOTE(JSON_EXTRACT(company, "$.type_id"));
		SET applicationID = JSON_UNQUOTE(JSON_EXTRACT(company, "$.company_application_id"));
		SELECT user_id, company_id INTO userID, companyID FROM companies WHERE company_application_id = applicationID;
		UPDATE LOW_PRIORITY IGNORE companies SET type_id = typeID WHERE company_id = companyID;
		SET responce = JSON_MERGE(responce, refreshUserCompanies(userID));
		SET interator = interator + 1;
		ITERATE companiesLoop;
	END LOOP;
	RETURN responce;
END