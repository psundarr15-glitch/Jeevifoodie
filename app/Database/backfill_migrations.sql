-- Run this if `php spark migrate` complains about tables/columns
-- already existing. Safe to re-run.

CREATE TABLE IF NOT EXISTS migrations (
  id INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  version VARCHAR(255) NOT NULL,
  class VARCHAR(255) NOT NULL,
  `group` VARCHAR(255) NOT NULL,
  namespace VARCHAR(255) NOT NULL,
  time INT(11) NOT NULL,
  batch INT(11) UNSIGNED NOT NULL,
  PRIMARY KEY (id)
);

-- If `php spark migrate` already runs cleanly for you, just run that -
-- it will pick up CreateSubCategoriesTable on its own. This manual
-- version is only a fallback for a DB whose migration history isn't
-- tracked correctly.

CREATE TABLE IF NOT EXISTS sub_categories (
  id INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  category_id INT(11) UNSIGNED NOT NULL,
  restaurant_id INT(11) UNSIGNED NOT NULL,
  name VARCHAR(100) NOT NULL,
  name_ta VARCHAR(100) NULL,
  PRIMARY KEY (id),
  KEY restaurant_id (restaurant_id),
  KEY category_id (category_id)
);

ALTER TABLE menu_items
  ADD COLUMN sub_category_id INT(11) UNSIGNED NULL AFTER category_id;
