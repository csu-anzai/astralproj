BEGIN
	DECLARE companyID, templateID, cityID, regionID, priorityValue, companiesLength, userID, typeID INT(11);
	DECLARE timeID INT(11) DEFAULT getTimeID(1);
	DECLARE companyDateCreate, companyDateUpdate VARCHAR(19);
	DECLARE companyOgrn VARCHAR(15);
	DECLARE	companyOgrnDate, companyPersonBirthday, companyDocDate VARCHAR(10);
	DECLARE companyPersonName, companyPersonSurname, companyPersonPatronymic, connectionApiID VARCHAR(128);
	DECLARE companyPersonBirthplace, companyAddress, companyOrganizationName, companyEmail VARCHAR(1024);
	DECLARE companyInn, companyDocNumber, companyInnfl VARCHAR(12);
	DECLARE companyOrganizationCode VARCHAR(6);
	DECLARE companyPhone, companyHouse, companyDocHouse VARCHAR(20);
	DECLARE companyOkvedCode VARCHAR(8);
	DECLARE companyOkvedName VARCHAR(2048);
	DECLARE companyKpp, companyIndex VARCHAR(9);
	DECLARE companyRegionType, companyDocRegionType VARCHAR(50);
	DECLARE companyRegionName, companyDocName, companyDocRegionName VARCHAR(120);
	DECLARE companyAreaType, companyAreaName, companyLocalityType, companyLocalityName, companyStreetType, companyStreetName, companyPersonPositionType, companyPersonPositionName, companyDocAreaType, companyDocAreaName, 	companyDocLocalityType, companyDocLocalityName, companyDocStreetType, companyDocStreetName, cityName, regionName VARCHAR(60);
	DECLARE companyDocGitfter VARCHAR(256);
	DECLARE companyDocCode VARCHAR(7);
	DECLARE companyDocFlat VARCHAR(40);
	DECLARE responce, companiesArray, company JSON;
	DECLARE done, connectionValid TINYINT(1);
	DECLARE companiesCursor CURSOR FOR SELECT city_name, region_name, type_id, company_id, template_id, city_id, region_id, priority, company_date_create, company_date_update, company_ogrn, company_ogrn_date, company_person_birthday, company_doc_date, company_person_name, company_person_surname, company_person_patronymic, company_person_birthplace, company_address, company_organization_name, company_email, company_inn, company_doc_number, company_innfl, company_organization_code, company_phone, company_house, company_doc_house, company_okved_code, company_okved_name,  company_kpp, company_index, company_region_type, company_doc_region_type, company_region_name, company_doc_name, company_doc_region_name, company_area_type, company_area_name, company_locality_type, company_locality_name, company_street_type, company_street_name, company_person_position_type, company_person_position_name, company_doc_area_type, company_doc_area_name, 	company_doc_locality_type, company_doc_locality_name, company_doc_street_type, company_doc_street_name, company_doc_gitfter, company_doc_code, company_doc_flat FROM bank_cities_time_priority_companies_view WHERE bank_id = bankID AND date(company_date_create) = date(now()) AND time_id = timeID limit rows;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
	SET connectionValid = checkConnection(connectionHash);
	SELECT connection_api_id, user_id INTO connectionApiID, userID FROM users_connections_view WHERE connection_hash = connectionHash;
	SET responce = JSON_ARRAY();
	IF connectionValid
		THEN BEGIN
			SET companiesArray = JSON_ARRAY();
			UPDATE companies SET user_id = NULL, type_id = 10 WHERE user_id = userID AND type_id = 9;
			SET done = 0;
			OPEN companiesCursor;
				companiesLoop: LOOP
					FETCH companiesCursor INTO cityName, regionName, typeID, companyID, templateID, cityID, regionID, priorityValue, companyDateCreate, companyDateUpdate, companyOgrn, companyOgrnDate, companyPersonBirthday, companyDocDate, companyPersonName, companyPersonSurname, companyPersonPatronymic, companyPersonBirthplace, companyAddress, companyOrganizationName, companyEmail, companyInn, companyDocNumber, companyInnfl, companyOrganizationCode, companyPhone, companyHouse, companyDocHouse, companyOkvedCode, companyOkvedName, companyKpp, companyIndex, companyRegionType, companyDocRegionType, companyRegionName, companyDocName, companyDocRegionName, companyAreaType, companyAreaName, companyLocalityType, companyLocalityName, companyStreetType, companyStreetName, companyPersonPositionType, companyPersonPositionName, companyDocAreaType, companyDocAreaName, companyDocLocalityType, companyDocLocalityName, companyDocStreetType, companyDocStreetName, companyDocGitfter, companyDocCode, companyDocFlat;
					IF done 
						THEN LEAVE companiesLoop;
					END IF;
					SET company = JSON_OBJECT("cityName", cityName, "regionName", regionName, "typeID", typeID, "companyID", companyID, "templateID", templateID, "cityID", cityID, "regionID", regionID, "timeID", timeID, "Priority", priorityValue, "companyDateCreate", companyDateCreate, "companyDateUpdate", companyDateUpdate, "companyOgrn", companyOgrn, "companyOgrnDate", companyOgrnDate, "companyPersonBirthday", companyPersonBirthday, "companyDocDate", companyDocDate, "companyPersonName", companyPersonName, "companyPersonSurname", companyPersonSurname, "companyPersonPatronymic", companyPersonPatronymic, "companyPersonBirthplace", companyPersonBirthplace, "companyAddress", companyAddress, "companyOrganizationName", companyOrganizationName, "companyEmail", companyEmail, "companyInn", companyInn, "companyDocNumber", companyDocNumber, "companyInnfl", companyInnfl, "companyOrganizationCode", companyOrganizationCode, "companyPhone", companyPhone, "companyHouse", companyHouse, "companyDocHouse", companyDocHouse, "companyOkvedCode", companyOkvedCode, "companyOkvedName", companyOkvedName, "companyKpp", companyKpp, "companyIndex", companyIndex, "companyRegionType", companyRegionType, "companyDocRegionType", companyDocRegionType, "companyRegionName", companyRegionName, "companyDocName", companyDocName, "companyDocRegionName", companyDocRegionName, "companyAreaType", companyAreaType, "companyAreaName", companyAreaName, "companyLocalityType", companyLocalityType, "companyLocalityName", companyLocalityName, "companyStreetType", companyStreetType, "companyStreetName", companyStreetName, "companyPersonPositionType", companyPersonPositionType, "companyPersonPositionName", companyPersonPositionName, "companyDocAreaType", companyDocAreaType, "companyDocAreaName", companyDocAreaName, "companyDocLocalityType", companyDocLocalityType, "companyDocLocalityName", companyDocLocalityName, "companyDocStreetType", companyDocStreetType, "companyDocStreetName", companyDocStreetName, "companyDocGitfter", companyDocGitfter, "companyDocCode", companyDocCode, "companyDocFlat", companyDocFlat);
					SET companiesArray = JSON_MERGE(companiesArray, company);
					UPDATE companies SET user_id = userID, type_id = 9 WHERE company_id = companyID;
					ITERATE companiesLoop;
				END LOOP;
			CLOSE companiesCursor;
			SET companiesLength = JSON_LENGTH(companiesArray);
			SET responce = JSON_MERGE(responce, JSON_OBJECT(
				"type", "sendToSocket",
				"data", JSON_OBJECT(
					"socketID", connectionApiID,
					"data", JSON_ARRAY(JSON_OBJECT(
						"type", "merge",
						"data", JSON_OBJECT(
							"companies", companiesArray,
							"messageType", IF(companiesLength > 0, "success", "error"),
							"message", IF(companiesLength > 0, CONCAT("Загружено компаний: ", companiesLength), CONCAT("Не удалось найти ни одной компании на данное время: ", HOUR(NOW()), ":", MINUTE(NOW())))
						)
					))
				)
			));
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