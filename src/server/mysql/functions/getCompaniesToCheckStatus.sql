BEGIN
	DECLARE done TINYINT(1);
	DECLARE responce, company JSON;
	DECLARE userID INT(11) DEFAULT (SELECT user_id FROM connections WHERE connection_hash = connectionHash);
	DECLARE companiesCursor CURSOR FOR SELECT JSON_OBJECT("companyID", company_id, "applicationID", company_application_id) FROM companies WHERE type_id in (16, 25, 26, 27, 28, 29) AND company_application_id IS NOT NULL AND IF(userID IS NOT NULL, user_id = userID, 1);
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
	SET responce = JSON_ARRAY();
	OPEN companiesCursor;
		companiesLoop: LOOP
			FETCH companiesCursor INTO company;
			IF done
				THEN LEAVE companiesLoop;
			END IF;
			SET responce = JSON_MERGE(responce, company);
			ITERATE companiesLoop;
		END LOOP;
	CLOSE companiesCursor;
	SET responce = JSON_OBJECT(
		"companies", responce
	);
	RETURN responce;
END