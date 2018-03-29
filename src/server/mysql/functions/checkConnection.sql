BEGIN
	DECLARE userID, userAuth INT(11);
	DECLARE connectionEnd, responce TINYINT(1);
	SELECT user_id, user_auth, connection_end INTO userID, userAuth, connectionEnd FROM users_connections_view WHERE connection_hash = connectionHash;
	IF userID IS NOT NULL AND userAuth = 1 AND connectionEnd = 0
		THEN SET responce = 1;
		ELSE SET responce = 0;
	END IF;
	RETURN responce;
END