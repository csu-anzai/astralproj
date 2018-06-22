BEGIN
	DECLARE callID, userID, fileID INT(11);
	DECLARE responce JSON;
	SET responce = JSON_ARRAY();
	SELECT call_id, user_id INTO callID, userID FROM end_calls_view WHERE company_phone = IF(companyPhone IS NOT NULL, companyPhone, company_phone) AND user_sip = userSip ORDER BY call_id DESC LIMIT 1;
	IF callID IS NOT NULL
		THEN BEGIN
			INSERT INTO files (file_name, type_id, user_id) VALUES (filePath, 45, userID);
			SELECT file_id INTO fileID FROM files ORDER BY file_id DESC LIMIT 1;
			UPDATE calls SET 
				call_destination_file_id = IF(internal = 0, fileID, call_destination_file_id),
				call_internal_file_id = IF(internal = 1, fileID, call_internal_file_id)
			WHERE call_id = callID;
			SET responce = JSON_MERGE(responce, JSON_OBJECT(
				"type", "moveFile",
				"data", JSON_OBJECT(
					"fileName", fileName,
					"from", "attachments",
					"to", "files"
				)
			));
			SET responce = JSON_MERGE(responce, refreshUserCompanies(userID));
		END;
	END IF;
	RETURN responce;
END
