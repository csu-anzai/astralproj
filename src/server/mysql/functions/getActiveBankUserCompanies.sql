BEGIN
	DECLARE company, responce JSON;
	DECLARE done TINYINT(1);
	DECLARE companiesCursor CURSOR FOR SELECT DISTINCT company_json FROM companies WHERE user_id = userID AND DATE(company_date_create) = DATE(NOW());
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