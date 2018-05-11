BEGIN
	DECLARE userID INT(11) DEFAULT (SELECT user_id FROM connections WHERE connection_id = connectionID);
	DECLARE responce, type, company JSON;
	DECLARE distributionFilters JSON DEFAULT (SELECT state_json ->> "$.distribution" FROM states WHERE connection_id = connectionID);
	DECLARE done TINYINT(1);
	DECLARE companiesCursor CURSOR FOR SELECT company_json FROM companies WHERE (((type_id IN (15,16,17,24,25,26,27,28,29,30,31,32) AND DATE(company_date_create) BETWEEN DATE(JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.api.dateStart"))) AND DATE(JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.api.dateEnd")))) OR (type_id = 14 AND DATE(company_date_create) BETWEEN DATE(JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.invalidate.dateStart"))) AND DATE(JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.invalidate.dateEnd")))) OR (type_id = 37 AND DATE(company_date_create) BETWEEN DATE(JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.difficult.dateStart"))) AND DATE(JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.difficult.dateEnd")))) OR (type_id = 23 AND DATE(company_date_create) BETWEEN DATE(JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.callBack.dateStart"))) AND DATE(JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.callBack.dateEnd")))) OR (type_id IN (9, 35))) AND user_id = userID) OR (type_id = 36 AND DATE(company_date_create) BETWEEN DATE(JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.notDial.dateStart"))) AND DATE(JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.notDial.dateEnd")))) ORDER BY type_id;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
	SET responce = JSON_ARRAY();
	IF distributionFilters IS NOT NULL
		THEN BEGIN
			UPDATE companies SET type_id = 9, company_date_call_back = NULL WHERE user_id = userID AND type_id = 23 AND NOW() >= company_date_call_back;
			OPEN companiesCursor;
				companiesLoop: LOOP
					FETCH companiesCursor INTO company;
					IF done 
						THEN LEAVE companiesLoop;
					END IF;
					SET responce = JSON_MERGE(responce, company);
					ITERATE companiesLoop;
				END LOOP;
			CLOSE companiesCursor;
		END;
	END IF;
	RETURN responce;
END