BEGIN
	DECLARE typeToView, period, bankID, type INT(11);
	DECLARE firstDate VARCHAR(19);
	DECLARE dataFree, dataBank TINYINT(11);
	DECLARE types JSON;
	SELECT bank_id INTO bankID FROM users WHERE user_id = NEW.user_id;
	SET NEW.state_date_update = NOW();
	IF JSON_EXTRACT(NEW.state_json, "$.statistic") IS NOT NULL
		THEN BEGIN
			SET typeToView = JSON_EXTRACT(NEW.state_json, "$.statistic.typeToView");
			SET period = JSON_EXTRACT(NEW.state_json, "$.statistic.period");
			CASE typeToView
				WHEN 0 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(9, 13, 14, 15, 16, 17, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32));
				WHEN 1 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(17, 24, 31, 32));
				WHEN 2 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(15));
				WHEN 3 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(16, 25, 26, 27, 28, 29, 30));
				WHEN 4 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(13));
				WHEN 5 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(14));
				WHEN 6 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(9));
				WHEN 7 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(15, 16, 17, 24, 25, 26, 27, 28, 29, 30, 31, 32));
				WHEN 8 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(13, 14));
				WHEN 9 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(13, 14, 15, 16, 17, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32));
				WHEN 10 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(23));
				WHEN 11 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(24));
				WHEN 12 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(25));
				WHEN 13 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(26));
				WHEN 14 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(27));
				WHEN 15 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(28));
				WHEN 16 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(29));
				WHEN 17 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(30));
				WHEN 18 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(31));
				WHEN 19 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(32));
				WHEN 20 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(17));
				WHEN 21 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(16));
				ELSE SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(9, 13, 14, 15, 16, 17, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32));
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
				WHEN 6 THEN BEGIN END;
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
				WHEN 6 THEN BEGIN END;
			END CASE;
		END;
	END IF;
	IF JSON_EXTRACT(NEW.state_json, "$.download") IS NOT NULL
		THEN BEGIN
			SET type = JSON_EXTRACT(NEW.state_json, "$.download.type");
			CASE type
				WHEN 0 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(9, 13, 14, 15, 16, 17, 10, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32));
				WHEN 1 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(17, 24, 31, 32));
				WHEN 2 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(15));
				WHEN 3 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(16, 25, 26, 27, 28, 29, 30));
				WHEN 4 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(13));
				WHEN 5 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(14));
				WHEN 6 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(9));
				WHEN 7 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(15, 16, 17, 24, 25, 26, 27, 28, 29, 30, 31, 32));
				WHEN 8 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(13, 14));
				WHEN 9 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(13, 14, 15, 16, 17, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32));
				WHEN 10 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(10));
				WHEN 11 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(23));
				WHEN 12 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(24));
				WHEN 13 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(25));
				WHEN 14 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(26));
				WHEN 15 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(27));
				WHEN 16 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(28));
				WHEN 17 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(29));
				WHEN 18 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(30));
				WHEN 19 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(31));
				WHEN 20 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(32));
				WHEN 21 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(17));
				WHEN 22 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(16));
				ELSE SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(9, 13, 14, 15, 16, 17, 10, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32));
			END CASE;
		END;
	END IF;
	IF JSON_EXTRACT(NEW.state_json, "$.distribution") IS NOT NULL
		THEN BEGIN
			SET type = JSON_EXTRACT(NEW.state_json, "$.distribution.invalidate.type");
			CASE type
				WHEN 0 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.invalidate.dateStart", DATE(NOW()), "$.distribution.invalidate.dateEnd", DATE(NOW()));
				WHEN 1 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.invalidate.dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 WEEK)), "$.distribution.invalidate.dateEnd", DATE(NOW()));
				WHEN 2 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.invalidate.dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 MONTH)), "$.distribution.invalidate.dateEnd", DATE(NOW()));
				WHEN 3 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.invalidate.dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 YEAR)), "$.distribution.invalidate.dateEnd", DATE(NOW()));
				WHEN 4 THEN BEGIN 
					SELECT company_date_create INTO firstDate FROM companies WHERE type_id = 14 AND bank_id = bankID ORDER BY company_date_update LIMIT 1;
					IF firstDate IS NULL
						THEN SET firstDate = DATE(NOW());
					END IF;
					SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.invalidate.dateStart", DATE(firstDate), "$.distribution.invalidate.dateEnd", DATE(NOW()));
				END;
				WHEN 5 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.invalidate.dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 DAY)), "$.distribution.invalidate.dateEnd", DATE(SUBDATE(NOW(), INTERVAL 1 DAY)));
				WHEN 6 THEN BEGIN
				END;
				ELSE SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.invalidate.dateStart", DATE(NOW()), "$.distribution.invalidate.dateEnd", DATE(NOW()));
			END CASE;
			SET type = JSON_EXTRACT(NEW.state_json, "$.distribution.callBack.type");
			CASE type
				WHEN 0 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.callBack.dateStart", DATE(NOW()), "$.distribution.callBack.dateEnd", DATE(NOW()));
				WHEN 1 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.callBack.dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 WEEK)), "$.distribution.callBack.dateEnd", DATE(NOW()));
				WHEN 2 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.callBack.dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 MONTH)), "$.distribution.callBack.dateEnd", DATE(NOW()));
				WHEN 3 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.callBack.dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 YEAR)), "$.distribution.callBack.dateEnd", DATE(NOW()));
				WHEN 4 THEN BEGIN 
					SELECT company_date_create INTO firstDate FROM companies WHERE type_id = 23 AND bank_id = bankID ORDER BY company_date_update LIMIT 1;
					IF firstDate IS NULL
						THEN SET firstDate = DATE(NOW());
					END IF;
					SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.callBack.dateStart", DATE(firstDate), "$.distribution.callBack.dateEnd", DATE(NOW()));
				END;
				WHEN 5 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.callBack.dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 DAY)), "$.distribution.callBack.dateEnd", DATE(SUBDATE(NOW(), INTERVAL 1 DAY)));
				WHEN 6 THEN BEGIN
				END;
				ELSE SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.callBack.dateStart", DATE(NOW()), "$.distribution.callBack.dateEnd", DATE(NOW()));
			END CASE;
			SET type = JSON_EXTRACT(NEW.state_json, "$.distribution.api.type");
			CASE type
				WHEN 0 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.api.dateStart", DATE(NOW()), "$.distribution.api.dateEnd", DATE(NOW()));
				WHEN 1 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.api.dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 WEEK)), "$.distribution.api.dateEnd", DATE(NOW()));
				WHEN 2 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.api.dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 MONTH)), "$.distribution.api.dateEnd", DATE(NOW()));
				WHEN 3 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.api.dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 YEAR)), "$.distribution.api.dateEnd", DATE(NOW()));
				WHEN 4 THEN BEGIN 
					SELECT company_date_create INTO firstDate FROM companies WHERE type_id IN (15, 16, 17) AND bank_id = bankID ORDER BY company_date_update LIMIT 1;
					IF firstDate IS NULL
						THEN SET firstDate = DATE(NOW());
					END IF;
					SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.api.dateStart", DATE(firstDate), "$.distribution.api.dateEnd", DATE(NOW()));
				END;
				WHEN 5 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.api.dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 DAY)), "$.distribution.api.dateEnd", DATE(SUBDATE(NOW(), INTERVAL 1 DAY)));
				WHEN 6 THEN BEGIN
				END;
				ELSE SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.api.dateStart", DATE(NOW()), "$.distribution.api.dateEnd", DATE(NOW()));
			END CASE;
		END;
	END IF;
END