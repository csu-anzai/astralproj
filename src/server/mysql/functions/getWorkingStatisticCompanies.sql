BEGIN
	DECLARE done TINYINT(1);
	DECLARE responce, company JSON;
	DECLARE companiesCursor CURSOR FOR SELECT company_json FROM working_statistic_companies_view WHERE bank_id = bankID AND JSON_CONTAINS(types, CONCAT(type_id)) AND IF(userID IS NOT NULL AND userID > 0, user_id = userID, 1) AND DATE(company_date_update) BETWEEN DATE(dateStart) AND DATE(dateEnd) LIMIT companiesLimit OFFSET companiesOffset;
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