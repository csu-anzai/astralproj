BEGIN
	DECLARE typeID INT(11);
	SET NEW.state_date_create = NOW();
	SELECT type_id INTO typeID FROM users WHERE user_id = NEW.user_id;
	IF typeID = 1 OR typeID = 19
		THEN BEGIN 
			SET NEW.state_json = JSON_OBJECT(
				"statistic", JSON_OBJECT(
					"dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 WEEK)),
					"dateEnd", DATE(NOW()),
					"typeToView", 3,
					"period", 0,
					"types", JSON_ARRAY(
						16
					),
					"user", 0,
					"dataDateStart", DATE(SUBDATE(NOW(), INTERVAL 1 WEEK)),
					"dataDateEnd", DATE(NOW()),
					"dataPeriod", 0,
					"dataBank", 1,
					"dataFree", 1
				)
			);
			IF typeID = 1
				THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download", JSON_OBJECT(
					"dateStart", DATE(NOW()),
					"dateEnd", DATE(NOW()),
					"type", 0,
					"types", JSON_ARRAY(
						10
					),
					"regions", JSON_ARRAY(),
					"nullColumns", JSON_ARRAY(),
					"notNullColumns", JSON_ARRAY()
				));
			END IF;
		END;
		ELSE SET NEW.state_json = JSON_OBJECT();
	END IF;
END