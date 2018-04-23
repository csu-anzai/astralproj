BEGIN
	DECLARE userID, typeID, bankID INT(11);
	DECLARE responce, company JSON;
	SET responce = JSON_ARRAY();
	SET typeID = IF(bool, 16, 17);
	UPDATE companies SET type_id = typeID WHERE company_id = companyID;
	SELECT user_id, bank_id INTO userID, bankID FROM companies WHERE company_id = companyID;
	IF userID IS NOT NULL
		THEN SET responce = JSON_MERGE(responce, sendToAlluserSockets(userID, JSON_ARRAY(JSON_OBJECT(
			"type", "updateArray",
			"data", JSON_OBJECT(
				"name", "companies",
				"search", JSON_OBJECT(
					"company_id", companyID
				),
				"values", JSON_OBJECT(
					"type_id", typeID
				)
			)
		))));
	END IF;
	SET responce = JSON_MERGE(responce, JSON_OBJECT(
		"type", "procedure",
		"data", JSON_OBJECT(
			"query", "refreshBankSupervisors",
			"values", JSON_ARRAY(
				bankID
			)
		)
	));
	RETURN responce;
END