BEGIN
	DECLARE callID, userID INT(11);
	DECLARE responce JSON;
	SET responce = JSON_ARRAY();
	SELECT call_id, user_id INTO callID, userID FROM end_calls_view WHERE company_phone = companyPhone AND user_sip = userSip ORDER BY call_id DESC LIMIT 1;
	IF callID IS NOT NULL
		THEN BEGIN
			INSERT INTO files (file_name, type_id, user_id) VALUES (fileName, 45, userID);
			SET responce = JSON_MERGE(responce, JSON_OBJECT(
				"type", "moveFile",
				"data", JSON_OBJECT(
					"fileName", fileName,
					"from", "attachments",
					"to", "files"
				)
			));
		END;
	END IF;
	RETURN responce;
END
