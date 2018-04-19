BEGIN
	DECLARE userID, userAuth, typeID INT(11);
	DECLARE connectionEnd, responce TINYINT(1);
	SELECT user_id, user_auth, connection_end INTO userID, userAuth, connectionEnd FROM users_connections_view WHERE connection_hash = connectionHash;
	SELECT type_id INTO typeID FROM users WHERE user_id = userID;
	IF userID IS NOT NULL AND userAuth = 1 AND connectionEnd = 0 AND typeID = 1
		THEN SET responce = 1;
		ELSE SET responce = 0;
	END IF;
	RETURN responce;
END