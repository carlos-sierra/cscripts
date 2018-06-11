----------------------------------------------------------------------------------------
--
-- File name:   sql_patch_set.sql
--
-- Purpose:     SQL Patch a set of Scan queries based on a string, such as bucket name
--
-- Author:      Carlos Sierra
--
-- Version:     2018/05/15
--
-- Usage:       Execute connected into the PDB of interest.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @sql_patch_set.sql
--
-- Example:     @sql_patch_set.sql "/* performScanQuery(ID_USER,USER_SCP_OBJNAME) */" "FIRST_ROWS(1) GATHER_PLAN_STATISTICS"
--              @sql_patch_set.sql "ID_USER" "FIRST_ROWS(1)"
--              @sql_patch_set.sql ID_USER FIRST_ROWS(1)
--
-- Notes:       Disables existing SQL Plan Baselines on selected SQL.
--
--              Only acts on SQL decorated with search string below, 
--              with performance worse than 25ms per execution.
--             
---------------------------------------------------------------------------------------
DEF ms_per_exec = '25';
--
SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
SET SERVEROUT ON;
PRO
PRO 1. Search String (e.g. bucket name of sql handle)
DEF search_string = "&1.";
PRO
PRO 2. HINTS_TEXT (required) e.g.: FIRST_ROWS(1) GATHER_PLAN_STATISTICS
DEF hints_text = "&2.";
PRO
--
COL output_file_name NEW_V output_file_name NOPRI;
SELECT 'sql_patch_set_'||LOWER(name)||'_'||LOWER(REPLACE(SUBSTR(host_name, 1 + INSTR(host_name, '.', 1, 2), 30), '.', '_'))||'_'||LOWER(SYS_CONTEXT('USERENV','CON_NAME'))||REPLACE('_&&search_string._', ' ')||TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') output_file_name FROM v$database, v$instance;
--
SPO &&output_file_name..sql;
DECLARE
  FUNCTION application_category (p_sql_text IN VARCHAR2)
  RETURN VARCHAR2
  DETERMINISTIC
  IS
    gk_appl_cat_1                  CONSTANT VARCHAR2(10) := 'BeginTx'; -- 1st application category
    gk_appl_cat_2                  CONSTANT VARCHAR2(10) := 'CommitTx'; -- 2nd application category
    gk_appl_cat_3                  CONSTANT VARCHAR2(10) := 'Scan'; -- 3rd application category
    gk_appl_cat_4                  CONSTANT VARCHAR2(10) := 'GC'; -- 4th application category
    k_appl_handle_prefix           CONSTANT VARCHAR2(30) := '/*'||CHR(37);
    k_appl_handle_suffix           CONSTANT VARCHAR2(30) := CHR(37)||'*/'||CHR(37);
  BEGIN
    IF   p_sql_text LIKE k_appl_handle_prefix||'addTransactionRow'||k_appl_handle_suffix 
      OR p_sql_text LIKE k_appl_handle_prefix||'checkStartRowValid'||k_appl_handle_suffix 
    THEN RETURN gk_appl_cat_1;
    ELSIF p_sql_text LIKE k_appl_handle_prefix||'SPM:CP'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'findMatchingRow'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'readTransactionsSince'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'writeTransactionKeys'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'setValueByUpdate'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'setValue'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'deleteValue'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'exists'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'existsUnique'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'updateIdentityValue'||k_appl_handle_suffix 
      OR  p_sql_text LIKE 'LOCK TABLE'||CHR(37) 
      OR  p_sql_text LIKE '/* null */ LOCK TABLE'||CHR(37)
      OR  p_sql_text LIKE k_appl_handle_prefix||'getTransactionProgress'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'recordTransactionState'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'checkEndRowValid'||k_appl_handle_suffix
      OR  p_sql_text LIKE k_appl_handle_prefix||'getMaxTransactionCommitID'||k_appl_handle_suffix 
    THEN RETURN gk_appl_cat_2;
    ELSIF p_sql_text LIKE k_appl_handle_prefix||'getValues'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'getNextIdentityValue'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'performScanQuery'||k_appl_handle_suffix
      OR  p_sql_text LIKE k_appl_handle_prefix||'performSnapshotScanQuery'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'performFirstRowsScanQuery'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'performStartScanValues'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'performContinuedScanValues'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'bucketIndexSelect'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'bucketKeySelect'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'selectBuckets'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'getAutoSequences'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'bucketValueSelect'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'countTransactions'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch snapshots'||k_appl_handle_suffix 
    THEN RETURN gk_appl_cat_3;
    ELSIF p_sql_text LIKE k_appl_handle_prefix||'populateBucketGCWorkspace'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'deleteBucketGarbage'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'Populate workspace'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'Delete garbage fOR  transaction GC'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'Delete garbage in KTK GC'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'hashBucket'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'validateIfWorkspaceEmpty'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'getGCLogEntries'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'gcEventTryInsert'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'countAllRows'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'Delete rows from'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'hashSnapshot'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'countKtkRows'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'gcEventMaxId'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'secondsSinceLastGcEvent'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'getMaxTransactionOlderThan'||k_appl_handle_suffix 
    THEN RETURN gk_appl_cat_4;
    ELSE RETURN 'Unknown';
    END IF;
  END application_category;
