BEGIN
	DECLARE typeID INT(11);
	SET NEW.state_date_create = NOW();
	SELECT type_id INTO typeID FROM users WHERE user_id = NEW.user_id;
	IF typeID = 1 OR typeID = 19
		THEN BEGIN 
			SET NEW.state_json = JSON_OBJECT(
				"statistic", JSON_OBJECT(
					"startDate", DATE(SUBDATE(NOW(), INTERVAL 1 WEEK)),
					"endDate", DATE(NOW()),
					"typeToView", 3,
					"period", 0,
					"types", JSON_ARRAY(
						16
					)
				)
			);
		END;
		ELSE SET NEW.state_json = JSON_OBJECT();
	END IF;
END