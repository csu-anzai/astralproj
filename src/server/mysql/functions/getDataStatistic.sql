BEGIN
	DECLARE done TINYINT(1);
	DECLARE companiesCount INT(11);
	DECLARE templateName VARCHAR(128);
	DECLARE companiesDate VARCHAR(10);
	DECLARE companiesTime VARCHAR(5);
	DECLARE responce JSON;
	DECLARE companiesCursor CURSOR FOR SELECT 
		COUNT(*), 
		ty.type_name, 
		DATE(c.company_date_create) company_date, 
		CONCAT(HOUR(c.company_date_create), ":", MINUTE(c.company_date_create)) company_time 
	FROM 
		companies c 
		JOIN templates t ON t.template_id = c.template_id 
		JOIN types ty ON ty.type_id = t.type_id 
	WHERE 
		IF(banks IS NOT NULL AND JSON_LENGTH(banks) > 0, jsonContainsLeastOne(banks, c.company_json ->> "$.company_banks.*.bank_id"), JSON_LENGTH(c.company_json ->> "$.company_banks") = 0) AND 
		IF(free, c.type_id = 10, 1) AND 
		DATE(c.company_date_create) BETWEEN DATE(dateStart) AND DATE(dateEnd) 
	GROUP BY 
		company_date, 
		company_time, 
		ty.type_name 
	ORDER BY 
		company_date, 
		HOUR(company_time), 
		MINUTE(company_time), 
		ty.type_name;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
	SET responce = JSON_ARRAY();
	OPEN companiesCursor;
		companiesLoop: LOOP
			FETCH companiesCursor INTO companiesCount, templateName, companiesDate, companiesTime;
			IF done 
				THEN LEAVE companiesLoop;
			END IF;
			SET responce = JSON_MERGE(responce, JSON_OBJECT(
				"template_name", templateName,
				"companies", companiesCount,
				"date", companiesDate,
				"time", companiesTime
			));
			ITERATE companiesLoop;
		END LOOP;
	CLOSE companiesCursor;
	RETURN responce;
END