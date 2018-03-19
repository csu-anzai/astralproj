BEGIN
	SET NEW.user_date_create = NOW();
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
END