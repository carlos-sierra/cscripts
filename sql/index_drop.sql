DEF sleep_seconds = '60';
--
-- exit graciously if executed on standby
-- exit graciously if executed on standby
WHENEVER SQLERROR EXIT SUCCESS;
DECLARE
  l_open_mode VARCHAR2(20);
BEGIN
  SELECT open_mode INTO l_open_mode FROM v$database;
  IF l_open_mode <> 'READ WRITE' THEN
    raise_application_error(-20000, 'Must execute on PRIMARY');
  END IF;
END;
/
WHENEVER SQLERROR CONTINUE;
--
PRO
SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
SET SERVEROUT ON;
PRO
ALTER SESSION SET CONTAINER = CDB$ROOT;
PRO
SELECT COUNT(*) to_drop FROM cdb_indexes WHERE index_name = 'KIEVTRANSACTIONS_AK2';
PRO
SPO drop_invisible_index.sql
PRO
BEGIN
  DBMS_OUTPUT.PUT_LINE('');
  FOR i IN (SELECT c.name pdb_name,
                   i.owner,
                   i.index_name
              FROM cdb_indexes i,
                   v$containers c
             WHERE i.index_name = 'KIEVTRANSACTIONS_AK2'
               AND i.visibility = 'INVISIBLE'
               AND c.con_id = i.con_id
               AND c.open_mode = 'READ WRITE'
             ORDER BY
                   c.name,
                   i.owner)
  LOOP
    DBMS_OUTPUT.PUT_LINE('ALTER SESSION SET CONTAINER = '||i.pdb_name||';');
    DBMS_OUTPUT.PUT_LINE('SELECT TO_CHAR(ROUND(s.blocks * t.block_size / POWER(2, 30), 3), ''999,990.000'') GBs FROM dba_segments s, dba_tablespaces t WHERE s.owner = '''||i.owner||''' AND s.segment_name = '''||i.index_name||''' AND s.segment_type = ''INDEX'' AND t.tablespace_name = s.tablespace_name;');
    DBMS_OUTPUT.PUT_LINE('DROP INDEX '||i.owner||'.'||i.index_name||';');
    DBMS_OUTPUT.PUT_LINE('EXEC DBMS_LOCK.SLEEP(&&sleep_seconds.);');
  END LOOP;
END;
/
PRO
SPO OFF;
PRO
CLEAR BREAK COMPUTE;
COL pdb FOR A35;
COL tablespace_name FOR A30;
COL used_space_gbs FOR 999,990.000;
COL max_size_gbs FOR 999,990.000;
COL used_percent FOR 990.000;
PRO
BREAK ON REPORT;
COMPUTE SUM LABEL 'TOTAL' OF used_space_gbs max_size_gbs ON REPORT; 
PRO
COL current_time NEW_V current_time FOR A15;
SELECT 'current_time: ' x, TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') current_time FROM DUAL;
PRO
PRO Execute drop_invisible_index.sql
PRO
SPO drop_invisible_index_&&current_time..txt;
PRO
PRO Tablespaces (before)
PRO ~~~~~~~~~~~~~~~~~~~
SELECT c.name||'('||c.con_id||')' pdb,
       ROUND(m.used_space * t.block_size / POWER(2, 30), 3) used_space_gbs,
       ROUND(m.tablespace_size * t.block_size / POWER(2, 30), 3) max_size_gbs,
       ROUND(m.used_percent, 3) used_percent, -- as per maximum size (considering auto extend)
       m.tablespace_name
  FROM cdb_tablespace_usage_metrics m,
       cdb_tablespaces t,
       v$containers c
 WHERE t.con_id = m.con_id
   AND t.tablespace_name = m.tablespace_name
   AND t.status = 'ONLINE'
   AND t.contents = 'PERMANENT'
   AND t.tablespace_name NOT IN ('SYSTEM', 'SYSAUX')
   AND c.con_id = m.con_id
   AND c.open_mode = 'READ WRITE'
 ORDER BY
       c.name,
       m.tablespace_name
/
PRO
SET ECHO ON TIM ON TIMI ON;
@@drop_invisible_index.sql
PRO
SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
ALTER SESSION SET CONTAINER = CDB$ROOT;
EXEC DBMS_LOCK.SLEEP(60);
PRO
PRO Tablespaces (after)
PRO ~~~~~~~~~~~~~~~~~~~
SELECT c.name||'('||c.con_id||')' pdb,
       ROUND(m.used_space * t.block_size / POWER(2, 30), 3) used_space_gbs,
       ROUND(m.tablespace_size * t.block_size / POWER(2, 30), 3) max_size_gbs,
       ROUND(m.used_percent, 3) used_percent, -- as per maximum size (considering auto extend)
       m.tablespace_name
  FROM cdb_tablespace_usage_metrics m,
       cdb_tablespaces t,
       v$containers c
 WHERE t.con_id = m.con_id
   AND t.tablespace_name = m.tablespace_name
   AND t.status = 'ONLINE'
   AND t.contents = 'PERMANENT'
   AND t.tablespace_name NOT IN ('SYSTEM', 'SYSAUX')
   AND c.con_id = m.con_id
   AND c.open_mode = 'READ WRITE'
 ORDER BY
       c.name,
       m.tablespace_name
/
PRO
SELECT COUNT(*) to_drop FROM cdb_indexes WHERE index_name = 'KIEVTRANSACTIONS_AK2';
PRO
SPO OFF;
PRO
EXIT;
