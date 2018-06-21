BEGIN
	DECLARE callInternalTypeID, callDestinationTypeID INT(11);
	DECLARE	callPredicted TINYINT(1);
	DECLARE fileName VARCHAR(128);
	IF NEW.call_id IS NOT NULL
		THEN BEGIN
			SELECT call_internal_type_id, call_destination_type_id, call_predicted INTO callInternalTypeID, callDestinationTypeID, callPredicted FROM calls WHERE call_id = NEW.call_id;
			SELECT IF(callPredicted = 1, destination_file_name, internal_file_name) INTO fileName FROM calls_file_view WHERE call_id = NEW.call_id;
		END;
	END IF;
	SET NEW.company_date_update = NOW();
	SET NEW.company_json = JSON_SET(NEW.company_json,
		"$.type_id", NEW.type_id,
		"$.company_date_update", NEW.company_date_update,
		"$.company_comment", NEW.company_comment,
		"$.company_date_call_back", NEW.company_date_call_back,
		"$.call_internal_type_id", callInternalTypeID,
		"$.call_destination_type_id", callDestinationTypeID,
		"$.file_name", fileName
	);
	IF NEW.type_id != OLD.type_id 
		THEN SET NEW.old_type_id = OLD.type_id;
	END IF;
END