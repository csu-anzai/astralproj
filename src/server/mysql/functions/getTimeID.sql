BEGIN
	DECLARE timeID INT(11); 
	SELECT time_id INTO timeID FROM bank_times_view WHERE TIME(time_value) = TIME(now()) AND bank_id = bankID ORDER BY TIME(time_value) LIMIT 1;
	IF timeID IS NULL
		THEN SELECT time_id INTO timeID FROM bank_times_view WHERE TIME(time_value) < TIME(NOW()) AND bank_id = bankID ORDER BY TIME(time_value) DESC LIMIT 1;
	END IF;
	IF timeID IS NULL
		THEN SELECT time_id INTO timeID FROM bank_times_view WHERE TIME(time_value) > TIME(NOW()) AND bank_id = bankID ORDER BY TIME(time_value) DESC LIMIT 1;
	END IF;
	RETURN timeID;
END