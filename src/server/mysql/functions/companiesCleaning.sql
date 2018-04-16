BEGIN
	DECLARE responce JSON;
	DECLARE companyInn VARCHAR(12);
	DECLARE companyOgrn VARCHAR(15);
	DECLARE companiesLength, deleteDuplicateCompaniesLength INT(11);
	DECLARE done TINYINT(1);
	DECLARE innCursor CURSOR FOR SELECT company_inn, length FROM duplicate_companies_inn_view;
	DECLARE ogrnCursor CURSOR FOR SELECT company_ogrn, length FROM duplicate_companies_ogrn_view;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
	SET deleteDuplicateCompaniesLength = 0;
	SET responce = JSON_OBJECT();
	OPEN innCursor;
		innLoop: LOOP
			FETCH innCursor INTO companyInn, companiesLength;
			IF done 
				THEN LEAVE innLoop;
			END IF;
			SET companiesLength = companiesLength - 1;
			DELETE FROM companies WHERE company_inn = companyInn ORDER BY company_date_create DESC LIMIT companiesLength;
			SET deleteDuplicateCompaniesLength = deleteDuplicateCompaniesLength + companiesLength;
			ITERATE innLoop;
		END LOOP;
	CLOSE innCursor;
	SET done = 0;
	OPEN ogrnCursor;
		innLoop: LOOP
			FETCH ogrnCursor INTO companyOgrn, companiesLength;
			IF done 
				THEN LEAVE innLoop;
			END IF;
			SET companiesLength = companiesLength - 1;
			DELETE FROM companies WHERE company_ogrn = companyOgrn ORDER BY company_date_create DESC LIMIT companiesLength;
			SET deleteDuplicateCompaniesLength = deleteDuplicateCompaniesLength + companiesLength;
			ITERATE innLoop;
		END LOOP;
	CLOSE ogrnCursor;
	SELECT COUNT(*) INTO companiesLength FROM empty_companies_view;
	DELETE c FROM empty_companies_view ecv JOIN companies c ON c.company_id = ecv.company_id;
	SET responce = JSON_SET(responce,
		"$.deleteDuplicateCompanies", deleteDuplicateCompaniesLength,
		"$.deleteEmptyCompanies", companiesLength
	);
	RETURN responce;
END