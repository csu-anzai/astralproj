SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
START TRANSACTION;
SET time_zone = "+00:00";

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;


CREATE TABLE `banks` (
  `bank_id` int(11) NOT NULL,
  `bank_name` varchar(128) COLLATE utf8_bin NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

CREATE TABLE `bank_cities` (
  `bank_city_id` int(11) NOT NULL,
  `bank_id` int(11) NOT NULL,
  `city_id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

CREATE TABLE `bank_cities_time_priority` (
  `bank_city_time_priority_id` int(11) NOT NULL,
  `bank_id` int(11) NOT NULL,
  `time_id` int(11) NOT NULL,
  `city_id` int(11) NOT NULL,
  `priority` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
CREATE TABLE `bank_cities_time_priority_companies_view` (
`time_id` int(11)
,`time_value` varchar(5)
,`priority` int(11)
,`region_name` varchar(60)
,`city_name` varchar(60)
,`company_id` int(11)
,`user_id` int(11)
,`company_date_create` varchar(19)
,`type_id` int(11)
,`company_date_update` varchar(19)
,`company_discount` int(11)
,`company_discount_percent` tinyint(1)
,`company_ogrn` varchar(15)
,`company_ogrn_date` varchar(10)
,`company_person_name` varchar(128)
,`company_person_surname` varchar(128)
,`company_person_patronymic` varchar(128)
,`company_person_birthday` varchar(10)
,`company_person_birthplace` varchar(1024)
,`company_inn` varchar(12)
,`company_address` varchar(1024)
,`company_doc_number` varchar(120)
,`company_doc_date` varchar(10)
,`company_organization_name` varchar(1024)
,`company_organization_code` varchar(20)
,`company_phone` varchar(120)
,`company_email` varchar(1024)
,`company_okved_code` varchar(8)
,`company_okved_name` varchar(2048)
,`purchase_id` int(11)
,`template_id` int(11)
,`company_kpp` varchar(9)
,`company_index` varchar(9)
,`company_house` varchar(128)
,`company_region_type` varchar(50)
,`company_region_name` varchar(120)
,`company_area_type` varchar(60)
,`company_area_name` varchar(60)
,`company_locality_type` varchar(60)
,`company_locality_name` varchar(60)
,`company_street_type` varchar(60)
,`company_street_name` varchar(60)
,`company_innfl` varchar(12)
,`company_person_position_type` varchar(60)
,`company_person_position_name` varchar(512)
,`company_doc_name` varchar(120)
,`company_doc_gifter` varchar(256)
,`company_doc_code` varchar(7)
,`company_doc_house` varchar(128)
,`company_doc_flat` varchar(40)
,`company_doc_region_type` varchar(50)
,`company_doc_region_name` varchar(120)
,`company_doc_area_type` varchar(60)
,`company_doc_area_name` varchar(60)
,`company_doc_locality_type` varchar(60)
,`company_doc_locality_name` varchar(60)
,`company_doc_street_type` varchar(60)
,`company_doc_street_name` varchar(60)
,`city_id` int(11)
,`region_id` int(11)
,`bank_id` int(11)
,`company_json` json
);
CREATE TABLE `bank_times_view` (
`time_id` int(11)
,`time_value` varchar(5)
,`bank_id` int(11)
);

CREATE TABLE `cities` (
  `city_id` int(11) NOT NULL,
  `city_name` varchar(60) COLLATE utf8_bin NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

CREATE TABLE `codes` (
  `code_id` int(11) NOT NULL,
  `code_value` int(3) NOT NULL,
  `region_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

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
  `company_doc_number` varchar(120) COLLATE utf8_bin DEFAULT NULL,
  `company_doc_date` varchar(10) COLLATE utf8_bin DEFAULT NULL,
  `company_organization_name` varchar(1024) COLLATE utf8_bin DEFAULT NULL,
  `company_organization_code` varchar(20) COLLATE utf8_bin DEFAULT NULL,
  `company_phone` varchar(120) COLLATE utf8_bin DEFAULT NULL,
  `company_email` varchar(1024) COLLATE utf8_bin DEFAULT NULL,
  `company_okved_code` varchar(8) COLLATE utf8_bin DEFAULT NULL,
  `company_okved_name` varchar(2048) COLLATE utf8_bin DEFAULT NULL,
  `purchase_id` int(11) DEFAULT NULL,
  `template_id` int(11) DEFAULT NULL,
  `company_kpp` varchar(9) COLLATE utf8_bin DEFAULT NULL,
  `company_index` varchar(9) COLLATE utf8_bin DEFAULT NULL,
  `company_house` varchar(128) COLLATE utf8_bin DEFAULT NULL,
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
  `company_person_position_name` varchar(512) COLLATE utf8_bin DEFAULT NULL,
  `company_doc_name` varchar(120) COLLATE utf8_bin DEFAULT NULL,
  `company_doc_gifter` varchar(256) COLLATE utf8_bin DEFAULT NULL,
  `company_doc_code` varchar(7) COLLATE utf8_bin DEFAULT NULL,
  `company_doc_house` varchar(128) COLLATE utf8_bin DEFAULT NULL,
  `company_doc_flat` varchar(40) COLLATE utf8_bin DEFAULT NULL,
  `company_doc_region_type` varchar(50) COLLATE utf8_bin DEFAULT NULL,
  `company_doc_region_name` varchar(120) COLLATE utf8_bin DEFAULT NULL,
  `company_doc_area_type` varchar(60) COLLATE utf8_bin DEFAULT NULL,
  `company_doc_area_name` varchar(60) COLLATE utf8_bin DEFAULT NULL,
  `company_doc_locality_type` varchar(60) COLLATE utf8_bin DEFAULT NULL,
  `company_doc_locality_name` varchar(60) COLLATE utf8_bin DEFAULT NULL,
  `company_doc_street_type` varchar(60) COLLATE utf8_bin DEFAULT NULL,
  `company_doc_street_name` varchar(60) COLLATE utf8_bin DEFAULT NULL,
  `city_id` int(11) DEFAULT NULL,
  `region_id` int(11) DEFAULT NULL,
  `bank_id` int(11) DEFAULT NULL,
  `company_date_registration` varchar(10) COLLATE utf8_bin DEFAULT NULL,
  `company_person_sex` int(1) DEFAULT NULL,
  `company_ip_type` varchar(1024) COLLATE utf8_bin DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
DELIMITER $$
CREATE TRIGGER `companies_before_insert` BEFORE INSERT ON `companies` FOR EACH ROW BEGIN
  DECLARE innLength, templateType INT(11);
  SET NEW.company_date_create = NOW();
  SET innLength = CHAR_LENGTH(NEW.company_inn);
  IF innLength = 9 OR innLength = 11
    THEN SET NEW.company_inn = CONCAT("0", NEW.company_inn);
  END IF;
  SET NEW.region_id = (SELECT region_id FROM codes WHERE code_value = SUBSTRING(NEW.company_inn, 1, 2));
  SET NEW.city_id = (SELECT city_id FROM fns_codes WHERE fns_code_value = SUBSTRING(NEW.company_inn, 1, 4));
  SET NEW.bank_id = (SELECT bank_id FROM bank_cities WHERE city_id = NEW.city_id LIMIT 1);
  SET NEW.company_phone = REPLACE(CONCAT("+", REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(NEW.company_phone, "(", ""), ")",""), " ", ""), "-", ""), "—", ""), "+", "")), "+8", "+7");
  IF NEW.bank_id = 1 AND (NEW.company_phone IS NULL OR NEW.company_inn IS NULL)
    THEN SET NEW.bank_id = NULL;
  END IF;
  SELECT type_id INTO templateType FROM templates WHERE template_id = NEW.template_id;
  IF NEW.company_organization_name IS NULL AND templateType = 11
    THEN SET NEW.company_organization_name = CONCAT(
      IF(NEW.company_person_name IS NOT NULL OR NEW.company_person_surname IS NOT NULL OR NEW.company_person_patronymic IS NOT NULL, "ИП", ""),
      IF(NEW.company_person_surname IS NOT NULL, CONCAT(" ", NEW.company_person_surname, " "), ""),
      IF(NEW.company_person_name IS NOT NULL, CONCAT(NEW.company_person_name, " "), ""),
      IF(NEW.company_person_patronymic IS NOT NULL, CONCAT(NEW.company_person_patronymic, " "), "")
    );
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
  IF NEW.user_id IS NOT NULL AND (NEW.user_id != OLD.user_id OR OLD.user_id IS NULL)
    THEN INSERT INTO states (connection_id, user_id) VALUES (NEW.connection_id, NEW.user_id);
  END IF;
