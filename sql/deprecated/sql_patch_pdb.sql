DEF sql_identification = '/* readTransactionsSince() */';
DEF sql_cbo_hint = 'LEADING(Tx) INDEX(Tx KIEVTRANSACTIONS_AK) USE_NL(Key) INDEX(Key KIEVTRANSACTIONKEYS_PK)';

SET SERVEROUT ON PAGES 100 LINES 300;

VAR l_sql_patch_template CLOB;
BEGIN
  :l_sql_patch_template := q'[
DECLARE
  l_sql_text CLOB;
BEGIN
  SELECT sql_fulltext
    INTO l_sql_text
    FROM v$sql
   WHERE sql_id = 'SQL_ID'
     AND ROWNUM = 1;
  SYS.DBMS_SQLDIAG_INTERNAL.I_CREATE_PATCH (
    sql_text    => l_sql_text,
    hint_text   => ']'||CHR(38)||CHR(38)||q'[sql_cbo_hint.',
    name        => 'sqlpch_SQL_ID',
    description => '/*+ ]'||CHR(38)||CHR(38)||q'[sql_cbo_hint. */',
    category    => 'DEFAULT',
    validate    => TRUE
  );
END;
/]';
END;
/
SPO create_patches_for_all_pdbs.sql;

select s.con_id, p.name, s.sql_id, s.child_number, s.executions, s.optimizer_cost, ROUND(s.elapsed_time/s.executions/1000000,6) secs_per_exec,  s.plan_hash_value, s.is_shareable, s.object_status, s.sql_plan_baseline, s.sql_patch
from v$sql s, v$pdbs p 
where s.sql_text like '&&sql_identification.%'
and p.con_id = s.con_id 
and s.executions > 0
order by 1, 3, 4;

ALTER SESSION SET CONTAINER = CDB$ROOT;

DECLARE
BEGIN
  DBMS_OUTPUT.PUT_LINE('SPO create_patches_for_all_pdbs.txt;');
  FOR i IN (SELECT /* sql_patch_pdb */ p.name, s.sql_id 
              FROM v$sql s, v$pdbs p 
             WHERE s.sql_text LIKE '%&&sql_identification.%' 
               AND UPPER(s.sql_text) NOT LIKE '%V$SQL%' -- exclude itself
               AND p.con_id = s.con_id 
               AND sql_plan_baseline IS NULL AND sql_profile IS NULL AND sql_patch IS NULL
             MINUS
            SELECT /* sql_patch_pdb */ p.name, s.sql_id 
              FROM v$sql s, v$pdbs p 
             WHERE s.sql_text LIKE '%&&sql_identification.%' 
               AND UPPER(s.sql_text) NOT LIKE '%V$SQL%' -- exclude itself
               AND p.con_id = s.con_id 
               AND (sql_plan_baseline IS NOT NULL OR sql_profile IS NOT NULL OR sql_patch IS NOT NULL))
  LOOP
    DBMS_OUTPUT.PUT_LINE(CHR(10)||CHR(10)||CHR(10)||'*****************'||CHR(10)||CHR(10)||'/* Creates SQL Patch for SQL_ID with CBO Hints: &&sql_cbo_hint. */');
    DBMS_OUTPUT.PUT_LINE(CHR(10)||'ALTER SESSION SET CONTAINER = '||i.name||';');
    DBMS_OUTPUT.PUT_LINE(REPLACE(:l_sql_patch_template, 'SQL_ID', i.sql_id));
  END LOOP;
  --DBMS_OUTPUT.PUT_LINE('SPO OFF;');
END;
/
SPO OFF;

SET ECHO ON FEED ON;
@create_patches_for_all_pdbs.sql
      
ALTER SESSION SET CONTAINER = CDB$ROOT;

select s.con_id, p.name, s.sql_id, s.child_number, s.executions, s.optimizer_cost, ROUND(s.elapsed_time/s.executions/1000000,6) secs_per_exec,  s.plan_hash_value, s.is_shareable, s.object_status, s.sql_plan_baseline, s.sql_patch
from v$sql s, v$pdbs p 
where s.sql_text like '&&sql_identification.%'
and p.con_id = s.con_id 
and s.executions > 0
order by 1, 3, 4;

SPO OFF;

