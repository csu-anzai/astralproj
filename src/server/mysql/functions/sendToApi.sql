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
					"companyEmail", c.company_email,
					"bankFilialApiCode", bf.bank_filial_api_code,
					"bankFilialRegionApiCode", bf.bank_filial_region_api_code,
					"bankFilialCityApiCode", bf.bank_filial_city_api_code,
					"bankFilialName", bf.bank_filial_name,
					"cityName", ci.city_name
				) 
			INTO company 
			FROM 
				companies c 
				LEFT JOIN codes cd ON cd.region_id = c.region_id
				LEFT JOIN bank_filials bf ON bf.bank_filial_id = bankFilialID
				LEFT JOIN cities ci ON ci.city_id = c.city_id
			WHERE c.company_id = companyID LIMIT 1;
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