END
$$
DELIMITER ;
CREATE TABLE `duplicate_companies_inn_view` (
`length` bigint(21)
,`company_inn` varchar(12)
);
CREATE TABLE `duplicate_companies_ogrn_view` (
`length` bigint(21)
,`company_ogrn` varchar(15)
);
CREATE TABLE `empty_companies_view` (
`company_id` int(11)
,`company_date_create` varchar(19)
);

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

CREATE TABLE `fns_codes` (
  `fns_code_id` int(11) NOT NULL,
  `region_id` int(11) DEFAULT NULL,
  `fns_code_value` int(2) NOT NULL,
  `city_id` int(11) DEFAULT NULL,
  `fns_name` varchar(128) COLLATE utf8_bin NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

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

CREATE TABLE `regions` (
  `region_id` int(11) NOT NULL,
  `region_name` varchar(60) COLLATE utf8_bin NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

CREATE TABLE `states` (
  `state_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `connection_id` int(11) NOT NULL,
  `state_json` json NOT NULL,
  `state_date_create` varchar(19) COLLATE utf8_bin NOT NULL,
  `state_date_update` varchar(19) COLLATE utf8_bin DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
DELIMITER $$
CREATE TRIGGER `state_before_insert` BEFORE INSERT ON `states` FOR EACH ROW BEGIN
  DECLARE typeID INT(11);
  SET NEW.state_date_create = NOW();
  SELECT type_id INTO typeID FROM users WHERE user_id = NEW.user_id;
  IF typeID = 1 OR typeID = 19
    THEN BEGIN 
      SET NEW.state_json = JSON_OBJECT(
        "statistic", JSON_OBJECT(
          "dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 WEEK)),
          "dateEnd", DATE(NOW()),
          "typeToView", 3,
          "period", 0,
          "types", JSON_ARRAY(
            16
          ),
          "user", 0,
          "dataDateStart", DATE(SUBDATE(NOW(), INTERVAL 1 WEEK)),
          "dataDateEnd", DATE(NOW()),
          "dataPeriod", 0,
          "dataBank", 1,
          "dataFree", 1
        )
      );
    END;
    ELSE SET NEW.state_json = JSON_OBJECT();
  END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `state_before_update` BEFORE UPDATE ON `states` FOR EACH ROW BEGIN
  DECLARE typeToView, period, bankID INT(11);
  DECLARE firstDate VARCHAR(19);
  DECLARE dataFree, dataBank TINYINT(11);
  DECLARE types JSON;
  SELECT bank_id INTO bankID FROM users WHERE user_id = NEW.user_id;
  SET NEW.state_date_update = NOW();
  SET typeToView = JSON_EXTRACT(NEW.state_json, "$.statistic.typeToView");
  SET period = JSON_EXTRACT(NEW.state_json, "$.statistic.period");
  CASE typeToView
    WHEN 0 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(9, 13, 14, 15, 16, 17));
    WHEN 1 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(17));
    WHEN 2 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(15));
    WHEN 3 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(16));
    WHEN 4 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(13));
    WHEN 5 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(14));
    WHEN 6 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(9));
    WHEN 7 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(15, 16, 17));
    WHEN 8 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(13, 14));
    WHEN 9 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(13, 14, 15, 16, 17));
    ELSE SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(9, 13, 14, 15, 16, 17));
  END CASE;
  SET types = JSON_EXTRACT(NEW.state_json, "$.statistic.types");
  CASE period
    WHEN 0 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 WEEK)), "$.statistic.dateEnd", DATE(NOW()));
    WHEN 1 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 MONTH)), "$.statistic.dateEnd", DATE(NOW()));
    WHEN 2 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 YEAR)), "$.statistic.dateEnd", DATE(NOW()));
    WHEN 3 THEN BEGIN 
      SELECT company_date_update INTO firstDate FROM companies WHERE JSON_CONTAINS(types, JSON_ARRAY(type_id)) AND bank_id = bankID ORDER BY company_date_update LIMIT 1;
      IF firstDate IS NULL
        THEN SET firstDate = DATE(NOW());
      END IF;
      SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.dateStart", DATE(firstDate), "$.statistic.dateEnd", DATE(NOW()));
    END;
    WHEN 4 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.dateStart", DATE(NOW()), "$.statistic.dateEnd", DATE(NOW()));
    WHEN 5 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 DAY)), "$.statistic.dateEnd", DATE(SUBDATE(NOW(), INTERVAL 1 DAY)));
    ELSE SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 WEEK)), "$.statistic.dateEnd", DATE(NOW()));
  END CASE;
  SET period = JSON_EXTRACT(NEW.state_json, "$.statistic.dataPeriod");
  CASE period
    WHEN 0 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.dataDateStart", DATE(SUBDATE(NOW(), INTERVAL 1 WEEK)), "$.statistic.dataDateEnd", DATE(NOW()));
    WHEN 1 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.dataDateStart", DATE(SUBDATE(NOW(), INTERVAL 1 MONTH)), "$.statistic.dataDateEnd", DATE(NOW()));
    WHEN 2 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.dataDateStart", DATE(SUBDATE(NOW(), INTERVAL 1 YEAR)), "$.statistic.dataDateEnd", DATE(NOW()));
    WHEN 3 THEN BEGIN
      SET dataFree = JSON_UNQUOTE(JSON_EXTRACT(NEW.state_json, "$.statistic.dataFree"));
      SET dataBank = JSON_UNQUOTE(JSON_EXTRACT(NEW.state_json, "$.statistic.dataBank"));
      SELECT company_date_create INTO firstDate FROM companies WHERE IF(dataFree, type_id = 10, 1) AND IF(dataBank, bank_id = bankID, 1) ORDER BY company_date_create LIMIT 1;
      SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.dataDateStart", DATE(firstDate), "$.statistic.dataDateEnd", DATE(NOW()));
    END;
    WHEN 4 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.dataDateStart", DATE(SUBDATE(NOW(), INTERVAL 1 DAY)), "$.statistic.dataDateEnd", DATE(SUBDATE(NOW(), INTERVAL 1 DAY)));
    WHEN 5 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.dataDateStart", DATE(NOW()), "$.statistic.dataDateEnd", DATE(NOW()));
  END CASE;
END
$$
DELIMITER ;
CREATE TABLE `statistic_view` (
`bank_id` int(11)
,`date` date
,`time` time(6)
,`type_id` int(11)
);

CREATE TABLE `templates` (
  `template_id` int(11) NOT NULL,
  `type_id` int(11) DEFAULT NULL,
  `template_columns_count` int(11) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
CREATE TABLE `templates_view` (
`template_id` int(11)
,`type_id` int(11)
,`template_columns_count` int(11)
,`type_name` varchar(128)
);

CREATE TABLE `template_columns` (
  `template_column_id` int(11) NOT NULL,
  `template_id` int(11) NOT NULL,
  `template_column_letters` varchar(3) COLLATE utf8_bin NOT NULL,
  `template_column_name` varchar(128) COLLATE utf8_bin NOT NULL,
  `column_id` int(11) DEFAULT NULL,
  `template_column_duplicate` tinyint(1) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
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

CREATE TABLE `times` (
  `time_id` int(11) NOT NULL,
  `time_value` varchar(5) COLLATE utf8_bin NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

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
  `user_connections_count` int(11) NOT NULL DEFAULT '0',
  `bank_id` int(11) DEFAULT NULL
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
$$
DELIMITER ;
CREATE TABLE `users_connections_view` (
`connection_id` int(11)
,`connection_hash` varchar(32)
,`connection_end` tinyint(1)
,`connection_api_id` varchar(128)
,`connection_type_id` int(11)
,`connection_type_name` varchar(128)
,`user_id` int(11)
,`type_id` int(11)
,`type_name` varchar(128)
,`user_auth` tinyint(1)
,`user_online` tinyint(1)
,`user_email` varchar(512)
,`bank_id` int(11)
);
DROP TABLE IF EXISTS `bank_cities_time_priority_companies_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `astralinside`.`bank_cities_time_priority_companies_view`  AS  select `b`.`time_id` AS `time_id`,`t`.`time_value` AS `time_value`,`b`.`priority` AS `priority`,`r`.`region_name` AS `region_name`,`ci`.`city_name` AS `city_name`,`c`.`company_id` AS `company_id`,`c`.`user_id` AS `user_id`,`c`.`company_date_create` AS `company_date_create`,`c`.`type_id` AS `type_id`,`c`.`company_date_update` AS `company_date_update`,`c`.`company_discount` AS `company_discount`,`c`.`company_discount_percent` AS `company_discount_percent`,`c`.`company_ogrn` AS `company_ogrn`,`c`.`company_ogrn_date` AS `company_ogrn_date`,`c`.`company_person_name` AS `company_person_name`,`c`.`company_person_surname` AS `company_person_surname`,`c`.`company_person_patronymic` AS `company_person_patronymic`,`c`.`company_person_birthday` AS `company_person_birthday`,`c`.`company_person_birthplace` AS `company_person_birthplace`,`c`.`company_inn` AS `company_inn`,`c`.`company_address` AS `company_address`,`c`.`company_doc_number` AS `company_doc_number`,`c`.`company_doc_date` AS `company_doc_date`,`c`.`company_organization_name` AS `company_organization_name`,`c`.`company_organization_code` AS `company_organization_code`,`c`.`company_phone` AS `company_phone`,`c`.`company_email` AS `company_email`,`c`.`company_okved_code` AS `company_okved_code`,`c`.`company_okved_name` AS `company_okved_name`,`c`.`purchase_id` AS `purchase_id`,`c`.`template_id` AS `template_id`,`c`.`company_kpp` AS `company_kpp`,`c`.`company_index` AS `company_index`,`c`.`company_house` AS `company_house`,`c`.`company_region_type` AS `company_region_type`,`c`.`company_region_name` AS `company_region_name`,`c`.`company_area_type` AS `company_area_type`,`c`.`company_area_name` AS `company_area_name`,`c`.`company_locality_type` AS `company_locality_type`,`c`.`company_locality_name` AS `company_locality_name`,`c`.`company_street_type` AS `company_street_type`,`c`.`company_street_name` AS `company_street_name`,`c`.`company_innfl` AS `company_innfl`,`c`.`company_person_position_type` AS `company_person_position_type`,`c`.`company_person_position_name` AS `company_person_position_name`,`c`.`company_doc_name` AS `company_doc_name`,`c`.`company_doc_gifter` AS `company_doc_gifter`,`c`.`company_doc_code` AS `company_doc_code`,`c`.`company_doc_house` AS `company_doc_house`,`c`.`company_doc_flat` AS `company_doc_flat`,`c`.`company_doc_region_type` AS `company_doc_region_type`,`c`.`company_doc_region_name` AS `company_doc_region_name`,`c`.`company_doc_area_type` AS `company_doc_area_type`,`c`.`company_doc_area_name` AS `company_doc_area_name`,`c`.`company_doc_locality_type` AS `company_doc_locality_type`,`c`.`company_doc_locality_name` AS `company_doc_locality_name`,`c`.`company_doc_street_type` AS `company_doc_street_type`,`c`.`company_doc_street_name` AS `company_doc_street_name`,`c`.`city_id` AS `city_id`,`c`.`region_id` AS `region_id`,`c`.`bank_id` AS `bank_id`,json_object('cityName',`ci`.`city_name`,'regionName',`r`.`region_name`,'typeID',`c`.`type_id`,'companyID',`c`.`company_id`,'templateID',`c`.`template_id`,'cityID',`c`.`city_id`,'regionID',`c`.`region_id`,'companyDateCreate',`c`.`company_date_create`,'companyDateUpdate',`c`.`company_date_update`,'companyOgrn',`c`.`company_ogrn`,'companyOgrnDate',`c`.`company_ogrn_date`,'companyPersonBirthday',`c`.`company_person_birthday`,'companyDocDate',`c`.`company_doc_date`,'companyPersonName',`c`.`company_person_name`,'companyPersonSurname',`c`.`company_person_surname`,'companyPersonPatronymic',`c`.`company_person_patronymic`,'companyPersonBirthplace',`c`.`company_person_birthplace`,'companyAddress',`c`.`company_address`,'companyOrganizationName',`c`.`company_organization_name`,'companyEmail',`c`.`company_email`,'companyInn',`c`.`company_inn`,'companyDocNumber',`c`.`company_doc_number`,'companyInnfl',`c`.`company_innfl`,'companyOrganizationCode',`c`.`company_organization_code`,'companyPhone',`c`.`company_phone`,'companyHouse',`c`.`company_house`,'companyDocHouse',`c`.`company_doc_house`,'companyOkvedCode',`c`.`company_okved_code`,'companyOkvedName',`c`.`company_okved_name`,'companyKpp',`c`.`company_kpp`,'companyIndex',`c`.`company_index`,'companyRegionType',`c`.`company_region_type`,'companyDocRegionType',`c`.`company_doc_region_type`,'companyRegionName',`c`.`company_region_name`,'companyDocName',`c`.`company_doc_name`,'companyDocRegionName',`c`.`company_doc_region_name`,'companyAreaType',`c`.`company_area_type`,'companyAreaName',`c`.`company_area_name`,'companyLocalityType',`c`.`company_locality_type`,'companyLocalityName',`c`.`company_locality_name`,'companyStreetType',`c`.`company_street_type`,'companyStreetName',`c`.`company_street_name`,'companyPersonPositionType',`c`.`company_person_position_type`,'companyPersonPositionName',`c`.`company_person_position_name`,'companyDocAreaType',`c`.`company_doc_area_type`,'companyDocAreaName',`c`.`company_doc_area_name`,'companyDocLocalityType',`c`.`company_doc_locality_type`,'companyDocLocalityName',`c`.`company_doc_locality_name`,'companyDocStreetType',`c`.`company_doc_street_type`,'companyDocStreetName',`c`.`company_doc_street_name`,'companyDocGifter',`c`.`company_doc_gifter`,'companyDocCode',`c`.`company_doc_code`,'companyDocFlat',`c`.`company_doc_flat`) AS `company_json` from ((((`astralinside`.`bank_cities_time_priority` `b` join `astralinside`.`companies` `c` on(((`c`.`city_id` = `b`.`city_id`) and (`c`.`bank_id` = `b`.`bank_id`)))) join `astralinside`.`times` `t` on((`t`.`time_id` = `b`.`time_id`))) join `astralinside`.`cities` `ci` on((`ci`.`city_id` = `b`.`city_id`))) join `astralinside`.`regions` `r` on((`r`.`region_id` = `c`.`region_id`))) order by `b`.`time_id`,`b`.`priority` ;
DROP TABLE IF EXISTS `bank_times_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `astralinside`.`bank_times_view`  AS  select distinct `b`.`time_id` AS `time_id`,`t`.`time_value` AS `time_value`,`b`.`bank_id` AS `bank_id` from (`astralinside`.`bank_cities_time_priority` `b` join `astralinside`.`times` `t` on((`t`.`time_id` = `b`.`time_id`))) order by cast(`t`.`time_value` as time(6)) ;
DROP TABLE IF EXISTS `duplicate_companies_inn_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `astralinside`.`duplicate_companies_inn_view`  AS  select `companies`.`length` AS `length`,`companies`.`company_inn` AS `company_inn` from (select count(`astralinside`.`companies`.`company_id`) AS `length`,`astralinside`.`companies`.`company_inn` AS `company_inn` from `astralinside`.`companies` group by `astralinside`.`companies`.`company_inn`) `companies` where ((`companies`.`length` > 1) and (`companies`.`company_inn` is not null)) ;
DROP TABLE IF EXISTS `duplicate_companies_ogrn_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `astralinside`.`duplicate_companies_ogrn_view`  AS  select `companies`.`length` AS `length`,`companies`.`company_ogrn` AS `company_ogrn` from (select count(`astralinside`.`companies`.`company_id`) AS `length`,`astralinside`.`companies`.`company_ogrn` AS `company_ogrn` from `astralinside`.`companies` group by `astralinside`.`companies`.`company_ogrn`) `companies` where ((`companies`.`length` > 1) and (`companies`.`company_ogrn` is not null)) ;
DROP TABLE IF EXISTS `empty_companies_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `astralinside`.`empty_companies_view`  AS  select `astralinside`.`companies`.`company_id` AS `company_id`,`astralinside`.`companies`.`company_date_create` AS `company_date_create` from `astralinside`.`companies` where (isnull(`astralinside`.`companies`.`company_ogrn`) and isnull(`astralinside`.`companies`.`company_ogrn_date`) and isnull(`astralinside`.`companies`.`company_person_name`) and isnull(`astralinside`.`companies`.`company_person_surname`) and isnull(`astralinside`.`companies`.`company_person_patronymic`) and isnull(`astralinside`.`companies`.`company_person_birthday`) and isnull(`astralinside`.`companies`.`company_person_birthplace`) and isnull(`astralinside`.`companies`.`company_inn`) and isnull(`astralinside`.`companies`.`company_address`) and isnull(`astralinside`.`companies`.`company_doc_number`) and isnull(`astralinside`.`companies`.`company_doc_date`) and isnull(`astralinside`.`companies`.`company_organization_name`) and isnull(`astralinside`.`companies`.`company_organization_code`) and isnull(`astralinside`.`companies`.`company_phone`) and isnull(`astralinside`.`companies`.`company_email`) and isnull(`astralinside`.`companies`.`company_okved_code`) and isnull(`astralinside`.`companies`.`company_okved_name`) and isnull(`astralinside`.`companies`.`company_kpp`) and isnull(`astralinside`.`companies`.`company_index`) and isnull(`astralinside`.`companies`.`company_house`) and isnull(`astralinside`.`companies`.`company_region_type`) and isnull(`astralinside`.`companies`.`company_region_name`) and isnull(`astralinside`.`companies`.`company_area_type`) and isnull(`astralinside`.`companies`.`company_area_name`) and isnull(`astralinside`.`companies`.`company_locality_type`) and isnull(`astralinside`.`companies`.`company_locality_name`) and isnull(`astralinside`.`companies`.`company_street_type`) and isnull(`astralinside`.`companies`.`company_street_name`) and isnull(`astralinside`.`companies`.`company_innfl`) and isnull(`astralinside`.`companies`.`company_person_position_type`) and isnull(`astralinside`.`companies`.`company_person_position_name`) and isnull(`astralinside`.`companies`.`company_doc_name`) and isnull(`astralinside`.`companies`.`company_doc_gifter`) and isnull(`astralinside`.`companies`.`company_doc_code`) and isnull(`astralinside`.`companies`.`company_doc_house`) and isnull(`astralinside`.`companies`.`company_doc_flat`) and isnull(`astralinside`.`companies`.`company_doc_region_type`) and isnull(`astralinside`.`companies`.`company_doc_region_name`) and isnull(`astralinside`.`companies`.`company_doc_area_type`) and isnull(`astralinside`.`companies`.`company_doc_area_name`) and isnull(`astralinside`.`companies`.`company_doc_locality_type`) and isnull(`astralinside`.`companies`.`company_doc_locality_name`) and isnull(`astralinside`.`companies`.`company_doc_street_type`) and isnull(`astralinside`.`companies`.`company_doc_street_name`) and isnull(`astralinside`.`companies`.`company_date_registration`) and isnull(`astralinside`.`companies`.`company_person_sex`) and isnull(`astralinside`.`companies`.`company_ip_type`)) ;
DROP TABLE IF EXISTS `statistic_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `astralinside`.`statistic_view`  AS  select `astralinside`.`companies`.`bank_id` AS `bank_id`,cast(`astralinside`.`companies`.`company_date_update` as date) AS `date`,cast(`astralinside`.`companies`.`company_date_update` as time(6)) AS `time`,`astralinside`.`companies`.`type_id` AS `type_id` from `astralinside`.`companies` group by `astralinside`.`companies`.`bank_id`,`date`,`time`,`astralinside`.`companies`.`type_id` order by `astralinside`.`companies`.`bank_id`,`date`,`time`,`astralinside`.`companies`.`type_id` ;
DROP TABLE IF EXISTS `templates_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `astralinside`.`templates_view`  AS  select `tm`.`template_id` AS `template_id`,`tm`.`type_id` AS `type_id`,`tm`.`template_columns_count` AS `template_columns_count`,`tp`.`type_name` AS `type_name` from (`astralinside`.`templates` `tm` join `astralinside`.`types` `tp` on((`tp`.`type_id` = `tm`.`type_id`))) ;
DROP TABLE IF EXISTS `template_columns_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `astralinside`.`template_columns_view`  AS  select `t`.`template_id` AS `template_id`,`tc`.`template_column_id` AS `template_column_id`,`c`.`column_id` AS `column_id`,`c`.`column_name` AS `column_name`,`c`.`column_price` AS `column_price`,`c`.`column_blocked` AS `column_blocked`,`tc`.`template_column_letters` AS `template_column_letters`,`tc`.`template_column_name` AS `template_column_name`,`ts`.`type_id` AS `type_id`,`ts`.`type_name` AS `type_name`,`tc`.`template_column_duplicate` AS `template_column_duplicate` from (((`astralinside`.`template_columns` `tc` join `astralinside`.`templates` `t` on((`t`.`template_id` = `tc`.`template_id`))) join `astralinside`.`columns` `c` on((`c`.`column_id` = `tc`.`column_id`))) join `astralinside`.`types` `ts` on((`ts`.`type_id` = `t`.`type_id`))) ;
DROP TABLE IF EXISTS `users_connections_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `astralinside`.`users_connections_view`  AS  select `c`.`connection_id` AS `connection_id`,`c`.`connection_hash` AS `connection_hash`,`c`.`connection_end` AS `connection_end`,`c`.`connection_api_id` AS `connection_api_id`,`c`.`type_id` AS `connection_type_id`,`tt`.`type_name` AS `connection_type_name`,`u`.`user_id` AS `user_id`,`u`.`type_id` AS `type_id`,`t`.`type_name` AS `type_name`,`u`.`user_auth` AS `user_auth`,`u`.`user_online` AS `user_online`,`u`.`user_email` AS `user_email`,`u`.`bank_id` AS `bank_id` from (((`astralinside`.`connections` `c` left join `astralinside`.`users` `u` on((`u`.`user_id` = `c`.`user_id`))) left join `astralinside`.`types` `t` on((`t`.`type_id` = `u`.`type_id`))) left join `astralinside`.`types` `tt` on((`tt`.`type_id` = `c`.`type_id`))) ;


ALTER TABLE `banks`
  ADD PRIMARY KEY (`bank_id`);

ALTER TABLE `bank_cities`
  ADD PRIMARY KEY (`bank_city_id`),
  ADD KEY `bank_id` (`bank_id`),
  ADD KEY `city_id` (`city_id`);

ALTER TABLE `bank_cities_time_priority`
  ADD PRIMARY KEY (`bank_city_time_priority_id`),
  ADD KEY `bank_id` (`bank_id`),
  ADD KEY `time_id` (`time_id`),
  ADD KEY `city_id` (`city_id`);

ALTER TABLE `cities`
  ADD PRIMARY KEY (`city_id`);

ALTER TABLE `codes`
  ADD PRIMARY KEY (`code_id`),
  ADD UNIQUE KEY `code_value` (`code_value`),
  ADD KEY `region_id` (`region_id`);

ALTER TABLE `columns`
  ADD PRIMARY KEY (`column_id`),
  ADD UNIQUE KEY `column_name` (`column_name`);

ALTER TABLE `companies`
  ADD PRIMARY KEY (`company_id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `type_id` (`type_id`),
  ADD KEY `purchase_id` (`purchase_id`),
  ADD KEY `template_id` (`template_id`),
  ADD KEY `city_id` (`city_id`),
  ADD KEY `region_id` (`region_id`),
  ADD KEY `bank_id` (`bank_id`);

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

ALTER TABLE `fns_codes`
  ADD PRIMARY KEY (`fns_code_id`),
  ADD KEY `city_id` (`city_id`),
  ADD KEY `region_id` (`region_id`);

ALTER TABLE `purchases`
  ADD PRIMARY KEY (`purchase_id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `transaction_id` (`transaction_id`);

ALTER TABLE `regions`
  ADD PRIMARY KEY (`region_id`),
  ADD UNIQUE KEY `region_name` (`region_name`);

ALTER TABLE `states`
  ADD PRIMARY KEY (`state_id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `connection_id` (`connection_id`);

ALTER TABLE `templates`
  ADD PRIMARY KEY (`template_id`),
  ADD KEY `type_id` (`type_id`);

ALTER TABLE `template_columns`
  ADD PRIMARY KEY (`template_column_id`),
  ADD KEY `template_id` (`template_id`),
  ADD KEY `column_id` (`column_id`);

ALTER TABLE `times`
  ADD PRIMARY KEY (`time_id`);

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
  ADD KEY `type_id` (`type_id`),
  ADD KEY `bank_id` (`bank_id`);


ALTER TABLE `banks`
  MODIFY `bank_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `bank_cities`
  MODIFY `bank_city_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `bank_cities_time_priority`
  MODIFY `bank_city_time_priority_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `cities`
  MODIFY `city_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `codes`
  MODIFY `code_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `columns`
  MODIFY `column_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `companies`
  MODIFY `company_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `connections`
  MODIFY `connection_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `files`
  MODIFY `file_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `fns_codes`
  MODIFY `fns_code_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `purchases`
  MODIFY `purchase_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `regions`
  MODIFY `region_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `states`
  MODIFY `state_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `templates`
  MODIFY `template_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `template_columns`
  MODIFY `template_column_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `times`
  MODIFY `time_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `transactions`
  MODIFY `transaction_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `types`
  MODIFY `type_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `users`
  MODIFY `user_id` int(11) NOT NULL AUTO_INCREMENT;


ALTER TABLE `bank_cities`
  ADD CONSTRAINT `bank_cities_ibfk_1` FOREIGN KEY (`bank_id`) REFERENCES `banks` (`bank_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `bank_cities_ibfk_2` FOREIGN KEY (`city_id`) REFERENCES `cities` (`city_id`) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `bank_cities_time_priority`
  ADD CONSTRAINT `bank_cities_time_priority_ibfk_1` FOREIGN KEY (`bank_id`) REFERENCES `banks` (`bank_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `bank_cities_time_priority_ibfk_2` FOREIGN KEY (`city_id`) REFERENCES `cities` (`city_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `bank_cities_time_priority_ibfk_3` FOREIGN KEY (`time_id`) REFERENCES `times` (`time_id`) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `codes`
  ADD CONSTRAINT `codes_ibfk_1` FOREIGN KEY (`region_id`) REFERENCES `regions` (`region_id`) ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE `companies`
  ADD CONSTRAINT `companies_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `companies_ibfk_2` FOREIGN KEY (`type_id`) REFERENCES `types` (`type_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `companies_ibfk_3` FOREIGN KEY (`purchase_id`) REFERENCES `purchases` (`purchase_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `companies_ibfk_4` FOREIGN KEY (`template_id`) REFERENCES `templates` (`template_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `companies_ibfk_5` FOREIGN KEY (`city_id`) REFERENCES `cities` (`city_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `companies_ibfk_6` FOREIGN KEY (`region_id`) REFERENCES `regions` (`region_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `companies_ibfk_7` FOREIGN KEY (`bank_id`) REFERENCES `banks` (`bank_id`) ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE `connections`
  ADD CONSTRAINT `connections_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `connections_ibfk_2` FOREIGN KEY (`type_id`) REFERENCES `types` (`type_id`) ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE `files`
  ADD CONSTRAINT `files_ibfk_1` FOREIGN KEY (`type_id`) REFERENCES `types` (`type_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `files_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `files_ibfk_3` FOREIGN KEY (`purchase_id`) REFERENCES `purchases` (`purchase_id`) ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE `fns_codes`
  ADD CONSTRAINT `fns_codes_ibfk_1` FOREIGN KEY (`city_id`) REFERENCES `cities` (`city_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fns_codes_ibfk_2` FOREIGN KEY (`region_id`) REFERENCES `regions` (`region_id`) ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE `purchases`
  ADD CONSTRAINT `purchases_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `purchases_ibfk_2` FOREIGN KEY (`transaction_id`) REFERENCES `transactions` (`transaction_id`) ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE `states`
  ADD CONSTRAINT `states_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `states_ibfk_2` FOREIGN KEY (`connection_id`) REFERENCES `connections` (`connection_id`) ON DELETE CASCADE ON UPDATE CASCADE;

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
  ADD CONSTRAINT `users_ibfk_2` FOREIGN KEY (`type_id`) REFERENCES `types` (`type_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `users_ibfk_3` FOREIGN KEY (`bank_id`) REFERENCES `banks` (`bank_id`) ON DELETE SET NULL ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
