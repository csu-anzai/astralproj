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
  `company_ogrn` varchar(15) COLLATE utf8_bin DEFAULT NULL,
  `company_ogrn_date` varchar(10) COLLATE utf8_bin DEFAULT NULL,
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
  `purchase_id` int(11) DEFAULT NULL,
  `template_id` int(11) DEFAULT NULL,
  `company_kpp` varchar(9) COLLATE utf8_bin DEFAULT NULL,
  `company_index` varchar(9) COLLATE utf8_bin DEFAULT NULL,
  `company_house` varchar(20) COLLATE utf8_bin DEFAULT NULL,
  `company_region_type` varchar(50) COLLATE utf8_bin DEFAULT NULL,
  `company_region_name` varchar(120) COLLATE utf8_bin DEFAULT NULL,
  `company_area_type` varchar(60) COLLATE utf8_bin DEFAULT NULL,
  `company_area_name` varchar(60) COLLATE utf8_bin DEFAULT NULL,
  `company_locality_type` varchar(60) COLLATE utf8_bin DEFAULT NULL,
  `company_locality_name` varchar(60) COLLATE utf8_bin DEFAULT NULL,
  `company_street_type` varchar(60) COLLATE utf8_bin DEFAULT NULL,
  `company_street_name` varchar(60) COLLATE utf8_bin DEFAULT NULL,
  `company_innfl` varchar(12) COLLATE utf8_bin DEFAULT NULL,
  `company_person_position_type` varchar(60) COLLATE utf8_bin DEFAULT NULL,
  `company_person_position_name` varchar(60) COLLATE utf8_bin DEFAULT NULL,
  `company_doc_name` varchar(120) COLLATE utf8_bin DEFAULT NULL,
  `company_doc_gitfter` varchar(256) COLLATE utf8_bin DEFAULT NULL,
  `company_doc_code` varchar(7) COLLATE utf8_bin DEFAULT NULL,
  `company_doc_house` varchar(20) COLLATE utf8_bin DEFAULT NULL,
  `company_doc_flat` varchar(40) COLLATE utf8_bin DEFAULT NULL,
  `company_doc_region_type` varchar(50) COLLATE utf8_bin DEFAULT NULL,
  `company_doc_region_name` varchar(120) COLLATE utf8_bin DEFAULT NULL,
  `company_doc_area_type` varchar(60) COLLATE utf8_bin DEFAULT NULL,
  `company_doc_area_name` varchar(60) COLLATE utf8_bin DEFAULT NULL,
  `company_doc_locality_type` varchar(60) COLLATE utf8_bin DEFAULT NULL,
  `company_doc_locality_name` varchar(60) COLLATE utf8_bin DEFAULT NULL,
  `company_doc_street_type` varchar(60) COLLATE utf8_bin DEFAULT NULL,
  `company_doc_street_name` varchar(60) COLLATE utf8_bin DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
DELIMITER $$
CREATE TRIGGER `companies_before_insert` BEFORE INSERT ON `companies` FOR EACH ROW BEGIN
  DECLARE innLength INT(11);
  SET NEW.company_date_create = NOW();
  SET innLength = CHAR_LENGTH(NEW.company_inn);
  IF innLength = 9 OR innLength = 11
    THEN SET NEW.company_inn = CONCAT("0", NEW.company_inn);
  END IF;
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

