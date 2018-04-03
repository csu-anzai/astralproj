BEGIN
	DECLARE companyID, typeID INT(11);
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
	SELECT connection_api_id INTO connectionApiID FROM connections WHERE connection_hash = connectionHash;
	IF connectionValid 
		THEN BEGIN
			SET done = 0;
			SET validCompaniesIDArray = JSON_ARRAY();
			SET validCompaniesArray = JSON_ARRAY();
			OPEN companiesCursor;
				companiesLOOP: LOOP
					FETCH companiesCursor INTO typeID, companyID, companyPersonName, companyPersonSurname, companyPersonPatronymic, companyPhone, companyOrganizationName, companyInn, companyOgrn;
					IF done 
						THEN LEAVE companiesLOOP;
					END IF;
					IF typeID = 13	
						THEN BEGIN 
							SET validCompaniesIDArray = JSON_MERGE(validCompaniesIDArray, CONCAT(companyID));
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
						END;
					END IF;
					ITERATE companiesLOOP;
				END LOOP;
			CLOSE companiesCursor;
			IF (JSON_LENGTH(validCompaniesIDArray) > 0)
				THEN BEGIN
					UPDATE companies SET type_id = 15 WHERE JSON_CONTAINS(validCompaniesIDArray, CONCAT(company_id));
					SET responce = JSON_MERGE(responce, 
						JSON_OBJECT(
							"type", "sendToApi",
							"data", JSON_OBJECT(
								"companies", validCompaniesArray
							)
						),
						JSON_OBJECT(
							"type", "sendToSocket",
							"data", JSON_OBJECT(
								"socketID", connectionApiID,
								"data", JSON_ARRAY(
									JSON_OBJECT(
										"type", "deleteFromArray",
										"data", JSON_OBJECT(
											"name", "companies",
											"searchParam", "companyID",
											"searchValues", validCompaniesIDArray
										)
									)
								)
							)
						)
					);
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