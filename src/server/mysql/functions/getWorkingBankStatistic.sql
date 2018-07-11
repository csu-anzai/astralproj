BEGIN
	DECLARE done TINYINT(1);
	DECLARE responce JSON;
	DECLARE companiesCount, iterator INT(11);
	DECLARE companiesHour VARCHAR(2);
	DECLARE companiesDate VARCHAR(10);  
	DECLARE templateName VARCHAR(128);
	DECLARE companiesCursor CURSOR FOR SELECT COUNT(*), DATE(c.company_date_update) company_date, HOUR(c.company_date_update) company_hour, ty.type_name FROM companies c JOIN templates t ON t.template_id = c.template_id JOIN types ty ON ty.type_id = t.type_id WHERE bank_id = bankID AND JSON_CONTAINS(companiesTypes, CONCAT(c.type_id)) AND IF(userID IS NOT NULL AND userID > 0, c.user_id = userID, 1) AND DATE(company_date_update) BETWEEN DATE(dateStart) AND DATE(dateEnd) GROUP BY company_date, company_hour, ty.type_name; 
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
	SET responce = JSON_ARRAY();
	SET iterator = 0;
	OPEN companiesCursor;
		companiesLoop: LOOP
			FETCH companiesCursor INTO companiesCount, companiesDate, companiesHour, templateName;
			IF done	
				THEN LEAVE companiesLoop;
			END IF;
			SET responce = JSON_MERGE(responce, JSON_OBJECT(
				"template_name", templateName,
				"companies", companiesCount,
				"date", companiesDate,
				"hour", companiesHour
			));
			ITERATE companiesLoop;
		END LOOP;
	CLOSE companiesCursor;
	RETURN responce;
END