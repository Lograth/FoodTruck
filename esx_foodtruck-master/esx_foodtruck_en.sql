SET @job_name = 'foodtruck';
SET @society_name = 'society_foodtruck';
SET @job_Name_Caps = 'Foodtruck';



INSERT INTO `addon_account` (name, label, shared) VALUES
  (@society_name, @job_Name_Caps, 1)
;

INSERT INTO `jobs` (name, label, whitelisted) VALUES
  (@job_name, @job_Name_Caps, 0)
;

INSERT INTO `job_grades` (job_name, grade, name, label, salary, skin_male, skin_female) VALUES
  (@job_name, 0, 'cook', 'Cook', 200, '{}', '{}') 
;

INSERT INTO `items` (`name`, `label`, `limit`) VALUES  
    ('cola', 'Coke', 20)
;  
INSERT INTO `items` (`name`, `label`, `limit`) VALUES 
    ('vegetables', 'Vegetables', 20)
;  
INSERT INTO `items` (`name`, `label`, `limit`) VALUES 
    ('meat', 'Meat', 20)
;  
INSERT INTO `items` (`name`, `label`, `limit`) VALUES 
    ('tacos', 'Tacos', 20)
;  
INSERT INTO `items` (`name`, `label`, `limit`) VALUES 
    ('burger', 'Burger', 20)
; 

INSERT INTO `shops` (`store`, `item`, `price`) VALUES
('Market', 'cola', 100)
; 
INSERT INTO `shops` (`store`, `item`, `price`) VALUES
('Market', 'vegetables', 100)
; 
INSERT INTO `shops` (`store`, `item`, `price`) VALUES
('Market', 'meat', 100)
;
