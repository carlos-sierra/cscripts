DEF enable_monitor = 'Y';
DEF severity_high = '2';
DEF 1 = 'C##IOD';
--
UPDATE &&1..regress_config SET enable_monitor = '&&enable_monitor.';
UPDATE &&1..highaas_config SET enable_monitor = '&&enable_monitor.';
UPDATE &&1..longexecs_config SET enable_monitor = '&&enable_monitor.';
UPDATE &&1..non_scalable_plan_config SET enable_monitor = '&&enable_monitor.';
COMMIT;
--
CREATE OR REPLACE VIEW &&1..me$sqlperf AS
SELECT value, key_value 
  FROM &&1..me$longexecs 
 WHERE severity BETWEEN 1 AND &&severity_high.
 UNION ALL
SELECT value, key_value 
  FROM &&1..me$highaas   
 WHERE severity BETWEEN 1 AND &&severity_high.
 UNION ALL
SELECT value, key_value 
  FROM &&1..me$regress   
 WHERE severity BETWEEN 1 AND &&severity_high.
 UNION ALL
SELECT value, key_value 
  FROM &&1..me$nonscale  
 WHERE severity BETWEEN 1 AND &&severity_high.
 UNION ALL
SELECT value, key_value 
  FROM &&1..me$demoted  
 WHERE severity BETWEEN 1 AND &&severity_high.
 UNION ALL
SELECT value, key_value 
  FROM &&1..me$killed  
 WHERE severity BETWEEN 1 AND &&severity_high.
/
