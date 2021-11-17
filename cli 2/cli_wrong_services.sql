SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
COL pdb_name FOR A30;
COL con_id FOR 999990;
COL service_name FOR A60;
COL service_type FOR A4 HEA 'TYPE';
COL current_state FOR A6 HEA 'STATE';
COL action FOR A7;
COL sessions FOR 999990;
COL service_id FOR 999 HEA 'ID';
COL enabled FOR A7;
COL creation_date FOR A19;
COL drop_candidate FOR A6 HEA 'DROP?';
WITH s AS (SELECT /*+ OPT_PARAM('_px_cdb_view_enabled' 'FALSE') */ name, pdb, con_id, service_id, enabled, creation_date FROM cdb_services)
SELECT bad.pdb_name, c.con_id, bad.service_name, bad.service_type, bad.current_state, bad.action,
       (SELECT COUNT(*) FROM v$session s WHERE s.con_id = c.con_id AND LOWER(s.service_name) = LOWER(bad.service_name||'.'||SYS_CONTEXT('USERENV','DB_DOMAIN'))) AS sessions,
       s.service_id, s.enabled, s.creation_date,
       CASE WHEN (SELECT COUNT(*) FROM v$session s WHERE s.con_id = c.con_id AND LOWER(s.service_name) = LOWER(bad.service_name||'.'||SYS_CONTEXT('USERENV','DB_DOMAIN'))) = 0 THEN 'DROP' END AS drop_candidate
  FROM (SELECT pdb_name, service_name, service_type, current_state, action FROM TABLE(C##IOD.IOD_ADMIN.select_services) WHERE service_name LIKE '%.%' AND ROWNUM >= 1) bad,
       (SELECT pdb_name, service_name FROM TABLE(C##IOD.IOD_ADMIN.select_services) WHERE ROWNUM >= 1) good,
       v$containers c, s
 WHERE bad.pdb_name = good.pdb_name
   AND LOWER(bad.service_name) LIKE LOWER(good.service_name||'.'||SYS_CONTEXT('USERENV','DB_DOMAIN'))
   AND LOWER(bad.service_name) LIKE 's\_%' ESCAPE '\'
   AND c.name = bad.pdb_name
   AND c.open_mode = 'READ WRITE'
   AND s.pdb(+) = bad.pdb_name
   AND s.name(+) = bad.service_name
 ORDER BY
       c.con_id, bad.pdb_name, bad.service_name
/