BEGIN
  FOR i IN (SELECT sql_id, 
                   exact_matching_signature signature,
                   SUM(executions) executions,
                   ROUND(SUM(elapsed_time)/SUM(executions)/1e3,3) ms_per_exec, 
                   ROUND(SUM(rows_processed)/SUM(executions)/1e3,3) rows_per_exec, 
                   ROUND(SUM(buffer_gets)/SUM(executions)/1e3,3) bg_per_exec, 
                   CASE COUNT(DISTINCT sql_plan_baseline) WHEN 0 THEN 'N' ELSE 'Y' END baselines,
                   CASE COUNT(DISTINCT sql_profile) WHEN 0 THEN 'N' ELSE 'Y' END profiles,
                   CASE COUNT(DISTINCT sql_patch) WHEN 0 THEN 'N' ELSE 'Y' END patches,
                   MAX(last_active_time) last_active_time,
                   sql_text
              FROM v$sql
             WHERE UPPER(sql_text) LIKE UPPER('%&&search_string.%')
               AND UPPER(sql_text) NOT LIKE '%V$SQL%' -- filters out this query and similar ones
               AND executions > 0 -- avoid division by zero error on HAVING
               AND parsing_user_id > 0 -- exclude sys
               AND parsing_schema_id > 0 -- exclude sys
               AND sql_text NOT LIKE '%RESULT_CACHE%'
               AND sql_text NOT LIKE '%EXCLUDE_ME%'
               AND exact_matching_signature > 0
             GROUP BY
                   sql_id,
                   exact_matching_signature,
                   sql_text
            HAVING SUM(elapsed_time)/SUM(executions)/1e3 > &&ms_per_exec.) 
  LOOP
    IF application_category(i.sql_text) = 'Scan' THEN
      DBMS_OUTPUT.PUT_LINE(RPAD('PRO ', 120, '-'));
      DBMS_OUTPUT.PUT_LINE('PRO');
      DBMS_OUTPUT.PUT_LINE('PRO SQL_ID       : '||i.sql_id);
      DBMS_OUTPUT.PUT_LINE('PRO SIGNATURE    : '||i.signature);
      DBMS_OUTPUT.PUT_LINE('PRO EXECUTIONS   : '||TRIM(TO_CHAR(i.executions, '999,999,999,990')));
      DBMS_OUTPUT.PUT_LINE('PRO MS_PER_EXEC  : '||TRIM(TO_CHAR(i.ms_per_exec, '999,999,990.000')));
      DBMS_OUTPUT.PUT_LINE('PRO ROWS_PER_EXEC: '||TRIM(TO_CHAR(i.rows_per_exec, '999,999,990.000')));
      DBMS_OUTPUT.PUT_LINE('PRO BG_PER_EXEC  : '||TRIM(TO_CHAR(i.bg_per_exec, '999,999,990.000')));
      DBMS_OUTPUT.PUT_LINE('PRO BASELINE?    : '||i.baselines);
      DBMS_OUTPUT.PUT_LINE('PRO PROFILE?     : '||i.profiles);
      DBMS_OUTPUT.PUT_LINE('PRO SQL_PATCH?   : '||i.patches);
      DBMS_OUTPUT.PUT_LINE('PRO LAST_ACTIVE  : '||TO_CHAR(i.last_active_time,'YYYY-MM-DD"T"HH24:MI:SS'));
      DBMS_OUTPUT.PUT_LINE('PRO SQL_TEXT     : '||REPLACE(SUBSTR(i.sql_text, 1, 100), CHR(10), CHR(32)));
      DBMS_OUTPUT.PUT_LINE('PRO');
      --
      DBMS_OUTPUT.PUT_LINE('@@sqlperf.sql '||i.sql_id);
      DBMS_OUTPUT.PUT_LINE('PRO');
      --
      FOR j IN (SELECT sql_handle, plan_name FROM dba_sql_plan_baselines WHERE signature = i.signature AND enabled = 'YES' AND accepted = 'YES')
      LOOP
        DBMS_OUTPUT.PUT_LINE('VAR l_plans NUMBER;');
        DBMS_OUTPUT.PUT_LINE('EXEC :l_plans := SYS.DBMS_SPM.alter_sql_plan_baseline(sql_handle => '''||j.sql_handle||''', plan_name => '''||j.plan_name||''', attribute_name => ''ENABLED'', attribute_value => ''NO'');');
        DBMS_OUTPUT.PUT_LINE('PRINT l_plans;');
      END LOOP;
      IF i.baselines = 'Y' THEN
        DBMS_OUTPUT.PUT_LINE('PRO');
      END IF;
      --
      FOR j IN (SELECT name FROM dba_sql_profiles WHERE signature = i.signature)
      LOOP
        DBMS_OUTPUT.PUT_LINE('EXEC SYS.DBMS_SQLTUNE.drop_sql_profile(name => '''||j.name||''');');
      END LOOP;
      IF i.profiles = 'Y' THEN
        DBMS_OUTPUT.PUT_LINE('PRO');
      END IF;
      --
      FOR j IN (SELECT name FROM dba_sql_patches WHERE signature = i.signature)
      LOOP
        DBMS_OUTPUT.PUT_LINE('EXEC SYS.DBMS_SQLDIAG.drop_sql_patch(name => '''||j.name||''', ignore => TRUE);');
      END LOOP;
      IF i.patches = 'Y' THEN
        DBMS_OUTPUT.PUT_LINE('PRO');
      END IF;
      --
      DBMS_OUTPUT.PUT_LINE('@@sqlpatch.sql '||i.sql_id||' "&&hints_text."');
      DBMS_OUTPUT.PUT_LINE('PRO');
      --
      DBMS_OUTPUT.PUT_LINE('EXEC DBMS_LOOK.sleep(10);');
      DBMS_OUTPUT.PUT_LINE('PRO');
      --
      DBMS_OUTPUT.PUT_LINE('@@sqlperf.sql '||i.sql_id);
      DBMS_OUTPUT.PUT_LINE('PRO');
    END IF;
  END LOOP;
  DBMS_OUTPUT.PUT_LINE(RPAD('PRO ', 120, '-'));
END;
/
SPO OFF;