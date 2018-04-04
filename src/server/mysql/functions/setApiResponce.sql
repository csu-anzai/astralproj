BEGIN
	DECLARE userID, typeID INT(11);
	DECLARE responce, company JSON;
	SET responce = JSON_ARRAY();
	SET typeID = IF(bool, 16, 17);
	UPDATE companies SET type_id = typeID WHERE company_id = companyID;
	SELECT user_id INTO userID FROM companies WHERE company_id = companyID;
	IF userID IS NOT NULL
		THEN SET responce = JSON_MERGE(responce, sendToAlluserSockets(userID, JSON_ARRAY(JSON_OBJECT(
			"type", "updateArray",
			"data", JSON_OBJECT(
				"name", "companies",
				"search", JSON_OBJECT(
					"companyID", companyID
				),
				"values", JSON_OBJECT(
					"typeID", typeID
				)
			)
		))));
	END IF;
	RETURN responce;
END