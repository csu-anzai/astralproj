BEGIN
	DECLARE typeToView, period, bankID, type INT(11);
	DECLARE firstDate VARCHAR(19);
	DECLARE dataFree, dataBank TINYINT(11);
	DECLARE types JSON;
	SELECT bank_id INTO bankID FROM users WHERE user_id = NEW.user_id;
	SET NEW.state_date_update = NOW();
	SET typeToView = JSON_EXTRACT(NEW.state_json, "$.statistic.typeToView");
	SET period = JSON_EXTRACT(NEW.state_json, "$.statistic.period");
	CASE typeToView
		WHEN 0 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(9, 13, 14, 15, 16, 17, 23));
		WHEN 1 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(17));
		WHEN 2 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(15));
		WHEN 3 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(16));
		WHEN 4 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(13));
		WHEN 5 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(14));
		WHEN 6 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(9));
		WHEN 7 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(15, 16, 17));
		WHEN 8 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(13, 14));
		WHEN 9 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(13, 14, 15, 16, 17, 23));
		WHEN 10 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(23));
		ELSE SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(9, 13, 14, 15, 16, 17, 23));
	END CASE;
	SET types = JSON_EXTRACT(NEW.state_json, "$.statistic.types");
	CASE period
		WHEN 0 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 WEEK)), "$.statistic.dateEnd", DATE(NOW()));
		WHEN 1 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 MONTH)), "$.statistic.dateEnd", DATE(NOW()));
		WHEN 2 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 YEAR)), "$.statistic.dateEnd", DATE(NOW()));
		WHEN 3 THEN BEGIN 
			SELECT company_date_update INTO firstDate FROM companies WHERE JSON_CONTAINS(types, JSON_ARRAY(type_id)) AND bank_id = bankID ORDER BY company_date_update LIMIT 1;
			IF firstDate IS NULL
				THEN SET firstDate = DATE(NOW());
			END IF;
			SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.dateStart", DATE(firstDate), "$.statistic.dateEnd", DATE(NOW()));
		END;
		WHEN 4 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.dateStart", DATE(NOW()), "$.statistic.dateEnd", DATE(NOW()));
		WHEN 5 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 DAY)), "$.statistic.dateEnd", DATE(SUBDATE(NOW(), INTERVAL 1 DAY)));
		ELSE SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 WEEK)), "$.statistic.dateEnd", DATE(NOW()));
	END CASE;
	SET period = JSON_EXTRACT(NEW.state_json, "$.statistic.dataPeriod");
	CASE period
		WHEN 0 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.dataDateStart", DATE(SUBDATE(NOW(), INTERVAL 1 WEEK)), "$.statistic.dataDateEnd", DATE(NOW()));
		WHEN 1 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.dataDateStart", DATE(SUBDATE(NOW(), INTERVAL 1 MONTH)), "$.statistic.dataDateEnd", DATE(NOW()));
		WHEN 2 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.dataDateStart", DATE(SUBDATE(NOW(), INTERVAL 1 YEAR)), "$.statistic.dataDateEnd", DATE(NOW()));
		WHEN 3 THEN BEGIN
			SET dataFree = JSON_UNQUOTE(JSON_EXTRACT(NEW.state_json, "$.statistic.dataFree"));
			SET dataBank = JSON_UNQUOTE(JSON_EXTRACT(NEW.state_json, "$.statistic.dataBank"));
			SELECT company_date_create INTO firstDate FROM companies WHERE IF(dataFree, type_id = 10, 1) AND IF(dataBank, bank_id = bankID, 1) ORDER BY company_date_create LIMIT 1;
			SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.dataDateStart", DATE(firstDate), "$.statistic.dataDateEnd", DATE(NOW()));
		END;
		WHEN 4 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.dataDateStart", DATE(SUBDATE(NOW(), INTERVAL 1 DAY)), "$.statistic.dataDateEnd", DATE(SUBDATE(NOW(), INTERVAL 1 DAY)));
		WHEN 5 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.dataDateStart", DATE(NOW()), "$.statistic.dataDateEnd", DATE(NOW()));
	END CASE;
	SET type = JSON_EXTRACT(NEW.state_json, "$.download.type");
	CASE type
		WHEN 0 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(9, 13, 14, 15, 16, 17, 10, 23));
		WHEN 1 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(17));
		WHEN 2 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(15));
		WHEN 3 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(16));
		WHEN 4 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(13));
		WHEN 5 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(14));
		WHEN 6 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(9));
		WHEN 7 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(15, 16, 17));
		WHEN 8 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(13, 14));
		WHEN 9 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(13, 14, 15, 16, 17, 23));
		WHEN 10 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(10));
		WHEN 11 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(23));
		ELSE SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(9, 13, 14, 15, 16, 17, 10, 23));
	END CASE;
END