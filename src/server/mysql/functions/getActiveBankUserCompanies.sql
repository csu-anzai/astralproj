BEGIN
	DECLARE userID INT(11);
	DECLARE dateEnd, dateStart VARCHAR(19);
	DECLARE responce, distributionFilters, types JSON;
	SET responce = JSON_ARRAY();
	SELECT state_json ->> "$.distribution" INTO distributionFilters FROM states WHERE connection_id = connectionID;
	IF distributionFilters IS NOT NULL
		THEN BEGIN
			SELECT user_id INTO userID FROM connections WHERE connection_id = connectionID;
			SET types = JSON_ARRAY(15,16,17); 
			SET dateStart = JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.api.dateStart"));
			SET dateEnd = JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.api.dateEnd"));
			SET responce = getFilterCompaniesForUser(userID, types, dateStart, dateEnd);
			SET types = JSON_ARRAY(14);
			SET dateStart = JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.invalidate.dateStart"));
			SET dateEnd = JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.invalidate.dateEnd"));
			SET responce = JSON_MERGE(responce, getFilterCompaniesForUser(userID, types, dateStart, dateEnd));
			SET types = JSON_ARRAY(23);
			SET dateStart = JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.callBack.dateStart"));
			SET dateEnd = JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.callBack.dateEnd"));
			SET responce = JSON_MERGE(responce, getFilterCompaniesForUser(userID, types, dateStart, dateEnd));
			SET types = JSON_ARRAY(9);
			SELECT MIN(DATE(company_date_create)) INTO dateStart FROM companies WHERE user_id = 1 AND type_id = 9;
			SET dateEnd = DATE(NOW());
			SET responce = JSON_MERGE(responce, getFilterCompaniesForUser(userID, types, dateStart, dateEnd));
		END;
	END IF;
	RETURN responce;
END