CREATE TABLE `templates` (
  `template_id` int(11) NOT NULL,
  `type_id` int(11) DEFAULT NULL,
  `template_columns_count` int(11) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

INSERT INTO `templates` (`template_id`, `type_id`, `template_columns_count`) VALUES
(1, 11, 0),
(2, 12, 0);

CREATE TABLE `template_columns` (
  `template_column_id` int(11) NOT NULL,
  `template_id` int(11) NOT NULL,
  `template_column_letters` varchar(3) COLLATE utf8_bin NOT NULL,
  `template_column_name` varchar(128) COLLATE utf8_bin NOT NULL,
  `column_id` int(11) DEFAULT NULL,
  `template_column_duplicate` tinyint(1) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

INSERT INTO `template_columns` (`template_column_id`, `template_id`, `template_column_letters`, `template_column_name`, `column_id`, `template_column_duplicate`) VALUES
(1, 1, 'a', 'OGRNIP', 1, 0),
(2, 1, 'b', 'DtOGRNIP', 2, 0),
(3, 1, 'c', 'FamFL', 4, 0),
(4, 1, 'd', 'NameFL', 3, 0),
(5, 1, 'e', 'OtchFL', 5, 0),
(6, 1, 'f', 'Birthday', 6, 0),
(7, 1, 'g', 'Birthplace', 7, 0),
(8, 1, 'h', 'INN', 8, 0),
(9, 1, 'i', 'AdresText', 9, 0),
(10, 1, 'j', 'NumDok36', 10, 0),
(11, 1, 'k', 'DtDok37', 11, 0),
(12, 1, 'l', 'NameOrg', 12, 0),
(13, 1, 'm', 'KodOrg', 13, 0),
(14, 1, 'n', 'Telefon', 14, 0),
(15, 1, 'o', 'EMail', 15, 0),
(16, 1, 'p', 'КодОКВЭД', 16, 0),
(17, 1, 'q', 'НаимОКВЭД', 17, 0),
(18, 2, 'a', 'ОГРН', 1, 0),
(19, 2, 'b', 'ИНН', 8, 0),
(22, 2, 'c', 'КПП', 18, 0),
(23, 2, 'd', 'НаимЮЛПолн', 12, 0),
(24, 2, 'e', 'Индекс', 19, 0),
(25, 2, 'f', 'Дом', 20, 0),
(26, 2, 'g', 'ТипРегион', 21, 0),
(27, 2, 'h', 'НаимРегион', 22, 0),
(28, 2, 'i', 'ТипРайон', 23, 0),
(29, 2, 'j', 'НаимРайон', 24, 0),
(30, 2, 'k', 'ТипНаселПункт', 25, 0),
(31, 2, 'l', 'НаимНаселПункт', 26, 0),
(32, 2, 'm', 'ТипУлица', 27, 0),
(33, 2, 'n', 'НаимУлица', 28, 0),
(34, 2, 'o', 'Фамилия', 4, 0),
(35, 2, 'p', 'Имя', 3, 0),
(36, 2, 'q', 'Отчество', 5, 0),
(37, 2, 'r', 'ИННФЛ', 29, 0),
(38, 2, 's', 'НаимВидДолжн', 30, 0),
(39, 2, 't', 'НаимДолжн', 31, 0),
(40, 2, 'u', 'НомТел', 14, 0),
(41, 2, 'v', 'ДатаРожд', 6, 0),
(42, 2, 'w', 'МестоРожд', 7, 0),
(43, 2, 'x', 'НаимДок', 32, 0),
(44, 2, 'y', 'СерНомДок', 10, 0),
(45, 2, 'z', 'ДатаДок', 11, 0),
(46, 2, 'aa', 'ВыдДок', 33, 0),
(47, 2, 'ab', 'КодВыдДок', 34, 0),
(48, 2, 'ac', 'Дом133', 35, 0),
(49, 2, 'ad', 'Кварт', 36, 0),
(50, 2, 'ae', 'ТипРегион134', 37, 0),
(51, 2, 'af', 'НаимРегион135', 38, 0),
(52, 2, 'ag', 'ТипРайон136', 39, 0),
(53, 2, 'ah', 'НаимРайон137', 40, 0),
(54, 2, 'ai', 'ТипНаселПункт138', 41, 0),
(55, 2, 'aj', 'НаимНаселПункт139', 42, 0),
(56, 2, 'ak', 'ТипУлица140', 43, 0),
(57, 2, 'al', 'НаимУлица141', 44, 0),
(58, 2, 'aq', 'КодОКВЭД', 16, 0),
(59, 2, 'ar', 'НаимОКВЭД', 17, 0),
(60, 2, 'am', 'СерНомДок158', 10, 1),
(61, 2, 'an', 'ДатаДок159', 11, 1),
(62, 2, 'ao', 'ВыдДок160', 33, 1),
(63, 2, 'ap', 'КодВыдДок161', 34, 1);
DELIMITER $$
CREATE TRIGGER `template_column_before_insert` BEFORE INSERT ON `template_columns` FOR EACH ROW BEGIN
  IF (SELECT COUNT(*) FROM template_columns WHERE column_id = NEW.column_id AND template_id = NEW.template_id) > 0
      THEN SET NEW.template_column_duplicate = 1;
    END IF;
END
$$
DELIMITER ;
CREATE TABLE `template_columns_view` (
`template_id` int(11)
,`template_column_id` int(11)
,`column_id` int(11)
,`column_name` varchar(128)
,`column_price` int(11)
,`column_blocked` tinyint(1)
,`template_column_letters` varchar(3)
,`template_column_name` varchar(128)
,`type_id` int(11)
,`type_name` varchar(128)
,`template_column_duplicate` tinyint(1)
);

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
(3, 'ws'),
(11, 'ИП'),
(12, 'ООО');

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
DROP TABLE IF EXISTS `template_columns_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `astralinside`.`template_columns_view`  AS  select `t`.`template_id` AS `template_id`,`tc`.`template_column_id` AS `template_column_id`,`c`.`column_id` AS `column_id`,`c`.`column_name` AS `column_name`,`c`.`column_price` AS `column_price`,`c`.`column_blocked` AS `column_blocked`,`tc`.`template_column_letters` AS `template_column_letters`,`tc`.`template_column_name` AS `template_column_name`,`ts`.`type_id` AS `type_id`,`ts`.`type_name` AS `type_name`,`tc`.`template_column_duplicate` AS `template_column_duplicate` from (((`astralinside`.`template_columns` `tc` join `astralinside`.`templates` `t` on((`t`.`template_id` = `tc`.`template_id`))) join `astralinside`.`columns` `c` on((`c`.`column_id` = `tc`.`column_id`))) join `astralinside`.`types` `ts` on((`ts`.`type_id` = `t`.`type_id`))) ;


ALTER TABLE `columns`
  ADD PRIMARY KEY (`column_id`),
  ADD UNIQUE KEY `column_name` (`column_name`);

ALTER TABLE `companies`
  ADD PRIMARY KEY (`company_id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `type_id` (`type_id`),
  ADD KEY `purchase_id` (`purchase_id`),
  ADD KEY `template_id` (`template_id`);

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

ALTER TABLE `templates`
  ADD PRIMARY KEY (`template_id`),
  ADD KEY `type_id` (`type_id`);

ALTER TABLE `template_columns`
  ADD PRIMARY KEY (`template_column_id`),
  ADD KEY `template_id` (`template_id`),
  ADD KEY `column_id` (`column_id`);

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


ALTER TABLE `columns`
  MODIFY `column_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=45;

ALTER TABLE `companies`
  MODIFY `company_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1562;

ALTER TABLE `connections`
  MODIFY `connection_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `files`
  MODIFY `file_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `purchases`
  MODIFY `purchase_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `templates`
  MODIFY `template_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

ALTER TABLE `template_columns`
  MODIFY `template_column_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=64;

ALTER TABLE `transactions`
  MODIFY `transaction_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `types`
  MODIFY `type_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

ALTER TABLE `users`
  MODIFY `user_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;


ALTER TABLE `companies`
  ADD CONSTRAINT `companies_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `companies_ibfk_2` FOREIGN KEY (`type_id`) REFERENCES `types` (`type_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `companies_ibfk_3` FOREIGN KEY (`purchase_id`) REFERENCES `purchases` (`purchase_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `companies_ibfk_4` FOREIGN KEY (`template_id`) REFERENCES `templates` (`template_id`) ON DELETE SET NULL ON UPDATE CASCADE;

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

ALTER TABLE `templates`
  ADD CONSTRAINT `templates_ibfk_1` FOREIGN KEY (`type_id`) REFERENCES `types` (`type_id`) ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE `template_columns`
  ADD CONSTRAINT `template_columns_ibfk_1` FOREIGN KEY (`template_id`) REFERENCES `templates` (`template_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `template_columns_ibfk_2` FOREIGN KEY (`column_id`) REFERENCES `columns` (`column_id`) ON DELETE SET NULL ON UPDATE CASCADE;

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
