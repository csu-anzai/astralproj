BEGIN
	DECLARE userID, iterator, banksLength, bankFilialID INT(11);
	DECLARE connectionValid TINYINT(1);
	DECLARE connectionApiID VARCHAR(128);
	DECLARE filialApiCode, regionApiCode, cityApiCode VARCHAR(32);
	DECLARE filialName VARCHAR(256);
	DECLARE statusText VARCHAR(22);
	DECLARE responce, company JSON;
	SET responce = JSON_ARRAY();
	SET statusText = "Ожидание";
	SET connectionValid = checkConnection(connectionHash);
	SET iterator = 0;
	SET banksLength = JSON_LENGTH(banks);
	SELECT connection_api_id, user_id INTO connectionApiID, userID FROM connections WHERE connection_hash = connectionHash;
	IF connectionValid 
		THEN BEGIN
			UPDATE companies SET company_comment = comment, type_id = 13 WHERE company_id = companyID;
			CALL checkBanksStatuses(banks, JSON_ARRAY(statusText));
			UPDATE company_banks cb JOIN bank_statuses bs ON bs.bank_id = cb.bank_id AND bs.bank_status_text = statusText SET cb.bank_status_id = bs.bank_status_id WHERE cb.company_id = companyID;  
			banksLoop: LOOP
				IF iterator >= banksLength
					THEN LEAVE banksLoop;
				END IF;
				SET bankFilialID = JSON_UNQUOTE(JSON_EXTRACT(banks, CONCAT("$[", iterator, "].bank_filial_id")));
				SELECT bank_filial_api_code, bank_filial_region_api_code, bank_filial_city_api_code, bank_filial_name INTO filialApiCode, regionApiCode, cityApiCode, filialName FROM bank_filials WHERE bank_filial_id = bankFilialID;
				SET banks = JSON_SET(banks, CONCAT("$[", iterator, "].bankFilialApiCode"), filialApiCode, CONCAT("$[", iterator, "].bankFilialRegionApiCode"), regionApiCode, CONCAT("$[", iterator, "].bankFilialCityApiCode"), cityApiCode, CONCAT("$[", iterator, "].bankFilialName"), filialName);
				SET iterator = iterator + 1;
				ITERATE banksLoop;
			END LOOP;
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
					"banks", banks,
					"templateTypeID", c.company_json ->> "$.template_type_id",
					"regionCode", cd.code_value,
					"companyEmail", c.company_email,
					"cityName", ci.city_name
				) 
			INTO company 
			FROM 
				companies c 
				LEFT JOIN codes cd ON cd.region_id = c.region_id
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