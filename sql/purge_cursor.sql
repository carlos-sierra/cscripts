-- purge_cursor.sql
PRO 1. Enter SQL_ID
DEF sql_id = '&&1.';
PRO
COL output_file_name NEW_V output_file_name;
SELECT '/tmp/purge_cursor_'||LOWER(name)||'_'||LOWER(REPLACE(SUBSTR(host_name, 1 + INSTR(host_name, '.', 1, 2), 30), '.', '_'))||'_&&sql_id._'||TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24-MI-SS') output_file_name FROM v$database, v$instance;
PRO
SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
SET FEED ON ECHO ON VER ON;
SPO &&output_file_name..txt;
PRO
SELECT sql_text FROM v$sql WHERE sql_id = '&&sql_id.' AND ROWNUM = 1
/
SELECT COUNT(*), con_id FROM v$sql WHERE sql_id = '&&sql_id.' GROUP BY con_id ORDER BY 1 DESC
/
PRO
DECLARE
  l_name     VARCHAR2(64);
  l_sql_text CLOB;
BEGIN
  -- get address, hash_value and sql text
  SELECT address||','||hash_value, sql_fulltext 
    INTO l_name, l_sql_text 
    FROM v$sqlarea 
   WHERE sql_id = '&&sql_id.'
     AND ROWNUM = 1; -- there are cases where it comes back with > 1 row!!!
  -- not always does the job
  SYS.DBMS_SHARED_POOL.PURGE (
    name  => l_name,
    flag  => 'C',
    heaps => 1
  );
  -- create fake sql patch
  SYS.DBMS_SQLDIAG_INTERNAL.I_CREATE_PATCH (
    sql_text    => l_sql_text,
    hint_text   => 'NULL',
    name        => 'purge_&&sql_id.',
    description => 'PURGE CURSOR',
    category    => 'DEFAULT',
    validate    => TRUE
  );
  -- drop fake sql patch
  SYS.DBMS_SQLDIAG.DROP_SQL_PATCH (
    name   => 'purge_&&sql_id.', 
    ignore => TRUE
  );
END;
/
PRO
SELECT COUNT(*), con_id FROM v$sql WHERE sql_id = '&&sql_id.' GROUP BY con_id ORDER BY 1 DESC
/
PRO
SPO OFF;
UNDEF 1

