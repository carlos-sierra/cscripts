DEF enable_monitor = 'Y';
DEF severity_high = '3';
DEF 1 = 'C##IOD';
--
UPDATE &&1..regress_config SET enable_monitor = '&&enable_monitor.';
UPDATE &&1..highaas_config SET enable_monitor = '&&enable_monitor.';
UPDATE &&1..longexecs_config SET enable_monitor = '&&enable_monitor.';
UPDATE &&1..non_scalable_plan_config SET enable_monitor = '&&enable_monitor.';
COMMIT;
