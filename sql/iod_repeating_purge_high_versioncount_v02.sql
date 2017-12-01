----------------------------------------------------------------------------------------
--
-- File name:   iod_repeating_purge_high_versioncount.sql
--
-- Purpose:     Woraround CPU spikes caused by bogus HVC on ACS, bypassing ACS
--              using a SQL Patch with CBO Hint NO_BIND_AWARE.
--
-- Author:      Carlos Sierra
--
-- Version:     v02 2017/11/22
--
-- Usage:       Execute connected as SYS at the CDB level.
--              Consider OEM hourly job.
--
-- Example:     $sqlplus / as sysdba
--              @iod_repeating_purge_high_versioncount.sql
--
-- Notes:       Developed and tested on 12.0.1.0.2
--             
---------------------------------------------------------------------------------------
--
WHENEVER SQLERROR EXIT SUCCESS;
PRO
PRO Error "ORA-01476: divisor is equal to zero" just means v$database.open_mode is not "READ WRITE"
SELECT CASE open_mode WHEN 'READ WRITE' THEN open_mode ELSE TO_CHAR(1/0) END open_mode FROM v$database;
WHENEVER SQLERROR EXIT FAILURE;

SET SERVEROUT ON LIN 300;
DECLARE
  l_purge_cursor BOOLEAN := TRUE;
  l_create_sql_patch BOOLEAN := TRUE;
  l_statement CLOB;
  l_cursor_id INTEGER;
  l_rows      INTEGER;
  l_sql_text  CLOB;
BEGIN
  l_statement := 
  q'[DECLARE PRAGMA AUTONOMOUS_TRANSACTION; BEGIN ]'||CHR(10)||
  q'[SYS.DBMS_SQLDIAG.DROP_SQL_PATCH ( ]'||CHR(10)||
  q'[  name   => :name,  ]'||CHR(10)||
  q'[  ignore => TRUE ]'||CHR(10)||
  q'[); ]'||CHR(10)||
  q'[SYS.DBMS_SQLDIAG_INTERNAL.I_CREATE_PATCH ( ]'||CHR(10)||
  q'[  sql_text    => :sql_text, ]'||CHR(10)||
  q'[  hint_text   => 'NO_BIND_AWARE', ]'||CHR(10)||
  q'[  name        => :name, ]'||CHR(10)||
  q'[  description => 'IOD ACS HVC', ]'||CHR(10)||
  q'[  category    => 'DEFAULT', ]'||CHR(10)||
  q'[  validate    => TRUE ]'||CHR(10)||
  q'[); ]'||CHR(10)||
  q'[COMMIT; END;]';
  FOR i IN (SELECT p.name pdb_name, s.sql_id, s.address, s.hash_value, s.sql_text,
                   COUNT(*) cursors, COUNT(DISTINCT s.plan_hash_value) plans
              FROM v$sql s, v$pdbs p, cdb_users u1, cdb_users u2
             WHERE s.parsing_user_id > 0
               AND s.parsing_schema_id > 0
               AND s.sql_text LIKE '/* '||CHR(37) -- kiev signature
               AND p.con_id = s.con_id
               AND u1.con_id = s.con_id
               AND u1.user_id = s.parsing_user_id
               AND u1.oracle_maintained = 'N'
               AND u2.con_id = s.con_id
               AND u2.user_id = s.parsing_schema_id
               AND u2.oracle_maintained = 'N'
             GROUP BY p.name, s.sql_id, s.address, s.hash_value, s.sql_text
             HAVING COUNT(*) > 100
             ORDER BY p.name, s.sql_id)
  LOOP
    SYS.DBMS_OUTPUT.PUT_LINE (
      'PDB:'||i.pdb_name||' '||
      'SQL_ID:'||i.sql_id||' '||
      'ADDRESS:'||i.address||' '||
      'HASH_VALUE:'||i.hash_value||' '||
      'CURSORS:'||i.cursors||' '||
      'PLANS:'||i.plans||' '||
      SUBSTR(i.sql_text, 1, 100)
    );
    SELECT sql_fulltext INTO l_sql_text FROM v$sql WHERE sql_id = i.sql_id AND ROWNUM = 1;
    IF l_purge_cursor THEN
      BEGIN
        -- execute at the CDB
        SYS.DBMS_SHARED_POOL.PURGE (
          name  => i.address||','||i.hash_value, 
          flag  => 'C', 
          heaps => 1
        );
      EXCEPTION
        WHEN OTHERS THEN
          DBMS_OUTPUT.PUT_LINE('*** '||SQLERRM);
          DBMS_OUTPUT.PUT_LINE('*** SYS.DBMS_SHARED_POOL.PURGE API');
      END;
    END IF;
    IF l_create_sql_patch THEN
      BEGIN
        -- execute at the PDB
        l_cursor_id := DBMS_SQL.OPEN_CURSOR;
        DBMS_SQL.PARSE(c => l_cursor_id, statement => l_statement, language_flag => DBMS_SQL.NATIVE, container => i.pdb_name);
        DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':name', value => 'NO_BIND_AWARE_'||i.sql_id);
        DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':sql_text', value => l_sql_text);
        l_rows := DBMS_SQL.EXECUTE(c => l_cursor_id);
        DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
      EXCEPTION
        WHEN OTHERS THEN
          DBMS_OUTPUT.PUT_LINE('*** '||SQLERRM);
          DBMS_OUTPUT.PUT_LINE('*** SYS.DBMS_SQL.EXECUTE BLOCK');
      END;
    END IF;
  END LOOP;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('*** '||SQLERRM);
    DBMS_OUTPUT.PUT_LINE('*** GLOBAL');
END;
/
