BEGIN
	DECLARE company, responce JSON;
	DECLARE done TINYINT(1);
	DECLARE companiesCursor CURSOR FOR SELECT company_json FROM companies WHERE  IF(dateStart IS NOT NULL AND dateEnd IS NOT NULL, DATE(company_date_create) BETWEEN dateStart AND dateEnd, 1) AND JSON_CONTAINS(types, CONCAT(type_id)) AND IF(userID IS NOT NULL, user_id = userID, 1) ORDER BY company_date_create DESC;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
	SET responce = JSON_ARRAY();
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
	RETURN responce;
END