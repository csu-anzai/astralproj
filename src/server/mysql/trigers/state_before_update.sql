BEGIN
	DECLARE typeToView, period, type, bankID INT(11);
	DECLARE firstDate VARCHAR(19);
	DECLARE dataFree, dataBank, done TINYINT(11);
	DECLARE types, bank, banks, status, statuses JSON;
	DECLARE banksCursor CURSOR FOR SELECT bank_json, bank_id FROM banks_statistic_view WHERE JSON_CONTAINS(@banks, JSON_ARRAY(CONCAT(bank_id)));
	DECLARE banksStatusesCursor CURSOR FOR SELECT status_json FROM bank_status_translate WHERE bank_id = @bankID;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1; 
	SET NEW.state_date_update = NOW();
	IF JSON_EXTRACT(NEW.state_json, "$.statistic") IS NOT NULL
		THEN BEGIN
			SET @banks = jsonMap(JSON_EXTRACT(NEW.state_json, "$.statistic.banks"), JSON_ARRAY("bank_id"));
			SET banks = JSON_ARRAY();
			OPEN banksCursor;
				banksLoop: LOOP
					FETCH banksCursor INTO bank, bankID;
					IF done 
						THEN LEAVE banksLoop;
					END IF;
					SET statuses = JSON_ARRAY();
					SET @bankID = bankID;
					OPEN banksStatusesCursor;
						banksStatusesLoop: LOOP
							FETCH banksStatusesCursor INTO status;
							IF done 
								THEN LEAVE banksStatusesLoop;
							END IF;
							SET statuses = JSON_MERGE(statuses, status);
							ITERATE banksStatusesLoop;
						END LOOP;
					CLOSE banksStatusesCursor;
					SET bank = JSON_SET(bank, "$.bank_statuses", statuses);
					SET banks = JSON_MERGE(banks, bank);
					SET done = 0;
					ITERATE banksLoop;
				END LOOP;
			CLOSE banksCursor;
			SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.banks", banks);
			SET period = JSON_EXTRACT(NEW.state_json, "$.statistic.period");
			SET types = JSON_UNQUOTE(JSON_EXTRACT(NEW.state_json, "$.statistic.types"));
			IF !JSON_CONTAINS(types, JSON_ARRAY(13))
				THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.banks", JSON_ARRAY(), "$.statistic.bankStatuses", JSON_ARRAY());
			END IF;
			CASE period
				WHEN 0 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 WEEK)), "$.statistic.dateEnd", DATE(NOW()));
				WHEN 1 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 MONTH)), "$.statistic.dateEnd", DATE(NOW()));
				WHEN 2 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 YEAR)), "$.statistic.dateEnd", DATE(NOW()));
				WHEN 3 THEN BEGIN 
					SELECT company_date_update INTO firstDate FROM companies WHERE JSON_CONTAINS(types, JSON_ARRAY(type_id)) ORDER BY company_date_update LIMIT 1;
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
					SELECT company_date_create INTO firstDate FROM companies WHERE IF(dataFree, type_id = 10, 1) AND IF(dataBank, JSON_LENGTH(JSON_KEYS(company_json ->> "$.company_banks")) > 0, 1) ORDER BY company_date_create LIMIT 1;
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
				WHEN 0 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(9, 13, 14, 15, 16, 17, 10, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 35, 36, 37));
				WHEN 1 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(17, 24, 31, 32));
				WHEN 2 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(15));
				WHEN 3 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(16, 25, 26, 27, 28, 29, 30));
				WHEN 4 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(13));
				WHEN 5 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(14));
				WHEN 6 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(9));
				WHEN 7 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(15, 16, 17, 24, 25, 26, 27, 28, 29, 30, 31, 32));
				WHEN 8 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(13, 14, 23, 35, 36, 37));
				WHEN 9 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(13, 14, 15, 16, 17, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 35, 36, 37));
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
				WHEN 23 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(35));
				WHEN 24 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(36));
				WHEN 25 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(37));
				ELSE SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(9, 13, 14, 15, 16, 17, 10, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 35, 36, 37));
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
					SELECT company_date_create INTO firstDate FROM companies WHERE type_id = 14 ORDER BY company_date_create LIMIT 1;
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
					SELECT company_date_create INTO firstDate FROM companies WHERE type_id = 23 ORDER BY company_date_create LIMIT 1;
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
					SELECT company_date_create INTO firstDate FROM companies WHERE type_id IN (15, 16, 17) ORDER BY company_date_create LIMIT 1;
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
			SET type = JSON_EXTRACT(NEW.state_json, "$.distribution.notDial.type");
			CASE type
				WHEN 0 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.notDial.dateStart", DATE(NOW()), "$.distribution.notDial.dateEnd", DATE(NOW()));
				WHEN 1 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.notDial.dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 WEEK)), "$.distribution.notDial.dateEnd", DATE(NOW()));
				WHEN 2 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.notDial.dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 MONTH)), "$.distribution.notDial.dateEnd", DATE(NOW()));
				WHEN 3 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.notDial.dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 YEAR)), "$.distribution.notDial.dateEnd", DATE(NOW()));
				WHEN 4 THEN BEGIN 
					SELECT company_date_create INTO firstDate FROM companies WHERE type_id = 36 ORDER BY company_date_create LIMIT 1;
					IF firstDate IS NULL
						THEN SET firstDate = DATE(NOW());
					END IF;
					SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.notDial.dateStart", DATE(firstDate), "$.distribution.notDial.dateEnd", DATE(NOW()));
				END;
				WHEN 5 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.notDial.dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 DAY)), "$.distribution.notDial.dateEnd", DATE(SUBDATE(NOW(), INTERVAL 1 DAY)));
				WHEN 6 THEN BEGIN
				END;
				ELSE SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.notDial.dateStart", DATE(NOW()), "$.distribution.notDial.dateEnd", DATE(NOW()));
			END CASE;
			SET type = JSON_EXTRACT(NEW.state_json, "$.distribution.difficult.type");
			CASE type
				WHEN 0 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.difficult.dateStart", DATE(NOW()), "$.distribution.difficult.dateEnd", DATE(NOW()));
				WHEN 1 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.difficult.dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 WEEK)), "$.distribution.difficult.dateEnd", DATE(NOW()));
				WHEN 2 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.difficult.dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 MONTH)), "$.distribution.difficult.dateEnd", DATE(NOW()));
				WHEN 3 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.difficult.dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 YEAR)), "$.distribution.difficult.dateEnd", DATE(NOW()));
				WHEN 4 THEN BEGIN 
					SELECT company_date_create INTO firstDate FROM companies WHERE type_id = 37 ORDER BY company_date_create LIMIT 1;
					IF firstDate IS NULL
						THEN SET firstDate = DATE(NOW());
					END IF;
					SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.difficult.dateStart", DATE(firstDate), "$.distribution.difficult.dateEnd", DATE(NOW()));
				END;
				WHEN 5 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.difficult.dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 DAY)), "$.distribution.difficult.dateEnd", DATE(SUBDATE(NOW(), INTERVAL 1 DAY)));
				WHEN 6 THEN BEGIN
				END;
				ELSE SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.difficult.dateStart", DATE(NOW()), "$.distribution.difficult.dateEnd", DATE(NOW()));
			END CASE;
		END;
	END IF;
END