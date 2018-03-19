BEGIN
  DECLARE symbol VARCHAR(1);
    DECLARE str VARCHAR(999) DEFAULT "";
    DECLARE iterator INT(11) DEFAULT 0;
    generation: LOOP
      SET symbol = LOWER(CONV(CEIL(RAND()*0xF),10,16)),
          iterator = iterator + 1;
        IF CEIL(RAND()*2) = 1 
          THEN SET symbol = UPPER(symbol);
        END IF;
        SET str = CONCAT(str, symbol);
        IF iterator < max
          THEN ITERATE generation;
          ELSE LEAVE generation;
        END IF;
    END LOOP;
    RETURN str;
END