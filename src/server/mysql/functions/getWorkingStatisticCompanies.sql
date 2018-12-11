BEGIN
	DECLARE done TINYINT(1);
	DECLARE responce, company JSON;
	DECLARE companiesCursor CURSOR FOR SELECT 
		company_json 
	FROM 
		working_statistic_companies_view 
	WHERE 
		JSON_LENGTH(company_banks) > 0 AND 
		IF(companiesTypes IS NOT NULL AND JSON_LENGTH(companiesTypes) > 0, JSON_CONTAINS(companiesTypes, CONCAT(type_id)), 1) AND 
		IF(users IS NOT NULL AND JSON_LENGTH(users) > 0, JSON_CONTAINS(users, CONCAT(user_id)), 1) AND
		IF(banks IS NOT NULL AND JSON_ARRAY(banks) > 0, jsonContainsLeastOne(JSON_EXTRACT(company_banks, "$.*.bank_id"), banks), 1) AND 
		IF(statuses IS NOT NULL AND JSON_LENGTH(statuses) > 0, jsonContainsLeastOne(JSON_EXTRACT(company_banks, "$.*.bank_status_id"), statuses), 1) AND
		DATE(company_date_update) BETWEEN DATE(dateStart) AND DATE(dateEnd) 
	LIMIT 
		companiesLimit 
	OFFSET 
		companiesOffset;
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