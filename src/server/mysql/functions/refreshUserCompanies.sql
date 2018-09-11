BEGIN
	DECLARE responce, activeCompany JSON;
	DECLARE connectionApiID VARCHAR(128);
	DECLARE connectionID INT(11);
	DECLARE done TINYINT(1);
	DECLARE connectionsCursor CURSOR FOR SELECT connection_id, connection_api_id FROM connections WHERE user_id = userID AND connection_end = 0;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
	SET responce = JSON_ARRAY();
	SET activeCompany = JSON_OBJECT();
	SELECT company_json INTO activeCompany FROM working_user_company_view WHERE user_id = userID LIMIT 1;
	OPEN connectionsCursor;
		connectionsLoop: LOOP
			FETCH connectionsCursor INTO connectionID, connectionApiID;
			IF done
				THEN LEAVE connectionsLoop; 
			END IF;
			SET responce = JSON_MERGE(responce, JSON_OBJECT(
				"type", "sendToSocket",
				"data", JSON_OBJECT(
					"socketID", connectionApiID,
					"data", JSON_ARRAY(
						JSON_OBJECT(
							"type", "merge",
							"data", JSON_OBJECT(
								"companies", getActiveBankUserCompanies(connectionID),
								"activeCompany", activeCompany
							)
						)
					)
				)
			));
			ITERATE connectionsLoop;
		END LOOP;
	CLOSE connectionsCursor;
	RETURN responce;
END