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
			UPDATE companies SET company_comment = comment, type_id = 15, bank_id = bankID WHERE company_id = companyID;
			SELECT 
				JSON_OBJECT(
					"companyID", c.company_id,
					"companyPersonName", c.company_person_name,
					"companyPersonSurname", c.company_person_surname,
					"companyPersonPatronymic", c.company_person_patronymic,
					"companyPhone", c.company_phone,
					"companyOrganizationName", c.company_organization_name,
					"companyInn", c.company_inn,
					"companyOgrn", c.company_ogrn,
					"companyComment", c.company_comment,
					"bankID", c.bank_id,
					"templateTypeID", c.company_json ->> "$.template_type_id",
					"regionCode", cd.code_value,
					"psbFilialCode", f.psb_filial_code_value
				) 
			INTO company 
			FROM 
				companies c 
				LEFT JOIN codes cd ON cd.region_id = c.region_id
				LEFT JOIN psb_filial_codes f ON f.city_id = c.city_id
			WHERE company_id = companyID LIMIT 1;
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