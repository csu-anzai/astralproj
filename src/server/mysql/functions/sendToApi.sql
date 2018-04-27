BEGIN
	DECLARE userID INT(11);
	DECLARE connectionValid TINYINT(1);
	DECLARE connectionApiID VARCHAR(128);
	DECLARE responce, company JSON;
	SET responce = JSON_ARRAY();
	SET connectionValid = checkConnection(connectionHash);
	SELECT connection_api_id, user_id INTO connectionApiID, userID FROM connections WHERE connection_hash = connectionHash;
	IF connectionValid 
		THEN BEGIN
			UPDATE companies SET company_comment = comment, type_id = 15 WHERE company_id = companyID;
			SELECT 
				JSON_OBJECT(
					"companyID", company_id,
					"companyPersonName", company_person_name,
					"companyPersonSurname", company_person_surname,
					"companyPersonPatronymic", company_person_patronymic,
					"companyPhone", company_phone,
					"companyOrganizationName", company_organization_name,
					"companyInn", company_inn,
					"companyOgrn", company_ogrn,
					"companyComment", company_comment
				) 
			INTO company FROM companies WHERE company_id = companyID;
			SET responce = JSON_MERGE(responce, refreshUserCompanies(userID));
			SET responce = JSON_MERGE(responce,
				JSON_OBJECT(
					"type", "sendToApi",
					"data", company
				)
			);
		END;
		ELSE SET responce = JSON_MERGE(responce, JSON_OBJECT(
			"type", "sendToSocket",
			"data", JSON_OBJECT(
				"socketID", connectionApiID,
				"data", JSON_ARRAY(JSON_OBJECT(
					"type", "merge",
					"data", JSON_OBJECT(
						"auth", 0,
						"loginMessage", "Требуется ручной вход в систему"
					)
				))
			)
		));
	END IF;
	RETURN responce;
END