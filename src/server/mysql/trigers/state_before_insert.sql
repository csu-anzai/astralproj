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
						"period", 0,
						"types", JSON_ARRAY(),
						"users", JSON_ARRAY(),
						"dataDateStart", DATE(NOW()),
						"dataDateEnd", DATE(NOW()),
						"dataPeriod", 5,
						"dataBanks", JSON_EXTRACT(getBanks(), "$[*].id"),
						"dataFree", 1,
						"workingCompaniesLimit", 10,
						"workingCompaniesOffset", 0
					)
				);
			END IF;
			IF typeID = 1
				THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download", JSON_OBJECT(
					"dateStart", DATE(NOW()),
					"dateEnd", DATE(NOW()),
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
						"work", JSON_OBJECT(
							"rowStart", 1,
							"rowLimit", 10
						),
						"invalidate", JSON_OBJECT(
							"dateStart", DATE(NOW()),
							"dateEnd", DATE(NOW()),
							"type", 0,
							"rowStart", 1,
							"rowLimit", 10
						),
						"callBack", JSON_OBJECT(
							"dateStart", DATE(NOW()),
							"dateEnd", DATE(NOW()),
							"type", 0,
							"rowStart", 1,
							"rowLimit", 10
						),
						"api", JSON_OBJECT(
							"dateStart", DATE(NOW()),
							"dateEnd", DATE(NOW()),
							"type", 0,
							"rowStart", 1,
							"rowLimit", 10
						),
						"notDial", JSON_OBJECT(
							"dateStart", DATE(NOW()),
							"dateEnd", DATE(NOW()),
							"type", 0,
							"rowStart", 1,
							"rowLimit", 10
						),
						"difficult", JSON_OBJECT(
							"dateStart", DATE(NOW()),
							"dateEnd", DATE(NOW()),
							"type", 0,
							"rowStart", 1,
							"rowLimit", 10
						),
						"duplicates", JSON_OBJECT(
							"dateStart", DATE(NOW()),
							"dateEnd", DATE(NOW()),
							"type", 0,
							"rowStart", 1,
							"rowLimit", 10
						)
					)
				);
			END IF;
		END;
	END IF;
END