BEGIN
	DECLARE companyID, typeID, userID, iterator, companiesLength, bankID INT(11);
	DECLARE done, connectionValid TINYINT(1);
	DECLARE connectionApiID, companyPersonName, companyPersonSurname, companyPersonPatronymic VARCHAR(128);
	DECLARE companyPhone VARCHAR(20);
	DECLARE companyOrganizationName VARCHAR(1024);
	DECLARE companyInn VARCHAR(12);
	DECLARE companyOgrn VARCHAR(15);
	DECLARE responce, validCompaniesIDArray, validCompaniesArray JSON;
	DECLARE companiesCursor CURSOR FOR SELECT type_id, company_id, company_person_name, company_person_surname, company_person_patronymic, company_phone, company_organization_name, company_inn, company_ogrn FROM companies WHERE JSON_CONTAINS(companiesArray, CONCAT(company_id));
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
	SET responce = JSON_ARRAY();
	SET connectionValid = checkConnection(connectionHash);
	SELECT connection_api_id, user_id, bank_id INTO connectionApiID, userID, bankID FROM users_connections_view WHERE connection_hash = connectionHash;
	IF connectionValid 
		THEN BEGIN
			SET done = 0;
			SET validCompaniesArray = JSON_ARRAY();
			OPEN companiesCursor;
				companiesLOOP: LOOP
					FETCH companiesCursor INTO typeID, companyID, companyPersonName, companyPersonSurname, companyPersonPatronymic, companyPhone, companyOrganizationName, companyInn, companyOgrn;
					IF done 
						THEN LEAVE companiesLOOP;
					END IF;
					SET validCompaniesArray = JSON_MERGE(validCompaniesArray, JSON_OBJECT(
						"companyID", companyID,
						"companyPersonName", companyPersonName,
						"companyPersonSurname", companyPersonSurname,
						"companyPersonPatronymic", companyPersonPatronymic,
						"companyPhone", companyPhone,
						"companyOrganizationName", companyOrganizationName,
						"companyInn", companyInn,
						"companyOgrn", companyOgrn 
					));
					ITERATE companiesLOOP;
				END LOOP;
			CLOSE companiesCursor;
			IF (JSON_LENGTH(companiesArray) > 0)
				THEN BEGIN
					UPDATE companies SET type_id = 15 WHERE JSON_CONTAINS(companiesArray, CONCAT(company_id));
					SET responce = JSON_MERGE(responce, 
						JSON_OBJECT(
							"type", "sendToApi",
							"data", JSON_OBJECT(
								"companies", validCompaniesArray
							)
						),
						JSON_OBJECT(
							"type", "procedure",
							"data", JSON_OBJECT(
								"query", "refreshBankSupervisors",
								"values", JSON_ARRAY(
									bankID
								)
							)
						)
					);
					SET companiesLength = JSON_LENGTH(companiesArray);
					IF companiesLength > 0
						THEN BEGIN
							SET iterator = 0;
							validCompaniesLoop: LOOP
								IF iterator >= companiesLength
									THEN LEAVE validCompaniesLoop;
								END IF;
								SET companyID = JSON_UNQUOTE(JSON_EXTRACT(validCompaniesArray, CONCAT("$[", iterator, "].companyID")));
								SET responce = JSON_MERGE(responce, sendToAllUserSockets(userID, JSON_ARRAY(JSON_OBJECT(
									"type", "updateArray",
									"data", JSON_OBJECT(
										"name", "companies",
										"search", JSON_OBJECT(
											"company_id", companyID
										),
										"values", JSON_OBJECT(
											"type_id", 15
										)
									)
								))));
								SET iterator = iterator + 1;
								ITERATE validCompaniesLoop;
							END LOOP;
						END;
					END IF;
				END;
			END IF;
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