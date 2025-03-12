CREATE TABLE IF NOT EXISTS `camping` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `type` varchar(50) NOT NULL,
  `model` varchar(50) NOT NULL,
  `x` float NOT NULL,
  `y` float NOT NULL,
  `z` float NOT NULL,
  `stashID` varchar(50) NOT NULL,
  `heading` float NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `camping_skills` (
  `identifier` varchar(60) NOT NULL,
  `cooking_level` int(11) NOT NULL DEFAULT 1,
  `cooking_xp` int(11) NOT NULL DEFAULT 0,
  `discovered_recipes` longtext DEFAULT NULL,
  PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
