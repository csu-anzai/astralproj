BEGIN
	DECLARE companyID INT(11);
	DECLARE companyInn VARCHAR(12);
	DECLARE responce, company, companies JSON;
	DECLARE done TINYINT(1);
	DECLARE companiesCursor CURSOR FOR SELECT company_id, company_inn FROM companies WHERE IF(endCompanyID IS NOT NULL, company_id BETWEEN startCompanyID AND endCompanyID, company_id > startCompanyID);
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
	SET responce = JSON_ARRAY();
	SET companies = JSON_ARRAY();
	OPEN companiesCursor;
		companiesLoop: LOOP
			FETCH companiesCursor INTO companyID, companyInn;
			IF done
				THEN LEAVE companiesLoop;
			END IF;
			SET company = JSON_OBJECT(
				"company_id", companyID,
				"company_inn", companyInn
			);
			SET companies = JSON_MERGE(companies, company);
			ITERATE companiesLoop;
		END LOOP;
	CLOSE companiesCursor;
	IF JSON_LENGTH(companies) > 0
		THEN SET responce = JSON_MERGE(responce, JSON_OBJECT(
			"type", "checkDuplicates",
			"data", JSON_OBJECT(
				"companies", companies
			)
		));
	END IF;
	RETURN responce;
END