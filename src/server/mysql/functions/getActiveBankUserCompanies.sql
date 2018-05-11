BEGIN
	DECLARE userID INT(11) DEFAULT (SELECT user_id FROM connections WHERE connection_id = connectionID);
	DECLARE responce, type, company JSON;
	DECLARE distributionFilters JSON DEFAULT (SELECT state_json ->> "$.distribution" FROM states WHERE connection_id = connectionID);
	DECLARE done TINYINT(1);
	DECLARE companiesCursor CURSOR FOR SELECT company_json FROM (SELECT company_json, @apiCount:=IF(type_id IN (15,16,17,24,25,26,27,28,29,30,31,32), @apiCount+1, @apiCount), @invalidateCount:=IF(type_id = 14, @invalidateCount+1, @invalidateCount), @difficultCount:=IF(type_id = 37, @difficultCount+1, @difficultCount), @callbackCount:=IF(type_id = 23, @callbackCount+1, @callbackCount), @inworkCount:=IF(type_id IN (9, 35), @inworkCount+1, @inworkCount), @dialCount:=IF(type_id = 36, @dialCount+1, @dialCount) FROM companies WHERE (((type_id IN (15,16,17,24,25,26,27,28,29,30,31,32) AND DATE(company_date_create) BETWEEN DATE(JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.api.dateStart"))) AND DATE(JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.api.dateEnd"))) AND @apiCount + 1 BETWEEN JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.api.rowStart")) AND JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.api.rowStart")) + JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.api.rowLimit"))) OR (type_id = 14 AND DATE(company_date_create) BETWEEN DATE(JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.invalidate.dateStart"))) AND DATE(JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.invalidate.dateEnd"))) AND @invalidateCount + 1 BETWEEN JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.invalidate.rowStart")) AND JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.invalidate.rowStart")) + JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.invalidate.rowLimit"))) OR (type_id = 37 AND DATE(company_date_create) BETWEEN DATE(JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.difficult.dateStart"))) AND DATE(JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.difficult.dateEnd"))) AND @difficultCount + 1 BETWEEN JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.difficult.rowStart")) AND JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.difficult.rowStart")) + JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.difficult.rowLimit"))) OR (type_id = 23 AND DATE(company_date_create) BETWEEN DATE(JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.callBack.dateStart"))) AND DATE(JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.callBack.dateEnd"))) AND @callbackCount + 1 BETWEEN JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.callBack.rowStart")) AND JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.callBack.rowStart")) + JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.callBack.rowLimit"))) OR (type_id IN (9, 35) AND @inworkCount + 1 BETWEEN JSON_EXTRACT(distributionFilters, "$.work.rowStart") AND JSON_EXTRACT(distributionFilters, "$.work.rowLimit") + JSON_EXTRACT(distributionFilters, "$.work.rowStart"))) AND user_id = userID) OR (type_id = 36 AND DATE(company_date_create) BETWEEN DATE(JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.notDial.dateStart"))) AND DATE(JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.notDial.dateEnd"))) AND @dialCount + 1 BETWEEN JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.notDial.rowStart")) AND JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.notDial.rowStart")) + JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.notDial.rowLimit"))) ORDER BY type_id) c;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
	SET responce = JSON_ARRAY();
	IF distributionFilters IS NOT NULL
		THEN BEGIN
			UPDATE companies SET type_id = 9, company_date_call_back = NULL WHERE user_id = userID AND type_id = 23 AND NOW() >= company_date_call_back;
			SET @apiCount = 0,
					@invalidateCount = 0,
					@difficultCount = 0,
					@callbackCount = 0,
					@dialCount = 0,
					@inworkCount = 0;
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