SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
START TRANSACTION;
SET time_zone = "+00:00";

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;


CREATE TABLE `columns` (
  `column_id` int(11) NOT NULL,
  `column_price` int(11) NOT NULL DEFAULT '0',
  `column_name` varchar(128) COLLATE utf8_bin NOT NULL,
  `column_blocked` tinyint(1) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

CREATE TABLE `companies` (
  `company_id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `company_date_create` varchar(19) COLLATE utf8_bin NOT NULL,
  `type_id` int(11) DEFAULT '10',
  `company_date_update` varchar(19) COLLATE utf8_bin DEFAULT NULL,
  `company_discount` int(11) DEFAULT '0',
  `company_discount_percent` tinyint(1) NOT NULL DEFAULT '0',
  `company_ogrnip` varchar(15) COLLATE utf8_bin DEFAULT NULL,
  `company_ogrnip_date` varchar(10) COLLATE utf8_bin DEFAULT NULL,
  `company_person_name` varchar(128) COLLATE utf8_bin DEFAULT NULL,
  `company_person_surname` varchar(128) COLLATE utf8_bin DEFAULT NULL,
  `company_person_patronymic` varchar(128) COLLATE utf8_bin DEFAULT NULL,
  `company_person_birthday` varchar(10) COLLATE utf8_bin DEFAULT NULL,
  `company_person_birthplace` varchar(1024) COLLATE utf8_bin DEFAULT NULL,
  `company_inn` varchar(12) COLLATE utf8_bin DEFAULT NULL,
  `company_address` varchar(1024) COLLATE utf8_bin DEFAULT NULL,
  `company_doc_number` varchar(12) COLLATE utf8_bin DEFAULT NULL,
  `company_doc_date` varchar(10) COLLATE utf8_bin DEFAULT NULL,
  `company_organization_name` varchar(1024) COLLATE utf8_bin DEFAULT NULL,
  `company_organization_code` varchar(6) COLLATE utf8_bin DEFAULT NULL,
  `company_phone` varchar(20) COLLATE utf8_bin DEFAULT NULL,
  `company_email` varchar(1024) COLLATE utf8_bin DEFAULT NULL,
  `company_okved_code` varchar(8) COLLATE utf8_bin DEFAULT NULL,
  `company_okved_name` varchar(2048) COLLATE utf8_bin DEFAULT NULL,
  `purchase_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
DELIMITER $$
CREATE TRIGGER `companies_before_insert` BEFORE INSERT ON `companies` FOR EACH ROW BEGIN
	SET NEW.company_date_create = NOW();
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `companies_before_update` BEFORE UPDATE ON `companies` FOR EACH ROW BEGIN
	SET NEW.company_date_update = NOW();
END
$$
DELIMITER ;

CREATE TABLE `connections` (
  `connection_id` int(11) NOT NULL,
  `connection_hash` varchar(32) COLLATE utf8_bin NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `connection_date_create` varchar(19) COLLATE utf8_bin NOT NULL,
  `connection_date_update` varchar(19) COLLATE utf8_bin DEFAULT NULL,
  `connection_date_disconnect` varchar(19) COLLATE utf8_bin DEFAULT NULL,
  `type_id` int(11) DEFAULT NULL,
  `connection_api_id` varchar(128) COLLATE utf8_bin DEFAULT NULL,
  `connection_end` tinyint(1) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
DELIMITER $$
CREATE TRIGGER `connections_after_insert` AFTER INSERT ON `connections` FOR EACH ROW BEGIN
	IF NEW.user_id IS NOT NULL
    	THEN UPDATE users SET user_connections_count = (SELECT COUNT(*) FROM connections WHERE user_id = NEW.user_id AND connection_end = 0) WHERE user_id = NEW.user_id;
  END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `connections_after_update` AFTER UPDATE ON `connections` FOR EACH ROW BEGIN
	IF NEW.user_id IS NOT NULL
    	THEN UPDATE users SET user_connections_count = (SELECT COUNT(*) FROM connections WHERE user_id = NEW.user_id AND connection_end = 0) WHERE user_id = NEW.user_id;
  END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `connections_before_insert` BEFORE INSERT ON `connections` FOR EACH ROW BEGIN
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
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `connections_before_update` BEFORE UPDATE ON `connections` FOR EACH ROW BEGIN
	SET NEW.connection_date_update = NOW();
    IF NEW.connection_end
    	THEN SET NEW.connection_date_disconnect = NOW();
    END IF;
END
$$
DELIMITER ;

CREATE TABLE `files` (
  `file_id` int(11) NOT NULL,
  `file_name` int(11) NOT NULL,
  `type_id` int(11) DEFAULT NULL,
  `file_date_create` varchar(19) COLLATE utf8_bin NOT NULL,
  `purchase_id` int(11) DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
DELIMITER $$
CREATE TRIGGER `files_before_insert` BEFORE INSERT ON `files` FOR EACH ROW BEGIN
	SET NEW.file_date_create = NOW();
END
$$
DELIMITER ;

CREATE TABLE `purchases` (
  `purchase_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `purchase_date_create` varchar(19) COLLATE utf8_bin NOT NULL,
  `purchase_date_update` varchar(19) COLLATE utf8_bin DEFAULT NULL,
  `purchase_date_buy` varchar(19) COLLATE utf8_bin DEFAULT NULL,
  `purchase_price` int(11) NOT NULL,
  `purchase_filter_date_start` varchar(19) COLLATE utf8_bin NOT NULL,
  `purchase_filter_date_end` varchar(19) COLLATE utf8_bin NOT NULL,
  `purchase_filter_items_count` int(11) NOT NULL,
  `purchase_filter_ogrnip` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_ogrnip_null` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_ogrnip_date` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_ogrnip_date_null` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_discount` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_person_name` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_person_name_null` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_person_surname` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_person_surname_null` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_person_patronymic` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_person_patronymic_null` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_person_birthday` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_person_birthday_null` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_person_birthplace` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_person_birthplace_null` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_inn` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_inn_null` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_address` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_address_null` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_doc_number` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_doc_number_null` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_doc_date` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_doc_date_null` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_organization_name` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_organization_name_null` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_organization_code` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_organization_code_null` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_phone` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_phone_null` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_email` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_email_null` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_okved_code` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_okved_code_null` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_okved_name` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_okved_name_null` tinyint(1) NOT NULL DEFAULT '0',
  `transaction_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
DELIMITER $$
CREATE TRIGGER `purchases_before_insert` BEFORE INSERT ON `purchases` FOR EACH ROW BEGIN
	SET NEW.purchase_date_create = NOW();
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `purchases_before_update` BEFORE UPDATE ON `purchases` FOR EACH ROW BEGIN
	SET NEW.purchase_date_update = NOW();
END
$$
DELIMITER ;

CREATE TABLE `transactions` (
  `transaction_id` int(11) NOT NULL,
  `type_id` int(11) DEFAULT NULL,
  `transaction_value` int(11) NOT NULL,
  `transaction_date_create` varchar(19) COLLATE utf8_bin NOT NULL,
  `transaction_date_update` varchar(19) COLLATE utf8_bin DEFAULT NULL,
  `transaction_date_end` varchar(19) COLLATE utf8_bin DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `transaction_end` tinyint(4) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
DELIMITER $$
CREATE TRIGGER `transactions_before_insert` BEFORE INSERT ON `transactions` FOR EACH ROW BEGIN
	SET NEW.transaction_date_create = NOW();
    IF NEW.transaction_end
    	THEN BEGIN 
        	SET NEW.transaction_date_end = NOW();
            UPDATE purchases SET purchase_date_buy = NOW() WHERE transaction_id = NEW.transaction_id;
        END;
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `transactions_before_update` BEFORE UPDATE ON `transactions` FOR EACH ROW BEGIN
	SET NEW.transaction_date_update = NOW();
    IF NEW.transaction_end
    	THEN BEGIN 
        	SET NEW.transaction_date_end = NOW();
            UPDATE purchases SET purchase_date_buy = NOW() WHERE transaction_id = NEW.transaction_id;
        END;
    END IF;
END
$$
DELIMITER ;

CREATE TABLE `types` (
  `type_id` int(11) NOT NULL,
  `type_name` varchar(128) COLLATE utf8_bin NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

INSERT INTO `types` (`type_id`, `type_name`) VALUES
(7, 'deposit'),
(10, 'free'),
(4, 'get'),
(5, 'post'),
(6, 'purchase'),
(9, 'reservation'),
(1, 'root'),
(8, 'sale'),
(2, 'user'),
(3, 'ws');

CREATE TABLE `users` (
  `user_id` int(11) NOT NULL,
  `user_name` varchar(64) COLLATE utf8_bin NOT NULL,
  `user_email` varchar(512) COLLATE utf8_bin NOT NULL,
  `user_password` varchar(128) COLLATE utf8_bin NOT NULL,
  `user_date_create` varchar(19) COLLATE utf8_bin NOT NULL,
  `user_date_update` varchar(19) COLLATE utf8_bin DEFAULT NULL,
  `user_creator_id` int(11) DEFAULT NULL,
  `type_id` int(11) DEFAULT NULL,
  `user_auth` tinyint(1) NOT NULL DEFAULT '0',
  `user_online` tinyint(1) NOT NULL DEFAULT '0',
  `user_hash` varchar(32) COLLATE utf8_bin DEFAULT NULL,
  `user_connections_count` int(11) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
DELIMITER $$
CREATE TRIGGER `users_before_insert` BEFORE INSERT ON `users` FOR EACH ROW BEGIN
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
	IF NEW.user_connections_count > 0
		THEN SET NEW.user_online = 1;
		ELSE SET NEW.user_online = 0;
	END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `users_before_update` BEFORE UPDATE ON `users` FOR EACH ROW BEGIN
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
$$
DELIMITER ;


ALTER TABLE `columns`
  ADD UNIQUE KEY `column_name` (`column_name`);

ALTER TABLE `companies`
  ADD PRIMARY KEY (`company_id`),
  ADD UNIQUE KEY `company_ogrnip` (`company_ogrnip`),
  ADD UNIQUE KEY `company_inn` (`company_inn`),
  ADD UNIQUE KEY `company_doc_number` (`company_doc_number`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `type_id` (`type_id`),
  ADD KEY `purchase_id` (`purchase_id`);

ALTER TABLE `connections`
  ADD PRIMARY KEY (`connection_id`),
  ADD UNIQUE KEY `connection_hash` (`connection_hash`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `type_id` (`type_id`);

ALTER TABLE `files`
  ADD PRIMARY KEY (`file_id`),
  ADD UNIQUE KEY `file_name` (`file_name`),
  ADD KEY `type_id` (`type_id`),
  ADD KEY `purchase_id` (`purchase_id`),
  ADD KEY `user_id` (`user_id`);

ALTER TABLE `purchases`
  ADD PRIMARY KEY (`purchase_id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `transaction_id` (`transaction_id`);

ALTER TABLE `transactions`
  ADD PRIMARY KEY (`transaction_id`),
  ADD KEY `type_id` (`type_id`),
  ADD KEY `user_id` (`user_id`);

ALTER TABLE `types`
  ADD PRIMARY KEY (`type_id`),
  ADD UNIQUE KEY `type_name` (`type_name`);

ALTER TABLE `users`
  ADD PRIMARY KEY (`user_id`),
  ADD UNIQUE KEY `user_email` (`user_email`),
  ADD UNIQUE KEY `user_hash` (`user_hash`),
  ADD KEY `user_creator_id` (`user_creator_id`),
  ADD KEY `type_id` (`type_id`);


ALTER TABLE `companies`
  MODIFY `company_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `connections`
  MODIFY `connection_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `files`
  MODIFY `file_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `purchases`
  MODIFY `purchase_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `transactions`
  MODIFY `transaction_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `types`
  MODIFY `type_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `users`
  MODIFY `user_id` int(11) NOT NULL AUTO_INCREMENT;


ALTER TABLE `companies`
  ADD CONSTRAINT `companies_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `companies_ibfk_2` FOREIGN KEY (`type_id`) REFERENCES `types` (`type_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `companies_ibfk_3` FOREIGN KEY (`purchase_id`) REFERENCES `purchases` (`purchase_id`) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `connections`
  ADD CONSTRAINT `connections_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `connections_ibfk_2` FOREIGN KEY (`type_id`) REFERENCES `types` (`type_id`) ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE `files`
  ADD CONSTRAINT `files_ibfk_1` FOREIGN KEY (`type_id`) REFERENCES `types` (`type_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `files_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `files_ibfk_3` FOREIGN KEY (`purchase_id`) REFERENCES `purchases` (`purchase_id`) ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE `purchases`
  ADD CONSTRAINT `purchases_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `purchases_ibfk_2` FOREIGN KEY (`transaction_id`) REFERENCES `transactions` (`transaction_id`) ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE `transactions`
  ADD CONSTRAINT `transactions_ibfk_1` FOREIGN KEY (`type_id`) REFERENCES `types` (`type_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `transactions_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE `users`
  ADD CONSTRAINT `users_ibfk_1` FOREIGN KEY (`user_creator_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `users_ibfk_2` FOREIGN KEY (`type_id`) REFERENCES `types` (`type_id`) ON DELETE SET NULL ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
