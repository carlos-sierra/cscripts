COL alert_log NEW_V alert_log;
SELECT value||'/alert_*.log' alert_log FROM v$diag_info WHERE name = 'Diag Trace';
!cp &&alert_log. .
