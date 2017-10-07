----------------------------------------------------------------------------------------
--
-- File name:   sql_baseline_pdb.sql
--
-- Purpose:     Create a SQL Plan Baseline for SQL statements decorated with
--              particular string (i.e. /* readTransactionsSince() */)
--
-- Author:      Carlos Sierra
--
-- Version:     2017/09/28
--
-- Usage:       Execute connected into CDB.
--
--              Update sql_identification and plan_hash_value_1 and 2.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @sql_baseline_pdb.sql
--
-- Notes:       You must have an Oracle Tuning Pack License.
--
--              Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
DEF sql_identification = '/* readTransactionsSince() */';
DEF plan_hash_value_1 = 766112998;
DEF plan_hash_value_2 = 2927568196;

WHENEVER SQLERROR CONTINUE;

COL current_time NEW_V current_time FOR A15;
SELECT 'current_time: ' x, TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') current_time FROM DUAL;
COL x_host_name NEW_V x_host_name;
SELECT host_name x_host_name FROM v$instance;
COL x_db_name NEW_V x_db_name;
SELECT name x_db_name FROM v$database;

SPO create_baselines_for_all_pdbs_&&current_time..txt;
PRO HOST: &&x_host_name.
PRO DATABASE: &&x_db_name.

SET SERVEROUT ON PAGES 100 LINES 300;
SET SQLBLANKLINES ON;

VAR l_sql_patch_template CLOB;
BEGIN
  :l_sql_patch_template := q'[
BEGIN
  :l_plans_1 :=
  SYS.DBMS_SPM.LOAD_PLANS_FROM_CURSOR_CACHE (
    sql_id            => 'SQL_ID',
    plan_hash_value   => &&plan_hash_value_1.,
    fixed             => 'YES',
    enabled           => 'YES');
  :l_plans_2 :=
  SYS.DBMS_SPM.LOAD_PLANS_FROM_CURSOR_CACHE (
    sql_id            => 'SQL_ID',
    plan_hash_value   => &&plan_hash_value_2.,
    fixed             => 'YES',
    enabled           => 'YES');
 BEGIN
   SYS.DBMS_SQLDIAG.DROP_SQL_PATCH('sqlpch_SQL_ID');
 EXCEPTION
   WHEN OTHERS THEN
     NULL;
 END;
END;
/]';
END;
/

ALTER SESSION SET CONTAINER = CDB$ROOT;

COL shar FOR A4;
COL obsl FOR A4;
COL obj_sta FOR A7;

select s.con_id, p.name, s.sql_id, s.child_number, s.executions, s.optimizer_cost, 
       ROUND(s.elapsed_time/s.executions/1000000,6) secs_per_exec,  
       ROUND(s.buffer_gets/s.executions) bg_per_exec,
       s.plan_hash_value, 
       is_shareable shar,
       is_obsolete obsl,
       SUBSTR(object_status, 1, 7) obj_sta, 
s.sql_plan_baseline, s.sql_patch
from v$sql s, v$pdbs p 
where s.sql_text like '&&sql_identification.%'
and p.con_id = s.con_id 
and s.executions > 0
order by 1, 3, 4;

SPO create_baselines_for_all_pdbs_&&current_time..sql;
PRO PRO HOST: &&x_host_name.
PRO PRO DATABASE: &&x_db_name.
DECLARE
BEGIN
  FOR i IN (SELECT /* sql_patch_pdb */  p.name, s.sql_id, MAX(s.sql_plan_baseline)
              FROM v$sql s, v$pdbs p 
             WHERE s.sql_text LIKE '%&&sql_identification.%' 
               AND UPPER(s.sql_text) NOT LIKE '%V$SQL%' -- exclude itself
               AND p.con_id = s.con_id
            GROUP BY p.name, s.sql_id
            HAVING MAX(s.sql_plan_baseline) IS NULL
            ORDER BY 1, 2)
  LOOP
    DBMS_OUTPUT.PUT_LINE(CHR(10)||CHR(10)||CHR(10)||'/******************/'||CHR(10)||CHR(10)||'/* Creates SQL Baseline for SQL_ID */');
    DBMS_OUTPUT.PUT_LINE(CHR(10)||'ALTER SESSION SET CONTAINER = '||i.name||';');
    DBMS_OUTPUT.PUT_LINE('VAR l_plans_1 NUMBER;');
    DBMS_OUTPUT.PUT_LINE('VAR l_plans_2 NUMBER;');
    DBMS_OUTPUT.PUT_LINE(REPLACE(:l_sql_patch_template, 'SQL_ID', i.sql_id));
    DBMS_OUTPUT.PUT_LINE('PRINT l_plans_1');
    DBMS_OUTPUT.PUT_LINE('PRINT l_plans_2');
  END LOOP;
END;
/

SPO create_baselines_for_all_pdbs_&&current_time..txt APP;

SET ECHO ON FEED ON VER ON;
@create_baselines_for_all_pdbs_&&current_time..sql
      
ALTER SESSION SET CONTAINER = CDB$ROOT;

PRO take a 60 seconds break...
EXEC DBMS_LOCK.SLEEP(60);

select s.con_id, p.name, s.sql_id, s.child_number, s.executions, s.optimizer_cost, 
       ROUND(s.elapsed_time/s.executions/1000000,6) secs_per_exec,  
       ROUND(s.buffer_gets/s.executions) bg_per_exec,
       s.plan_hash_value, 
       is_shareable shar,
       is_obsolete obsl,
       SUBSTR(object_status, 1, 7) obj_sta, 
s.sql_plan_baseline, s.sql_patch
from v$sql s, v$pdbs p 
where s.sql_text like '&&sql_identification.%'
and p.con_id = s.con_id 
and s.executions > 0
order by 1, 3, 4;

select s.con_id, p.name, s.sql_id, s.child_number, s.executions, s.optimizer_cost, 
       ROUND(s.elapsed_time/s.executions/1000000,6) secs_per_exec,  
       ROUND(s.buffer_gets/s.executions) bg_per_exec,
       s.plan_hash_value, 
       is_shareable shar,
       is_obsolete obsl,
       SUBSTR(object_status, 1, 7) obj_sta, 
s.sql_plan_baseline, s.sql_patch
from v$sql s, v$pdbs p 
where s.sql_text like '&&sql_identification.%'
and s.sql_plan_baseline IS NOT NULL
and p.con_id = s.con_id 
and s.executions > 0
order by 1, 3, 4;

SPO OFF;

