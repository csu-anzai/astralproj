BEGIN
	DECLARE cityID, bankID INT(11);
	DECLARE done TINYINT(1);
	DECLARE cityName VARCHAR(60);
	DECLARE bankName VARCHAR(128);
	DECLARE responce, cityBanks, city JSON;
	DECLARE citiesCursor CURSOR FOR SELECT city_id, city_name FROM cities;
	DECLARE banksCursor CURSOR FOR SELECT DISTINCT bc.bank_id, b.bank_name FROM bank_cities bc JOIN banks b ON b.bank_id = bc.bank_id WHERE bc.city_id = @cityID;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
	SET responce = JSON_ARRAY();
	OPEN citiesCursor;
		citiesLoop: LOOP
			SET done = 0;	
			FETCH citiesCursor INTO cityID, cityName;
			IF done
				THEN LEAVE citiesLoop;
			END IF;
			SET @cityID = cityID;
			SET city = JSON_OBJECT(
				"city_id", cityID,
				"city_name", cityName
			);
			SET cityBanks = JSON_ARRAY();
			OPEN banksCursor;
				banksLoop: LOOP
					SET done = 0;
					FETCH banksCursor INTO bankID, bankName;
					IF done 
						THEN LEAVE banksLoop;
					END IF;
					SET cityBanks = JSON_MERGE(cityBanks, JSON_OBJECT(
						"bank_id", bankID,
						"bank_name", bankName
					));
					ITERATE banksLoop;
				END LOOP;
			CLOSE banksCursor;
			SET city = JSON_SET(city, "$.city_banks", cityBanks);
			SET responce = JSON_MERGE(responce, city);
			ITERATE citiesLoop;
		END LOOP;
	CLOSE citiesCursor;
	RETURN responce;
END