BEGIN
	DECLARE userID, typeID INT(11);
	DECLARE responce, company JSON;
	SET responce = JSON_ARRAY();
	SELECT user_id INTO userID FROM companies WHERE company_id = companyID;
	IF userID IS NOT NULL
		THEN BEGIN 
			SET typeID = IF(bool, 16, 17);
			UPDATE companies SET type_id = typeID WHERE company_id = companyID;
			SET responce = JSON_MERGE(responce, refreshUserCompanies(userID));
		END;
	END IF;
	RETURN responce;
END