BEGIN
	SET NEW.connection_date_create = NOW();
    IF NEW.connection_end 
    	THEN SET NEW.connection_date_disconnect = NOW();
    END IF;
    hashLoop: LOOP
    	SET NEW.connection_hash = getHash(32);
    	IF (SELECT COUNT(*) FROM connections WHERE connection_hash = NEW.connection_hash) > 0
        	THEN ITERATE hashLoop;
            ELSE LEAVE hashLoop;
        END IF;
   	END LOOP;
END