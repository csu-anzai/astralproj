BEGIN
	DECLARE responce JSON;
	DECLARE userID, bankID INT(11);
	DECLARE userOnline TINYINT(1);
	SET responce = JSON_ARRAY();
	IF connectionApiID IS NOT NULL
		THEN BEGIN 
			SELECT user_id INTO userID FROM users_connections_view WHERE connection_api_id = connectionApiID;
			UPDATE connections SET connection_end = 1 WHERE connection_api_id = connectionApiID;
		END;
	END IF;
	IF connectionHash IS NOT NULL
		THEN BEGIN 
			SELECT user_id INTO userID FROM users_connections_view WHERE connection_hash = connectionHash;
			UPDATE connections SET connection_end = 1 WHERE connection_hash = connectionHash;
		END;
	END IF;
  RETURN responce;
END