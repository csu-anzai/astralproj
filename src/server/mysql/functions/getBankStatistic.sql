BEGIN
	DECLARE responce, allTypes, apiError, apiProcess, apiSuccess, invalidate, validate, labelsArr, ipArr, allArr, oooArr JSON;
	DECLARE done TINYINT(1);
	DECLARE typeID, oooCount, ipCount, allCount INT(11);
	DECLARE companyDate VARCHAR(10);
	DECLARE companyTime VARCHAR(8);
	DECLARE allTypesCursor CURSOR FOR SELECT DISTINCT type_id, date FROM statistic_view WHERE bank_id = bankID AND type_id IN (15, 16, 17, 13, 14) AND date BETWEEN date(dateStart) AND date(dateEnd);
	DECLARE apiErrorCursor CURSOR FOR SELECT DISTINCT type_id, date FROM statistic_view WHERE bank_id = bankID AND type_id = 17 AND date BETWEEN date(dateStart) AND date(dateEnd);
	DECLARE apiProcessCursor CURSOR FOR SELECT DISTINCT type_id, date FROM statistic_view WHERE bank_id = bankID AND type_id = 15 AND date BETWEEN date(dateStart) AND date(dateEnd);
	DECLARE apiSuccessCursor CURSOR FOR SELECT DISTINCT type_id, date FROM statistic_view WHERE bank_id = bankID AND type_id = 16 AND date BETWEEN date(dateStart) AND date(dateEnd);
	DECLARE validateCursor CURSOR FOR SELECT DISTINCT type_id, date FROM statistic_view WHERE bank_id = bankID AND type_id = 13 AND date BETWEEN date(dateStart) AND date(dateEnd);
	DECLARE invalidateCursor CURSOR FOR SELECT DISTINCT type_id, date FROM statistic_view WHERE bank_id = bankID AND type_id = 14 AND date BETWEEN date(dateStart) AND date(dateEnd);
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
	SET responce = JSON_OBJECT();
	SET allTypes = JSON_OBJECT(
		"labels", JSON_ARRAY(),
		"ooo", JSON_ARRAY(),
		"ip", JSON_ARRAY()
	);
	SET apiError = JSON_OBJECT(
		"labels", JSON_ARRAY(),
		"ooo", JSON_ARRAY(),
		"ip", JSON_ARRAY(),
		"all", JSON_ARRAY()
	);
	SET apiProcess = JSON_OBJECT(
		"labels", JSON_ARRAY(),
		"ooo", JSON_ARRAY(),
		"ip", JSON_ARRAY(),
		"all", JSON_ARRAY()
	);
	SET apiSuccess = JSON_OBJECT(
		"labels", JSON_ARRAY(),
		"ooo", JSON_ARRAY(),
		"ip", JSON_ARRAY(),
		"all", JSON_ARRAY()
	);
	SET invalidate = JSON_OBJECT(
		"labels", JSON_ARRAY(),
		"ooo", JSON_ARRAY(),
		"ip", JSON_ARRAY(),
		"all", JSON_ARRAY()
	);
	SET validate = JSON_OBJECT(
		"labels", JSON_ARRAY(),
		"ooo", JSON_ARRAY(),
		"ip", JSON_ARRAY(),
		"all", JSON_ARRAY()
	);

	SET labelsArr = JSON_ARRAY();
	SET ipArr = JSON_ARRAY();
	SET oooArr = JSON_ARRAY();
	SET allArr = JSON_ARRAY();
	OPEN allTypesCursor;
		allTypesLoop: LOOP
			FETCH allTypesCursor INTO typeID, companyDate;
			IF done 
				THEN LEAVE allTypesLoop;
			END IF;
			SELECT COUNT(*) INTO allCount FROM companies WHERE bank_id = bankID AND type_id = typeID AND date(company_date_update) = date(companyDate);
			SELECT COUNT(*) INTO ipCount FROM companies WHERE bank_id = bankID AND type_id = typeID AND date(company_date_update) = date(companyDate) AND template_id = 1;
			SELECT COUNT(*) INTO oooCount FROM companies WHERE bank_id = bankID AND type_id = typeID AND date(company_date_update) = date(companyDate) AND template_id = 2; 
			SET labelsArr = JSON_MERGE(labelsArr, JSON_ARRAY(companyDate));
			SET ipArr = JSON_MERGE(ipArr, JSON_ARRAY(ipCount));
			SET oooArr = JSON_MERGE(oooArr, JSON_ARRAY(oooCount));
			SET allArr = JSON_MERGE(allArr, JSON_ARRAY(allCount));
			ITERATE allTypesLoop;
		END LOOP;
	CLOSE allTypesCursor;
	SET allTypes = JSON_SET(allTypes, "$.labels", labelsArr, "$.all", allArr, "$.ip", ipArr, "$.ooo", oooArr);
	SET responce = JSON_SET(responce, "$.allTypes", allTypes);

	SET labelsArr = JSON_ARRAY();
	SET ipArr = JSON_ARRAY();
	SET oooArr = JSON_ARRAY();
	SET allArr = JSON_ARRAY();
	SET done = 0;
	OPEN apiErrorCursor;
		apiErrorLoop: LOOP
			FETCH apiErrorCursor INTO typeID, companyDate;
			IF done 
				THEN LEAVE apiErrorLoop;
			END IF;
			SELECT COUNT(*) INTO allCount FROM companies WHERE bank_id = bankID AND type_id = typeID AND date(company_date_update) = date(companyDate);
			SELECT COUNT(*) INTO ipCount FROM companies WHERE bank_id = bankID AND type_id = typeID AND date(company_date_update) = date(companyDate) AND template_id = 1;
			SELECT COUNT(*) INTO oooCount FROM companies WHERE bank_id = bankID AND type_id = typeID AND date(company_date_update) = date(companyDate) AND template_id = 2; 
			SET labelsArr = JSON_MERGE(labelsArr, JSON_ARRAY(companyDate));
			SET ipArr = JSON_MERGE(ipArr, JSON_ARRAY(ipCount));
			SET oooArr = JSON_MERGE(oooArr, JSON_ARRAY(oooCount));
			SET allArr = JSON_MERGE(allArr, JSON_ARRAY(allCount));
			ITERATE apiErrorLoop;
		END LOOP;
	CLOSE apiErrorCursor;
	SET apiError = JSON_SET(apiError, "$.labels", labelsArr, "$.all", allArr, "$.ip", ipArr, "$.ooo", oooArr);
	SET responce = JSON_SET(responce, "$.apiError", apiError);

	SET labelsArr = JSON_ARRAY();
	SET ipArr = JSON_ARRAY();
	SET oooArr = JSON_ARRAY();
	SET allArr = JSON_ARRAY();
	SET done = 0;
	OPEN apiProcessCursor;
		apiProcessLoop: LOOP
			FETCH apiProcessCursor INTO typeID, companyDate;
			IF done 
				THEN LEAVE apiProcessLoop;
			END IF;
			SELECT COUNT(*) INTO allCount FROM companies WHERE bank_id = bankID AND type_id = typeID AND date(company_date_update) = date(companyDate);
			SELECT COUNT(*) INTO ipCount FROM companies WHERE bank_id = bankID AND type_id = typeID AND date(company_date_update) = date(companyDate) AND template_id = 1;
			SELECT COUNT(*) INTO oooCount FROM companies WHERE bank_id = bankID AND type_id = typeID AND date(company_date_update) = date(companyDate) AND template_id = 2; 
			SET labelsArr = JSON_MERGE(labelsArr, JSON_ARRAY(companyDate));
			SET ipArr = JSON_MERGE(ipArr, JSON_ARRAY(ipCount));
			SET oooArr = JSON_MERGE(oooArr, JSON_ARRAY(oooCount));
			SET allArr = JSON_MERGE(allArr, JSON_ARRAY(allCount));
			ITERATE apiProcessLoop;
		END LOOP;
	CLOSE apiProcessCursor;
	SET apiProcess = JSON_SET(apiProcess, "$.labels", labelsArr, "$.all", allArr, "$.ip", ipArr, "$.ooo", oooArr);
	SET responce = JSON_SET(responce, "$.apiProcess", apiProcess);

	SET labelsArr = JSON_ARRAY();
	SET ipArr = JSON_ARRAY();
	SET oooArr = JSON_ARRAY();
	SET allArr = JSON_ARRAY();
	SET done = 0;
	OPEN apiSuccessCursor;
		apiSuccessLoop: LOOP
			FETCH apiSuccessCursor INTO typeID, companyDate;
			IF done 
				THEN LEAVE apiSuccessLoop;
			END IF;
			SELECT COUNT(*) INTO allCount FROM companies WHERE bank_id = bankID AND type_id = typeID AND date(company_date_update) = date(companyDate);
			SELECT COUNT(*) INTO ipCount FROM companies WHERE bank_id = bankID AND type_id = typeID AND date(company_date_update) = date(companyDate) AND template_id = 1;
			SELECT COUNT(*) INTO oooCount FROM companies WHERE bank_id = bankID AND type_id = typeID AND date(company_date_update) = date(companyDate) AND template_id = 2; 
			SET labelsArr = JSON_MERGE(labelsArr, JSON_ARRAY(companyDate));
			SET ipArr = JSON_MERGE(ipArr, JSON_ARRAY(ipCount));
			SET oooArr = JSON_MERGE(oooArr, JSON_ARRAY(oooCount));
			SET allArr = JSON_MERGE(allArr, JSON_ARRAY(allCount));
			ITERATE apiSuccessLoop;
		END LOOP;
	CLOSE apiSuccessCursor;
	SET apiSuccess = JSON_SET(apiSuccess, "$.labels", labelsArr, "$.all", allArr, "$.ip", ipArr, "$.ooo", oooArr);
	SET responce = JSON_SET(responce, "$.apiSuccess", apiSuccess);

	SET labelsArr = JSON_ARRAY();
	SET ipArr = JSON_ARRAY();
	SET oooArr = JSON_ARRAY();
	SET allArr = JSON_ARRAY();
	SET done = 0;
	OPEN invalidateCursor;
		invalidateLoop: LOOP
			FETCH invalidateCursor INTO typeID, companyDate;
			IF done 
				THEN LEAVE invalidateLoop;
			END IF;
			SELECT COUNT(*) INTO allCount FROM companies WHERE bank_id = bankID AND type_id = typeID AND date(company_date_update) = date(companyDate);
			SELECT COUNT(*) INTO ipCount FROM companies WHERE bank_id = bankID AND type_id = typeID AND date(company_date_update) = date(companyDate) AND template_id = 1;
			SELECT COUNT(*) INTO oooCount FROM companies WHERE bank_id = bankID AND type_id = typeID AND date(company_date_update) = date(companyDate) AND template_id = 2; 
			SET labelsArr = JSON_MERGE(labelsArr, JSON_ARRAY(companyDate));
			SET ipArr = JSON_MERGE(ipArr, JSON_ARRAY(ipCount));
			SET oooArr = JSON_MERGE(oooArr, JSON_ARRAY(oooCount));
			SET allArr = JSON_MERGE(allArr, JSON_ARRAY(allCount));
			ITERATE invalidateLoop;
		END LOOP;
	CLOSE invalidateCursor;
	SET invalidate = JSON_SET(invalidate, "$.labels", labelsArr, "$.all", allArr, "$.ip", ipArr, "$.ooo", oooArr);
	SET responce = JSON_SET(responce, "$.invalidate", invalidate);

	SET labelsArr = JSON_ARRAY();
	SET ipArr = JSON_ARRAY();
	SET oooArr = JSON_ARRAY();
	SET allArr = JSON_ARRAY();
	SET done = 0;
	OPEN validateCursor;
		validateLoop: LOOP
			FETCH validateCursor INTO typeID, companyDate;
			IF done 
				THEN LEAVE validateLoop;
			END IF;
			SELECT COUNT(*) INTO allCount FROM companies WHERE bank_id = bankID AND type_id = typeID AND date(company_date_update) = date(companyDate);
			SELECT COUNT(*) INTO ipCount FROM companies WHERE bank_id = bankID AND type_id = typeID AND date(company_date_update) = date(companyDate) AND template_id = 1;
			SELECT COUNT(*) INTO oooCount FROM companies WHERE bank_id = bankID AND type_id = typeID AND date(company_date_update) = date(companyDate) AND template_id = 2; 
			SET labelsArr = JSON_MERGE(labelsArr, JSON_ARRAY(companyDate));
			SET ipArr = JSON_MERGE(ipArr, JSON_ARRAY(ipCount));
			SET oooArr = JSON_MERGE(oooArr, JSON_ARRAY(oooCount));
			SET allArr = JSON_MERGE(allArr, JSON_ARRAY(allCount));
			ITERATE validateLoop;
		END LOOP;
	CLOSE validateCursor;
	SET validate = JSON_SET(validate, "$.labels", labelsArr, "$.all", allArr, "$.ip", ipArr, "$.ooo", oooArr);
	SET responce = JSON_SET(responce, "$.validate", validate);

	RETURN responce;
END