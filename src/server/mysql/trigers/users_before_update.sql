BEGIN
	SET NEW.user_date_update = NOW();
	IF NEW.user_auth
		THEN BEGIN
			hashLoop: LOOP
		  	SET NEW.user_hash = getHash(32);
		      IF (SELECT COUNT(*) FROM users WHERE user_hash = NEW.user_hash) > 0
		      	THEN ITERATE hashLoop;
		          ELSE LEAVE hashLoop;
		      END IF;
		  END LOOP;
		END;
	END IF;
	IF NEW.user_connections_count > 0
		THEN SET NEW.user_online = 1;
		ELSE SET NEW.user_online = 0;
	END IF;
END