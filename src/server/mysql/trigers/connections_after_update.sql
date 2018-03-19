BEGIN
	IF NEW.user_id IS NOT NULL
    	THEN UPDATE users SET user_connections_count = (SELECT COUNT(*) FROM connections WHERE user_id = NEW.user_id AND connection_end = 0) WHERE user_id = NEW.user_id;
  END IF;
END