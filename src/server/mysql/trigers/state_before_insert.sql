BEGIN
	DECLARE typeID INT(11);
	SET NEW.state_date_create = NOW();
	SELECT type_id INTO typeID FROM users WHERE user_id = NEW.user_id;
	IF typeID = 1 OR typeID = 19 OR typeID = 18
		THEN BEGIN
			SET NEW.state_json = JSON_OBJECT(); 
			IF typeID = 1 OR typeID = 19
				THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic", 
					JSON_OBJECT(
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
			END IF;
			IF typeID = 1
				THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download", JSON_OBJECT(
					"dateStart", DATE(NOW()),
					"dateEnd", DATE(NOW()),
					"type", 10,
					"types", JSON_ARRAY(
						10
					),
					"regions", JSON_ARRAY(),
					"banks", JSON_ARRAY(NULL),
					"nullColumns", JSON_ARRAY(),
					"notNullColumns", JSON_ARRAY(),
					"limit", 50,
					"offset", 0,
					"orders", JSON_ARRAY(
						JSON_OBJECT(
							"name", "company_date_create",
							"desc", 1
						)
					),
					"count", 100
				));
			END IF;
			IF typeID = 1 OR typeID = 18
				THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution", 
					JSON_OBJECT(
						"invalidate", JSON_OBJECT(
							"dateStart", DATE(NOW()),
							"dateEnd", DATE(NOW()),
							"type", 0
						),
						"callBack", JSON_OBJECT(
							"dateStart", DATE(NOW()),
							"dateEnd", DATE(NOW()),
							"type", 0
						),
						"api", JSON_OBJECT(
							"dateStart", DATE(NOW()),
							"dateEnd", DATE(NOW()),
							"type", 0
						)
					)
				);
			END IF;
		END;
	END IF;
END