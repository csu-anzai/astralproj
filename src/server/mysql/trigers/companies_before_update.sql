BEGIN
	DECLARE callType INT(11);
	DECLARE fileName, callApiIDInternal, callApiIDDestination VARCHAR(128);
	IF NEW.call_id IS NOT NULL
		THEN BEGIN
			SELECT type_id, callApiIDInternal, callApiIDDestination INTO callType, callApiIDInternal, callApiIDDestination FROM calls WHERE call_id = NEW.call_id;
			SELECT file_name INTO fileName FROM calls_file_view WHERE call_id = NEW.call_id;
		END;
	END IF;
	IF (callApiIDInternal IS NULL OR callApiIDDestination IS NULL) AND callType IN (40, 41, 42)
		THEN SET NEW.type_id = IF(
			NEW.type_id IN (9, 35),
			IF(
				NEW.type_id = 35,
				36,
				35
			),
			OLD.type_id
		);
	END IF;
	SET NEW.company_date_update = NOW();
	SET NEW.company_json = JSON_SET(NEW.company_json,
		"$.type_id", NEW.type_id,
		"$.company_date_update", NEW.company_date_update,
		"$.company_comment", NEW.company_comment,
		"$.company_date_call_back", NEW.company_date_call_back,
		"$.call_type", callType,
		"$.file_name", fileName
	);
	IF NEW.type_id != OLD.type_id 
		THEN SET NEW.old_type_id = OLD.type_id;
	END IF;
END