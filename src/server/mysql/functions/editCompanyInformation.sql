BEGIN
	DECLARE userID, companyTypeID, oldCityID, bankID INT(11);
	DECLARE connectionValid, done TINYINT(1);
	DECLARE connectionApiID VARCHAR(32);
	DECLARE cityName VARCHAR(60);
	DECLARE bankName VARCHAR(128);
	DECLARE responce, companyBanks JSON;
	DECLARE banksCursor CURSOR FOR SELECT bank_id FROM bank_cities WHERE city_id = cityID;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
	SET responce = JSON_ARRAY();
	SET connectionValid = checkConnection(connectionHash);
	IF connectionValid
		THEN BEGIN
			SELECT type_id, city_id INTO companyTypeID, oldCityID FROM companies WHERE company_id = companyID;
			SELECT user_id INTO userID FROM connections WHERE connection_hash = connectionHash;
			SELECT city_name INTO cityName FROM cities WHERE city_id = cityID;
			SET companyBanks = JSON_OBJECT();
			IF oldCityID != cityID
				THEN BEGIN
					DELETE FROM company_banks WHERE company_id = companyID;
					OPEN banksCursor;
						banksLoop: LOOP
							SET done = 0;
							FETCH banksCursor INTO bankID;
							IF done
								THEN LEAVE banksLoop;
							END IF;
							INSERT INTO company_banks (company_id, bank_id) VALUES (companyID, bankID);
							SELECT bank_name INTO bankName FROM banks WHERE bank_id = bankID;
							SET companyBanks = JSON_SET(companyBanks, CONCAT("$.b", bankID), JSON_OBJECT("bank_id", bankID, "bank_name", bankName, "company_bank_status", NULL, "bank_status_id", NULL));
							ITERATE banksLoop;
						END LOOP;
					CLOSE banksCursor;
				END;
			END IF;
			UPDATE companies SET company_phone = phone, city_id = cityID, company_json = JSON_SET(company_json, "$.company_phone", phone, "$.city_name", cityName, "$.city_id", cityID, "$.company_banks", companyBanks) WHERE company_id = companyID;
			SET responce = JSON_MERGE(responce, IF(companyTypeID = 36, refreshUsersCompanies(), refreshUserCompanies(userID)));
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