-- IOD_REPEATING_KIEV_GC_STATUS_MONITOR (hourly) KIEV
-- exit graciously if executed on standby
WHENEVER SQLERROR EXIT SUCCESS;
DECLARE
  l_open_mode VARCHAR2(20);
BEGIN
  SELECT open_mode INTO l_open_mode FROM v$database;
  IF l_open_mode <> 'READ WRITE' THEN
    raise_application_error(-20000, '*** Must execute on PRIMARY ***');
  END IF;
END;
/
WHENEVER SQLERROR EXIT FAILURE;
--
SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 SERVEROUT OFF;
--
COL pdbs FOR 9,990;
COL buckets FOR 999,990;
COL last_active_time FOR A19;
COL cdb_seconds NEW_V cdb_seconds FOR 999,990 HEA 'SECONDS';
COL pdb_seconds FOR 999,990 HEA 'SECONDS';
COL pdb_name FOR A35;
DEF is_ok = 'NO';
COL is_ok NEW_V is_ok FOR A3 HEA 'OK?';
--
PRO
PRO KIEV GC STATUS
PRO ~~~~~~~~~~~~~~
SELECT COUNT(DISTINCT s.con_id) pdbs,
       COUNT(DISTINCT s.sql_text) buckets,
       TO_CHAR(MAX(s.last_active_time), 'YYYY-MM-DD"T"HH24:MI:SS') last_active_time,
       (SYSDATE - MAX(s.last_active_time)) * 24 * 3600 cdb_seconds,
       CASE WHEN (SYSDATE - MAX(s.last_active_time)) * 24 < 1 THEN 'YES' ELSE 'NO' END is_ok
  FROM v$sql s, 
       audit_actions a
 WHERE s.sql_id IS NOT NULL
   AND s.object_status = 'VALID'
   AND s.is_obsolete = 'N'
   AND s.is_shareable = 'Y'
   AND s.parsing_user_id > 0
   AND s.parsing_schema_id > 0
   AND s.sql_text LIKE '/* deleteBucketGarbage */'||CHR(37) -- KIEV
   AND s.last_active_time > SYSDATE - (6/24) -- look last 6h
   AND a.action = s.command_type
   AND a.name = 'DELETE'
/
--
PRO
PRO KIEV GC STATUS BY PDB
PRO ~~~~~~~~~~~~~~~~~~~~~
SELECT c.name||'('||c.con_id||')' pdb_name,
       COUNT(DISTINCT s.sql_text) buckets,
       TO_CHAR(MAX(s.last_active_time), 'YYYY-MM-DD"T"HH24:MI:SS') last_active_time,
       (SYSDATE - MAX(s.last_active_time)) * 24 * 3600 pdb_seconds
  FROM v$containers c,
       v$sql s, 
       audit_actions a
 WHERE SYS_CONTEXT ('USERENV', 'CON_NAME') = 'CDB$ROOT'
   AND c.open_mode = 'READ WRITE'
   AND s.con_id = c.con_id
   AND s.sql_id IS NOT NULL
   AND s.object_status = 'VALID'
   AND s.is_obsolete = 'N'
   AND s.is_shareable = 'Y'
   AND s.parsing_user_id > 0
   AND s.parsing_schema_id > 0
   AND s.sql_text LIKE '/* deleteBucketGarbage */'||CHR(37) -- KIEV
   AND s.last_active_time > SYSDATE - (6/24) -- look last 6h
   AND a.action = s.command_type
   AND a.name = 'DELETE'
 GROUP BY
       c.name, c.con_id
 ORDER BY
       c.name
/
--
WHENEVER SQLERROR EXIT FAILURE;
BEGIN
  IF '&&is_ok.' = 'YES' THEN
    NULL;
  ELSE
    raise_application_error(-20000, '*** KIEV GC last executed over "'||TRIM('&&cdb_seconds.')||'" seconds ago ***');
  END IF;
END;
/
--
WHENEVER SQLERROR CONTINUE;
