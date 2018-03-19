BEGIN
	SET NEW.transaction_date_update = NOW();
    IF NEW.transaction_end
    	THEN BEGIN 
        	SET NEW.transaction_date_end = NOW();
            UPDATE purchases SET purchase_date_buy = NOW() WHERE transaction_id = NEW.transaction_id;
        END;
    END IF;
END