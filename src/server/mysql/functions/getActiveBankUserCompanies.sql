BEGIN
	DECLARE userID INT(11) DEFAULT (SELECT user_id FROM connections WHERE connection_id = connectionID);
	DECLARE responce, type, company JSON;
	DECLARE distributionFilters JSON DEFAULT (SELECT state_json ->> "$.distribution" FROM states WHERE connection_id = connectionID);
	DECLARE done TINYINT(1);
	DECLARE companiesCursor CURSOR FOR 
		SELECT 
			company_json
		FROM (
			SELECT 
				company_json, 
				@apiCount:=IF(type_id IN (15,16,17,24,25,26,27,28,29,30,31,32), @apiCount+1, @apiCount) apiCount, 
				@invalidateCount:=IF(type_id = 14, @invalidateCount+1, @invalidateCount) invalidateCount, 
				@difficultCount:=IF(type_id = 37, @difficultCount+1, @difficultCount) difficultCount, 
				@callbackCount:=IF(type_id = 23, @callbackCount+1, @callbackCount) callbackCount, 
				@inworkCount:=IF(type_id IN (9, 35), @inworkCount+1, @inworkCount) inworkCount, 
				@dialCount:=IF(type_id = 36, @dialCount+1, @dialCount) dialCount,
				type_id
			FROM 
				companies 
			WHERE 
				(
					(
						(type_id IN (15,16,17,24,25,26,27,28,29,30,31,32) AND DATE(company_date_create) BETWEEN DATE(@apiDateStart) AND DATE(@apiDateEnd)) OR 
						(type_id = 14 AND DATE(company_date_create) BETWEEN DATE(@invalidateDateStart) AND DATE(@invalidateDateEnd)) OR 
						(type_id = 37 AND DATE(company_date_create) BETWEEN DATE(@difficultDateStart) AND DATE(@difficultDateEnd)) OR 
						(type_id = 23 AND DATE(company_date_create) BETWEEN DATE(@callbackDateStart) AND DATE(@callbackDateEnd)) OR 
						(type_id IN (9, 35))
					) AND user_id = userID
				) OR 
				(type_id = 36 AND DATE(company_date_create) BETWEEN DATE(@dialDateStart) AND DATE(@dialDateEnd))
			ORDER BY type_id ASC, company_date_registration DESC
		) c
		WHERE 
			(apiCount BETWEEN @apiRowStart AND @apiRowLimit AND type_id IN (15,16,17,24,25,26,27,28,29,30,31,32)) OR
			(invalidateCount BETWEEN @invalidateRowStart AND @invalidateRowLimit AND type_id = 14) OR
			(difficultCount BETWEEN @difficultRowStart AND @difficultRowLimit AND type_id = 37) OR
			(callbackCount BETWEEN @callbackRowStart AND @callbackRowLimit AND type_id = 23) OR
			(inworkCount BETWEEN @inworkRowStart AND @inworkRowLimit AND type_id IN (9, 35)) OR
			(dialCount BETWEEN @dialRowStart AND @dialRowLimit AND type_id = 36);
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
					@inworkCount = 0,
					@apiRowStart = JSON_EXTRACT(distributionFilters, "$.api.rowStart"),
					@apiRowLimit = JSON_EXTRACT(distributionFilters, "$.api.rowLimit"),
					@apiDateStart = JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.api.dateStart")),
					@apiDateEnd = JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.api.dateEnd")),
					@invalidateRowStart = JSON_EXTRACT(distributionFilters, "$.invalidate.rowStart"),
					@invalidateRowLimit = JSON_EXTRACT(distributionFilters, "$.invalidate.rowLimit"),
					@invalidateDateStart = JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.invalidate.dateStart")),
					@invalidateDateEnd = JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.invalidate.dateEnd")),
					@difficultRowStart = JSON_EXTRACT(distributionFilters, "$.difficult.rowStart"),
					@difficultRowLimit = JSON_EXTRACT(distributionFilters, "$.difficult.rowLimit"),
					@difficultDateStart = JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.difficult.dateStart")),
					@difficultDateEnd = JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.difficult.dateEnd")),
					@callbackRowStart = JSON_EXTRACT(distributionFilters, "$.callBack.rowStart"),
					@callbackRowLimit = JSON_EXTRACT(distributionFilters, "$.callBack.rowLimit"),
					@callbackDateStart = JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.callBack.dateStart")),
					@callbackDateEnd = JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.callBack.dateEnd")),
					@dialRowStart = JSON_EXTRACT(distributionFilters, "$.notDial.rowStart"),
					@dialRowLimit = JSON_EXTRACT(distributionFilters, "$.notDial.rowLimit"),
					@dialDateStart = JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.notDial.dateStart")),
					@dialDateEnd = JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.notDial.dateEnd")),
					@inworkRowStart = JSON_EXTRACT(distributionFilters, "$.work.rowStart"),
					@inworkRowLimit = JSON_EXTRACT(distributionFilters, "$.work.rowLimit");
			SET @apiRowLimit = @apiRowLimit + @apiRowStart - 1,
					@invalidateRowLimit = @invalidateRowLimit + @invalidateRowStart - 1,
					@difficultRowLimit = @difficultRowLimit + @difficultRowStart - 1,
					@callbackRowLimit = @callbackRowLimit + @callbackRowStart - 1,
					@inworkRowLimit = @inworkRowLimit + @inworkRowStart - 1,
					@dialRowLimit = @dialRowLimit + @dialRowStart - 1;
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