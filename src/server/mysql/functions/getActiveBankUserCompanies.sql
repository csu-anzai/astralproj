BEGIN
	DECLARE userID INT(11);
	DECLARE dateEnd, dateStart VARCHAR(19);
	DECLARE responce, distributionFilters, types JSON;
	SET responce = JSON_ARRAY();
	SELECT state_json ->> "$.distribution" INTO distributionFilters FROM states WHERE connection_id = connectionID;
	IF distributionFilters IS NOT NULL
		THEN BEGIN
			SELECT user_id INTO userID FROM connections WHERE connection_id = connectionID;
			SET types = JSON_ARRAY(15,16,17,24,25,26,27,28,29,30,31,32); 
			SET dateStart = JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.api.dateStart"));
			SET dateEnd = JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.api.dateEnd"));
			SET responce = getFilterCompaniesForUser(userID, types, dateStart, dateEnd);
			SET types = JSON_ARRAY(14);
			SET dateStart = JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.invalidate.dateStart"));
			SET dateEnd = JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.invalidate.dateEnd"));
			SET responce = JSON_MERGE(responce, getFilterCompaniesForUser(userID, types, dateStart, dateEnd));
			SET types = JSON_ARRAY(36);
			SET dateStart = JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.notDial.dateStart"));
			SET dateEnd = JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.notDial.dateEnd"));
			SET responce = JSON_MERGE(responce, getFilterCompaniesForUser(NULL, types, dateStart, dateEnd));
			SET types = JSON_ARRAY(37);
			SET dateStart = JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.difficult.dateStart"));
			SET dateEnd = JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.difficult.dateEnd"));
			SET responce = JSON_MERGE(responce, getFilterCompaniesForUser(userID, types, dateStart, dateEnd));
			SET types = JSON_ARRAY(23);
			SET dateStart = JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.callBack.dateStart"));
			SET dateEnd = JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.callBack.dateEnd"));
			UPDATE companies SET type_id = 9, company_date_call_back = NULL WHERE user_id = userID AND type_id = 23 AND NOW() >= company_date_call_back;
			SET responce = JSON_MERGE(responce, getFilterCompaniesForUser(userID, types, dateStart, dateEnd));
			SET types = JSON_ARRAY(9);
			SET responce = JSON_MERGE(responce, getFilterCompaniesForUser(userID, types, NULL, NULL));
			SET types = JSON_ARRAY(35);
			SET responce = JSON_MERGE(responce, getFilterCompaniesForUser(userID, types, NULL, NULL));
		END;
	END IF;
	RETURN responce;
END