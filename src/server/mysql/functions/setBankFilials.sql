BEGIN
	DECLARE iterator, filialsLength, regionCode, regionID, cityID, bankFilialsCountBefore, bankFilialsCountAfter INT(11);
	DECLARE cityName, regionName VARCHAR(60);
	DECLARE bankFilialApiCode, bankFilialRegionApiCode, bankFilialCityApiCode VARCHAR(32);
	DECLARE bankFilialName VARCHAR(256);
	DECLARE bankName VARCHAR(128);
	DECLARE filial, responce JSON;
	SET responce = JSON_ARRAY();
	SET iterator = 0;
	SET filialsLength = JSON_LENGTH(filials);
	SELECT bank_name INTO bankName FROM banks WHERE bank_id = bankID;
	SELECT count(*) INTO bankFilialsCountBefore FROM bank_filials WHERE bank_id = bankID;
	IF deleteFilials 
		THEN DELETE FROM bank_filials WHERE bank_id = bankID;
	END IF;
	filialsLoop: LOOP
		IF iterator >= filialsLength
			THEN LEAVE filialsLoop;
		END IF;
		SET filial = JSON_UNQUOTE(JSON_EXTRACT(filials, CONCAT("$[", iterator, "]")));
		IF filial IS NOT NULL
			THEN BEGIN
				SET cityName = JSON_UNQUOTE(JSON_EXTRACT(filial, "$.city_name"));
				SET regionCode = JSON_UNQUOTE(JSON_EXTRACT(filial, "$.region_code"));
				SET regionName = JSON_UNQUOTE(JSON_EXTRACT(filial, "$.region_name"));
				SET bankFilialApiCode = JSON_UNQUOTE(JSON_EXTRACT(filial, "$.bank_filial_api_code"));
				SET bankFilialName = JSON_UNQUOTE(JSON_EXTRACT(filial, "$.bank_filial_name"));
				SET bankFilialRegionApiCode = JSON_UNQUOTE(JSON_EXTRACT(filial, "$.bank_filial_region_api_code"));
				SET bankFilialCityApiCode = JSON_UNQUOTE(JSON_EXTRACT(filial, "$.bank_filial_city_api_code"));
				IF regionCode IS NOT NULL
					THEN SELECT region_id INTO regionID FROM codes WHERE code_value = regionCode;
					ELSE IF regionName IS NOT NULL
						THEN SELECT region_id INTO regionID FROM regions WHERE LOWER(region_name) = LOWER(regionName);
					END IF;
				END IF;
				IF cityName IS NOT NULL
					THEN SELECT city_id INTO cityID FROM cities WHERE LOWER(city_name) = LOWER(cityName);
				END IF;
				IF bankFilialName IS NULL AND cityName IS NOT NULL
					THEN SET bankFilialName = cityName;
				END IF;
				IF bankFilialName IS NOT NULL AND cityID IS NOT NULL AND bankFilialApiCode IS NOT NULL AND bankID IS NOT NULL
					THEN INSERT INTO bank_filials (bank_id, city_id, region_id, bank_filial_name, bank_filial_api_code, bank_filial_region_api_code, bank_filial_city_api_code) VALUES (bankID, cityID, regionID, bankFilialName, bankFilialApiCode, bankFilialRegionApiCode, bankFilialCityApiCode);
				END IF;
			END;
		END IF;
		SET iterator = iterator + 1;
		ITERATE filialsLoop; 
	END LOOP;
	SELECT count(*) INTO bankFilialsCountAfter FROM bank_filials WHERE bank_id = bankID;
	SET responce = JSON_MERGE(responce, JSON_OBJECT(
		"type", "print",
		"data", JSON_OBJECT(
			"message", CONCAT("Обновление филиалов банка ", bankName, ". Было филиалов ", bankFilialsCountBefore, ". Стало ", bankFilialsCountAfter, ".")
		)
	));
	RETURN responce;
END;