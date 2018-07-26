BEGIN	
	DECLARE done TINYINT(1);
	DECLARE userName, search VARCHAR(64);
	DECLARE typeID, companies INT(11);
	DECLARE responce, userCompanies, apiSuccessAllTypes JSON;
	DECLARE dateNow VARCHAR(10) DEFAULT DATE(NOW());
	DECLARE companiesCursor CURSOR FOR SELECT u.user_name, c.type_id, count(*) FROM companies c JOIN users u ON u.user_id = c.user_id WHERE DATE(c.company_date_update) = dateNow GROUP BY u.user_name, c.type_id;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
	SET responce = JSON_ARRAY();
	SET apiSuccessAllTypes = JSON_ARRAY(16, 25, 26, 27, 28, 29, 30);
	OPEN companiesCursor;
		companiesLoop: LOOP
			FETCH companiesCursor INTO userName, typeID, companies;
			IF done
				THEN LEAVE companiesLoop;
			END IF;
			SET search = JSON_UNQUOTE(JSON_SEARCH(responce, "one", userName, NULL, "$[*].user_name"));
			IF search IS NOT NULL
				THEN BEGIN
					SET search = REPLACE(REPLACE(search, "$[", ""), "].user_name", "");
					SET userCompanies = JSON_EXTRACT(responce, CONCAT("$[", search, "]"));
					SET responce = JSON_SET(responce, 
						CONCAT("$[", search, "].all_companies"), JSON_UNQUOTE(JSON_EXTRACT(userCompanies, "$.all_companies")) + companies,
						CONCAT("$[", search, "].api_success_all"), JSON_UNQUOTE(JSON_EXTRACT(userCompanies, "$.api_success_all")) + IF(JSON_CONTAINS(apiSuccessAllTypes, CONCAT(typeID)), companies, 0)
					);
				END;
				ELSE SET responce = JSON_MERGE(responce, JSON_OBJECT(
					"user_name", userName,
					"all_companies", companies,
					"api_success_all", IF(JSON_CONTAINS(apiSuccessAllTypes, CONCAT(typeID)), companies, 0)
				));
			END IF;
			ITERATE companiesLoop;
		END LOOP;
	CLOSE companiesCursor;
	RETURN responce;
END