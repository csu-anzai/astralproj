BEGIN
	SET NEW.user_date_update = NOW();
	IF NEW.user_auth = 1 AND OLD.user_auth = 0
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
	IF (NEW.user_auth = 0 AND OLD.user_auth = 1) OR (NEW.user_online = 0 AND OLD.user_online = 1)
		THEN UPDATE companies SET user_id = NULL, type_id = 10 WHERE user_id = NEW.user_id AND type_id = 9;
	END IF;
END