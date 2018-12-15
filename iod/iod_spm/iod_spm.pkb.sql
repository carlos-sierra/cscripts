CREATE OR REPLACE PACKAGE BODY &&1..iod_spm AS
/* $Header: iod_spm.pkb.sql &&library_version. carlos.sierra $ */
/* ------------------------------------------------------------------------------------ */  
gk_date_format                 CONSTANT VARCHAR2(30) := 'YYYY-MM-DD"T"HH24:MI:SS';
gk_output_part_1_length        CONSTANT INTEGER := 35;
gk_output_metrics_length       CONSTANT INTEGER := 15;                  
gk_output_part_2_length        CONSTANT INTEGER := 10 * (gk_output_metrics_length + 1);                  
gk_appl_cat_1                  CONSTANT VARCHAR2(10) := 'BeginTx'; -- 1st application category
gk_appl_cat_2                  CONSTANT VARCHAR2(10) := 'CommitTx'; -- 2nd application category
gk_appl_cat_3                  CONSTANT VARCHAR2(10) := 'Scan'; -- 3rd application category
gk_appl_cat_4                  CONSTANT VARCHAR2(10) := 'GC'; -- 4th application category
/* ------------------------------------------------------------------------------------ */  
FUNCTION application_category (p_sql_text IN VARCHAR2)
RETURN VARCHAR2
IS
  k_appl_handle_prefix           CONSTANT VARCHAR2(30) := '/*'||CHR(37);
  k_appl_handle_suffix           CONSTANT VARCHAR2(30) := CHR(37)||'*/'||CHR(37);
BEGIN
  IF   p_sql_text LIKE k_appl_handle_prefix||'addTransactionRow'||k_appl_handle_suffix 
    OR p_sql_text LIKE k_appl_handle_prefix||'checkStartRowValid'||k_appl_handle_suffix 
  THEN RETURN gk_appl_cat_1;
  ELSIF p_sql_text LIKE k_appl_handle_prefix||'checkEndRowValid'||k_appl_handle_suffix
    OR  p_sql_text LIKE k_appl_handle_prefix||'deleteValue'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'exists'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch commit by idempotency token'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'findMatchingRow'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getMaxTransactionCommitID'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getTransactionProgress'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'lockForCommit'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'lockKievTransactor'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'putBucket'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'readTransactionsSince'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'recordTransactionState'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'setValue'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'updateIdentityValue'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'updateNextKievTransID'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'updateTransactorState'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'upsert_transactor_state'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'writeTransactionKeys'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'SPM:CP'||k_appl_handle_suffix 
    OR  LOWER(p_sql_text) LIKE CHR(37)||'lock table kievtransactions'||CHR(37) 
  THEN RETURN gk_appl_cat_2;
  ELSIF p_sql_text LIKE k_appl_handle_prefix||'bucketIndexSelect'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'bucketKeySelect'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'bucketValueSelect'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'countTransactions'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch snapshots'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getAutoSequences'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getNextIdentityValue'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getValues'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'performContinuedScanValues'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'performScanQuery'||k_appl_handle_suffix
    OR  p_sql_text LIKE k_appl_handle_prefix||'performSnapshotScanQuery'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'performFirstRowsScanQuery'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'performStartScanValues'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'selectBuckets'||k_appl_handle_suffix 
  THEN RETURN gk_appl_cat_3;
  ELSIF p_sql_text LIKE k_appl_handle_prefix||'countAllRows'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'countKtkRows'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Delete garbage'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Delete rows from'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'deleteBucketGarbage'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'gcEventMaxId'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'gcEventTryInsert'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getGCLogEntries'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getMaxTransactionOlderThan'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'hashBucket'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'hashSnapshot'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Populate workspace'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'populateBucketGCWorkspace'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'secondsSinceLastGcEvent'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'validateIfWorkspaceEmpty'||k_appl_handle_suffix 
  THEN RETURN gk_appl_cat_4;
  ELSE RETURN 'Unknown';
  END IF;
END application_category;
/* ------------------------------------------------------------------------------------ */  
PROCEDURE output (p_line IN VARCHAR2, p_alert_log IN BOOLEAN DEFAULT FALSE) 
IS
BEGIN
  DBMS_OUTPUT.PUT_LINE (a => SUBSTR(p_line, 1, gk_output_part_1_length + 5 + gk_output_part_2_length));
  --
  IF p_alert_log THEN
    SYS.DBMS_SYSTEM.KSDWRT(dest => 2, tst => p_line); -- write to alert log
  END IF;
END output;
/* ------------------------------------------------------------------------------------ */  
PROCEDURE output (p_col_1 IN VARCHAR2, p_col_2 IN VARCHAR2) 
IS
BEGIN
  IF TRIM(p_col_2) IS NOT NULL THEN
    output (p_line => '| '||RPAD(SUBSTR(NVL(p_col_1, ' '), 1, gk_output_part_1_length), gk_output_part_1_length)||' : '||SUBSTR(p_col_2, 1, gk_output_part_2_length));
    IF LENGTH(p_col_2) > gk_output_part_2_length THEN
      output(p_col_1 => NULL, p_col_2 => SUBSTR(p_col_2, gk_output_part_2_length + 1)); -- wrap p_col_2
    END IF;
  END IF;
END output;
/* ------------------------------------------------------------------------------------ */  
/* ORA-13831: SQL profile name specified is invalid 
*/
PROCEDURE workaround_ora_13831_internal ( 
  p_report_only    IN  VARCHAR2 DEFAULT NULL, -- (Y|N) when Y then only produces report and changes nothing
  x_plans_found    OUT INTEGER,
  x_plans_disabled OUT INTEGER
)
IS
  l_cursor_id INTEGER;
  l_statement CLOB;
  l_rows      INTEGER;
  l_plans_found_pdb INTEGER := 0;
  l_plans_disabled_pdb INTEGER := 0;
  l_plans_found_cdb INTEGER := 0;
  l_plans_disabled_cdb INTEGER := 0;
BEGIN
  output(RPAD('+', gk_output_part_1_length + 5 + gk_output_part_2_length, '-'));
  output('ORA-13831 PID<>PH2 PREVENTION', 'CDB SCREENING');
  output(RPAD('+', gk_output_part_1_length + 5 + gk_output_part_2_length, '-'));
  l_statement := 
  q'{DECLARE PRAGMA AUTONOMOUS_TRANSACTION; }'||CHR(10)||
  q'{  l_plans INTEGER; }'||CHR(10)||
  q'{  l_plans_f INTEGER := 0; }'||CHR(10)||
  q'{  l_plans_d INTEGER := 0; }'||CHR(10)||
  q'{BEGIN }'||CHR(10)||
  --q'{  SYS.DBMS_SYSTEM.KSDWRT(1, 'iod_spm.workaround_ora_13831_internal '||SYS_CONTEXT('USERENV', 'CON_NAME')); }'||CHR(10)||
  q'{  FOR i IN (SELECT t.sql_handle, }'||CHR(10)||
  q'{                   o.name plan_name, }'||CHR(10)||
  q'{                   p.plan_id, }'||CHR(10)||
  q'{                   CASE WHEN p.other_xml IS NOT NULL THEN TO_NUMBER(extractvalue(xmltype(p.other_xml),'/*/info[@type = "plan_hash_2"]')) END plan_hash_2, }'||CHR(10)||
  q'{                   a.description }'||CHR(10)||
  q'{              FROM sys.sqlobj$plan p, }'||CHR(10)||
  q'{                   sys.sqlobj$ o, }'||CHR(10)||
  q'{                   sys.sqlobj$auxdata a, }'||CHR(10)||
  q'{                   sys.sql$text t }'||CHR(10)||
  q'{             WHERE p.obj_type = 2 /* 1=profile, 2=baseline, 3=patch */ }'||CHR(10)||
  q'{               AND p.id = 1 }'||CHR(10)||
  q'{               AND p.other_xml IS NOT NULL }'||CHR(10)||
  q'{               -- plan_hash_value ignoring transient object names (must be same than plan_id) }'||CHR(10)||
  q'{               AND p.plan_id <> CASE WHEN p.other_xml IS NOT NULL THEN TO_NUMBER(extractvalue(xmltype(p.other_xml),'/*/info[@type = "plan_hash_2"]')) END }'||CHR(10)||
  q'{               AND o.obj_type = 2 }'||CHR(10)||
  q'{               AND o.signature = p.signature }'||CHR(10)||
  q'{               AND o.plan_id = p.plan_id }'||CHR(10)||
  q'{               AND BITAND(o.flags, 1) = 1 /* enabled */ }'||CHR(10)||
  q'{               AND a.obj_type = o.obj_type }'||CHR(10)||
  q'{               AND a.signature = p.signature }'||CHR(10)||
  q'{               AND a.plan_id = p.plan_id }'||CHR(10)||
  q'{               AND a.parsing_schema_name NOT IN ('SYS', 'C##IOD') }'||CHR(10)||
  q'{               AND t.signature = p.signature }'||CHR(10)||
  q'{             ORDER BY }'||CHR(10)||
  q'{                   t.sql_handle, }'||CHR(10)||
  q'{                   o.name) }'||CHR(10)||
  q'{  LOOP }'||CHR(10)||
  --q'{    SYS.DBMS_SYSTEM.KSDWRT(1, 'iod_spm.workaround_ora_13831_internal '||i.sql_handle||' '||i.plan_name||' '||i.plan_id||' '||i.plan_hash_2||' '||i.description); }'||CHR(10)||
  q'{    l_plans_f := l_plans_f + 1; }'||CHR(10)||
  q'{    IF :report_only = 'N' THEN }'||CHR(10)||
  q'{      l_plans := }'||CHR(10)||
  q'{      DBMS_SPM.ALTER_SQL_PLAN_BASELINE ( }'||CHR(10)||
  q'{        sql_handle      => i.sql_handle, }'||CHR(10)||
  q'{        plan_name       => i.plan_name, }'||CHR(10)||
  q'{        attribute_name  => 'ENABLED', }'||CHR(10)||
  q'{        attribute_value => 'NO' }'||CHR(10)||
  q'{      ); }'||CHR(10)||
  q'{      l_plans_d := l_plans_d + l_plans; }'||CHR(10)||
  q'{      l_plans := }'||CHR(10)||
  q'{      DBMS_SPM.ALTER_SQL_PLAN_BASELINE ( }'||CHR(10)||
  q'{        sql_handle      => i.sql_handle, }'||CHR(10)||
  q'{        plan_name       => i.plan_name, }'||CHR(10)||
  q'{        attribute_name  => 'DESCRIPTION', }'||CHR(10)||
  q'{        attribute_value => i.description||' ERR-00050: ORA-13831 PID<>PH2 PID:'||i.plan_id||' PH2: '||i.plan_hash_2||' DISABLED='||TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS') }'||CHR(10)||
  q'{      ); }'||CHR(10)||
  q'{    END IF; }'||CHR(10)||
  q'{  END LOOP; }'||CHR(10)||
  q'{  :plans_found := l_plans_f; }'||CHR(10)||
  q'{  :plans_disabled := l_plans_d; }'||CHR(10)||
  q'{COMMIT; END; }';
  l_cursor_id := DBMS_SQL.OPEN_CURSOR;
  FOR i IN (SELECT con_id,
                   name pdb_name
              FROM v$pdbs
             WHERE con_id > 2
               AND open_mode = 'READ WRITE'
             ORDER BY
                   con_id)
  LOOP
    output(i.pdb_name);
    DECLARE
      self_deadlock EXCEPTION;
      PRAGMA EXCEPTION_INIT(self_deadlock, -04024); -- ORA-04024: self-deadlock detected while trying to mutex pin cursor
      sessions_exceeded EXCEPTION;
      PRAGMA EXCEPTION_INIT(sessions_exceeded, -00018); -- ORA-00018: maximum number of sessions exceeded
    BEGIN
      l_plans_found_pdb := 0;
      l_plans_disabled_pdb := 0;
      DBMS_SQL.PARSE(c => l_cursor_id, statement => l_statement, language_flag => DBMS_SQL.NATIVE, container => i.pdb_name);
      DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':report_only', value => p_report_only);
      DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':plans_found', value => l_plans_found_pdb);
      DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':plans_disabled', value => l_plans_disabled_pdb);
      l_rows := DBMS_SQL.EXECUTE(c => l_cursor_id);
      DBMS_SQL.VARIABLE_VALUE(c => l_cursor_id, name => ':plans_found', value => l_plans_found_pdb);
      DBMS_SQL.VARIABLE_VALUE(c => l_cursor_id, name => ':plans_disabled', value => l_plans_disabled_pdb);
      IF l_plans_found_pdb > 0 THEN
        IF l_plans_found_cdb = 0 THEN
          output(RPAD('+', gk_output_part_1_length + 5 + gk_output_part_2_length, '-'));
          output('|');
        END IF;
        output('ORA-13831 PID<>PH2 ERR-00050', i.pdb_name||'('||i.con_id||')');
        output('Plans Found', l_plans_found_pdb);
        output('Plans Disabled', l_plans_disabled_pdb);
        output('|');
        l_plans_found_cdb := l_plans_found_cdb + l_plans_found_pdb;
        l_plans_disabled_cdb := l_plans_disabled_cdb + l_plans_disabled_pdb;
      END IF;
    EXCEPTION
      WHEN self_deadlock THEN
        output('ORA-04024: self-deadlock detected while trying to mutex pin cursor - on workaround_ora_13831_internal during '||i.pdb_name||' scan');
        --RAISE self_deadlock;
      WHEN sessions_exceeded THEN
        output('ORA-00018: maximum number of sessions exceeded - on workaround_ora_13831_internal during '||i.pdb_name||' scan');
    END;
  END LOOP;
  DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
  IF l_plans_found_cdb > 0 THEN
    output('ORA-13831 PID<>PH2 ERR-00050', 'CDB TOTAL');
    output('Plans Found', l_plans_found_cdb);
    output('Plans Disabled', l_plans_disabled_cdb);
    output('|');
    output(RPAD('+', gk_output_part_1_length + 5 + gk_output_part_2_length, '-'));
  END IF;
  x_plans_found := l_plans_found_cdb;
  x_plans_disabled := l_plans_disabled_cdb;
END workaround_ora_13831_internal;
/* ------------------------------------------------------------------------------------ */  
PROCEDURE workaround_ora_13831 (
  p_report_only IN VARCHAR2 DEFAULT NULL -- (Y|N) when Y then only produces report and changes nothing
)
IS
  l_plans_found INTEGER;
  l_plans_disabled INTEGER;
BEGIN
  workaround_ora_13831_internal (
    p_report_only    => p_report_only,
    x_plans_found    => l_plans_found,
    x_plans_disabled => l_plans_disabled
  );
END workaround_ora_13831;
/* ------------------------------------------------------------------------------------ */  
/* An uncaught error happened in display_sql_plan_baseline : ORA-06502: PL/SQL: numeric or value error
   ORA-06512: at "SYS.XMLTYPE", line 272
   ORA-06512: at line 1
*/
PROCEDURE workaround_ora_06512_internal ( 
  p_report_only    IN  VARCHAR2 DEFAULT NULL, -- (Y|N) when Y then only produces report and changes nothing
  x_plans_found    OUT INTEGER,
  x_plans_disabled OUT INTEGER
)
IS
  l_cursor_id INTEGER;
  l_statement CLOB;
  l_rows      INTEGER;
  l_plans_found_pdb INTEGER := 0;
  l_plans_disabled_pdb INTEGER := 0;
  l_plans_found_cdb INTEGER := 0;
  l_plans_disabled_cdb INTEGER := 0;
BEGIN
  output(RPAD('+', gk_output_part_1_length + 5 + gk_output_part_2_length, '-'));
  output('ORA-06512 MISSING PID PREVENTION', 'CDB SCREENING');
  output(RPAD('+', gk_output_part_1_length + 5 + gk_output_part_2_length, '-'));
  l_statement := 
  q'{DECLARE PRAGMA AUTONOMOUS_TRANSACTION; }'||CHR(10)||
  q'{  l_plans INTEGER; }'||CHR(10)||
  q'{  l_plans_f INTEGER := 0; }'||CHR(10)||
  q'{  l_plans_d INTEGER := 0; }'||CHR(10)||
  q'{BEGIN }'||CHR(10)||
  --q'{  SYS.DBMS_SYSTEM.KSDWRT(1, 'iod_spm.workaround_ora_06512_internal '||SYS_CONTEXT('USERENV', 'CON_NAME')); }'||CHR(10)||
  q'{  FOR i IN (SELECT t.sql_handle, }'||CHR(10)||
  q'{                   o.name plan_name, }'||CHR(10)||
  q'{                   a.description }'||CHR(10)||
  q'{              FROM sys.sqlobj$ o, }'||CHR(10)||
  q'{                   sys.sql$text t, }'||CHR(10)||
  q'{                   sys.sqlobj$auxdata a }'||CHR(10)||
  q'{             WHERE o.obj_type = 2 }'||CHR(10)||
  q'{               AND BITAND(o.flags, 1) = 1 /* enabled */ }'||CHR(10)||
  q'{               AND t.signature = o.signature }'||CHR(10)||
  q'{               AND a.obj_type = o.obj_type }'||CHR(10)||
  q'{               AND a.signature = o.signature }'||CHR(10)||
  q'{               AND a.plan_id = o.plan_id }'||CHR(10)||
  q'{               AND a.parsing_schema_name NOT IN ('SYS', 'C##IOD') }'||CHR(10)||
  q'{               AND NOT EXISTS  }'||CHR(10)||
  q'{                   ( SELECT NULL }'||CHR(10)||
  q'{                       FROM sys.sqlobj$plan p }'||CHR(10)||
  q'{                      WHERE p.signature = o.signature }'||CHR(10)||
  q'{                        AND p.obj_type = o.obj_type }'||CHR(10)||
  q'{                        AND p.plan_id = o.plan_id }'||CHR(10)||
  q'{                    ) }'||CHR(10)||
  q'{             ORDER BY }'||CHR(10)||
  q'{                   o.signature, }'||CHR(10)||
  q'{                   o.plan_id) }'||CHR(10)||
  q'{  LOOP }'||CHR(10)||
  --q'{    SYS.DBMS_SYSTEM.KSDWRT(1, 'iod_spm.workaround_ora_06512_internal '||i.sql_handle||' '||i.plan_name||' '||i.description); }'||CHR(10)||
  q'{    l_plans_f := l_plans_f + 1; }'||CHR(10)||
  q'{    IF :report_only = 'N' THEN }'||CHR(10)||
  q'{      l_plans := }'||CHR(10)||
  q'{      DBMS_SPM.ALTER_SQL_PLAN_BASELINE ( }'||CHR(10)||
  q'{        sql_handle      => i.sql_handle, }'||CHR(10)||
  q'{        plan_name       => i.plan_name, }'||CHR(10)||
  q'{        attribute_name  => 'ENABLED', }'||CHR(10)||
  q'{        attribute_value => 'NO' }'||CHR(10)||
  q'{      ); }'||CHR(10)||
  q'{      l_plans_d := l_plans_d + l_plans; }'||CHR(10)||
  q'{      l_plans := }'||CHR(10)||
  q'{      DBMS_SPM.ALTER_SQL_PLAN_BASELINE ( }'||CHR(10)||
  q'{        sql_handle      => i.sql_handle, }'||CHR(10)||
  q'{        plan_name       => i.plan_name, }'||CHR(10)||
  q'{        attribute_name  => 'DESCRIPTION', }'||CHR(10)||
  q'{        attribute_value => i.description||' ERR-00060: ORA-06512 MISSING PID DISABLED='||TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS') }'||CHR(10)||
  q'{      ); }'||CHR(10)||
  q'{    END IF; }'||CHR(10)||
  q'{  END LOOP; }'||CHR(10)||
  q'{  :plans_found := l_plans_f; }'||CHR(10)||
  q'{  :plans_disabled := l_plans_d; }'||CHR(10)||
  q'{COMMIT; END; }';
  l_cursor_id := DBMS_SQL.OPEN_CURSOR;
  FOR i IN (SELECT con_id,
                   name pdb_name
              FROM v$pdbs
             WHERE con_id > 2
               AND open_mode = 'READ WRITE'
             ORDER BY
                   con_id)
  LOOP
    output(i.pdb_name);
    DECLARE
      self_deadlock EXCEPTION;
      PRAGMA EXCEPTION_INIT(self_deadlock, -04024); -- ORA-04024: self-deadlock detected while trying to mutex pin cursor
      sessions_exceeded EXCEPTION;
      PRAGMA EXCEPTION_INIT(sessions_exceeded, -00018); -- ORA-00018: maximum number of sessions exceeded
    BEGIN
      l_plans_found_pdb := 0;
      l_plans_disabled_pdb := 0;
      DBMS_SQL.PARSE(c => l_cursor_id, statement => l_statement, language_flag => DBMS_SQL.NATIVE, container => i.pdb_name);
      DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':report_only', value => p_report_only);
      DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':plans_found', value => l_plans_found_pdb);
      DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':plans_disabled', value => l_plans_disabled_pdb);
      l_rows := DBMS_SQL.EXECUTE(c => l_cursor_id);
      DBMS_SQL.VARIABLE_VALUE(c => l_cursor_id, name => ':plans_found', value => l_plans_found_pdb);
      DBMS_SQL.VARIABLE_VALUE(c => l_cursor_id, name => ':plans_disabled', value => l_plans_disabled_pdb);
      IF l_plans_found_pdb > 0 THEN
        IF l_plans_found_cdb = 0 THEN
          output(RPAD('+', gk_output_part_1_length + 5 + gk_output_part_2_length, '-'));
          output('|');
        END IF;
        output('ORA-06512 MISSING PID ERR-00060', i.pdb_name||'('||i.con_id||')');
        output('Plans Found', l_plans_found_pdb);
        output('Plans Disabled', l_plans_disabled_pdb);
        output('|');
        l_plans_found_cdb := l_plans_found_cdb + l_plans_found_pdb;
        l_plans_disabled_cdb := l_plans_disabled_cdb + l_plans_disabled_pdb;
      END IF;
    EXCEPTION
      WHEN self_deadlock THEN
        output('ORA-04024: self-deadlock detected while trying to mutex pin cursor - on workaround_ora_06512_internal during '||i.pdb_name||' scan');
        --RAISE self_deadlock;
      WHEN sessions_exceeded THEN
        output('ORA-00018: maximum number of sessions exceeded - on workaround_ora_06512_internal during '||i.pdb_name||' scan');
    END;
  END LOOP;
  DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
  IF l_plans_found_cdb > 0 THEN
    output('ORA-06512 MISSING PID ERR-00060', 'CDB TOTAL');
    output('Plans Found', l_plans_found_cdb);
    output('Plans Disabled', l_plans_disabled_cdb);
    output('|');
    output(RPAD('+', gk_output_part_1_length + 5 + gk_output_part_2_length, '-'));
  END IF;
  x_plans_found := l_plans_found_cdb;
  x_plans_disabled := l_plans_disabled_cdb;
END workaround_ora_06512_internal;
/* ------------------------------------------------------------------------------------ */  
PROCEDURE workaround_ora_06512 (
  p_report_only IN VARCHAR2 DEFAULT NULL -- (Y|N) when Y then only produces report and changes nothing
)
IS
  l_plans_found INTEGER;
  l_plans_disabled INTEGER;
BEGIN
  workaround_ora_06512_internal (
    p_report_only    => p_report_only,
    x_plans_found    => l_plans_found,
    x_plans_disabled => l_plans_disabled
  );
END workaround_ora_06512;
/* ------------------------------------------------------------------------------------ */  
PROCEDURE maintain_plans_internal (
  p_report_only                  IN VARCHAR2 DEFAULT NULL, -- (Y|N) when Y then only produces report and changes nothing
  p_kiev_pdbs_only               IN VARCHAR2 DEFAULT NULL, -- (Y|N) when Y then execute only on KIEV PDBs
  p_create_spm_limit             IN NUMBER   DEFAULT NULL, -- limits the number of SPMs to be created in one execution
  p_promote_spm_limit            IN NUMBER   DEFAULT NULL, -- limits the number of SPMs to be promoted to "FIXED" in one execution
  p_disable_spm_limit            IN NUMBER   DEFAULT NULL, -- limits the number of SPMs to be demoted to "DISABLE" in one execution
  p_aggressiveness               IN NUMBER   DEFAULT NULL, -- (1-5) range between 1 to 5 where 1 is conservative and 5 is aggresive
  p_repo_rejected_candidates     IN VARCHAR2 DEFAULT 'Y',  -- (Y|N) include on report rejected candidates
  p_repo_non_promoted_spb        IN VARCHAR2 DEFAULT 'Y',  -- (Y|N) include on report non-fixed SPB that is not getting promoted to "FIXED"
  p_repo_fixed_spb               IN VARCHAR2 DEFAULT 'Y',  -- (Y|N) include on report "FIXED" SPB
  p_pdb_name                     IN VARCHAR2 DEFAULT NULL, -- evaluate only this one PDB
  p_sql_id                       IN VARCHAR2 DEFAULT NULL, -- evaluate only this one SQL
  p_incl_plans_appl_1            IN VARCHAR2 DEFAULT 'Y',  -- (Y|N) include SQL from 1st application (BeginTx)
  p_incl_plans_appl_2            IN VARCHAR2 DEFAULT 'Y',  -- (Y|N) include SQL from 2nd application (CommitTx)
  p_incl_plans_appl_3            IN VARCHAR2 DEFAULT 'Y',  -- (Y|N) include SQL from 3rd application (Read)
  p_incl_plans_appl_4            IN VARCHAR2 DEFAULT 'Y',  -- (Y|N) include SQL from 4th application (GC)
  p_incl_plans_non_appl          IN VARCHAR2 DEFAULT 'Y',  -- (N|Y) consider as candidate SQL not qualified as "application module"
  p_execs_candidate              IN NUMBER   DEFAULT NULL, -- a plan must be executed these many times to be a candidate
  p_secs_per_exec_cand           IN NUMBER   DEFAULT NULL, -- a plan must perform better than this threshold to be a candidate
  p_first_load_time_days_cand    IN NUMBER   DEFAULT NULL, -- a sql must be loaded into memory at least this many days before it is considered as candidate
  p_spb_thershold_over_cat_max   IN NUMBER   DEFAULT NULL, -- plan must perform better than this many times the category max threshold
  p_spb_thershold_over_spf_perf  IN NUMBER   DEFAULT NULL, -- plan must perform better than this many times the its own performance at the time SPB was created
  p_spb_cap_over_cat_max         IN NUMBER   DEFAULT NULL, -- plan must perform better than this many times the category max threshold, regardless if fixed or number of executions
  p_spb_cap_over_spf_perf        IN NUMBER   DEFAULT NULL, -- plan must perform better than this many times the its own performance at the time SPB was created, regardless if fixed or number of executions
  p_awr_plan_days                IN NUMBER   DEFAULT NULL, -- amount of days to consider from AWR plan history assuming retention is at least this long
  p_awr_days                     IN NUMBER   DEFAULT NULL, -- amount of days to consider from AWR metrics history assuming retention is at least this long
  p_cur_days                     IN NUMBER   DEFAULT NULL, -- cursor must be active within the past k_cur_days to be considered
  x_plan_candidates              OUT NUMBER, -- Candidates
  x_qualified_for_spb_creation   OUT NUMBER, -- SPBs Qualified for Creation
  x_spbs_created                 OUT NUMBER, -- SPBs Created
  x_qualified_for_spb_promotion  OUT NUMBER, -- SPBs Qualified for Promotion
  x_spbs_promoted                OUT NUMBER, -- SPBs Promoted
  x_qualified_for_spb_demotion   OUT NUMBER, -- SPBs Qualified for Demotion
  x_spbs_demoted                 OUT NUMBER, -- SPBs Demoted
  x_spbs_already_fixed           OUT NUMBER, -- SPBs already Fixed
  x_found_13831_with_issues      OUT NUMBER, -- Found Plans with issues (ORA-13831)
  x_disabled_13831_with_issues   OUT NUMBER, -- Disabled Plans with issues (ORA-13831)
  x_found_06512_with_issues      OUT NUMBER, -- Found Plans with issues (ORA-06512)
  x_disabled_06512_with_issues   OUT NUMBER  -- Disabled Plans with issues (ORA-06512)
)
IS
/* ------------------------------------------------------------------------------------ */
  k_report_only                  CONSTANT CHAR(1) := NVL(UPPER(SUBSTR(TRIM(p_report_only), 1, 1)), 'Y'); -- (Y|N) when Y then only produces report and changes nothing
  k_kiev_pdbs_only               CONSTANT CHAR(1) := NVL(UPPER(SUBSTR(TRIM(p_kiev_pdbs_only), 1, 1)), 'Y'); -- (Y|N) when Y then execute only on KIEV PDBs
  k_create_spm_limit             CONSTANT NUMBER := NVL(p_create_spm_limit, 10000); -- limits the number of SPMs to be created in one execution
  k_promote_spm_limit            CONSTANT NUMBER := NVL(p_promote_spm_limit, 10000); -- limits the number of SPMs to be promoted to "FIXED" in one execution
  k_disable_spm_limit            CONSTANT NUMBER := NVL(p_disable_spm_limit, 10000); -- limits the number of SPMs to be demoted to "DISABLE" in one execution
  k_aggressiveness_upper_limit   CONSTANT NUMBER := 5; -- (2-5) levels the aggressiveness parameter can take (calibrated to value of 5)
  k_aggressiveness               CONSTANT NUMBER := GREATEST(LEAST(NVL(ROUND(p_aggressiveness), 1), k_aggressiveness_upper_limit), 1); -- (1-k_aggressiveness_upper_limit) range between 1 to k_aggressiveness_upper_limit where 1 is conservative and k_aggressiveness_upper_limit is most aggresive
  k_repo_rejected_candidates     CONSTANT CHAR(1) := NVL(UPPER(SUBSTR(TRIM(p_repo_rejected_candidates), 1, 1)), 'Y'); -- (Y|N) include on report rejected candidates
  k_repo_non_promoted_spb        CONSTANT CHAR(1) := NVL(UPPER(SUBSTR(TRIM(p_repo_non_promoted_spb), 1, 1)), 'Y'); -- (Y|N) include on report non-fixed SPB that is not getting promoted to "FIXED"
  k_repo_fixed_spb               CONSTANT CHAR(1) := NVL(UPPER(SUBSTR(TRIM(p_repo_fixed_spb), 1, 1)), 'Y'); -- (Y|N) include on report "FIXED" SPB
  k_pdb_name                     CONSTANT VARCHAR2(30) := SUBSTR(TRIM(p_pdb_name), 1, 30); -- evaluate only this one PDB
  k_sql_id                       CONSTANT VARCHAR2(13) := SUBSTR(TRIM(p_sql_id), 1, 13); -- evaluate only this one SQL
  k_incl_plans_appl_1            CONSTANT CHAR(1) := NVL(UPPER(SUBSTR(TRIM(p_incl_plans_appl_1), 1, 1)), 'Y'); -- (Y|N) include SQL from 1st application (BeginTx)
  k_incl_plans_appl_2            CONSTANT CHAR(1) := NVL(UPPER(SUBSTR(TRIM(p_incl_plans_appl_2), 1, 1)), 'Y'); -- (Y|N) include SQL from 2nd application (CommitTx)
  k_incl_plans_appl_3            CONSTANT CHAR(1) := NVL(UPPER(SUBSTR(TRIM(p_incl_plans_appl_3), 1, 1)), 'Y'); -- (Y|N) include SQL from 3rd application (Read)
  k_incl_plans_appl_4            CONSTANT CHAR(1) := NVL(UPPER(SUBSTR(TRIM(p_incl_plans_appl_4), 1, 1)), 'Y'); -- (Y|N) include SQL from 4th application (GC)
  k_incl_plans_non_appl          CONSTANT CHAR(1) := NVL(UPPER(SUBSTR(TRIM(p_incl_plans_non_appl), 1, 1)), 'Y'); -- (Y|N) consider as candidate SQL not qualified as "application module"
  k_execs_candidate_min          CONSTANT NUMBER := NVL(p_execs_candidate, 500); -- a plan must be executed these many times to be a candidate (for aggressiveness level 5)
  k_execs_candidate_max          CONSTANT NUMBER := k_aggressiveness_upper_limit * k_execs_candidate_min; -- a plan must be executed these many times to be a candidate (for aggressiveness level 1)
  k_execs_candidate              CONSTANT NUMBER := NVL(p_execs_candidate, ROUND((k_aggressiveness_upper_limit - k_aggressiveness + 1) * k_execs_candidate_max / k_aggressiveness_upper_limit));
  k_execs_appl_cat_1_max         CONSTANT NUMBER := 25000; -- a plan of this appl category must be executed these many times to qualify for a SPB (for aggressiveness level 1)
  k_execs_appl_cat_1             CONSTANT NUMBER := ROUND((k_aggressiveness_upper_limit - k_aggressiveness + 1) * k_execs_appl_cat_1_max / k_aggressiveness_upper_limit);
  k_execs_appl_cat_2_max         CONSTANT NUMBER := 25000; -- a plan of this appl category must be executed these many times to qualify for a SPB (for aggressiveness level 1)
  k_execs_appl_cat_2             CONSTANT NUMBER := ROUND((k_aggressiveness_upper_limit - k_aggressiveness + 1) * k_execs_appl_cat_2_max / k_aggressiveness_upper_limit);
  k_execs_appl_cat_3_max         CONSTANT NUMBER := 5000; -- a plan of this appl category must be executed these many times to qualify for a SPB (for aggressiveness level 1)
  k_execs_appl_cat_3             CONSTANT NUMBER := ROUND((k_aggressiveness_upper_limit - k_aggressiveness + 1) * k_execs_appl_cat_3_max / k_aggressiveness_upper_limit);
  k_execs_appl_cat_4_max         CONSTANT NUMBER := 5000; -- a plan of this appl category must be executed these many times to qualify for a SPB (for aggressiveness level 1)
  k_execs_appl_cat_4             CONSTANT NUMBER := ROUND((k_aggressiveness_upper_limit - k_aggressiveness + 1) * k_execs_appl_cat_4_max / k_aggressiveness_upper_limit);
  k_execs_non_appl_max           CONSTANT NUMBER := 5000; -- a plan of this appl category must be executed these many times to qualify for a SPB (for aggressiveness level 1)
  k_execs_non_appl               CONSTANT NUMBER := ROUND((k_aggressiveness_upper_limit - k_aggressiveness + 1) * k_execs_non_appl_max / k_aggressiveness_upper_limit);
  k_secs_per_exec_cand_max       CONSTANT NUMBER := GREATEST(10.000, NVL(p_secs_per_exec_cand, 0)); -- (10s) a plan must perform better than this threshold to be a candidate (for aggressiveness level 5)
  k_secs_per_exec_cand           CONSTANT NUMBER := NVL(p_secs_per_exec_cand, ROUND(k_aggressiveness * k_secs_per_exec_cand_max / k_aggressiveness_upper_limit, 6));
  k_secs_per_exec_appl_1_max     CONSTANT NUMBER := 0.005; -- (5ms) a plan must perform better than this threshold to be a candidate (for aggressiveness level 5)
  k_secs_per_exec_appl_1         CONSTANT NUMBER := ROUND(k_aggressiveness * k_secs_per_exec_appl_1_max / k_aggressiveness_upper_limit, 6);
  k_secs_per_exec_appl_2_max     CONSTANT NUMBER := 0.005; -- (5ms) a plan must perform better than this threshold to be a candidate (for aggressiveness level 5)
  k_secs_per_exec_appl_2         CONSTANT NUMBER := ROUND(k_aggressiveness * k_secs_per_exec_appl_2_max / k_aggressiveness_upper_limit, 6);
  k_secs_per_exec_appl_3_max     CONSTANT NUMBER := 0.250; -- (250ms) a plan must perform better than this threshold to be a candidate (for aggressiveness level 5)
  k_secs_per_exec_appl_3         CONSTANT NUMBER := ROUND(k_aggressiveness * k_secs_per_exec_appl_3_max / k_aggressiveness_upper_limit, 6);
  k_secs_per_exec_appl_4_max     CONSTANT NUMBER := 5.000; -- (5s) a plan must perform better than this threshold to be a candidate (for aggressiveness level 5)
  k_secs_per_exec_appl_4         CONSTANT NUMBER := ROUND(k_aggressiveness * k_secs_per_exec_appl_4_max / k_aggressiveness_upper_limit, 6);
  k_secs_per_exec_noappl_max     CONSTANT NUMBER := 0.250; -- (250ms) a plan must perform better than this threshold to be a candidate (for aggressiveness level 5)
  k_secs_per_exec_noappl         CONSTANT NUMBER := ROUND(k_aggressiveness * k_secs_per_exec_noappl_max / k_aggressiveness_upper_limit, 6);
  k_num_rows_appl_1              CONSTANT NUMBER := 5000; -- minimum number of rows on cbo stats for main table to be a candidate
  k_num_rows_appl_2              CONSTANT NUMBER := 5000; -- minimum number of rows on cbo stats for main table to be a candidate
  k_num_rows_appl_3              CONSTANT NUMBER := 5000; -- minimum number of rows on cbo stats for main table to be a candidate
  k_num_rows_appl_4              CONSTANT NUMBER := 100000; -- minimum number of rows on cbo stats for main table to be a candidate
  k_num_rows_noappl              CONSTANT NUMBER := 100000; -- minimum number of rows on cbo stats for main table to be a candidate
  k_90th_pctl_factor_cat         CONSTANT NUMBER := 2; -- the 90th percentile of "Avg Elapsed Time per Exec" should be less than this many times the "secs_per_exec" threshold for a Plan to qualify for SPM
  k_95th_pctl_factor_cat         CONSTANT NUMBER := 3; -- ditto for 95th percentile
  k_97th_pctl_factor_cat         CONSTANT NUMBER := 4; -- ditto for 97th percentile
  k_99th_pctl_factor_cat         CONSTANT NUMBER := 5; -- ditto for 99th percentile
  --k_90th_pctl_factor_avg         CONSTANT NUMBER := 5; -- the 90th percentile of "Avg Elapsed Time per Exec" should be less than this many times the "MEM/AWR/Median of Avg Elapsed Time per Exec" for a Plan to qualify for SPM
  --k_95th_pctl_factor_avg         CONSTANT NUMBER := 10; -- ditto for 95th percentile
  --k_97th_pctl_factor_avg         CONSTANT NUMBER := 15; -- ditto for 97th percentile
  --k_99th_pctl_factor_avg         CONSTANT NUMBER := 20; -- ditto for 99th percentile
  k_90th_pctl_factor_avg         CONSTANT NUMBER := 10; -- the 90th percentile of "Avg Elapsed Time per Exec" should be less than this many times the "MEM/AWR/Median of Avg Elapsed Time per Exec" for a Plan to qualify for SPM
  k_95th_pctl_factor_avg         CONSTANT NUMBER := 20; -- ditto for 95th percentile
  k_97th_pctl_factor_avg         CONSTANT NUMBER := 30; -- ditto for 97th percentile
  k_99th_pctl_factor_avg         CONSTANT NUMBER := 40; -- ditto for 99th percentile
  k_instance_age_days            CONSTANT NUMBER := 1; -- instance must be at least this many days old
  --k_first_load_time_days_cand    CONSTANT NUMBER := NVL(p_first_load_time_days_cand, k_aggressiveness_upper_limit - k_aggressiveness); -- a sql must be loaded into memory at least this many days before it is considered as candidate
  k_first_load_time_days_cand    CONSTANT NUMBER := ROUND(k_aggressiveness / 10, 1); -- a sql must be loaded into memory at least this many days before it is considered as candidate
  --k_first_load_time_days         CONSTANT NUMBER := 7 - k_aggressiveness; -- a sql must be loaded into memory at least this many days before it qualifies for a SPB
  k_first_load_time_days         CONSTANT NUMBER := ROUND(k_aggressiveness / 5, 1); -- a sql must be loaded into memory at least this many days before it qualifies for a SPB
  k_fixed_mature_days            CONSTANT NUMBER := 60; -- a non-fixed SPB needs to be older than this many days in order to be promoted to "FIXED"
  k_spb_thershold_over_cat_max   CONSTANT NUMBER := NVL(p_spb_thershold_over_cat_max, 5); -- plan must perform better than 5x category max threshold
  k_spb_thershold_over_spf_perf  CONSTANT NUMBER := NVL(p_spb_thershold_over_spf_perf, 50); -- plan must perform better than 50x its own performance at the time SPB was created
  k_spb_cap_over_cat_max         CONSTANT NUMBER := NVL(p_spb_thershold_over_cat_max, 100); -- plan must perform better than 100x category max threshold, regardless if fixed or number of executions
  k_spb_cap_over_spf_perf        CONSTANT NUMBER := NVL(p_spb_thershold_over_spf_perf, 1000); -- plan must perform better than 1000x its own performance at the time SPB was created, regardless if fixed or number of executions
  k_execs_per_hr_thershold_spb   CONSTANT NUMBER := 1; -- minimum number of executions per hour in order to promote or demote a SPB
  k_awr_plan_days                CONSTANT NUMBER := NVL(p_awr_plan_days, 180); -- amount of days to consider from AWR plan history assuming retention is at least this long
  k_awr_days                     CONSTANT NUMBER := NVL(p_awr_days, 14); -- amount of days to consider from AWR metrics history assuming retention is at least this long
  k_cur_days                     CONSTANT NUMBER := NVL(p_cur_days, 7); -- cursor must be active within the past k_cur_days to be considered
  k_display_plan                 CONSTANT CHAR(1) := 'Y'; -- include execution plan on report
  /* ---------------------------------------------------------------------------------- */
  k_source_mem                   CONSTANT VARCHAR2(30) := 'v$sql';
  k_source_awr                   CONSTANT VARCHAR2(30) := 'dba_hist_sqlstat';
  k_display_plan_format          CONSTANT VARCHAR2(100) := 'ADVANCED ALLSTATS LAST';
  k_debugging                    CONSTANT BOOLEAN := FALSE; -- future use
  k_secs_after_any_spm_api_call  CONSTANT NUMBER := 0; -- sleep this many seconds after each dbms_spm api call (trying to avoid bug 27496360)
  k_secs_before_spm_call_sql_id  CONSTANT NUMBER := 0; -- sleep this many seconds before a dbms_spm api call on same sql_id (trying to avoid bug 27496360)
  /* ---------------------------------------------------------------------------------- */
  l_pdb_id                       NUMBER;
  l_candidate_was_accepted       BOOLEAN;
  l_spb_promotion_was_accepted   BOOLEAN;
  l_spb_demotion_was_accepted    BOOLEAN;
  l_spb_exists                   BOOLEAN;
  l_spb_was_promoted             BOOLEAN;
  l_spb_was_created              BOOLEAN;
  l_candidate_count_p            NUMBER := 0;
  l_spb_created_count_p          NUMBER := 0;
  l_spb_promoted_count_p         NUMBER := 0;
  l_spb_created_qualified_p      NUMBER := 0;
  l_spb_promoted_qualified_p     NUMBER := 0;
  l_spb_already_fixed_count_p    NUMBER := 0;
  l_candidate_count_t            NUMBER := 0;
  l_spb_created_count_t          NUMBER := 0;
  l_spb_promoted_count_t         NUMBER := 0;
  l_spb_created_qualified_t      NUMBER := 0;
  l_spb_promoted_qualified_t     NUMBER := 0;
  l_spb_already_fixed_count_t    NUMBER := 0;
  l_spb_disable_qualified_p      NUMBER := 0;
  l_spb_disable_qualified_t      NUMBER := 0;
  l_spb_disabled_count_p         NUMBER := 0;
  l_spb_disabled_count_t         NUMBER := 0;
  l_message1                     VARCHAR2(1000);
  l_message2                     VARCHAR2(1000);
  l_message3                     VARCHAR2(1000);
  l_messaget                     VARCHAR2(1000); -- temporary message
  l_messaged                     VARCHAR2(1000); -- message for debugging
  l_cur_ms                       VARCHAR2(1000);
  l_mrs_ms                       VARCHAR2(1000);
  l_cat_ms                       VARCHAR2(1000);
  l_spb_ms                       VARCHAR2(1000);
  l_cat_cap_ms                   VARCHAR2(1000);
  l_spb_cap_ms                   VARCHAR2(1000);
  l_cur_slower_than_cat          BOOLEAN;
  l_cur_slower_than_spb          BOOLEAN;
  l_mrs_slower_than_cat          BOOLEAN;
  l_mrs_slower_than_spb          BOOLEAN;
  l_cur_violates_cat_cap         BOOLEAN;
  l_cur_violates_spb_cap         BOOLEAN;
  l_cur_in_compliance            BOOLEAN;
  l_dbid                         NUMBER;
  l_con_id                       NUMBER;
  l_con_id_prior                 NUMBER := -666;
  l_max_snap_id                  NUMBER;
  l_min_snap_id_sqlstat          NUMBER; -- for dba_hist_sqlstat
  l_min_snap_id_sts              NUMBER; -- for sql tuning sets
  l_open_mode                    VARCHAR2(20);
  l_db_name                      VARCHAR2(9);
  l_host_name                    VARCHAR2(64);
  l_pdb_name                     VARCHAR2(128);
  l_pdb_name_prior               VARCHAR2(128) := '-666';
  l_start_time			 DATE := SYSDATE;
  l_signature                    NUMBER;
  l_sql_handle                   VARCHAR2(128);
  l_plan_name                    VARCHAR2(128);
  l_description                  VARCHAR2(500);
  l_sql_text                     CLOB;
  l_sysdate                      DATE;
  l_sqlset_name                  VARCHAR2(30);
  l_plans_returned               NUMBER;
  l_instance_startup_time        DATE;
  l_us_per_exec_c                NUMBER;
  l_us_per_exec_b                NUMBER;
  l_owner                        VARCHAR2(30);
  l_table_name                   VARCHAR2(30);
  l_temporary                    VARCHAR2(1);
  l_blocks                       NUMBER;
  l_num_rows                     NUMBER;
  l_avg_row_len                  NUMBER;
  l_last_analyzed                DATE;
  l_pre_existing_plans           INTEGER;
  l_pre_existing_valid_plans     INTEGER;
  l_pre_existing_fixed_plans     INTEGER;
  l_only_plan_demotions          CHAR(1);
  l_only_create_spbl             CHAR(1);
  l_spb_plan                     CLOB;
  l_next                         INTEGER;
  l_prior                        INTEGER;
  l_prior_sql_id                 VARCHAR2(13);
  l_other_xml                    CLOB;
  l_plan_id                      NUMBER;
  l_plan_hash                    NUMBER;
  l_plan_hash_2                  NUMBER;
  l_plan_hash_full               NUMBER;
  l_action                       VARCHAR2(8); -- [LOADED|DISABLED|FIXED|NULL]
  l_13831_found_this_call        INTEGER := 0;
  l_13831_disabled_this_call     INTEGER := 0;
  l_13831_found_all_calls        INTEGER := 0;
  l_13831_disabled_all_calls     INTEGER := 0;
  l_06512_found_this_call        INTEGER := 0;
  l_06512_disabled_this_call     INTEGER := 0;
  l_06512_found_all_calls        INTEGER := 0;
  l_06512_disabled_all_calls     INTEGER := 0;
  l_snap_id                      NUMBER;
  l_snap_time                    DATE := SYSDATE;
  l_zapper_report                CLOB;
  l_zapper_report_enabled        BOOLEAN := FALSE;
  l_kiev_pdbs_count              NUMBER;
  h_rec                          &&1..sql_plan_baseline_hist%ROWTYPE;
  b_rec                          cdb_sql_plan_baselines%ROWTYPE;
  /* ---------------------------------------------------------------------------------- */
  CURSOR candidate_plan
  IS
    WITH /*+ GATHER_PLAN_STATISTICS IOD_SPM candidate_plan */
    pdbs AS (
    SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS QB_NAME(pdbs) */ -- disjoint for perf reasons
           c.con_id,
           c.name pdb_name,
           (SELECT /*+ NO_MERGE */
                   CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
              FROM cdb_tables t
             WHERE t.con_id = c.con_id
               AND t.table_name = 'KIEVBUCKETS') kiev_pdb
      FROM v$containers c
     WHERE c.open_mode = 'READ WRITE'
    ),
    v_sql AS (
    -- one row per sql/phv
    -- if a sql/phv as crsors with and without spb still aggregates them into one row and qualifies it with spb
    SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS QB_NAME(v_sql) */ -- disjoint to avoid runing into ora-1555
           c.con_id,
           c.parsing_user_id,
           c.parsing_schema_id,
           c.parsing_schema_name,
           c.sql_id,
           SUBSTR(c.sql_text, 1, gk_output_part_2_length) sql_text,
           COUNT(*) child_cursors,
           MIN(c.child_number) min_child_number,
           MAX(c.child_number) max_child_number,
           c.plan_hash_value,
           SUM(c.executions) executions,
           SUM(c.buffer_gets) buffer_gets,
           SUM(c.disk_reads) disk_reads,
           SUM(c.rows_processed) rows_processed,
           SUM(c.sharable_mem) sharable_mem,
           SUM(c.elapsed_time) elapsed_time,
           SUM(c.cpu_time) cpu_time,
           SUM(c.user_io_wait_time) user_io_wait_time,
           SUM(c.application_wait_time) application_wait_time,
           SUM(c.concurrency_wait_time) concurrency_wait_time,
           MIN(c.optimizer_cost) min_optimizer_cost,
           MAX(c.optimizer_cost) max_optimizer_cost,
           MAX(c.module) module,
           MAX(c.action) action,
           MAX(c.last_active_time) last_active_time, -- newest
           MAX(TO_DATE(c.last_load_time, 'YYYY-MM-DD/HH24:MI:SS')) last_load_time, -- newest
           MIN(TO_DATE(c.first_load_time, 'YYYY-MM-DD/HH24:MI:SS')) first_load_time, -- oldest
           MAX(c.sql_profile) sql_profile,
           MAX(c.sql_patch) sql_patch,
           MAX(c.sql_plan_baseline) sql_plan_baseline, -- it is possible to have some child cursors (for same phv) with spb and some without
           c.exact_matching_signature
      FROM v$sql c
     WHERE (NVL(k_sql_id, 'ALL') = 'ALL' OR c.sql_id = k_sql_id)
       AND (l_pdb_id IS NULL OR c.con_id = l_pdb_id)
       AND c.con_id > 2 -- exclude CDB$ROOT and PDB$SEED
       AND c.parsing_user_id > 0 -- exclude SYS
       AND c.parsing_schema_id > 0 -- exclude SYS
       AND c.parsing_schema_name NOT LIKE 'C##'||CHR(37)
       AND c.plan_hash_value > 0
       AND c.executions > 0
       AND c.elapsed_time > 0
       AND c.sql_text NOT LIKE '/* SQL Analyze'||CHR(37)
       AND c.sql_text NOT LIKE 'LOCK TABLE'||CHR(37)
       AND c.sql_text NOT LIKE '/* null */ LOCK TABLE'||CHR(37)
       AND c.last_active_time > SYSDATE - k_awr_days -- to ignore cursors with possible plans that haven't been executed for a while
       AND c.last_active_time > SYSDATE - k_cur_days -- to ignore cursors with possible plans that haven't been executed for a while
       AND c.plan_hash_value <> 187644085 -- /* addTransactionRow() */  INSERT INTO KievTransactions
       --AND SUBSTR(c.object_status, 1, 5) = 'VALID' -- removed since having this filter risks exluding some child cursors that actually have a plan that performs well
       --AND c.is_obsolete = 'N' -- removed since having this filter risks exluding some child cursors that actually have a plan that performs well
       --AND c.is_shareable = 'Y' -- removed since having this filter risks exluding some child cursors that actually have a plan that performs well
       -- putting back these predicates since we are getting "ERR-00010: SPB is missing!"
       AND c.object_status = 'VALID'
       AND c.is_obsolete = 'N'
       AND c.is_shareable = 'Y'
     GROUP BY
           c.con_id,
           c.parsing_user_id,
           c.parsing_schema_id,
           c.parsing_schema_name,
           c.sql_id,
           SUBSTR(c.sql_text, 1, gk_output_part_2_length),
           c.plan_hash_value,
           c.exact_matching_signature
    HAVING SUM(c.executions) > k_execs_candidate_min
       AND SUM(c.executions) > 0 -- redunant
       AND MIN(TO_DATE(c.first_load_time, 'YYYY-MM-DD/HH24:MI:SS')) < SYSDATE - k_first_load_time_days_cand -- sql is mature
       AND (l_only_plan_demotions = 'N' OR MAX(c.sql_plan_baseline) IS NOT NULL) -- if l_only_plan_demotions = 'Y' then consider only cursors with spb
       AND (l_only_create_spbl = 'N' OR MAX(c.sql_plan_baseline) IS NULL) -- if l_only_create_spbl = 'Y' then consider only cursors without spb
       --AND (SUM(c.elapsed_time) / SUM(c.executions) / 1e6) < k_secs_per_exec_cand_max (removed to trap SPB regressions)
       AND MIN(c.is_obsolete) = 'N' -- only consider plan if it has usable cursors
       AND MAX(c.is_shareable) = 'Y' -- only consider plan if it has usable cursors
       AND MAX(SUBSTR(c.object_status, 1, 5)) = 'VALID' -- only consider plan if it has usable cursors
    ),
    child AS
    ( SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS QB_NAME(latest_child) */
             l.con_id,
             l.sql_id,
             l.plan_hash_value,
             l.child_number,
             l.object_status,
             l.is_obsolete,
             l.is_shareable,
             l.last_active_time,
             ROW_NUMBER() OVER (PARTITION BY l.con_id, l.sql_id, l.plan_hash_value ORDER BY l.is_obsolete, l.is_shareable DESC, CASE WHEN l.object_status = 'VALID' THEN 1 WHEN SUBSTR(l.object_status, 1, 5) = 'VALID' THEN 2 ELSE 3 END, l.last_active_time DESC) row_number
        FROM v_sql c,
             v$sql l
       WHERE l.con_id = c.con_id
         AND l.sql_id = c.sql_id
         AND l.plan_hash_value = c.plan_hash_value
         AND l.child_number BETWEEN c.min_child_number AND c.max_child_number
    ),
    application_users AS (
    SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS QB_NAME(application_users) */ -- disjoint for perf reasons
           con_id,
           user_id
      FROM cdb_users
     WHERE oracle_maintained = 'N'
    ),
    mem_plan_metrics AS (
    SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS QB_NAME(mem_plan_metrics) */
           c.con_id,
           p.pdb_name,         
           p.kiev_pdb,
           c.parsing_user_id,
           c.parsing_schema_id,
           c.parsing_schema_name,
           c.sql_id,
           c.sql_text,
           c.child_cursors,
           c.min_child_number,
           c.max_child_number,
           c.plan_hash_value,
           k_source_mem metrics_source,
           c.executions,
           c.buffer_gets,
           c.disk_reads,
           c.rows_processed,
           c.sharable_mem,
           c.elapsed_time,
           c.cpu_time,
           c.user_io_wait_time,
           c.application_wait_time,
           c.concurrency_wait_time,
           c.min_optimizer_cost,
           c.max_optimizer_cost,
           c.module,
           c.action,
           c.last_active_time,
           c.last_load_time,
           c.first_load_time,
           c.sql_profile,
           c.sql_patch,
           c.sql_plan_baseline,
           c.exact_matching_signature,
           l.child_number l_child_number,
           l.object_status l_object_status,
           l.is_obsolete l_is_obsolete,
           l.is_shareable l_is_shareable,
           l.last_active_time l_last_active_time
      FROM v_sql c,
           child l,
           application_users pu,
           application_users ps,
           pdbs p
     WHERE l.con_id = c.con_id
       AND l.sql_id = c.sql_id
       AND l.plan_hash_value = c.plan_hash_value
       AND l.row_number = 1 -- most recent child that is valid, not obsolete and shareable
       AND pu.con_id = c.con_id
       AND pu.user_id = c.parsing_user_id
       AND ps.con_id = c.con_id
       AND ps.user_id = c.parsing_schema_id
       AND p.con_id = c.con_id
       AND CASE 
             WHEN k_kiev_pdbs_only = 'Y' AND p.kiev_pdb = 'Y' THEN 1
             WHEN k_kiev_pdbs_only = 'N' THEN 1
             ELSE 0
           END = 1
       -- subquery c1 is to skip a cursor that has no SPB yet, but there are other
       -- active cursors for same SQL_ID that already have a SPB.
       -- if a SQL has already a SPB in use at the time this tool executes, we simply do not
       -- want to create a new plan in SPB. reason is that maybe an earlier execution of this
       -- tool with a lower aggressiveness level just created a SPB, then on a subsequent
       -- execution of this tool we don't want to create a lower-quality SPB if we already
       -- have one created by a more conservative level of execution.
       AND CASE
             WHEN c.sql_plan_baseline IS NULL THEN 
               -- verify there are no cursors for this SQL (different plan) with active SPB
               ( SELECT /*+ NO_MERGE QB_NAME(c1) */ COUNT(*)
                   FROM v_sql c1
                  WHERE c1.con_id = c.con_id
                    AND c1.parsing_user_id = c.parsing_user_id
                    AND c1.parsing_schema_id = c.parsing_schema_id
                    AND c1.sql_id = c.sql_id
                    AND c1.sql_plan_baseline IS NOT NULL
                    AND ROWNUM = 1
               )
             ELSE 0 -- c.sql_plan_baseline IS NOT NULL (this cursor has a SPB)
             END = 0
    )
    , dba_hist_sqlstat_m AS (
    -- one row per sql/phv/snap
    -- this query block gets executed only when sql_id is passed as parameter
    -- skip this query block when executed to evaluate demotions only
    SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS QB_NAME(awr_plan_metrics) */ -- disjoint for perf reasons
           c.con_id,
           MAX(c.instance_number) instance_number,
           c.parsing_user_id,
           c.parsing_schema_id,
           SUBSTR(c.parsing_schema_name, 1, 30) parsing_schema_name,
           c.sql_id,
           c.plan_hash_value,
           SUM(c.executions_total) executions,
           SUM(c.buffer_gets_total) buffer_gets,
           SUM(c.disk_reads_total) disk_reads,
           SUM(c.rows_processed_total) rows_processed,
           SUM(c.sharable_mem) sharable_mem,
           SUM(c.elapsed_time_total) elapsed_time,
           SUM(c.cpu_time_total) cpu_time,
           SUM(c.iowait_total) user_io_wait_time,
           SUM(c.apwait_total) application_wait_time,
           SUM(c.ccwait_total) concurrency_wait_time,
           MIN(c.optimizer_cost) min_optimizer_cost,
           MAX(c.optimizer_cost) max_optimizer_cost,
           MAX(c.module) module,
           MAX(c.action) action,
           MAX(c.sql_profile) sql_profile,
           c.snap_id,
           ROW_NUMBER() OVER (PARTITION BY c.con_id, c.parsing_user_id, c.parsing_schema_id, c.sql_id, c.plan_hash_value ORDER BY c.snap_id DESC NULLS LAST) newest,
           ROW_NUMBER() OVER (PARTITION BY c.con_id, c.parsing_user_id, c.parsing_schema_id, c.sql_id, c.plan_hash_value ORDER BY c.snap_id ASC  NULLS LAST) oldest,
           (SELECT MAX(p.timestamp) FROM dba_hist_sql_plan p WHERE p.con_id = c.con_id AND p.dbid = l_dbid AND p.sql_id = sql_id AND p.plan_hash_value = c.plan_hash_value AND p.id = 0) timestamp
      FROM dba_hist_sqlstat c
     WHERE c.con_id > 2 -- exclude CDB$ROOT and PDB$SEED
       AND c.parsing_user_id > 0 -- exclude SYS
       AND c.parsing_schema_id > 0 -- exclude SYS
       AND c.parsing_schema_name NOT LIKE 'C##'||CHR(37)
       AND c.plan_hash_value > 0
       AND c.executions_total > 0
       AND c.elapsed_time_total > 0
       AND c.dbid = l_dbid
       AND c.snap_id >= l_min_snap_id_sqlstat
       --AND (NVL(k_sql_id, 'ALL') = 'ALL' OR c.sql_id = k_sql_id)
       AND c.sql_id = k_sql_id -- consider plans from history only when executed for one SQL
       AND (l_pdb_id IS NULL OR c.con_id = l_pdb_id)
       AND c.plan_hash_value <> 187644085 -- /* addTransactionRow() */  INSERT INTO KievTransactions
       AND l_only_plan_demotions = 'N' -- skip this query block when executed to evaluate demotions only
     GROUP BY
           c.con_id,
           c.parsing_user_id,
           c.parsing_schema_id,
           SUBSTR(c.parsing_schema_name, 1, 30),
           c.sql_id,
           c.plan_hash_value,
           --c.sql_profile,
           c.snap_id
    HAVING SUM(c.executions_total) > k_execs_candidate_min
       AND SUM(c.executions_total) > 0 -- redundant
       --AND (SUM(c.elapsed_time_total) / SUM(c.executions_total) / 1e6) < k_secs_per_exec_cand_max (removed to trap SPB regressions)
    )
    , awr_plan_metrics AS (
    -- two rows per sql/phv (the oldest and the newest)
    SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS QB_NAME(awr_plan_metrics) */
           c.con_id,
           --c.instance_number,
           p.pdb_name,  
           p.kiev_pdb,
           c.parsing_user_id,
           c.parsing_schema_id,
           c.parsing_schema_name,
           c.sql_id,
           ( SELECT DBMS_LOB.SUBSTR(t.sql_text, gk_output_part_2_length) 
               FROM dba_hist_sqltext t
              WHERE t.sql_id = c.sql_id
                AND t.dbid   = l_dbid
                AND ROWNUM   = 1
           ) sql_text,
           c.plan_hash_value,
           k_source_awr metrics_source,
           c.executions,
           c.buffer_gets,
           c.disk_reads,
           c.rows_processed,
           c.sharable_mem,
           c.elapsed_time,
           c.cpu_time,
           c.user_io_wait_time,
           c.application_wait_time,
           c.concurrency_wait_time,
           c.min_optimizer_cost,
           c.max_optimizer_cost,
           c.module,
           c.action,
           CAST(s.end_interval_time AS DATE) last_active_time,
           c.sql_profile,
           c.snap_id,
           c.newest,
           c.oldest
      FROM dba_hist_sqlstat_m c,
           dba_hist_snapshot s,
           application_users pu,
           application_users ps,
           pdbs p
     WHERE (c.oldest = 1 OR c.newest = 1)
       AND c.timestamp > SYSDATE - k_awr_plan_days -- amount of days to consider from AWR plan history assuming retention is at least this long
       AND c.executions > 0 -- redundant
       AND s.snap_id = c.snap_id
       AND s.dbid = l_dbid
       AND s.instance_number = c.instance_number
       --AND CAST(s.end_interval_time AS DATE) - CAST(s.begin_interval_time AS DATE) < 1
       AND s.end_interval_time - s.begin_interval_time < INTERVAL '1' DAY
       AND pu.con_id = c.con_id
       AND pu.user_id = c.parsing_user_id
       AND ps.con_id = c.con_id
       AND ps.user_id = c.parsing_schema_id
       AND p.con_id = c.con_id
       AND CASE 
             WHEN k_kiev_pdbs_only = 'Y' AND p.kiev_pdb = 'Y' THEN 1
             WHEN k_kiev_pdbs_only = 'N' THEN 1
             ELSE 0
           END = 1
       -- subqueries m1 and m2 below are needed to include awr plans for which there is
       -- no cursor, as long as their SQL is active (has at least one cursor under a 
       -- different plan but with no SPB), and the plan is not already being considered 
       -- from an existing cursor from shared pool.
       -- we don't want to select from awr a plan that we are already selecting from
       -- shared pool since the one from awr does not store sql_plan_baseline, then we
       -- could be creating and re-creating the same spb from awr every time we execute
       -- this script. 
       -- Three scenarios are handled by m1 and m2:
       -- 1. if plan x comes from awr, and shared pool contains plans x, y and z, then
       --    plan x from awr is filtered out (since awr lacks sql_plan_baseline column).
       -- 2. if plan x comes from awr, and shared pool contains only plans y and z, then
       --    plan x from awr is selected (since this plan x is a potential candidate).
       -- 3. if plan x comes from awr, and there are no plans on shared pool, then
       --    plan x from awr is filtered out (SQL is not in use).
       -- Note that if SQL has already a SPB as per cursors in shared pool, then we do
       -- not consider plans from awr.
       AND EXISTS -- SQL has at least one cursor with a plan "y" or "z" other than this c "x", but no SPB (i.e. sql is active)
           ( SELECT /*+ NO_MERGE QB_NAME(m1) */ NULL 
               FROM mem_plan_metrics m1
              WHERE m1.con_id = c.con_id
                AND m1.parsing_user_id = c.parsing_user_id
                AND m1.parsing_schema_id = c.parsing_schema_id
                AND m1.sql_id = c.sql_id
                AND m1.plan_hash_value <> c.plan_hash_value -- there is a cursor with a different plan
                AND m1.sql_plan_baseline IS NULL -- such cursor has no spb
           )
       AND NOT EXISTS -- There are no cursors with this plan c "x" (i.e. plan is not active)
           ( SELECT /*+ NO_MERGE QB_NAME(m2) */ NULL
               FROM mem_plan_metrics m2
              WHERE m2.con_id = c.con_id
                AND m2.parsing_user_id = c.parsing_user_id
                AND m2.parsing_schema_id = c.parsing_schema_id
                AND m2.sql_id = c.sql_id
                AND m2.plan_hash_value = c.plan_hash_value -- there is a cursor with same plan
           )
    )
    , mem_and_awr_plan_metrics AS (
    -- one row per sql/phv regardless if source is shared pool or awr
    SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS QB_NAME(mem_n_awr_metrics_m) */
           m.con_id,
           m.pdb_name,         
           m.kiev_pdb,
           m.parsing_schema_name,
           m.sql_id,
           m.sql_text,
           m.child_cursors,
           m.min_child_number,
           m.max_child_number,
           m.plan_hash_value,
           m.metrics_source,
           m.executions,
           m.buffer_gets,
           m.disk_reads,
           m.rows_processed,
           m.sharable_mem,
           m.elapsed_time,
           m.cpu_time,
           m.user_io_wait_time,
           m.application_wait_time,
           m.concurrency_wait_time,
           m.min_optimizer_cost,
           m.max_optimizer_cost,
           m.module,
           m.action,
           m.last_active_time,
           m.last_load_time, 
           m.first_load_time, 
           m.sql_profile,
           m.sql_patch,
           m.sql_plan_baseline,
           m.exact_matching_signature,
           m.l_child_number,
           m.l_object_status,
           m.l_is_obsolete,
           m.l_is_shareable,
           m.l_last_active_time
      FROM mem_plan_metrics m
     UNION ALL
    SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS QB_NAME(mem_n_awr_metrics_a) */
           a.con_id,
           a.pdb_name,         
           a.kiev_pdb,
           a.parsing_schema_name,
           a.sql_id,
           a.sql_text,
           TO_NUMBER(NULL) child_cursors,
           TO_NUMBER(NULL) min_child_number,
           TO_NUMBER(NULL) max_child_number,
           a.plan_hash_value,
           a.metrics_source,
           a.executions,
           a.buffer_gets,
           a.disk_reads,
           a.rows_processed,
           a.sharable_mem,
           a.elapsed_time,
           a.cpu_time,
           a.user_io_wait_time,
           a.application_wait_time,
           a.concurrency_wait_time,
           a.min_optimizer_cost,
           a.max_optimizer_cost,
           a.module,
           a.action,
           a.last_active_time,
           TO_DATE(NULL) last_load_time,
           ( SELECT o.last_active_time 
               FROM awr_plan_metrics o 
              WHERE o.con_id = a.con_id 
                AND o.parsing_user_id = a.parsing_user_id
                AND o.parsing_schema_id = a.parsing_schema_id
                AND o.sql_id = a.sql_id
                AND o.plan_hash_value = a.plan_hash_value
                AND o.oldest = 1
           ) first_load_time, 
           a.sql_profile,
           TO_CHAR(NULL) sql_patch,
           TO_CHAR(NULL) sql_plan_baseline,
           TO_NUMBER(NULL) exact_matching_signature,
           TO_NUMBER(NULL) l_child_number,
           TO_CHAR(NULL) l_object_status,
           TO_CHAR(NULL) l_is_obsolete,
           TO_CHAR(NULL) l_is_shareable,
           TO_DATE(NULL) l_last_active_time
      FROM awr_plan_metrics a
     WHERE a.newest = 1
    )
    , con_sql_phv AS (
    SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS QB_NAME(con_sql_phv) */
           DISTINCT
           p.con_id,
           p.sql_id,
           p.plan_hash_value
      FROM mem_and_awr_plan_metrics p
     WHERE p.con_id > 2 -- exclude CDB$ROOT and PDB$SEED
       AND p.plan_hash_value > 0
       AND (NVL(k_sql_id, 'ALL') = 'ALL' OR p.sql_id = k_sql_id)
       AND (l_pdb_id IS NULL OR p.con_id = l_pdb_id)
    )
    , plan_performance_time_series AS (
    -- historical performance metrics for each sql/phv/snap. not all have a history!
    SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS QB_NAME(plan_perf_time) */
           h.con_id,
           h.sql_id,
           h.plan_hash_value,
           h.snap_id,
           s.begin_interval_time,
           s.end_interval_time,
           ((CAST(s.end_interval_time AS DATE) - CAST(s.begin_interval_time AS DATE)) * 24 * 60 * 60) interval_secs,
           SUM(h.executions_delta)/((CAST(s.end_interval_time AS DATE) - CAST(s.begin_interval_time AS DATE)) * 24 * 60 * 60) execs_per_sec,
           SUM(h.buffer_gets_delta)/SUM(h.executions_delta) buffer_gets_per_exec,
           SUM(h.disk_reads_delta)/SUM(h.executions_delta) disk_reads_per_exec,
           SUM(h.rows_processed_delta)/SUM(h.executions_delta) rows_processed_per_exec,
           SUM(h.sharable_mem) sharable_mem,
           SUM(h.elapsed_time_delta)/SUM(h.executions_delta) avg_et_us,
           SUM(h.cpu_time_delta)/SUM(h.executions_delta) avg_cpu_us,
           SUM(h.iowait_delta)/SUM(h.executions_delta) avg_user_io_us,
           SUM(h.apwait_delta)/SUM(h.executions_delta) avg_application_us,
           SUM(h.ccwait_delta)/SUM(h.executions_delta) avg_concurrency_us,
           MIN(h.optimizer_cost) min_optimizer_cost,
           MAX(h.optimizer_cost) max_optimizer_cost,
           ROW_NUMBER() OVER (PARTITION BY h.con_id, h.sql_id, h.plan_hash_value ORDER BY h.snap_id DESC NULLS LAST) most_recent
      FROM con_sql_phv p,
           dba_hist_sqlstat h,
           dba_hist_snapshot s
     WHERE h.con_id = p.con_id
       AND h.sql_id = p.sql_id
       AND h.plan_hash_value = p.plan_hash_value
       AND h.con_id > 2 -- exclude CDB$ROOT and PDB$SEED
       AND h.parsing_user_id > 0 -- exclude SYS
       AND h.parsing_schema_id > 0 -- exclude SYS
       AND h.parsing_schema_name NOT LIKE 'C##'||CHR(37)
       AND h.plan_hash_value > 0
       AND h.executions_total > 0
       AND h.elapsed_time_total > 0
       AND h.dbid = l_dbid
       AND h.snap_id >= l_min_snap_id_sqlstat
       AND h.executions_delta > 0
       AND (NVL(k_sql_id, 'ALL') = 'ALL' OR h.sql_id = k_sql_id)
       AND (l_pdb_id IS NULL OR h.con_id = l_pdb_id)
       --AND (h.con_id, h.sql_id, h.plan_hash_value) IN (SELECT cm.con_id, cm.sql_id, cm.plan_hash_value FROM mem_and_awr_plan_metrics cm)
       AND s.snap_id = h.snap_id
       AND s.dbid = h.dbid
       AND s.instance_number = h.instance_number
       --AND CAST(s.end_interval_time AS DATE) - CAST(s.begin_interval_time AS DATE) < 1
       AND s.end_interval_time - s.begin_interval_time < INTERVAL '1' DAY
     GROUP BY
           h.con_id,
           h.sql_id,
           h.plan_hash_value,
           h.snap_id,
           s.begin_interval_time,
           s.end_interval_time
    )
    , plan_performance_metrics AS (
    -- historical performance metrics for each sql/phv. not all have a history!
    SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS QB_NAME(plan_perf_metrics) */
           con_id,
           sql_id,
           plan_hash_value,
           MIN(snap_id) phv_min_snap_id,
           MAX(snap_id) phv_max_snap_id,
           COUNT(*) awr_snapshots,
           AVG(execs_per_sec) avg_execs_per_sec,
           MAX(execs_per_sec) max_execs_per_sec,
           PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY execs_per_sec) p99_execs_per_sec,
           PERCENTILE_DISC(0.97) WITHIN GROUP (ORDER BY execs_per_sec) p97_execs_per_sec,
           PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY execs_per_sec) p95_execs_per_sec,
           PERCENTILE_DISC(0.90) WITHIN GROUP (ORDER BY execs_per_sec) p90_execs_per_sec,
           MEDIAN(execs_per_sec) med_execs_per_sec,
           AVG(buffer_gets_per_exec) avg_buffer_gets_per_exec,
           MAX(buffer_gets_per_exec) max_buffer_gets_per_exec,
           PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY buffer_gets_per_exec) p99_buffer_gets_per_exec,
           PERCENTILE_DISC(0.97) WITHIN GROUP (ORDER BY buffer_gets_per_exec) p97_buffer_gets_per_exec,
           PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY buffer_gets_per_exec) p95_buffer_gets_per_exec,
           PERCENTILE_DISC(0.90) WITHIN GROUP (ORDER BY buffer_gets_per_exec) p90_buffer_gets_per_exec,
           MEDIAN(buffer_gets_per_exec) med_buffer_gets_per_exec,
           AVG(disk_reads_per_exec) avg_disk_reads_per_exec,
           MAX(disk_reads_per_exec) max_disk_reads_per_exec,
           PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY disk_reads_per_exec) p99_disk_reads_per_exec,
           PERCENTILE_DISC(0.97) WITHIN GROUP (ORDER BY disk_reads_per_exec) p97_disk_reads_per_exec,
           PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY disk_reads_per_exec) p95_disk_reads_per_exec,
           PERCENTILE_DISC(0.90) WITHIN GROUP (ORDER BY disk_reads_per_exec) p90_disk_reads_per_exec,
           MEDIAN(disk_reads_per_exec) med_disk_reads_per_exec,
           AVG(rows_processed_per_exec) avg_rows_processed_per_exec,
           MAX(rows_processed_per_exec) max_rows_processed_per_exec,
           PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rows_processed_per_exec) p99_rows_processed_per_exec,
           PERCENTILE_DISC(0.97) WITHIN GROUP (ORDER BY rows_processed_per_exec) p97_rows_processed_per_exec,
           PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY rows_processed_per_exec) p95_rows_processed_per_exec,
           PERCENTILE_DISC(0.90) WITHIN GROUP (ORDER BY rows_processed_per_exec) p90_rows_processed_per_exec,
           MEDIAN(rows_processed_per_exec) med_rows_processed_per_exec,
           AVG(sharable_mem) avg_sharable_mem,
           MAX(sharable_mem) max_sharable_mem,
           PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY sharable_mem) p99_sharable_mem,
           PERCENTILE_DISC(0.97) WITHIN GROUP (ORDER BY sharable_mem) p97_sharable_mem,
           PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY sharable_mem) p95_sharable_mem,
           PERCENTILE_DISC(0.90) WITHIN GROUP (ORDER BY sharable_mem) p90_sharable_mem,
           MEDIAN(sharable_mem) med_sharable_mem,
           AVG(avg_et_us) avg_avg_et_us,
           MAX(avg_et_us) max_avg_et_us,
           PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY avg_et_us) p99_avg_et_us,
           PERCENTILE_DISC(0.97) WITHIN GROUP (ORDER BY avg_et_us) p97_avg_et_us,
           PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY avg_et_us) p95_avg_et_us,
           PERCENTILE_DISC(0.90) WITHIN GROUP (ORDER BY avg_et_us) p90_avg_et_us,
           MEDIAN(avg_et_us) med_avg_et_us,
           AVG(avg_cpu_us) avg_avg_cpu_us,
           MAX(avg_cpu_us) max_avg_cpu_us,
           PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY avg_cpu_us) p99_avg_cpu_us,
           PERCENTILE_DISC(0.97) WITHIN GROUP (ORDER BY avg_cpu_us) p97_avg_cpu_us,
           PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY avg_cpu_us) p95_avg_cpu_us,
           PERCENTILE_DISC(0.90) WITHIN GROUP (ORDER BY avg_cpu_us) p90_avg_cpu_us,
           MEDIAN(avg_cpu_us) med_avg_cpu_us,
           AVG(avg_user_io_us) avg_avg_user_io_us,
           MAX(avg_user_io_us) max_avg_user_io_us,
           PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY avg_user_io_us) p99_avg_user_io_us,
           PERCENTILE_DISC(0.97) WITHIN GROUP (ORDER BY avg_user_io_us) p97_avg_user_io_us,
           PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY avg_user_io_us) p95_avg_user_io_us,
           PERCENTILE_DISC(0.90) WITHIN GROUP (ORDER BY avg_user_io_us) p90_avg_user_io_us,
           MEDIAN(avg_user_io_us) med_avg_user_io_us,
           AVG(avg_application_us) avg_avg_application_us,
           MAX(avg_application_us) max_avg_application_us,
           PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY avg_application_us) p99_avg_application_us,
           PERCENTILE_DISC(0.97) WITHIN GROUP (ORDER BY avg_application_us) p97_avg_application_us,
           PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY avg_application_us) p95_avg_application_us,
           PERCENTILE_DISC(0.90) WITHIN GROUP (ORDER BY avg_application_us) p90_avg_application_us,
           MEDIAN(avg_application_us) med_avg_application_us,
           AVG(avg_concurrency_us) avg_avg_concurrency_us,
           MAX(avg_concurrency_us) max_avg_concurrency_us,
           PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY avg_concurrency_us) p99_avg_concurrency_us,
           PERCENTILE_DISC(0.97) WITHIN GROUP (ORDER BY avg_concurrency_us) p97_avg_concurrency_us,
           PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY avg_concurrency_us) p95_avg_concurrency_us,
           PERCENTILE_DISC(0.90) WITHIN GROUP (ORDER BY avg_concurrency_us) p90_avg_concurrency_us,
           MEDIAN(avg_concurrency_us) med_avg_concurrency_us,
           MIN(min_optimizer_cost) min_optimizer_cost,
           MAX(max_optimizer_cost) max_optimizer_cost,
           MAX(CASE most_recent WHEN 1 THEN snap_id END) mr_snap_id,
           MAX(CASE most_recent WHEN 1 THEN begin_interval_time END) mr_begin_interval_time,
           MAX(CASE most_recent WHEN 1 THEN end_interval_time END) mr_end_interval_time,
           MAX(CASE most_recent WHEN 1 THEN interval_secs END) mr_interval_secs,
           MAX(CASE most_recent WHEN 1 THEN execs_per_sec END) mr_execs_per_sec,
           MAX(CASE most_recent WHEN 1 THEN buffer_gets_per_exec END) mr_buffer_gets_per_exec,
           MAX(CASE most_recent WHEN 1 THEN disk_reads_per_exec END) mr_disk_reads_per_exec,
           MAX(CASE most_recent WHEN 1 THEN rows_processed_per_exec END) mr_rows_processed_per_exec,
           MAX(CASE most_recent WHEN 1 THEN sharable_mem END) mr_sharable_mem,
           MAX(CASE most_recent WHEN 1 THEN avg_et_us END) mr_avg_et_us,
           MAX(CASE most_recent WHEN 1 THEN avg_cpu_us END) mr_avg_cpu_us,
           MAX(CASE most_recent WHEN 1 THEN avg_user_io_us END) mr_avg_user_io_us,
           MAX(CASE most_recent WHEN 1 THEN avg_application_us END) mr_avg_application_us,
           MAX(CASE most_recent WHEN 1 THEN avg_concurrency_us END) mr_avg_concurrency_us
      FROM plan_performance_time_series
     GROUP BY
           con_id,
           sql_id,
           plan_hash_value
    ) -- Categorize SQL statement
    , extended_plan_metrics AS ( -- adding application_category
    -- application catagory is a custom grouping needed to assign thresholds on this tool
    SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS QB_NAME(ext_plan_metrics) */
           cm.con_id,
           cm.pdb_name,         
           cm.kiev_pdb,
           cm.parsing_schema_name,
           cm.sql_id,
           cm.sql_text,
           &&1..iod_spm.application_category(cm.sql_text) application_category,
           cm.plan_hash_value,
           cm.metrics_source,
           cm.child_cursors,
           cm.min_child_number,
           cm.max_child_number,
           cm.executions,
           cm.buffer_gets,
           cm.disk_reads,
           cm.rows_processed,
           cm.sharable_mem,
           cm.elapsed_time,
           cm.cpu_time,
           cm.user_io_wait_time,
           cm.application_wait_time,
           cm.concurrency_wait_time,
           LEAST(cm.min_optimizer_cost, pm.min_optimizer_cost) min_optimizer_cost,
           GREATEST(cm.max_optimizer_cost, pm.max_optimizer_cost) max_optimizer_cost,
           cm.module,
           cm.action,
           cm.last_active_time,
           cm.last_load_time,
           cm.first_load_time,
           cm.sql_profile,
           cm.sql_patch,
           cm.sql_plan_baseline,
           cm.exact_matching_signature,
           cm.l_child_number,
           cm.l_object_status,
           cm.l_is_obsolete,
           cm.l_is_shareable,
           cm.l_last_active_time,
           pm.awr_snapshots,
           pm.phv_min_snap_id,
           pm.phv_max_snap_id,
           pm.avg_execs_per_sec,
           pm.max_execs_per_sec,
           pm.p99_execs_per_sec,
           pm.p97_execs_per_sec,
           pm.p95_execs_per_sec,
           pm.p90_execs_per_sec,
           pm.med_execs_per_sec,
           pm.avg_buffer_gets_per_exec,
           pm.max_buffer_gets_per_exec,
           pm.p99_buffer_gets_per_exec,
           pm.p97_buffer_gets_per_exec,
           pm.p95_buffer_gets_per_exec,
           pm.p90_buffer_gets_per_exec,
           pm.med_buffer_gets_per_exec,
           pm.avg_disk_reads_per_exec,
           pm.max_disk_reads_per_exec,
           pm.p99_disk_reads_per_exec,
           pm.p97_disk_reads_per_exec,
           pm.p95_disk_reads_per_exec,
           pm.p90_disk_reads_per_exec,
           pm.med_disk_reads_per_exec,
           pm.avg_rows_processed_per_exec,
           pm.max_rows_processed_per_exec,
           pm.p99_rows_processed_per_exec,
           pm.p97_rows_processed_per_exec,
           pm.p95_rows_processed_per_exec,
           pm.p90_rows_processed_per_exec,
           pm.med_rows_processed_per_exec,
           pm.avg_sharable_mem,
           pm.max_sharable_mem,
           pm.p99_sharable_mem,
           pm.p97_sharable_mem,
           pm.p95_sharable_mem,
           pm.p90_sharable_mem,
           pm.med_sharable_mem,
           pm.avg_avg_et_us,
           pm.max_avg_et_us,
           pm.p99_avg_et_us,
           pm.p97_avg_et_us,
           pm.p95_avg_et_us,
           pm.p90_avg_et_us,
           pm.med_avg_et_us,
           pm.avg_avg_cpu_us,
           pm.max_avg_cpu_us,
           pm.p99_avg_cpu_us,
           pm.p97_avg_cpu_us,
           pm.p95_avg_cpu_us,
           pm.p90_avg_cpu_us,
           pm.med_avg_cpu_us,
           pm.avg_avg_user_io_us,
           pm.max_avg_user_io_us,
           pm.p99_avg_user_io_us,
           pm.p97_avg_user_io_us,
           pm.p95_avg_user_io_us,
           pm.p90_avg_user_io_us,
           pm.med_avg_user_io_us,
           pm.avg_avg_application_us,
           pm.max_avg_application_us,
           pm.p99_avg_application_us,
           pm.p97_avg_application_us,
           pm.p95_avg_application_us,
           pm.p90_avg_application_us,
           pm.med_avg_application_us,
           pm.avg_avg_concurrency_us,
           pm.max_avg_concurrency_us,
           pm.p99_avg_concurrency_us,
           pm.p97_avg_concurrency_us,
           pm.p95_avg_concurrency_us,
           pm.p90_avg_concurrency_us,
           pm.med_avg_concurrency_us,
           pm.mr_snap_id,
           pm.mr_begin_interval_time,
           pm.mr_end_interval_time,
           pm.mr_interval_secs,
           pm.mr_execs_per_sec,
           pm.mr_buffer_gets_per_exec,
           pm.mr_disk_reads_per_exec,
           pm.mr_rows_processed_per_exec,
           pm.mr_sharable_mem,
           pm.mr_avg_et_us,
           pm.mr_avg_cpu_us,
           pm.mr_avg_user_io_us,
           pm.mr_avg_application_us,
           pm.mr_avg_concurrency_us
      FROM mem_and_awr_plan_metrics cm,
           plan_performance_metrics pm
     WHERE cm.executions > 0 -- redundant
       AND pm.con_id(+) = cm.con_id
       AND pm.sql_id(+) = cm.sql_id
       AND pm.plan_hash_value(+) = cm.plan_hash_value
    )
    -- candidates include sql that may get a spb and sql that already has one
    SELECT /*+ GATHER_PLAN_STATISTICS QB_NAME(candidate) */
           con_id,
           pdb_name,         
           kiev_pdb,
           parsing_schema_name,
           sql_id,
           sql_text,
           CASE application_category
             WHEN gk_appl_cat_1 THEN 'Y'
             WHEN gk_appl_cat_2 THEN 'Y'
             WHEN gk_appl_cat_3 THEN 'N'
             WHEN gk_appl_cat_4 THEN 'Y'
           END critical_application,
           application_category,
           plan_hash_value,
           metrics_source,
           CASE metrics_source WHEN k_source_mem THEN 'MEM' WHEN k_source_awr THEN 'AWR' ELSE 'UNKOWN' END src,
           child_cursors,
           min_child_number,
           max_child_number,
           executions,
           buffer_gets,
           disk_reads,
           rows_processed,
           sharable_mem,
           elapsed_time,
           cpu_time,
           user_io_wait_time,
           application_wait_time,
           concurrency_wait_time,
           min_optimizer_cost,
           max_optimizer_cost,
           module,
           action,
           last_active_time,
           last_load_time,
           first_load_time,
           sql_profile,
           sql_patch,
           sql_plan_baseline,
           exact_matching_signature,
           l_child_number,
           l_object_status,
           l_is_obsolete,
           l_is_shareable,
           l_last_active_time,
           awr_snapshots,
           phv_min_snap_id,
           phv_max_snap_id,
           avg_execs_per_sec,
           max_execs_per_sec,
           p99_execs_per_sec,
           p97_execs_per_sec,
           p95_execs_per_sec,
           p90_execs_per_sec,
           med_execs_per_sec,
           avg_buffer_gets_per_exec,
           max_buffer_gets_per_exec,
           p99_buffer_gets_per_exec,
           p97_buffer_gets_per_exec,
           p95_buffer_gets_per_exec,
           p90_buffer_gets_per_exec,
           med_buffer_gets_per_exec,
           avg_disk_reads_per_exec,
           max_disk_reads_per_exec,
           p99_disk_reads_per_exec,
           p97_disk_reads_per_exec,
           p95_disk_reads_per_exec,
           p90_disk_reads_per_exec,
           med_disk_reads_per_exec,
           avg_rows_processed_per_exec,
           max_rows_processed_per_exec,
           p99_rows_processed_per_exec,
           p97_rows_processed_per_exec,
           p95_rows_processed_per_exec,
           p90_rows_processed_per_exec,
           med_rows_processed_per_exec,
           avg_sharable_mem,
           max_sharable_mem,
           p99_sharable_mem,
           p97_sharable_mem,
           p95_sharable_mem,
           p90_sharable_mem,
           med_sharable_mem,
           avg_avg_et_us,
           max_avg_et_us,
           p99_avg_et_us,
           p97_avg_et_us,
           p95_avg_et_us,
           p90_avg_et_us,
           med_avg_et_us,
           avg_avg_cpu_us,
           max_avg_cpu_us,
           p99_avg_cpu_us,
           p97_avg_cpu_us,
           p95_avg_cpu_us,
           p90_avg_cpu_us,
           med_avg_cpu_us,
           avg_avg_user_io_us,
           max_avg_user_io_us,
           p99_avg_user_io_us,
           p97_avg_user_io_us,
           p95_avg_user_io_us,
           p90_avg_user_io_us,
           med_avg_user_io_us,
           avg_avg_application_us,
           max_avg_application_us,
           p99_avg_application_us,
           p97_avg_application_us,
           p95_avg_application_us,
           p90_avg_application_us,
           med_avg_application_us,
           avg_avg_concurrency_us,
           max_avg_concurrency_us,
           p99_avg_concurrency_us,
           p97_avg_concurrency_us,
           p95_avg_concurrency_us,
           p90_avg_concurrency_us,
           med_avg_concurrency_us,
           mr_snap_id,
           mr_begin_interval_time,
           mr_end_interval_time,
           mr_interval_secs,
           mr_execs_per_sec,
           mr_buffer_gets_per_exec,
           mr_disk_reads_per_exec,
           mr_rows_processed_per_exec,
           mr_sharable_mem,
           mr_avg_et_us,
           mr_avg_cpu_us,
           mr_avg_user_io_us,
           mr_avg_application_us,
           mr_avg_concurrency_us,
           CASE application_category
             WHEN gk_appl_cat_1 THEN k_secs_per_exec_appl_1
             WHEN gk_appl_cat_2 THEN k_secs_per_exec_appl_2
             WHEN gk_appl_cat_3 THEN k_secs_per_exec_appl_3
             WHEN gk_appl_cat_4 THEN k_secs_per_exec_appl_4
             ELSE k_secs_per_exec_noappl
           END secs_per_exec_threshold,
           CASE application_category
             WHEN gk_appl_cat_1 THEN k_secs_per_exec_appl_1_max
             WHEN gk_appl_cat_2 THEN k_secs_per_exec_appl_2_max
             WHEN gk_appl_cat_3 THEN k_secs_per_exec_appl_3_max
             WHEN gk_appl_cat_4 THEN k_secs_per_exec_appl_4_max
             ELSE k_secs_per_exec_noappl_max
           END secs_per_exec_threshold_max,
           CASE application_category
             WHEN gk_appl_cat_1 THEN k_execs_appl_cat_1
             WHEN gk_appl_cat_2 THEN k_execs_appl_cat_2
             WHEN gk_appl_cat_3 THEN k_execs_appl_cat_3
             WHEN gk_appl_cat_4 THEN k_execs_appl_cat_4
             ELSE k_execs_non_appl
           END executions_threshold,
           CASE application_category
             WHEN gk_appl_cat_1 THEN k_execs_appl_cat_1_max
             WHEN gk_appl_cat_2 THEN k_execs_appl_cat_2_max
             WHEN gk_appl_cat_3 THEN k_execs_appl_cat_3_max
             WHEN gk_appl_cat_4 THEN k_execs_appl_cat_4_max
             ELSE k_execs_non_appl_max
           END executions_threshold_max,
           CASE application_category
             WHEN gk_appl_cat_1 THEN k_num_rows_appl_1
             WHEN gk_appl_cat_2 THEN k_num_rows_appl_2
             WHEN gk_appl_cat_3 THEN k_num_rows_appl_3
             WHEN gk_appl_cat_4 THEN k_num_rows_appl_4
             ELSE k_num_rows_noappl
           END num_rows_min_main_table
      FROM extended_plan_metrics
     WHERE executions > 0 -- redundant
       AND (    (k_incl_plans_appl_1    = 'Y' AND application_category = gk_appl_cat_1) 
             OR (k_incl_plans_appl_2    = 'Y' AND application_category = gk_appl_cat_2)
             OR (k_incl_plans_appl_3    = 'Y' AND application_category = gk_appl_cat_3)
             OR (k_incl_plans_appl_4    = 'Y' AND application_category = gk_appl_cat_4)
             OR (k_incl_plans_non_appl  = 'Y' AND NVL(application_category, 'Unknown') = 'Unknown')
           )
     ORDER BY
           pdb_name, -- 1st since we have subtotals per PDB
           parsing_schema_name, -- same SQL_ID may exist under more than one parsing_schema_name (they share same spb!!!)
           CASE application_category
             WHEN gk_appl_cat_1 THEN 1 
             WHEN gk_appl_cat_2 THEN 2 
             WHEN gk_appl_cat_3 THEN 3 
             WHEN gk_appl_cat_4 THEN 4 
             ELSE 5 
           END,
           sql_id, -- clustered for easier review
           elapsed_time / executions; -- average performance
  /* ---------------------------------------------------------------------------------- */  
  PROCEDURE output (p_line IN VARCHAR2, p_alert_log IN BOOLEAN DEFAULT FALSE, p_force_spool IN BOOLEAN DEFAULT FALSE) 
  IS
    l_line VARCHAR2(528);
  BEGIN
    l_line := SUBSTR(p_line, 1, gk_output_part_1_length + 5 + gk_output_part_2_length);
    --
    IF l_line IS NULL THEN
      RETURN;
    END IF;
    --
    IF p_force_spool OR NOT l_zapper_report_enabled THEN -- writes to spool all but SQL specific report, which goes into a table
      DBMS_OUTPUT.PUT_LINE (a => l_line);
    END IF;
    --
    IF l_zapper_report_enabled THEN -- SQL specific zapper report (use cs_spbl_zap_hist_list.sql and cs_spbl_zap_hist_report.sql)
      DBMS_LOB.writeappend (
         lob_loc => l_zapper_report,
         amount  => LENGTH(l_line) + 1, 
         buffer  => l_line||CHR(10)
      );
    END IF; 
    --
    IF p_alert_log THEN -- few things need to be written to alert log
      SYS.DBMS_SYSTEM.KSDWRT(dest => 2, tst => l_line); -- write to alert log
    END IF;
  END output;
  /* ---------------------------------------------------------------------------------- */  
  PROCEDURE output (p_col_1 IN VARCHAR2, p_col_2 IN VARCHAR2) 
  IS
  BEGIN
    IF TRIM(p_col_2) IS NOT NULL THEN
      output (p_line => '| '||RPAD(SUBSTR(NVL(p_col_1, ' '), 1, gk_output_part_1_length), gk_output_part_1_length)||' : '||SUBSTR(p_col_2, 1, gk_output_part_2_length));
      IF LENGTH(p_col_2) > gk_output_part_2_length THEN
        output(p_col_1 => NULL, p_col_2 => SUBSTR(p_col_2, gk_output_part_2_length + 1)); -- wrap p_col_2
      END IF;
    END IF;
  END output;
  /* ---------------------------------------------------------------------------------- */
  PROCEDURE output (p_col_01 IN VARCHAR2, 
                    p_col_02 IN VARCHAR2, p_col_03 IN VARCHAR2, p_col_04 IN VARCHAR2, 
                    p_col_05 IN VARCHAR2, p_col_06 IN VARCHAR2, p_col_07 IN VARCHAR2, 
                    p_col_08 IN VARCHAR2, p_col_09 IN VARCHAR2, p_col_10 IN VARCHAR2,
                    p_col_11 IN VARCHAR2) 
  IS
    FUNCTION trim_and_pad (p_col IN VARCHAR) RETURN VARCHAR2 
    IS
    BEGIN
      RETURN LPAD(NVL(TRIM(p_col), ' '), gk_output_metrics_length + 1);
    END trim_and_pad;
  BEGIN
    output (p_col_1 => p_col_01, p_col_2 =>
      trim_and_pad(p_col_02)||trim_and_pad(p_col_03)||trim_and_pad(p_col_04)||
      trim_and_pad(p_col_05)||trim_and_pad(p_col_06)||trim_and_pad(p_col_07)||
      trim_and_pad(p_col_08)||trim_and_pad(p_col_09)||trim_and_pad(p_col_10)||
      trim_and_pad(p_col_11)
      );
  END output;
  /* ---------------------------------------------------------------------------------- */
  PROCEDURE get_spb_rec (p_signature IN NUMBER, p_plan_name IN VARCHAR2, p_con_id IN NUMBER)
  IS
  BEGIN
    SELECT b.* 
      INTO b_rec 
      FROM cdb_sql_plan_baselines b
     WHERE b.con_id = p_con_id 
       AND b.signature = p_signature
       AND b.plan_name = p_plan_name;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      b_rec := NULL;
  END get_spb_rec;
  /* ---------------------------------------------------------------------------------- */  
  PROCEDURE load_plan_from_cursor_cache (p_sql_id IN VARCHAR2, p_plan_hash_value IN VARCHAR2, p_con_id IN NUMBER, p_con_name IN VARCHAR2, r_plans OUT NUMBER)
  IS
    l_cursor_id INTEGER;
    l_statement CLOB;
    l_rows      INTEGER;
    l_count     INTEGER;
    self_deadlock EXCEPTION;
    PRAGMA EXCEPTION_INIT(self_deadlock, -04024); -- ORA-04024: self-deadlock detected while trying to mutex pin cursor
    sessions_exceeded EXCEPTION;
    PRAGMA EXCEPTION_INIT(sessions_exceeded, -00018); -- ORA-00018: maximum number of sessions exceeded
  BEGIN
    SELECT COUNT(*)
      INTO l_count
      FROM v$sql
     WHERE sql_id = p_sql_id
       AND plan_hash_value = p_plan_hash_value
       AND con_id = p_con_id
       AND object_status = 'VALID'
       AND is_obsolete = 'N'
       AND is_shareable = 'Y';
    --
    IF l_count = 0 THEN
      r_plans := -1;
      RETURN;
    END IF;
    --
    l_statement := 
    q'[DECLARE ]'||CHR(10)||
    q'[PRAGMA AUTONOMOUS_TRANSACTION; ]'||CHR(10)||
    q'[BEGIN ]'||CHR(10)||
    q'[:plans := DBMS_SPM.LOAD_PLANS_FROM_CURSOR_CACHE(sql_id => :sql_id, plan_hash_value => :plan_hash_value); ]'||CHR(10)||
    q'[COMMIT; ]'||CHR(10)||
    q'[END;]';
    l_cursor_id := DBMS_SQL.OPEN_CURSOR;
    DBMS_SQL.PARSE(c => l_cursor_id, statement => l_statement, language_flag => DBMS_SQL.NATIVE, container => p_con_name);
    DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':plans', value => 0);
    DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':sql_id', value => p_sql_id);
    DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':plan_hash_value', value => p_plan_hash_value);
    l_rows := DBMS_SQL.EXECUTE(c => l_cursor_id);
    DBMS_SQL.VARIABLE_VALUE(c => l_cursor_id, name => ':plans', value => r_plans);
    DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
    DBMS_LOCK.SLEEP(k_secs_after_any_spm_api_call);
    --
    l_action := 'LOADED';
  EXCEPTION
    WHEN self_deadlock THEN
      output('ORA-04024: self-deadlock detected while trying to mutex pin cursor - on load_plan_from_cursor_cache during '||p_sql_id||' '||p_plan_hash_value||' '||p_con_name);
      DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
      RAISE;
    WHEN sessions_exceeded THEN
      output('ORA-00018: maximum number of sessions exceeded - on load_plan_from_cursor_cache during '||p_sql_id||' '||p_plan_hash_value||' '||p_con_name);
      DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
      RAISE;
  END load_plan_from_cursor_cache;
  /* ---------------------------------------------------------------------------------- */  
  PROCEDURE set_spb_attribute (p_sql_handle IN VARCHAR2, p_plan_name IN VARCHAR2, p_con_name IN VARCHAR2, p_attribute_name IN VARCHAR2, p_attribute_value IN VARCHAR2, r_plans OUT NUMBER)
  IS
    l_cursor_id INTEGER;
    l_statement CLOB;
    l_rows      INTEGER;
    self_deadlock EXCEPTION;
    PRAGMA EXCEPTION_INIT(self_deadlock, -04024); -- ORA-04024: self-deadlock detected while trying to mutex pin cursor
    sessions_exceeded EXCEPTION;
    PRAGMA EXCEPTION_INIT(sessions_exceeded, -00018); -- ORA-00018: maximum number of sessions exceeded
  BEGIN
    l_statement := 
    q'[DECLARE ]'||CHR(10)||
    q'[PRAGMA AUTONOMOUS_TRANSACTION; ]'||CHR(10)||
    q'[BEGIN ]'||CHR(10)||
    q'[:plans := DBMS_SPM.ALTER_SQL_PLAN_BASELINE(sql_handle => :sql_handle, plan_name => :plan_name, attribute_name => :attribute_name, attribute_value => :attribute_value); ]'||CHR(10)||
    q'[COMMIT; ]'||CHR(10)||
    q'[END;]';
    l_cursor_id := DBMS_SQL.OPEN_CURSOR;
    DBMS_SQL.PARSE(c => l_cursor_id, statement => l_statement, language_flag => DBMS_SQL.NATIVE, container => p_con_name);
    DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':plans', value => 0);
    DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':sql_handle', value => p_sql_handle);
    DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':plan_name', value => p_plan_name);
    DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':attribute_name', value => p_attribute_name);
    DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':attribute_value', value => SUBSTR(p_attribute_value, 1, 500));
    l_rows := DBMS_SQL.EXECUTE(c => l_cursor_id);
    DBMS_SQL.VARIABLE_VALUE(c => l_cursor_id, name => ':plans', value => r_plans);
    DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
    DBMS_LOCK.SLEEP(k_secs_after_any_spm_api_call);
    --
    IF p_attribute_name = 'ENABLED' AND p_attribute_value = 'NO' THEN
      l_action := 'DISABLED';
    ELSIF p_attribute_name = 'FIXED' AND p_attribute_value = 'YES' THEN
      l_action := 'FIXED';
    END IF;
  EXCEPTION
    WHEN self_deadlock THEN
      output('ORA-04024: self-deadlock detected while trying to mutex pin cursor - on set_spb_attribute during '||p_sql_handle||' '||p_plan_name||' '||p_con_name||' '||p_attribute_name||' '||p_attribute_value);
      DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
      RAISE;
    WHEN sessions_exceeded THEN
      output('ORA-00018: maximum number of sessions exceeded - on set_spb_attribute during '||p_sql_handle||' '||p_plan_name||' '||p_con_name||' '||p_attribute_name||' '||p_attribute_value);
      DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
      RAISE;
  END set_spb_attribute;
  /* ---------------------------------------------------------------------------------- */  
  PROCEDURE drop_sqlset (p_sqlset_name IN VARCHAR2, p_con_name IN VARCHAR2)
  IS
    l_cursor_id INTEGER;
    l_statement CLOB;
    l_rows      INTEGER;
    self_deadlock EXCEPTION;
    PRAGMA EXCEPTION_INIT(self_deadlock, -04024); -- ORA-04024: self-deadlock detected while trying to mutex pin cursor
    sessions_exceeded EXCEPTION;
    PRAGMA EXCEPTION_INIT(sessions_exceeded, -00018); -- ORA-00018: maximum number of sessions exceeded
  BEGIN
    l_statement := 
    q'[DECLARE ]'||CHR(10)||
    q'[PRAGMA AUTONOMOUS_TRANSACTION; ]'||CHR(10)||
    q'[sqlset_does_not_exist EXCEPTION; ]'||CHR(10)||
    q'[PRAGMA EXCEPTION_INIT(sqlset_does_not_exist, -13754); ]'||CHR(10)||
    q'[BEGIN ]'||CHR(10)||
    q'[DBMS_SQLTUNE.DROP_SQLSET(sqlset_name => :sqlset_name); ]'||CHR(10)||
    q'[COMMIT; ]'||CHR(10)||
    q'[EXCEPTION WHEN sqlset_does_not_exist THEN NULL; ]'||CHR(10)||
    q'[END;]';
    l_cursor_id := DBMS_SQL.OPEN_CURSOR;
    DBMS_SQL.PARSE(c => l_cursor_id, statement => l_statement, language_flag => DBMS_SQL.NATIVE, container => p_con_name);
    DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':sqlset_name', value => p_sqlset_name);
    l_rows := DBMS_SQL.EXECUTE(c => l_cursor_id);
    DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
    DBMS_LOCK.SLEEP(k_secs_after_any_spm_api_call);
  EXCEPTION
    WHEN self_deadlock THEN
      output('ORA-04024: self-deadlock detected while trying to mutex pin cursor - on drop_sqlset during '||p_sqlset_name||' '||p_con_name);
      DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
      RAISE;
    WHEN sessions_exceeded THEN
      output('ORA-00018: maximum number of sessions exceeded - on drop_sqlset during '||p_sqlset_name||' '||p_con_name);
      DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
      RAISE;
  END drop_sqlset;
  /* ---------------------------------------------------------------------------------- */  
  PROCEDURE create_and_load_sqlset (p_sqlset_name IN VARCHAR2, p_sql_id IN VARCHAR2, p_plan_hash_value IN VARCHAR2, p_begin_snap IN NUMBER, p_end_snap IN NUMBER, p_con_name IN VARCHAR2)
  IS
    l_cursor_id INTEGER;
    l_statement CLOB;
    l_rows      INTEGER;
    self_deadlock EXCEPTION;
    PRAGMA EXCEPTION_INIT(self_deadlock, -04024); -- ORA-04024: self-deadlock detected while trying to mutex pin cursor
    sessions_exceeded EXCEPTION;
    PRAGMA EXCEPTION_INIT(sessions_exceeded, -00018); -- ORA-00018: maximum number of sessions exceeded
  BEGIN
    l_statement := 
    q'[DECLARE ]'||CHR(10)||
    q'[PRAGMA AUTONOMOUS_TRANSACTION; ]'||CHR(10)||
    q'[ref_cur DBMS_SQLTUNE.SQLSET_CURSOR; ]'||CHR(10)||
    q'[BEGIN ]'||CHR(10)||
    q'[DBMS_SQLTUNE.CREATE_SQLSET(sqlset_name => :sqlset_name); ]'||CHR(10)||
    q'[OPEN ref_cur FOR ]'||CHR(10)||
    q'[SELECT VALUE(p) FROM TABLE(DBMS_SQLTUNE.SELECT_WORKLOAD_REPOSITORY(begin_snap => :begin_snap, end_snap => :end_snap, basic_filter => :basic_filter, attribute_list => :attribute_list)) p; ]'||CHR(10)||
    q'[DBMS_SQLTUNE.LOAD_SQLSET(sqlset_name => :sqlset_name, populate_cursor => ref_cur); ]'||CHR(10)||
    q'[CLOSE ref_cur; ]'||CHR(10)||
    q'[COMMIT; ]'||CHR(10)||
    q'[END;]';
    l_cursor_id := DBMS_SQL.OPEN_CURSOR;
    DBMS_SQL.PARSE(c => l_cursor_id, statement => l_statement, language_flag => DBMS_SQL.NATIVE, container => p_con_name);
    DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':begin_snap', value => p_begin_snap);
    DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':end_snap', value => p_end_snap);
    DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':basic_filter', value => 'sql_id = '''||p_sql_id||''' AND plan_hash_value = '||p_plan_hash_value);
    DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':attribute_list', value => 'ALL');
    DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':sqlset_name', value => p_sqlset_name);
    l_rows := DBMS_SQL.EXECUTE(c => l_cursor_id);
    DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
    DBMS_LOCK.SLEEP(k_secs_after_any_spm_api_call);
    l_action := 'LOADED';
  EXCEPTION
    WHEN self_deadlock THEN
      output('ORA-04024: self-deadlock detected while trying to mutex pin cursor - on create_and_load_sqlset during '||p_sqlset_name||' '||p_sql_id||' '||p_plan_hash_value||' '||p_con_name);
      DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
      RAISE;
    WHEN sessions_exceeded THEN
      output('ORA-00018: maximum number of sessions exceeded - on create_and_load_sqlset during '||p_sqlset_name||' '||p_sql_id||' '||p_plan_hash_value||' '||p_con_name);
      DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
      RAISE;
  END create_and_load_sqlset;
  /* ---------------------------------------------------------------------------------- */  
  PROCEDURE load_plan_from_sqlset (p_sqlset_name IN VARCHAR2, p_con_name IN VARCHAR2, r_plans OUT NUMBER)
  IS
    l_cursor_id INTEGER;
    l_statement CLOB;
    l_rows      INTEGER;
    self_deadlock EXCEPTION;
    PRAGMA EXCEPTION_INIT(self_deadlock, -04024); -- ORA-04024: self-deadlock detected while trying to mutex pin cursor
    sessions_exceeded EXCEPTION;
    PRAGMA EXCEPTION_INIT(sessions_exceeded, -00018); -- ORA-00018: maximum number of sessions exceeded
  BEGIN
    l_statement := 
    q'[DECLARE ]'||CHR(10)||
    q'[PRAGMA AUTONOMOUS_TRANSACTION; ]'||CHR(10)||
    q'[BEGIN ]'||CHR(10)||
    q'[:plans := DBMS_SPM.LOAD_PLANS_FROM_SQLSET(sqlset_name => :sqlset_name); ]'||CHR(10)||
    q'[COMMIT; ]'||CHR(10)||
    q'[END;]';
    l_cursor_id := DBMS_SQL.OPEN_CURSOR;
    DBMS_SQL.PARSE(c => l_cursor_id, statement => l_statement, language_flag => DBMS_SQL.NATIVE, container => p_con_name);
    DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':plans', value => 0);
    DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':sqlset_name', value => p_sqlset_name);
    l_rows := DBMS_SQL.EXECUTE(c => l_cursor_id);
    DBMS_SQL.VARIABLE_VALUE(c => l_cursor_id, name => ':plans', value => r_plans);
    DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
    DBMS_LOCK.SLEEP(k_secs_after_any_spm_api_call);
  EXCEPTION
    WHEN self_deadlock THEN
      output('ORA-04024: self-deadlock detected while trying to mutex pin cursor - on load_plan_from_sqlset during '||p_sqlset_name||' '||p_con_name);
      DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
      RAISE;
    WHEN sessions_exceeded THEN
      output('ORA-00018: maximum number of sessions exceeded - on load_plan_from_sqlset during '||p_sqlset_name||' '||p_con_name);
      DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
      RAISE;
  END load_plan_from_sqlset;
  /* ---------------------------------------------------------------------------------- */  
  PROCEDURE display_sql_plan_baseline (p_sql_handle IN VARCHAR2, p_plan_name IN VARCHAR2, p_con_name IN VARCHAR2, r_plan_clob OUT CLOB)
  IS
    l_cursor_id INTEGER;
    l_statement CLOB;
    l_rows      INTEGER;
    l_plan_clob CLOB;
    self_deadlock EXCEPTION;
    PRAGMA EXCEPTION_INIT(self_deadlock, -04024); -- ORA-04024: self-deadlock detected while trying to mutex pin cursor
    sessions_exceeded EXCEPTION;
    PRAGMA EXCEPTION_INIT(sessions_exceeded, -00018); -- ORA-00018: maximum number of sessions exceeded
  BEGIN
    l_statement := 
    q'[DECLARE ]'||CHR(10)||
    q'[PRAGMA AUTONOMOUS_TRANSACTION; ]'||CHR(10)||
    q'[BEGIN ]'||CHR(10)||
    q'[DBMS_LOB.CREATETEMPORARY(:plan_clob, TRUE); ]'||CHR(10)||
    q'[FOR i IN (SELECT plan_table_output FROM TABLE(DBMS_XPLAN.DISPLAY_SQL_PLAN_BASELINE(sql_handle => :sql_handle, plan_name => :plan_name, format => :format))) ]'||CHR(10)||
    q'[LOOP DBMS_LOB.WRITEAPPEND(:plan_clob, LENGTH(i.plan_table_output) + 1, i.plan_table_output||CHR(10)); END LOOP; ]'||CHR(10)||
    q'[COMMIT; ]'||CHR(10)||
    q'[END;]';
    l_cursor_id := DBMS_SQL.OPEN_CURSOR;
    DBMS_SQL.PARSE(c => l_cursor_id, statement => l_statement, language_flag => DBMS_SQL.NATIVE, container => p_con_name);
    DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':plan_clob', value => l_plan_clob);
    DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':sql_handle', value => p_sql_handle);
    DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':plan_name', value => p_plan_name);
    DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':format', value => 'ADVANCED');
    l_rows := DBMS_SQL.EXECUTE(c => l_cursor_id);
    DBMS_SQL.VARIABLE_VALUE(c => l_cursor_id, name => ':plan_clob', value => r_plan_clob);
    DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
    DBMS_LOCK.SLEEP(k_secs_after_any_spm_api_call);
  EXCEPTION
    WHEN self_deadlock THEN
      output('ORA-04024: self-deadlock detected while trying to mutex pin cursor - on '||p_con_name||' display_sql_plan_baseline during '||p_sql_handle||' '||p_plan_name||' '||p_con_name);
      DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
      RAISE;
    WHEN sessions_exceeded THEN
      output('ORA-00018: maximum number of sessions exceeded - on display_sql_plan_baseline during '||p_sql_handle||' '||p_plan_name||' '||p_con_name);
      DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
      RAISE;
  END display_sql_plan_baseline;
  /* ---------------------------------------------------------------------------------- */  
  PROCEDURE sql_plan_baseline_other_xml (p_signature IN NUMBER, p_plan_name IN VARCHAR2, p_con_name IN VARCHAR2, r_plan_id OUT NUMBER, r_plan_hash OUT NUMBER, r_plan_hash_2 OUT NUMBER, r_plan_hash_full OUT NUMBER, r_other_xml OUT CLOB)
  IS
    l_cursor_id  INTEGER;
    l_statement  CLOB;
    l_rows       INTEGER;
    l2_plan_id   NUMBER;
    l2_plan_hash NUMBER;
    l2_plan_hash_2 NUMBER;
    l2_plan_hash_full NUMBER;
    l2_other_xml CLOB;
    self_deadlock EXCEPTION;
    PRAGMA EXCEPTION_INIT(self_deadlock, -04024); -- ORA-04024: self-deadlock detected while trying to mutex pin cursor
    sessions_exceeded EXCEPTION;
    PRAGMA EXCEPTION_INIT(sessions_exceeded, -00018); -- ORA-00018: maximum number of sessions exceeded
  BEGIN
    l_statement := 
    q'{DECLARE }'||CHR(10)||
    q'{PRAGMA AUTONOMOUS_TRANSACTION; }'||CHR(10)||
    q'{BEGIN }'||CHR(10)||
    q'{SELECT p.plan_id, }'||CHR(10)||
    q'{       CASE WHEN p.other_xml IS NOT NULL THEN TO_NUMBER(extractvalue(xmltype(p.other_xml),'/*/info[@type = "plan_hash"]')) END, }'||CHR(10)|| /* null */
    q'{       CASE WHEN p.other_xml IS NOT NULL THEN TO_NUMBER(extractvalue(xmltype(p.other_xml),'/*/info[@type = "plan_hash_2"]')) END, }'||CHR(10)|| /* null */
    q'{       CASE WHEN p.other_xml IS NOT NULL THEN TO_NUMBER(extractvalue(xmltype(p.other_xml),'/*/info[@type = "plan_hash_full"]')) END, }'||CHR(10)|| /* null */
    q'{       p.other_xml }'||CHR(10)||
    q'{  INTO :plan_id, :plan_hash, :plan_hash_2, :plan_hash_full, :other_xml }'||CHR(10)||
    q'{  FROM sys.sqlobj$ o, sys.sqlobj$plan p }'||CHR(10)||
    q'{ WHERE o.signature =  :signature AND o.obj_type = 2 AND o.name = :plan_name }'||CHR(10)||
    q'{   AND p.signature = o.signature AND p.obj_type = o.obj_type AND p.plan_id = o.plan_id }'||CHR(10)||
    q'{   AND p.id = 1 AND p.other_xml IS NOT NULL; }'||CHR(10)||
    q'{COMMIT; }'||CHR(10)||
    q'{EXCEPTION }'||CHR(10)||
    q'{WHEN NO_DATA_FOUND THEN NULL; }'||CHR(10)||
    q'{END;}';
    l_cursor_id := DBMS_SQL.OPEN_CURSOR;
    DBMS_SQL.PARSE(c => l_cursor_id, statement => l_statement, language_flag => DBMS_SQL.NATIVE, container => p_con_name);
    DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':plan_id', value => l2_plan_id);
    DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':plan_hash', value => l2_plan_hash);
    DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':plan_hash_2', value => l2_plan_hash_2);
    DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':plan_hash_full', value => l2_plan_hash_full);
    DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':other_xml', value => l2_other_xml);
    DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':signature', value => p_signature);
    DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':plan_name', value => p_plan_name);
    l_rows := DBMS_SQL.EXECUTE(c => l_cursor_id);
    DBMS_SQL.VARIABLE_VALUE(c => l_cursor_id, name => ':plan_id', value => r_plan_id);
    DBMS_SQL.VARIABLE_VALUE(c => l_cursor_id, name => ':plan_hash', value => r_plan_hash);
    DBMS_SQL.VARIABLE_VALUE(c => l_cursor_id, name => ':plan_hash_2', value => r_plan_hash_2);
    DBMS_SQL.VARIABLE_VALUE(c => l_cursor_id, name => ':plan_hash_full', value => r_plan_hash_full);
    DBMS_SQL.VARIABLE_VALUE(c => l_cursor_id, name => ':other_xml', value => r_other_xml);
    DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
    DBMS_LOCK.SLEEP(k_secs_after_any_spm_api_call);
  EXCEPTION
    WHEN self_deadlock THEN
      output('ORA-04024: self-deadlock detected while trying to mutex pin cursor - on '||p_con_name||' sql_plan_baseline_other_xml during '||p_signature||' '||p_plan_name||' scan');
      DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
      RAISE;
    WHEN sessions_exceeded THEN
      output('ORA-00018: maximum number of sessions exceeded - on '||p_con_name||' sql_plan_baseline_other_xml during '||p_signature||' '||p_plan_name||' scan');
      DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
      RAISE;
  END sql_plan_baseline_other_xml;
  /* ---------------------------------------------------------------------------------- */  
  PROCEDURE get_sql_handle_and_plan_name (p_signature IN NUMBER, p_sysdate IN DATE, p_con_id IN NUMBER, r_sql_handle OUT VARCHAR2, r_plan_name OUT VARCHAR2)
  IS
  BEGIN
    SELECT sql_handle, plan_name
      INTO r_sql_handle, r_plan_name
      FROM cdb_sql_plan_baselines
     WHERE con_id = p_con_id
       AND signature = p_signature
       AND origin = 'MANUAL-LOAD'
       AND creator = UPPER('&&1.')
       AND created >= p_sysdate
       AND last_modified >= p_sysdate
       AND description IS NULL
       AND enabled = 'YES'
       AND accepted = 'YES'
       AND fixed = 'NO'
       AND reproduced = 'YES'
       AND ROWNUM = 1;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      r_sql_handle := NULL;
      r_plan_name := NULL;
  END get_sql_handle_and_plan_name;
  /* ---------------------------------------------------------------------------------- */  
  FUNCTION pre_existing_plans (p_signature IN NUMBER, p_con_id IN NUMBER, p_valid_only IN VARCHAR2 DEFAULT 'N', p_fixed_only IN VARCHAR2 DEFAULT 'N')
  RETURN INTEGER
  IS
    l_plans INTEGER;
  BEGIN
    SELECT COUNT(*)
      INTO l_plans
      FROM cdb_sql_plan_baselines
     WHERE con_id = p_con_id
       AND signature = p_signature
       AND (CASE p_valid_only WHEN 'Y' THEN (CASE WHEN enabled = 'YES' AND accepted = 'YES' AND reproduced = 'YES' THEN 1 ELSE 0 END) ELSE 1 END) = 1
       AND (CASE p_fixed_only WHEN 'Y' THEN (CASE fixed WHEN 'YES' THEN 1 ELSE 0 END) ELSE 1 END) = 1;
       --AND created < l_start_time;
    RETURN l_plans;
  END pre_existing_plans;
  /* ---------------------------------------------------------------------------------- */  
  PROCEDURE get_stats_main_table (p_con_id IN NUMBER, p_sql_id IN VARCHAR2, r_owner OUT VARCHAR2, r_table_name OUT VARCHAR2, r_temporary OUT VARCHAR2, r_blocks OUT NUMBER, r_num_rows OUT NUMBER, r_avg_row_len OUT NUMBER, r_last_analyzed OUT DATE)
  IS
  BEGIN  
    WITH /*+ GATHER_PLAN_STATISTICS IOD_SPM get_stats_main_table */
    v_sqlarea_m AS (
    SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS QB_NAME(sqlarea) */ 
           hash_value, address
      FROM v$sqlarea 
     WHERE con_id = p_con_id 
       AND sql_id = p_sql_id
    ),
    v_object_dependency_m AS (
    SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS QB_NAME(obj_dependency) */ 
           o.to_hash, o.to_address 
      FROM v$object_dependency o,
           v_sqlarea_m s
     WHERE o.con_id = p_con_id 
       AND o.from_hash = s.hash_value 
       AND o.from_address = s.address
    ),
    v_db_object_cache_m AS (
    SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS QB_NAME(obj_cache) */ 
           SUBSTR(c.owner,1,30) object_owner, 
           SUBSTR(c.name,1,30) object_name 
      FROM v$db_object_cache c,
           v_object_dependency_m d
     WHERE c.con_id = p_con_id 
       AND c.type IN ('TABLE','VIEW') 
       AND c.hash_value = d.to_hash
       AND c.addr = d.to_address 
    ),
    cdb_tables_m AS (
    SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS QB_NAME(cdb_tables) */ 
           t.owner, 
           t.table_name, 
           t.temporary,
           t.blocks,
           t.num_rows, 
           t.avg_row_len,
           t.last_analyzed, 
           ROW_NUMBER() OVER (ORDER BY t.num_rows DESC NULLS LAST) row_number 
      FROM cdb_tables t,
           v_db_object_cache_m c
     WHERE t.con_id = p_con_id 
       AND t.owner = c.object_owner
       AND t.table_name = c.object_name 
    )
    SELECT /*+ GATHER_PLAN_STATISTICS QB_NAME(get_stats) */
           owner, 
           table_name, 
           temporary,
           blocks,
           num_rows,
           avg_row_len, 
           last_analyzed
      INTO r_owner, 
           r_table_name, 
           r_temporary,
           r_blocks,
           r_num_rows, 
           r_avg_row_len,
           r_last_analyzed
      FROM cdb_tables_m
     WHERE row_number = 1;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      r_owner := NULL;
      r_table_name := NULL;
      r_temporary := NULL;
      r_blocks := TO_NUMBER(NULL);
      r_num_rows := TO_NUMBER(NULL);
      r_avg_row_len := TO_NUMBER(NULL);
      r_last_analyzed := TO_DATE(NULL);
  END get_stats_main_table;
  /* ---------------------------------------------------------------------------------- */  
BEGIN
  -- gets dbid for awr
  SELECT dbid, name, open_mode INTO l_dbid, l_db_name, l_open_mode FROM v$database;
  -- to be executed on DG primary only
  IF l_open_mode <> 'READ WRITE' THEN
    output ('*** to be executed on DG primary only ***');
    RETURN;
  END IF;
  -- EXIT if requested to execute only on KIEV PDBs, and there were none on this CDB
  IF k_kiev_pdbs_only = 'Y' THEN
    SELECT COUNT(*)
      INTO l_kiev_pdbs_count
      FROM cdb_tables
     WHERE table_name = 'KIEVBUCKETS'
       AND ROWNUM = 1; -- stop after finding one
    --
    IF l_kiev_pdbs_count = 0 THEN
      output ('*** there are no KIEV PDBs on this CDB ***');
      RETURN;
    END IF;
  END IF;
  -- 
  DBMS_APPLICATION_INFO.SET_MODULE(UPPER('&&1.')||'.IOD_SPM','MAINTAIN_PLANS_INTERNAL');
  EXECUTE IMMEDIATE q'[ALTER SESSION SET tracefile_identifier = 'iod_spm' ]';
  -- avoid PX on cdb view
  BEGIN
    EXECUTE IMMEDIATE 'ALTER SESSION SET "_px_cdb_view_enabled" = FALSE';
  EXCEPTION
    WHEN OTHERS THEN
      output(SQLERRM);
      output('ALTER SESSION SET "_px_cdb_view_enabled" = FALSE');
  END;
  -- workaround for bug 20118545 - Query using Subquery and Distinct Clause Raises ORA-600[kkqctinvvm(2): no qb found!]
  BEGIN
    EXECUTE IMMEDIATE 'ALTER SESSION SET "_complex_view_merging" = FALSE';
  EXCEPTION
    WHEN OTHERS THEN
      output(SQLERRM);
      output('ALTER SESSION SET "_complex_view_merging" = FALSE');
  END;
  -- look for ORA-13831 and ORA-06512 candidates
  IF gk_workaround_ora_13831 AND p_pdb_name IS NULL AND p_sql_id IS NULL THEN
    workaround_ora_13831_internal (
      p_report_only    => p_report_only,
      x_plans_found    => l_13831_found_this_call,
      x_plans_disabled => l_13831_disabled_this_call
    );
    l_13831_found_all_calls := l_13831_found_all_calls + l_13831_found_this_call;
    l_13831_disabled_all_calls := l_13831_disabled_all_calls + l_13831_disabled_this_call;
  END IF;
  --
  IF gk_workaround_ora_06512 AND p_pdb_name IS NULL AND p_sql_id IS NULL THEN
    workaround_ora_06512_internal (
      p_report_only    => p_report_only,
      x_plans_found    => l_06512_found_this_call,
      x_plans_disabled => l_06512_disabled_this_call
    );
    l_06512_found_all_calls := l_06512_found_all_calls + l_06512_found_this_call;
    l_06512_disabled_all_calls := l_06512_disabled_all_calls + l_06512_disabled_this_call;
  END IF;
  -- gets host name and starup time
  SELECT host_name, startup_time INTO l_host_name, l_instance_startup_time FROM v$instance;
  -- gets pdb name and con_id
  l_pdb_name := SYS_CONTEXT('USERENV', 'CON_NAME');
  l_con_id := SYS_CONTEXT('USERENV', 'CON_ID');
  -- gets pdb id if pdb_name was passed
  IF p_pdb_name IS NOT NULL THEN
    SELECT con_id INTO l_pdb_id FROM v$containers WHERE open_mode = 'READ WRITE' AND name = UPPER(p_pdb_name);
  END IF;
  -- is this execution only to demote plans?
  IF k_create_spm_limit = 0 AND k_promote_spm_limit = 0 AND k_disable_spm_limit > 0 THEN
    l_only_plan_demotions := 'Y';
  ELSE
    l_only_plan_demotions := 'N';
  END IF;
  -- is this execution only to create spbs?
  IF k_create_spm_limit > 0 AND k_promote_spm_limit = 0 AND k_disable_spm_limit = 0 THEN
    l_only_create_spbl := 'Y';
  ELSE
    l_only_create_spbl := 'N';
  END IF;
  -- gets min snap_id for awr 
  SELECT MAX(snap_id) INTO l_min_snap_id_sqlstat FROM dba_hist_snapshot WHERE dbid = l_dbid AND begin_interval_time < SYSTIMESTAMP - k_awr_days AND end_interval_time - begin_interval_time < INTERVAL '1' DAY;
  IF l_min_snap_id_sqlstat IS NULL THEN
    SELECT MIN(s.snap_id) INTO l_min_snap_id_sqlstat FROM dba_hist_snapshot s WHERE s.dbid = l_dbid AND s.end_interval_time - s.begin_interval_time < INTERVAL '1' DAY;
  END IF;
  SELECT MAX(s.snap_id) INTO l_min_snap_id_sts FROM dba_hist_snapshot s, v$instance i WHERE s.dbid = l_dbid AND CAST(s.begin_interval_time AS DATE) < GREATEST(SYSDATE - k_awr_days, i.startup_time) AND s.end_interval_time - s.begin_interval_time < INTERVAL '1' DAY;
  IF l_min_snap_id_sts IS NULL THEN
    SELECT MIN(s.snap_id) INTO l_min_snap_id_sts FROM dba_hist_snapshot s, v$instance i WHERE s.dbid = l_dbid AND CAST(s.begin_interval_time AS DATE) > i.startup_time AND s.end_interval_time - s.begin_interval_time < INTERVAL '1' DAY;
  END IF;
  -- gets max snap_id for awr 
  SELECT MAX(snap_id) INTO l_max_snap_id FROM dba_hist_snapshot WHERE dbid = l_dbid AND end_interval_time - begin_interval_time < INTERVAL '1' DAY;
  -- get sql_plan_baseline_hist snap_id
  SELECT NVL(MAX(snap_id), 0) + 1
  INTO l_snap_id
  FROM &&1..sql_plan_baseline_hist;
  -- output header
  output(RPAD('+', gk_output_part_1_length + 5 + gk_output_part_2_length, '-'));
  output('|');
  output('IOD SPM AUT FPZ',                   'Flipping-Plan Zapper (FPZ)');
  output('FPZ Aggressiveness',                k_aggressiveness||' (1-5) 1=conservative, 3=moderate, 5=aggressive');
  output('|');
  output('Database',                          l_db_name);
  output('Plugable Database (PDB)',           l_pdb_name||' ('||l_con_id||')');
  output('Host',                              l_host_name);
  output('Instance Startup Time',             TO_CHAR(l_instance_startup_time, gk_date_format));
  output('Date and Time (begin)',             TO_CHAR(SYSDATE, gk_date_format));
  output('|');
  output('Report Only',                       k_report_only);
  output('KIEV PDBs Only',                    k_kiev_pdbs_only);
  IF k_report_only = 'N' THEN
    output('Create SPM Limit',                k_create_spm_limit||' (0 means: report only)');
    output('Promote (to FIXED) SPM Limit',    k_promote_spm_limit||' (0 means: report only)');
    output('Demote (disable) SPM Limit',      k_disable_spm_limit||' (0 means: report only)');
  END IF;
  output('Report SPB Rejected Candidates',    k_repo_rejected_candidates);
  output('Report Non-Promoted SPBs',          k_repo_non_promoted_spb);
  output('Report Promoted (FIXED) SPBs',      k_repo_fixed_spb);
  output('PDB Name',                          NVL(k_pdb_name, 'ALL'));
  output('SQL_ID',                            NVL(k_sql_id, 'ALL'));
  output('Evaluate '||gk_appl_cat_1||' Plans', k_incl_plans_appl_1);
  output('Evaluate '||gk_appl_cat_2||' Plans', k_incl_plans_appl_2);
  output('Evaluate '||gk_appl_cat_3||' Plans', k_incl_plans_appl_3);
  output('Evaluate '||gk_appl_cat_4||' Plans', k_incl_plans_appl_4);
  output('Evaluate Non-Application Plans',    k_incl_plans_non_appl);
  output('Min Executions - Candidate',        k_execs_candidate||' (range:0-'||k_execs_candidate_max||')');
  output('Min Executions - '||gk_appl_cat_1,   k_execs_appl_cat_1||' (category range:0-'||k_execs_appl_cat_1_max||')');
  output('Min Executions - '||gk_appl_cat_2,   k_execs_appl_cat_2||' (category range:0-'||k_execs_appl_cat_2_max||')');
  output('Min Executions - '||gk_appl_cat_3,   k_execs_appl_cat_3||' (category range:0-'||k_execs_appl_cat_3_max||')');
  output('Min Executions - '||gk_appl_cat_4,   k_execs_appl_cat_4||' (category range:0-'||k_execs_appl_cat_4_max||')');
  IF k_incl_plans_non_appl = 'Y' THEN
    output('Min Executions - Non-Application',k_execs_non_appl||' (category range:0-'||k_execs_non_appl_max||')');
  END IF;
  output('Time Threshold (ms) Candidate',     
                                              TO_CHAR(k_secs_per_exec_cand * 1e3, 'FM9,999,990.000')||' (ms) (range:0-'||
                                              TO_CHAR(k_secs_per_exec_cand_max * 1e3, 'FM9,999,990.000')||')');
  output('Time Threshold (ms) '||gk_appl_cat_1,
                                              TO_CHAR(k_secs_per_exec_appl_1 * 1e3, 'FM9,999,990.000')||' (ms) (category range:0-'||
                                              TO_CHAR(k_secs_per_exec_appl_1_max * 1e3, 'FM9,999,990.000')||')');
  output('Time Threshold (ms) '||gk_appl_cat_2,
                                              TO_CHAR(k_secs_per_exec_appl_2 * 1e3, 'FM9,999,990.000')||' (ms) (category range:0-'||
                                              TO_CHAR(k_secs_per_exec_appl_2_max * 1e3, 'FM9,999,990.000')||')');
  output('Time Threshold (ms) '||gk_appl_cat_3,
                                              TO_CHAR(k_secs_per_exec_appl_3 * 1e3, 'FM9,999,990.000')||' (ms) (category range:0-'||
                                              TO_CHAR(k_secs_per_exec_appl_3_max * 1e3, 'FM9,999,990.000')||')');
  output('Time Threshold (ms) '||gk_appl_cat_4,
                                              TO_CHAR(k_secs_per_exec_appl_4 * 1e3, 'FM9,999,990.000')||' (ms) (category range:0-'||
                                              TO_CHAR(k_secs_per_exec_appl_4_max * 1e3, 'FM9,999,990.000')||')');
  IF k_incl_plans_non_appl = 'Y' THEN
    output('Time Threshold (ms) Non-Appl', 
                                              TO_CHAR(k_secs_per_exec_noappl * 1e3, 'FM9,999,990.000')||' (ms) (category range:0-'||
                                              TO_CHAR(k_secs_per_exec_noappl_max * 1e3, 'FM9,999,990.000')||')');
  END IF;
  output('Min Rows - '||gk_appl_cat_1,         k_num_rows_appl_1);
  output('Min Rows - '||gk_appl_cat_2,         k_num_rows_appl_2);
  output('Min Rows - '||gk_appl_cat_3,         k_num_rows_appl_3);
  output('Min Rows - '||gk_appl_cat_4,         k_num_rows_appl_4);
  IF k_incl_plans_non_appl = 'Y' THEN
    output('Min Rows - Non-Application',      k_num_rows_noappl);
  END IF;
  output('90th Pctl Factor - Over Min Time',  k_90th_pctl_factor_cat||'x');
  output('95th Pctl Factor - Over Min Time',  k_95th_pctl_factor_cat||'x');
  output('97th Pctl Factor - Over Min Time',  k_97th_pctl_factor_cat||'x');
  output('99th Pctl Factor - Over Min Time',  k_99th_pctl_factor_cat||'x');
  output('90th Pctl Factor - Over Avg ET',    k_90th_pctl_factor_avg||'x');
  output('95th Pctl Factor - Over Avg ET',    k_95th_pctl_factor_avg||'x');
  output('97th Pctl Factor - Over Avg ET',    k_97th_pctl_factor_avg||'x');
  output('99th Pctl Factor - Over Avg ET',    k_99th_pctl_factor_avg||'x');
  output('Min Age (days) - Candidate',        k_first_load_time_days_cand||' (days)');
  output('Min Age (days) - To Qualify',       k_first_load_time_days||' (days)');
  output('Min Age (days) - SPB 4 Promotion',  k_fixed_mature_days||' (days)');
  output('SPB Threshold - Over Categ Max',    k_spb_thershold_over_cat_max||'x');
  output('SPB Threshold - Over SPB Perf',     k_spb_thershold_over_spf_perf||'x');
  output('SPB Cap - Over Categ Max',          k_spb_cap_over_cat_max||'x');
  output('SPB Cap - Over SPB Perf',           k_spb_cap_over_spf_perf||'x');
  output('SPB Threshold - Min Exec per Hour', TO_CHAR(ROUND(k_execs_per_hr_thershold_spb, 3), 'FM999,999,990.000'));
  output('Plan History Considered (days)',    k_awr_days||' (days)');
  output('Min Snap ID (DBA_HIST_SQLSTAT)',    l_min_snap_id_sqlstat);
  output('Min Snap ID (SQL Tuning Sets)',     l_min_snap_id_sts);
  output('Max Snap ID',                       l_max_snap_id);
  output('Cursor Age Considered (days)',      k_cur_days||' (days)');
  output('Display Execution Plans',           k_display_plan);
  output('|');
  output(RPAD('+', gk_output_part_1_length + 5 + gk_output_part_2_length, '-'));
  /* ---------------------------------------------------------------------------------- */  
  -- Pre-select SQL_ID/PHV candidates from shared pool
  FOR c_rec IN candidate_plan
  LOOP
    IF l_candidate_count_p > 0 AND l_pdb_name_prior <> c_rec.pdb_name THEN -- totals for prior PDB
      output(RPAD('+', gk_output_part_1_length + 5 + gk_output_part_2_length, '-'));
      output('|');
      output('Plugable Database (PDB)',       l_pdb_name_prior||' ('||l_con_id_prior||')');
      output('Candidates',                    l_candidate_count_p);
      output('SPBs Qualified for Creation',   l_spb_created_qualified_p);
      output('SPBs Created',                  l_spb_created_count_p);
      output('SPBs Qualified for Promotion',  l_spb_promoted_qualified_p);
      output('SPBs Promoted',                 l_spb_promoted_count_p);
      output('SPBs Qualified for Demotion',   l_spb_disable_qualified_p);
      output('SPBs Demoted',                  l_spb_disabled_count_p);
      output('SPBs already Fixed',            l_spb_already_fixed_count_p);
      output('Date and Time',                 TO_CHAR(SYSDATE, gk_date_format));
      output('|');
      output(RPAD('+', gk_output_part_1_length + 5 + gk_output_part_2_length, '-'));
    END IF;
    IF l_pdb_name_prior <> c_rec.pdb_name THEN 
      l_candidate_count_p := 0;
      l_spb_created_qualified_p := 0;
      l_spb_promoted_qualified_p := 0;
      l_spb_created_count_p := 0;
      l_spb_promoted_count_p := 0;
      l_spb_already_fixed_count_p := 0;
      l_spb_disable_qualified_p := 0;
      l_spb_disabled_count_p := 0;
      --IF k_debugging THEN
        output(RPAD('+', gk_output_part_1_length + 5 + gk_output_part_2_length, '-'));
        output('|');
        output('Plugable Database (PDB)',       c_rec.pdb_name||' ('||c_rec.con_id||')');
        output('Date and Time',                 TO_CHAR(SYSDATE, gk_date_format));
        output('|');
        output(RPAD('+', gk_output_part_1_length + 5 + gk_output_part_2_length, '-'));
      --END IF;
    END IF;
    -- initialize flags and counters
    l_candidate_count_t          := l_candidate_count_t + 1;
    l_candidate_count_p          := l_candidate_count_p + 1;
    l_candidate_was_accepted     := FALSE;
    l_spb_promotion_was_accepted := FALSE;
    l_spb_demotion_was_accepted  := FALSE;
    l_spb_exists                 := FALSE;
    l_spb_was_created            := FALSE;
    l_spb_was_promoted           := FALSE;
    l_description                := NULL;
    l_message1                   := NULL;
    l_message2                   := NULL;
    l_message3                   := NULL;
    l_messaget                   := NULL;
    l_cur_ms                     := NULL;
    l_mrs_ms                     := NULL;
    l_cat_ms                     := NULL;
    l_spb_ms                     := NULL;
    l_cat_cap_ms                 := NULL;
    l_spb_cap_ms                 := NULL;
    l_cur_slower_than_cat        := FALSE;
    l_cur_slower_than_spb        := FALSE;
    l_mrs_slower_than_cat        := FALSE;
    l_mrs_slower_than_spb        := FALSE;
    l_cur_violates_cat_cap       := FALSE;
    l_cur_violates_spb_cap       := FALSE;
    l_cur_in_compliance          := FALSE;
    l_plans_returned             := 0;
    b_rec                        := NULL;
    l_us_per_exec_c              := c_rec.elapsed_time / GREATEST(c_rec.executions, 1);
    l_us_per_exec_b              := NULL;
    l_owner                      := NULL;
    l_table_name                 := NULL;
    l_temporary                  := NULL;
    l_blocks                     := TO_NUMBER(NULL);
    l_num_rows                   := TO_NUMBER(NULL);
    l_avg_row_len                := TO_NUMBER(NULL);
    l_last_analyzed              := TO_DATE(NULL);
    l_pre_existing_plans         := TO_NUMBER(NULL);
    l_pre_existing_valid_plans   := TO_NUMBER(NULL);
    l_pre_existing_fixed_plans   := TO_NUMBER(NULL);
    l_other_xml                  := NULL;
    l_plan_id                    := TO_NUMBER(NULL);
    l_plan_hash                  := TO_NUMBER(NULL);
    l_plan_hash_2                := TO_NUMBER(NULL);
    l_plan_hash_full             := TO_NUMBER(NULL);
    l_signature                  := TO_NUMBER(NULL);
    l_sql_handle                 := NULL;
    l_plan_name                  := NULL;
    --
    h_rec                        := NULL;
    l_zapper_report_enabled      := TRUE;
    l_action                     := 'NULL';
    DBMS_LOB.createtemporary(lob_loc => l_zapper_report, cache => TRUE, dur => DBMS_LOB.session);
    --
    -- print one line with basic info in case of unexpected error
    IF k_debugging THEN
      output(RPAD('+', gk_output_part_1_length + 5 + gk_output_part_2_length, '-'));
      output('|');
      output('Candidate Number',              l_candidate_count_t);
      output('Parsing Schema Name',           c_rec.parsing_schema_name);
      output('SQL Text',                      REPLACE(REPLACE(c_rec.sql_text, CHR(10), CHR(32)), CHR(9), CHR(32)));
      output('SQL ID',                        c_rec.sql_id);
      output('Plan Hash Value (PHV)',         c_rec.plan_hash_value);
      output('Metrics Source',                c_rec.metrics_source);
      IF c_rec.metrics_source = k_source_mem THEN
        output('Min Child Number',            c_rec.min_child_number);
        output('Max Child Number',            c_rec.max_child_number);
      END IF;
      output('Exact Matching Signature',      c_rec.exact_matching_signature);
      output('SQL Plan Baseline (SPB)',       c_rec.sql_plan_baseline);
      output('SQL Profile',                   c_rec.sql_profile);
      output('SQL Patch',                     c_rec.sql_patch);
      output('|');
      output(RPAD('+', gk_output_part_1_length + 5 + gk_output_part_2_length, '-'));
    ELSE
      l_messaged := '| '||
                    --/*'PDB:'||*/c_rec.pdb_name||' '||
                    --/*'SCHEMA:'||*/c_rec.parsing_schema_name||' '||
                    /*'SQL_ID:'||*/c_rec.sql_id||' '||
                    /*'PHV:'||*/c_rec.plan_hash_value||' '||
                    /*'SRC:'||*/c_rec.metrics_source||' '||
                    /*'SIGN:'||*/c_rec.exact_matching_signature||' ';
      IF c_rec.sql_plan_baseline IS NOT NULL THEN
        l_messaged := l_messaged||/*'SPB:'||*/c_rec.sql_plan_baseline||' ';
      END IF;
      IF c_rec.sql_profile IS NOT NULL THEN
        l_messaged := l_messaged||/*'PROF:'||*/c_rec.sql_profile||' ';
      END IF;
      IF c_rec.sql_patch IS NOT NULL THEN
        l_messaged := l_messaged||/*'PATCH:'||*/c_rec.sql_patch||' ';
      END IF;
      l_messaged := l_messaged||/*'CATEGORY:'||*/c_rec.application_category||' ';
      l_messaged := l_messaged||/*'TEXT:'||*/REPLACE(REPLACE(c_rec.sql_text, CHR(10), CHR(32)), CHR(9), CHR(32));
      output(l_messaged, p_force_spool => TRUE);
    END IF;
    -- get main table
    get_stats_main_table (
      p_con_id        => c_rec.con_id,
      p_sql_id        => c_rec.sql_id,
      r_owner         => l_owner,
      r_table_name    => l_table_name,
      r_temporary     => l_temporary,
      r_blocks        => l_blocks,
      r_num_rows      => l_num_rows,
      r_avg_row_len   => l_avg_row_len,
      r_last_analyzed => l_last_analyzed
    );
    -- figure out signature
    IF c_rec.metrics_source = k_source_mem THEN
      l_signature := c_rec.exact_matching_signature;
    ELSIF c_rec.metrics_source = k_source_awr THEN
      SELECT sql_text INTO l_sql_text FROM dba_hist_sqltext WHERE sql_id = c_rec.sql_id AND dbid = l_dbid AND ROWNUM = 1;
      l_signature := DBMS_SQLTUNE.SQLTEXT_TO_SIGNATURE(l_sql_text);
    ELSE
      l_signature := NULL;
    END IF;
    -- pre-existing SPB plans
    l_pre_existing_plans := 0;
    l_pre_existing_valid_plans := 0;
    l_pre_existing_fixed_plans := 0;
    IF l_signature IS NOT NULL THEN
      l_pre_existing_plans := pre_existing_plans (p_signature => l_signature, p_con_id => c_rec.con_id, p_valid_only => 'N', p_fixed_only => 'N');
      IF l_pre_existing_plans > 0 THEN
        l_pre_existing_valid_plans := pre_existing_plans (p_signature => l_signature, p_con_id => c_rec.con_id, p_valid_only => 'Y', p_fixed_only => 'N');
        IF l_pre_existing_valid_plans > 0 THEN
          l_pre_existing_fixed_plans := pre_existing_plans (p_signature => l_signature, p_con_id => c_rec.con_id, p_valid_only => 'Y', p_fixed_only => 'Y');
        END IF;
      END IF;
    END IF;    
    /* -------------------------------------------------------------------------------- */  
    --
    -- If there exists a SQL Plan Baseline (SPB) for candidate 
    --
    IF c_rec.sql_plan_baseline IS NOT NULL THEN
      get_spb_rec (
        p_signature => c_rec.exact_matching_signature,
        p_plan_name => c_rec.sql_plan_baseline,
        p_con_id    => c_rec.con_id
      );
      l_us_per_exec_b := b_rec.elapsed_time / GREATEST(b_rec.executions, 1);
      IF b_rec.signature IS NULL THEN -- not expected 
        l_message1 := '*** ERR-00010: SPB is missing!';
      ELSIF b_rec.enabled = 'NO' THEN -- ignore it 
        l_message1 := 'MSG-00180: Skip. SPB already DISABLED.';
      ELSE -- SPB record is available (as expected)
        l_spb_exists := TRUE;
        -- get other_xml
        sql_plan_baseline_other_xml (
          p_signature      => b_rec.signature,
          p_plan_name      => b_rec.plan_name,
          p_con_name       => c_rec.pdb_name,
          r_plan_id        => l_plan_id,
          r_plan_hash      => l_plan_hash,
          r_plan_hash_2    => l_plan_hash_2,
          r_plan_hash_full => l_plan_hash_full,          
          r_other_xml      => l_other_xml
        );
        -- cursor slower than max category threshold
        l_cur_slower_than_cat := (l_us_per_exec_c    / 1e3 > k_spb_thershold_over_cat_max  * c_rec.secs_per_exec_threshold_max * 1e3);
        -- cursor slower than plan when spb was created
        l_cur_slower_than_spb := (l_us_per_exec_c    / 1e3 > k_spb_thershold_over_spf_perf * l_us_per_exec_b                   / 1e3 AND l_us_per_exec_b > 0);
        -- most recent snap slower than max category threshold
        l_mrs_slower_than_cat := (c_rec.mr_avg_et_us / 1e3 > k_spb_thershold_over_cat_max  * c_rec.secs_per_exec_threshold_max * 1e3);
        -- most recent snap slower than plan when spb was created
        l_mrs_slower_than_spb := (c_rec.mr_avg_et_us / 1e3 > k_spb_thershold_over_spf_perf * l_us_per_exec_b                   / 1e3 AND l_us_per_exec_b > 0);
        -- cursor violates category cap 
        l_cur_violates_cat_cap := (l_us_per_exec_c    / 1e3 > k_spb_cap_over_cat_max  * c_rec.secs_per_exec_threshold_max * 1e3);
        -- cursor violates performamce cap 
        l_cur_violates_spb_cap := (l_us_per_exec_c    / 1e3 > k_spb_cap_over_spf_perf * l_us_per_exec_b                   / 1e3 AND l_us_per_exec_b > 0);
        -- cursor is in compliance if it does not violate category cap nor performance cap
        l_cur_in_compliance := NOT l_cur_violates_cat_cap AND NOT l_cur_violates_spb_cap;
        -- most recent snap slower than max category threshold
        --
        IF b_rec.fixed = 'YES' AND l_cur_in_compliance THEN
          IF k_repo_fixed_spb = 'Y' THEN
            l_message1 := 'MSG-00010: Skip. SPB already FIXED.';
            l_spb_already_fixed_count_p := l_spb_already_fixed_count_p + 1;
            l_spb_already_fixed_count_t := l_spb_already_fixed_count_t + 1;
          ELSE
            -- simply ignore.
            l_message1 := 'MSG-00011: Skip. SPB already FIXED.';
            -- adjust candidate counters
            l_candidate_count_t := l_candidate_count_t - 1;
            l_candidate_count_p := l_candidate_count_p - 1;
          END IF;
        ELSIF b_rec.enabled = 'NO' OR b_rec.accepted = 'NO' OR b_rec.reproduced = 'NO' THEN -- not expected
          l_message1 := '*** ERR-00020: SPB is inactive: Enabled='||b_rec.enabled||' Accepted='||b_rec.accepted||' Reproduced='||b_rec.reproduced||'.';
        ELSIF c_rec.avg_execs_per_sec * 3600 < k_execs_per_hr_thershold_spb AND l_cur_in_compliance THEN
          l_message1 := 'MSG-00110: Skip. Not enough execs per hour to promote or demote SPB. Threshold:'||TO_CHAR(ROUND(k_execs_per_hr_thershold_spb, 3), 'FM999,999,990.000')||'. Has:'||TO_CHAR(ROUND(c_rec.avg_execs_per_sec * 3600, 3), 'FM999,999,990.000');
        ELSIF c_rec.mr_execs_per_sec * 3600 < k_execs_per_hr_thershold_spb AND l_cur_in_compliance THEN
          l_message1 := 'MSG-00120: Skip. Not enough execs per hour to promote or demote SPB. Threshold:'||TO_CHAR(ROUND(k_execs_per_hr_thershold_spb, 3), 'FM999,999,990.000')||'. Has:'||TO_CHAR(ROUND(c_rec.mr_execs_per_sec * 3600, 3), 'FM999,999,990.000');        
        ELSIF c_rec.executions < c_rec.executions_threshold AND l_cur_in_compliance THEN
          l_message1 := 'MSG-00130: Skip. Not enough execs to promote or demote SPB. Threshold:'||c_rec.executions_threshold||'. Has:'||c_rec.executions;
        ELSIF l_cur_slower_than_cat -- cursor slower than max category threshold
           OR l_cur_slower_than_spb -- cursor slower than plan when spb was created
           OR l_mrs_slower_than_cat -- most recent snap slower than max category threshold
           OR l_mrs_slower_than_spb -- most recent snap slower than plan when spb was created
           OR l_cur_violates_cat_cap -- cursor slower than category cap
           OR l_cur_violates_spb_cap -- cursor slower than performance cap
        /* ---------------------------------------------------------------------------- */  
        THEN
          --
          -- Demote SPB if underperforms (disable it)
          --
          l_spb_demotion_was_accepted := TRUE;
          l_spb_disable_qualified_p := l_spb_disable_qualified_p + 1;
          l_spb_disable_qualified_t := l_spb_disable_qualified_t + 1;
          --
          l_cur_ms := NVL(TO_CHAR(ROUND(l_us_per_exec_c / 1e3, 3), 'FM999,999,990.000'), '?')||'ms';
          l_mrs_ms := NVL(TO_CHAR(ROUND(c_rec.mr_avg_et_us / 1e3, 3), 'FM999,999,990.000'), '?')||'ms';
          l_cat_ms := k_spb_thershold_over_cat_max||'x '||TO_CHAR(ROUND(c_rec.secs_per_exec_threshold_max * 1e3, 3), 'FM999,999,990.000')||'ms';
          l_spb_ms := k_spb_thershold_over_spf_perf||'x '||TO_CHAR(ROUND(l_us_per_exec_b / 1e3, 3), 'FM999,999,990.000')||'ms';
          --
          l_cat_cap_ms := k_spb_cap_over_cat_max||'x '||TO_CHAR(ROUND(c_rec.secs_per_exec_threshold_max * 1e3, 3), 'FM999,999,990.000')||'ms';
          l_spb_cap_ms := k_spb_cap_over_spf_perf||'x '||TO_CHAR(ROUND(l_us_per_exec_b / 1e3, 3), 'FM999,999,990.000')||'ms';
          --
          IF    l_cur_violates_cat_cap -- cursor slower than category cap
          THEN
            l_message2 := 'MEM Avg ET per Exec > SPB Cap Over Category x Time per Exec Max Threshold: '||
                          l_cur_ms||' > '||l_cat_cap_ms;
          ELSIF l_cur_violates_spb_cap -- cursor slower than performance cap
          THEN
            l_message2 := 'MEM Avg ET per Exec > SPB Cap Over SPB Perf x SPB Avg ET per Exec: '||
                           l_cur_ms||' > '||l_spb_cap_ms;
          ELSIF l_cur_slower_than_cat -- cursor slower than max category threshold
          THEN
            l_message2 := 'MEM Avg ET per Exec > SPB Threshold Over Category x Time per Exec Max Threshold: '||
                          l_cur_ms||' > '||l_cat_ms;
          ELSIF l_cur_slower_than_spb -- cursor slower than plan when spb was created
          THEN
            l_message2 := 'MEM Avg ET per Exec > SPB Threshold Over SPB Perf x SPB Avg ET per Exec: '||
                           l_cur_ms||' > '||l_spb_ms;
          ELSIF l_mrs_slower_than_cat -- most recent snap slower than max category threshold 
          THEN
            l_message2 := 'SNAP:'||NVL(TO_CHAR(c_rec.mr_snap_id), 'NA')||' Avg ET per Exec > SPB Threshold Over Category x Time per Exec Max Threshold: '||
                          l_mrs_ms||' > '||l_cat_ms;
          ELSIF l_mrs_slower_than_spb -- most recent snap slower than plan when spb was created  
          THEN
            l_message2 := 'SNAP:'||NVL(TO_CHAR(c_rec.mr_snap_id), 'NA')||' Avg ET per Exec > SPB Threshold Over SPB Perf x SPB Avg ET per Exec: '||
                          l_mrs_ms||' > '||l_spb_ms;
          END IF;
          --
          l_message3 := '('||
                        'cur:'||l_cur_ms||', '||
                        'mrs:'||l_mrs_ms||', '||
                        'cat:'||l_cat_ms||', '||
                        'spb:'||l_spb_ms||', '||
                        'catc:'||l_cat_ms||', '||
                        'spbc:'||l_spb_ms||
                        ')';
          --
          IF l_spb_disabled_count_t < k_disable_spm_limit AND k_report_only = 'N' THEN
            l_message1 := 'MSG-00020: SPB was demoted (DISABLED)';
            l_spb_disabled_count_p := l_spb_disabled_count_p + 1;
            l_spb_disabled_count_t := l_spb_disabled_count_t + 1;
            -- call dbms_spm
            set_spb_attribute (
              p_sql_handle        => b_rec.sql_handle,
              p_plan_name         => b_rec.plan_name,
              p_con_name          => c_rec.pdb_name,
              p_attribute_name    => 'ENABLED',
              p_attribute_value   => 'NO',
              r_plans             => l_plans_returned
            );
            IF b_rec.description IS NULL THEN
              l_description := 'IOD FPZ LVL='||k_aggressiveness||' SQL_ID='||c_rec.sql_id||' PHV='||c_rec.plan_hash_value||' DISABLED='||TO_CHAR(SYSDATE, gk_date_format);
            ELSE
              l_description := b_rec.description||' PHV='||c_rec.plan_hash_value||' DISABLED='||TO_CHAR(SYSDATE, gk_date_format);
            END IF;
            set_spb_attribute (
              p_sql_handle        => b_rec.sql_handle,
              p_plan_name         => b_rec.plan_name,
              p_con_name          => c_rec.pdb_name,
              p_attribute_name    => 'DESCRIPTION',
              p_attribute_value   => l_description,
              r_plans             => l_plans_returned
            );
            get_spb_rec (
              p_signature         => b_rec.signature,
              p_plan_name         => b_rec.plan_name,
              p_con_id            => c_rec.con_id
            );
            l_us_per_exec_b := b_rec.elapsed_time / GREATEST(b_rec.executions, 1);
          ELSE -- l_spb_disabled_count_t > k_disable_spm_limit OR k_report_only = 'Y'
            l_message1 := 'MSG-00030: SPB qualifies for demotion (DISABLE).';
          END IF; -- l_spb_disabled_count_t < k_disable_spm_limit
        /* ---------------------------------------------------------------------------- */
        --
        -- Existing SPB could be bogus (trying to avoid ORA-13831 as per bug 27496360)
        -- If SPB is suspected bogus then disable it!!!
        --
        --ELSIF c_rec.plan_hash_value <> NVL(l_plan_hash, -666) OR NVL(l_plan_id, 666) <> NVL(l_plan_hash_2, -666) THEN
        --ELSIF NVL(l_plan_id, 666) <> NVL(l_plan_hash_2, -666) THEN
        ELSIF gk_workaround_ora_13831 AND l_plan_id <> l_plan_hash_2 THEN -- if one or both are null, then simply skip this part
          --
          -- Disable SPB if bogus
          --
          l_spb_demotion_was_accepted := TRUE;
          l_spb_disable_qualified_p := l_spb_disable_qualified_p + 1;
          l_spb_disable_qualified_t := l_spb_disable_qualified_t + 1;
          l_13831_found_all_calls := l_13831_found_all_calls + 1;
          l_messaget := 'ERR-00040: ORA-13831 PID<>PH2 PHV:'||c_rec.plan_hash_value||' PH:'||l_plan_hash||' PID:'||l_plan_id||' PH2:'||l_plan_hash_2||' PHF:'||l_plan_hash_full;
          l_message2 := '*** '||l_messaget||'. BOGUS SPB (DISABLED)';
          --
          IF l_spb_disabled_count_t < k_disable_spm_limit AND k_report_only = 'N' THEN
            l_message1 := 'MSG-00140: SPB was demoted (DISABLED)';
            l_spb_disabled_count_p := l_spb_disabled_count_p + 1;
            l_spb_disabled_count_t := l_spb_disabled_count_t + 1;
            -- call dbms_spm
            set_spb_attribute (
              p_sql_handle        => b_rec.sql_handle,
              p_plan_name         => b_rec.plan_name,
              p_con_name          => c_rec.pdb_name,
              p_attribute_name    => 'ENABLED',
              p_attribute_value   => 'NO',
              r_plans             => l_plans_returned
            );
            IF b_rec.description IS NULL THEN
              l_description := 'IOD FPZ LVL='||k_aggressiveness||' SQL_ID='||c_rec.sql_id||' '||l_messaget||' DISABLED='||TO_CHAR(SYSDATE, gk_date_format);
            ELSE
              l_description := b_rec.description||' '||l_messaget||' DISABLED='||TO_CHAR(SYSDATE, gk_date_format);
            END IF;
            set_spb_attribute (
              p_sql_handle        => b_rec.sql_handle,
              p_plan_name         => b_rec.plan_name,
              p_con_name          => c_rec.pdb_name,
              p_attribute_name    => 'DESCRIPTION',
              p_attribute_value   => l_description,
              r_plans             => l_plans_returned
            );
            get_spb_rec (
              p_signature         => b_rec.signature,
              p_plan_name         => b_rec.plan_name,
              p_con_id            => c_rec.con_id
            );
            l_us_per_exec_b := b_rec.elapsed_time / GREATEST(b_rec.executions, 1);
            l_13831_disabled_all_calls := l_13831_disabled_all_calls + 1;
          ELSE -- l_spb_disabled_count_t > k_disable_spm_limit OR k_report_only = 'Y'
            l_message1 := 'MSG-00150: SPB qualifies for demotion (DISABLE)';          
          END IF;
        /* ---------------------------------------------------------------------------- */
        --
        -- Existing SPB could be bogus (trying to avoid ORA-06502 and ORA-06512)
        -- If SPB is suspected bogus then disable it!!!
        --
        ELSIF gk_workaround_ora_06512 AND l_plan_id IS NULL THEN
          --
          -- Disable SPB if bogus
          --
          l_spb_demotion_was_accepted := TRUE;
          l_spb_disable_qualified_p := l_spb_disable_qualified_p + 1;
          l_spb_disable_qualified_t := l_spb_disable_qualified_t + 1;
          l_06512_found_all_calls := l_06512_found_all_calls + 1;
          l_messaget := 'ERR-00070: ORA-06512 MISSING PID';
          l_message2 := '*** '||l_messaget||'. BOGUS SPB (DISABLED)';
          --
          IF l_spb_disabled_count_t < k_disable_spm_limit AND k_report_only = 'N' THEN
            l_message1 := 'MSG-00160: SPB was demoted (DISABLED)';
            l_spb_disabled_count_p := l_spb_disabled_count_p + 1;
            l_spb_disabled_count_t := l_spb_disabled_count_t + 1;
            -- call dbms_spm
            set_spb_attribute (
              p_sql_handle        => b_rec.sql_handle,
              p_plan_name         => b_rec.plan_name,
              p_con_name          => c_rec.pdb_name,
              p_attribute_name    => 'ENABLED',
              p_attribute_value   => 'NO',
              r_plans             => l_plans_returned
            );
            IF b_rec.description IS NULL THEN
              l_description := 'IOD FPZ LVL='||k_aggressiveness||' SQL_ID='||c_rec.sql_id||' '||l_messaget||' DISABLED='||TO_CHAR(SYSDATE, gk_date_format);
            ELSE
              l_description := b_rec.description||' '||l_messaget||' DISABLED='||TO_CHAR(SYSDATE, gk_date_format);
            END IF;
            set_spb_attribute (
              p_sql_handle        => b_rec.sql_handle,
              p_plan_name         => b_rec.plan_name,
              p_con_name          => c_rec.pdb_name,
              p_attribute_name    => 'DESCRIPTION',
              p_attribute_value   => l_description,
              r_plans             => l_plans_returned
            );
            get_spb_rec (
              p_signature         => b_rec.signature,
              p_plan_name         => b_rec.plan_name,
              p_con_id            => c_rec.con_id
            );
            l_us_per_exec_b := b_rec.elapsed_time / GREATEST(b_rec.executions, 1);
            l_06512_disabled_all_calls := l_06512_disabled_all_calls + 1;
          ELSE -- l_spb_disabled_count_t > k_disable_spm_limit OR k_report_only = 'Y'
            l_message1 := 'MSG-00170: SPB qualifies for demotion (DISABLE)';          
          END IF;
        /* ---------------------------------------------------------------------------- */
        --
        -- If existing SQL Plan Baseline (SPB) for candidate is valid then
        -- Evaluate and perform conditional SPB promotion
        --
        ELSIF l_only_plan_demotions = 'Y' THEN
          l_message1 := 'MSG-00041: Promotion evaluation skipped. Only demotions are considered.';
          -- adjust candidate counters
          l_candidate_count_t := l_candidate_count_t - 1;
          l_candidate_count_p := l_candidate_count_p - 1;            
        ELSIF b_rec.created > SYSDATE - k_fixed_mature_days THEN
          l_message1 := 'MSG-00040: SPB promotion to "FIXED" rejected. SPB needs to be older than '||k_fixed_mature_days||' days.';
        --ELSIF b_rec.last_executed < SYSDATE - k_fixed_mature_days THEN (had to remove this, "last_executed" is not reliable)
          --l_message1 := 'MSG-00050: SPB promotion to "FIXED" is rejected at this time. SPB has not been used within the last '||k_fixed_mature_days||' days.';
        ELSIF l_owner IS NULL OR l_table_name IS NULL THEN
          l_message1 := 'MSG-00060: SPB promotion to "FIXED" rejected. Unknown main table.';
        ELSIF l_temporary = 'N' AND (l_last_analyzed IS NULL OR l_num_rows IS NULL) THEN
          l_message1 := 'MSG-00070: SPB promotion to "FIXED" rejected. Main table has no CBO statistics.';
        ELSIF l_num_rows < c_rec.num_rows_min_main_table THEN
          l_message1 := 'MSG-00080: SPB promotion to "FIXED" rejected. Number of rows on main table ('||l_num_rows||') is below required threshold ('||c_rec.num_rows_min_main_table||').';        
        /* ---------------------------------------------------------------------------- */  
        ELSE 
          --
          -- Promote SPB after proven performance (i.e. "fix" it)
          --
          l_spb_promotion_was_accepted := TRUE;
          l_spb_promoted_qualified_p := l_spb_promoted_qualified_p + 1;
          l_spb_promoted_qualified_t := l_spb_promoted_qualified_t + 1;
          IF l_spb_promoted_count_t < k_promote_spm_limit AND k_report_only = 'N' THEN
            l_spb_promoted_count_p := l_spb_promoted_count_p + 1;
            l_spb_promoted_count_t := l_spb_promoted_count_t + 1;
            l_message1 := 'MSG-00090: SPB was promoted (FIXED).';
            l_spb_was_promoted := TRUE;
            -- call dbms_spm
            set_spb_attribute (
              p_sql_handle        => b_rec.sql_handle,
              p_plan_name         => b_rec.plan_name,
              p_con_name          => c_rec.pdb_name,
              p_attribute_name    => 'FIXED',
              p_attribute_value   => 'YES',
              r_plans             => l_plans_returned
            );
            IF b_rec.description IS NULL THEN
              l_description := 'IOD FPZ LVL='||k_aggressiveness||' SQL_ID='||c_rec.sql_id||' PHV='||c_rec.plan_hash_value||' FIXED='||TO_CHAR(SYSDATE, gk_date_format);
            ELSE
              l_description := b_rec.description||' PHV='||c_rec.plan_hash_value||' FIXED='||TO_CHAR(SYSDATE, gk_date_format);
            END IF;
            set_spb_attribute (
              p_sql_handle        => b_rec.sql_handle,
              p_plan_name         => b_rec.plan_name,
              p_con_name          => c_rec.pdb_name,
              p_attribute_name    => 'DESCRIPTION',
              p_attribute_value   => l_description,
              r_plans             => l_plans_returned
            );
            get_spb_rec (
              p_signature         => b_rec.signature,
              p_plan_name         => b_rec.plan_name,
              p_con_id            => c_rec.con_id
            );
            l_us_per_exec_b := b_rec.elapsed_time / GREATEST(b_rec.executions, 1);
          ELSE -- l_spb_promoted_count_t > k_promote_spm_limit OR k_report_only = 'Y'
            l_message1 := 'MSG-00100: SPB qualifies for promotion (FIXED).';
          END IF; -- l_spb_promoted_count_t < k_promote_spm_limit
        END IF; -- b_rec.fixed = 'YES'
      END IF; -- b_rec.signature IS NULL
    /* -------------------------------------------------------------------------------- */  
    ELSE 
      --
      -- If there does not exist a SQL Plan Baseline (SPB) for candidate
      --
      -- First, further screen candidate
      --
      IF l_us_per_exec_c / 1e6 > k_secs_per_exec_cand OR c_rec.executions < k_execs_candidate THEN
        -- simply ignore. this is to make it up for adjusting predicates from mem_plan_metrics and awr_plan_metrics queries on candidate_plan
        l_message1 := 'MSG-01015: Candidate rejected. '||TRIM(TO_CHAR(l_us_per_exec_c/1e3,'999,999,990.000'))||' ms per exec > '||TRIM(TO_CHAR(k_secs_per_exec_cand*1e3,'999,999,990.000'))||' ms threshold, or '||c_rec.executions||' execs < '||k_execs_candidate||' execs threshold.';
        -- adjust candidate counters
        l_candidate_count_t := l_candidate_count_t - 1;
        l_candidate_count_p := l_candidate_count_p - 1;
      ELSIF p_sql_id IS NULL AND SYSDATE - l_instance_startup_time < k_instance_age_days THEN
        l_message1 := 'MSG-01010: SPB rejected. Instance is '||TRUNC(SYSDATE - l_instance_startup_time)||' days old. Has to be older than '||k_instance_age_days||' days.';
      ELSIF c_rec.first_load_time > SYSDATE - k_first_load_time_days THEN
        l_message1 := 'MSG-01020: SPB rejected. SQL''s first load time is too recent. Still within the last '||ROUND(k_first_load_time_days, 1)||' day(s) window.';
      ELSIF c_rec.executions < c_rec.executions_threshold THEN
        l_message1 := 'MSG-01030: SPB rejected. '||c_rec.executions||' executions is less than '||c_rec.executions_threshold||' threshold for this SQL category.';
      ELSIF l_us_per_exec_c / 1e6 > c_rec.secs_per_exec_threshold AND c_rec.metrics_source = k_source_mem THEN
        l_message1 := 'MSG-01040: SPB rejected. "MEM Avg Elapsed Time per Exec" exceeds '||(c_rec.secs_per_exec_threshold * 1e3)||'ms threshold for this SQL category.';
      ELSIF c_rec.mr_avg_et_us / 1e6 > c_rec.secs_per_exec_threshold THEN
        l_message1 := 'MSG-01045: SPB rejected. "SNAP:'||NVL(TO_CHAR(c_rec.mr_snap_id), 'NA')||' Avg ET per Exec" exceeds '||(c_rec.secs_per_exec_threshold * 1e3)||'ms threshold for this SQL category.';
      ELSIF c_rec.avg_avg_et_us / 1e6 > c_rec.secs_per_exec_threshold THEN
        l_message1 := 'MSG-01050: SPB rejected. "AWR Avg Elapsed Time per Exec" exceeds '||(c_rec.secs_per_exec_threshold * 1e3)||'ms threshold for this SQL category.';
      ELSIF c_rec.med_avg_et_us / 1e6 > c_rec.secs_per_exec_threshold THEN
        l_message1 := 'MSG-01060: SPB rejected. "Median Elapsed Time per Exec" exceeds '||(c_rec.secs_per_exec_threshold * 1e3)||'ms threshold for this SQL category.';
      ELSIF c_rec.p90_avg_et_us / 1e6 > k_90th_pctl_factor_cat * c_rec.secs_per_exec_threshold THEN
        l_message1 := 'MSG-01070: SPB rejected. "90th Pctl Elapsed Time per Exec" exceeds '||(k_90th_pctl_factor_cat * c_rec.secs_per_exec_threshold * 1e3)||'ms threshold for this SQL category.';
      ELSIF c_rec.p95_avg_et_us / 1e6 > k_95th_pctl_factor_cat * c_rec.secs_per_exec_threshold THEN
        l_message1 := 'MSG-01080: SPB rejected. "95th Pctl Elapsed Time per Exec" exceeds '||(k_95th_pctl_factor_cat * c_rec.secs_per_exec_threshold * 1e3)||'ms threshold for this SQL category.';
      ELSIF c_rec.p97_avg_et_us / 1e6 > k_97th_pctl_factor_cat * c_rec.secs_per_exec_threshold THEN
        l_message1 := 'MSG-01090: SPB rejected. "97th Pctl Elapsed Time per Exec" exceeds '||(k_97th_pctl_factor_cat * c_rec.secs_per_exec_threshold * 1e3)||'ms threshold for this SQL category.';
      ELSIF c_rec.p99_avg_et_us / 1e6 > k_99th_pctl_factor_cat * c_rec.secs_per_exec_threshold THEN
        l_message1 := 'MSG-01100: SPB rejected. "99th Pctl Elapsed Time per Exec" exceeds '||(k_99th_pctl_factor_cat * c_rec.secs_per_exec_threshold * 1e3)||'ms threshold for this SQL category.';
      ELSIF c_rec.p90_avg_et_us > k_90th_pctl_factor_avg * l_us_per_exec_c     AND c_rec.p90_avg_et_us / 1e6 > c_rec.secs_per_exec_threshold AND c_rec.metrics_source = k_source_mem THEN
        l_message1 := 'MSG-01110: SPB rejected. "90th Pctl Elapsed Time per Exec" exceeds '||k_90th_pctl_factor_avg||'x "MEM Avg Elapsed Time per Exec" threshold.';
      ELSIF c_rec.p90_avg_et_us > k_90th_pctl_factor_avg * c_rec.avg_avg_et_us AND c_rec.p90_avg_et_us / 1e6 > c_rec.secs_per_exec_threshold THEN
        l_message1 := 'MSG-01120: SPB rejected. "90th Pctl Elapsed Time per Exec" exceeds '||k_90th_pctl_factor_avg||'x "AWR Avg Elapsed Time per Exec" threshold.';
      ELSIF c_rec.p90_avg_et_us > k_90th_pctl_factor_avg * c_rec.med_avg_et_us AND c_rec.p90_avg_et_us / 1e6 > c_rec.secs_per_exec_threshold THEN
        l_message1 := 'MSG-01130: SPB rejected. "90th Pctl Elapsed Time per Exec" exceeds '||k_90th_pctl_factor_avg||'x "Median Elapsed Time per Exec" threshold.';
      ELSIF c_rec.p95_avg_et_us > k_95th_pctl_factor_avg * l_us_per_exec_c     AND c_rec.p95_avg_et_us / 1e6 > c_rec.secs_per_exec_threshold AND c_rec.metrics_source = k_source_mem THEN
        l_message1 := 'MSG-01140: SPB rejected. "95th Pctl Elapsed Time per Exec" exceeds '||k_95th_pctl_factor_avg||'x "MEM Avg Elapsed Time per Exec" threshold.';
      ELSIF c_rec.p95_avg_et_us > k_95th_pctl_factor_avg * c_rec.avg_avg_et_us AND c_rec.p95_avg_et_us / 1e6 > c_rec.secs_per_exec_threshold THEN
        l_message1 := 'MSG-01150: SPB rejected. "95th Pctl Elapsed Time per Exec" exceeds '||k_95th_pctl_factor_avg||'x "AWR Avg Elapsed Time per Exec" threshold.';
      ELSIF c_rec.p95_avg_et_us > k_95th_pctl_factor_avg * c_rec.med_avg_et_us AND c_rec.p95_avg_et_us / 1e6 > c_rec.secs_per_exec_threshold THEN
        l_message1 := 'MSG-01160: SPB rejected. "95th Pctl Elapsed Time per Exec" exceeds '||k_95th_pctl_factor_avg||'x "Median Elapsed Time per Exec" threshold.';
      ELSIF c_rec.p97_avg_et_us > k_97th_pctl_factor_avg * l_us_per_exec_c     AND c_rec.p97_avg_et_us / 1e6 > c_rec.secs_per_exec_threshold AND c_rec.metrics_source = k_source_mem THEN
        l_message1 := 'MSG-01170: SPB rejected. "97th Pctl Elapsed Time per Exec" exceeds '||k_97th_pctl_factor_avg||'x "MEM Avg Elapsed Time per Exec" threshold.';
      ELSIF c_rec.p97_avg_et_us > k_97th_pctl_factor_avg * c_rec.avg_avg_et_us AND c_rec.p97_avg_et_us / 1e6 > c_rec.secs_per_exec_threshold THEN
        l_message1 := 'MSG-01180: SPB rejected. "97th Pctl Elapsed Time per Exec" exceeds '||k_97th_pctl_factor_avg||'x "AWR Avg Elapsed Time per Exec" threshold.';
      ELSIF c_rec.p97_avg_et_us > k_97th_pctl_factor_avg * c_rec.med_avg_et_us AND c_rec.p97_avg_et_us / 1e6 > c_rec.secs_per_exec_threshold THEN
        l_message1 := 'MSG-01190: SPB rejected. "97th Pctl Elapsed Time per Exec" exceeds '||k_97th_pctl_factor_avg||'x "Median Elapsed Time per Exec" threshold.';
      ELSIF c_rec.p99_avg_et_us > k_99th_pctl_factor_avg * l_us_per_exec_c     AND c_rec.p99_avg_et_us / 1e6 > c_rec.secs_per_exec_threshold AND c_rec.metrics_source = k_source_mem THEN
        l_message1 := 'MSG-01200: SPB rejected. "99th Pctl Elapsed Time per Exec" exceeds '||k_99th_pctl_factor_avg||'x "MEM Avg Elapsed Time per Exec" threshold.';
      ELSIF c_rec.p99_avg_et_us > k_99th_pctl_factor_avg * c_rec.avg_avg_et_us AND c_rec.p99_avg_et_us / 1e6 > c_rec.secs_per_exec_threshold THEN
        l_message1 := 'MSG-01210: SPB rejected. "99th Pctl Elapsed Time per Exec" exceeds '||k_99th_pctl_factor_avg||'x "AWR Avg Elapsed Time per Exec" threshold.';
      ELSIF c_rec.p99_avg_et_us > k_99th_pctl_factor_avg * c_rec.med_avg_et_us AND c_rec.p99_avg_et_us / 1e6 > c_rec.secs_per_exec_threshold THEN
        l_message1 := 'MSG-01220: SPB rejected. "99th Pctl Elapsed Time per Exec" exceeds '||k_99th_pctl_factor_avg||'x "Median Elapsed Time per Exec" threshold.';
      ELSIF c_rec.metrics_source = k_source_awr AND NVL(c_rec.avg_avg_et_us, 0) = 0 THEN
        l_message1 := 'MSG-01230: SPB rejected. Source is "'||k_source_awr||'" and average elapsed time per execution is null or zero.';
      ELSIF l_owner IS NULL OR l_table_name IS NULL THEN
        l_message1 := 'MSG-01240: SPB rejected. Unknown main table.';
      ELSIF l_temporary = 'N' AND (l_last_analyzed IS NULL OR l_num_rows IS NULL) THEN
        l_message1 := 'MSG-01250: SPB rejected. Main table has no CBO statistics.';
      ELSIF l_num_rows < c_rec.num_rows_min_main_table THEN
        l_message1 := 'MSG-01260: SPB rejected. Number of rows on main table ('||l_num_rows||') is below required threshold ('||c_rec.num_rows_min_main_table||').';        
      ELSIF c_rec.last_load_time < l_last_analyzed - 1 THEN
        l_message1 := 'MSG-01270: SPB rejected. Cursor "last load time" is prior to main table "last analyzed" time for more than 24hrs.';
      ELSIF l_pre_existing_valid_plans > 0 THEN
        l_message1 := 'MSG-01280: SPB rejected. There are '||l_pre_existing_valid_plans||' pre-existing valid plans.';
      /* ------------------------------------------------------------------------------ */  
      ELSE 
        --
        -- Create SPB if candidate is accepted
        --
        l_spb_created_qualified_p := l_spb_created_qualified_p + 1;
        l_spb_created_qualified_t := l_spb_created_qualified_t + 1;
        l_sysdate := SYSDATE;
        l_candidate_was_accepted := TRUE;
        IF l_spb_created_count_t < k_create_spm_limit AND k_report_only = 'N' THEN
          -- call dbms_spm
          IF c_rec.metrics_source = k_source_mem THEN
            IF c_rec.sql_id = l_prior_sql_id THEN
              DBMS_LOCK.SLEEP(k_secs_before_spm_call_sql_id);
            END IF;
            load_plan_from_cursor_cache (
              p_sql_id          => c_rec.sql_id, 
              p_plan_hash_value => c_rec.plan_hash_value,
              p_con_id          => c_rec.con_id,
              p_con_name        => c_rec.pdb_name,
              r_plans           => l_plans_returned
            );
          ELSE -- c_rec.metrics_source = k_source_awr THEN
            IF c_rec.sql_id = l_prior_sql_id THEN
              DBMS_LOCK.SLEEP(k_secs_before_spm_call_sql_id);
            END IF;
            l_sqlset_name := UPPER(c_rec.sql_id||'_'||c_rec.plan_hash_value);
            drop_sqlset (
              p_sqlset_name     => l_sqlset_name,
              p_con_name        => c_rec.pdb_name
            );
            create_and_load_sqlset (
              p_sqlset_name     => l_sqlset_name,
              p_sql_id          => c_rec.sql_id, 
              p_plan_hash_value => c_rec.plan_hash_value,
              p_begin_snap      => l_min_snap_id_sts,
              p_end_snap        => l_max_snap_id,
              p_con_name        => c_rec.pdb_name
            );
            load_plan_from_sqlset (
              p_sqlset_name     => l_sqlset_name,
              p_con_name        => c_rec.pdb_name,
              r_plans           => l_plans_returned
            );
            drop_sqlset (
              p_sqlset_name     => l_sqlset_name,
              p_con_name        => c_rec.pdb_name
            );
          END IF;
          IF l_plans_returned > 0 THEN
            get_sql_handle_and_plan_name (
              p_signature         => l_signature,
              p_sysdate           => l_sysdate,
              p_con_id            => c_rec.con_id,
              r_sql_handle        => l_sql_handle,
              r_plan_name         => l_plan_name
            );
            IF l_sql_handle IS NOT NULL AND l_plan_name IS NOT NULL THEN
              l_description := 'IOD FPZ SRC='||c_rec.src||' LVL='||k_aggressiveness||' SQL_ID='||c_rec.sql_id||' PHV='||c_rec.plan_hash_value||' CREATED='||TO_CHAR(SYSDATE, gk_date_format);
              set_spb_attribute (
                p_sql_handle        => l_sql_handle,
                p_plan_name         => l_plan_name,
                p_con_name          => c_rec.pdb_name,
                p_attribute_name    => 'DESCRIPTION',
                p_attribute_value   => l_description,
                r_plans             => l_plans_returned
              );
            END IF;
            get_spb_rec (
              p_signature         => l_signature,
              p_plan_name         => l_plan_name,
              p_con_id            => c_rec.con_id
            );
            -- get other_xml
            sql_plan_baseline_other_xml (
              p_signature      => l_signature,
              p_plan_name      => l_plan_name,
              p_con_name       => c_rec.pdb_name,
              r_plan_id        => l_plan_id,
              r_plan_hash      => l_plan_hash,
              r_plan_hash_2    => l_plan_hash_2,
              r_plan_hash_full => l_plan_hash_full,          
              r_other_xml      => l_other_xml
            );
            l_us_per_exec_b := b_rec.elapsed_time / GREATEST(b_rec.executions, 1);
            l_spb_created_count_p := l_spb_created_count_p + 1;
            l_spb_created_count_t := l_spb_created_count_t + 1;
            l_spb_exists := TRUE;
            l_message1 := 'MSG-02010: SPB (CREATED).';
            l_spb_was_created := TRUE;
            /* ------------------------------------------------------------------------ */
            --
            -- New SPB could be bogus (trying to avoid ORA-13831 as per bug 27496360)
            -- If SPB is suspected bogus then disable it!!!
            --
            --IF c_rec.plan_hash_value <> NVL(l_plan_hash, -666) OR NVL(l_plan_id, 666) <> NVL(l_plan_hash_2, -666) THEN
            --IF NVL(l_plan_id, 666) <> NVL(l_plan_hash_2, -666) THEN
            IF gk_workaround_ora_13831 AND l_plan_id <> l_plan_hash_2 THEN -- if one or both are null, then simply skip this part
              --
              -- Disable SPB if bogus
              --
              l_spb_demotion_was_accepted := TRUE;
              l_spb_disable_qualified_p := l_spb_disable_qualified_p + 1;
              l_spb_disable_qualified_t := l_spb_disable_qualified_t + 1;
              l_13831_found_all_calls := l_13831_found_all_calls + 1;
              l_messaget := 'ERR-00030: ORA-13831 PID<>PH2 PHV:'||c_rec.plan_hash_value||' PH:'||l_plan_hash||' PID:'||l_plan_id||' PH2:'||l_plan_hash_2||' PHF:'||l_plan_hash_full;
              l_message2 := '*** '||l_messaget||'. BOGUS SPB (DISABLED)';
              l_spb_disabled_count_p := l_spb_disabled_count_p + 1;
              l_spb_disabled_count_t := l_spb_disabled_count_t + 1;
              -- call dbms_spm
              set_spb_attribute (
                p_sql_handle        => b_rec.sql_handle,
                p_plan_name         => b_rec.plan_name,
                p_con_name          => c_rec.pdb_name,
                p_attribute_name    => 'ENABLED',
                p_attribute_value   => 'NO',
                r_plans             => l_plans_returned
              );
              IF b_rec.description IS NULL THEN
                l_description := 'IOD FPZ LVL='||k_aggressiveness||' SQL_ID='||c_rec.sql_id||' '||l_messaget||' DISABLED='||TO_CHAR(SYSDATE, gk_date_format);
              ELSE
                l_description := b_rec.description||' '||l_messaget||' DISABLED='||TO_CHAR(SYSDATE, gk_date_format);
              END IF;
              set_spb_attribute (
                p_sql_handle        => b_rec.sql_handle,
                p_plan_name         => b_rec.plan_name,
                p_con_name          => c_rec.pdb_name,
                p_attribute_name    => 'DESCRIPTION',
                p_attribute_value   => l_description,
                r_plans             => l_plans_returned
              );
              get_spb_rec (
                p_signature         => b_rec.signature,
                p_plan_name         => b_rec.plan_name,
                p_con_id            => c_rec.con_id
              );
              l_us_per_exec_b := b_rec.elapsed_time / GREATEST(b_rec.executions, 1);
              l_13831_disabled_all_calls := l_13831_disabled_all_calls + 1;
            END IF; -- l_plan_id <> l_plan_hash_2
            /* ------------------------------------------------------------------------ */
            --
            -- New SPB could be bogus (trying to avoid ORA-06502 and ORA-06512)
            -- If SPB is suspected bogus then disable it!!!
            --
            IF gk_workaround_ora_06512 AND l_plan_id IS NULL THEN
              --
              -- Disable SPB if bogus
              --
              l_spb_demotion_was_accepted := TRUE;
              l_spb_disable_qualified_p := l_spb_disable_qualified_p + 1;
              l_spb_disable_qualified_t := l_spb_disable_qualified_t + 1;
              l_06512_found_all_calls := l_06512_found_all_calls + 1;
              l_messaget := 'ERR-00080: ORA-06512 MISSING PID';
              l_message2 := '*** '||l_messaget||'. BOGUS SPB (DISABLED)';
              l_spb_disabled_count_p := l_spb_disabled_count_p + 1;
              l_spb_disabled_count_t := l_spb_disabled_count_t + 1;
              -- call dbms_spm
              set_spb_attribute (
                p_sql_handle        => b_rec.sql_handle,
                p_plan_name         => b_rec.plan_name,
                p_con_name          => c_rec.pdb_name,
                p_attribute_name    => 'ENABLED',
                p_attribute_value   => 'NO',
                r_plans             => l_plans_returned
              );
              IF b_rec.description IS NULL THEN
                l_description := 'IOD FPZ LVL='||k_aggressiveness||' SQL_ID='||c_rec.sql_id||' '||l_messaget||' DISABLED='||TO_CHAR(SYSDATE, gk_date_format);
              ELSE
                l_description := b_rec.description||' '||l_messaget||' DISABLED='||TO_CHAR(SYSDATE, gk_date_format);
              END IF;
              set_spb_attribute (
                p_sql_handle        => b_rec.sql_handle,
                p_plan_name         => b_rec.plan_name,
                p_con_name          => c_rec.pdb_name,
                p_attribute_name    => 'DESCRIPTION',
                p_attribute_value   => l_description,
                r_plans             => l_plans_returned
              );
              get_spb_rec (
                p_signature         => b_rec.signature,
                p_plan_name         => b_rec.plan_name,
                p_con_id            => c_rec.con_id
              );
              l_us_per_exec_b := b_rec.elapsed_time / GREATEST(b_rec.executions, 1);
              l_06512_disabled_all_calls := l_06512_disabled_all_calls + 1;
            END IF; -- NVL(l_plan_id, 666) <> NVL(l_plan_hash_2, -666)
          ELSIF l_plans_returned = -1 THEN
            l_message1 := 'MSG-02022: Plan qualifies for SPB (CREATION). But there are no valid cursors as per: status, is_obsolete and is_shareable v$sql attributes.';
          ELSE
            l_message1 := 'MSG-02020: Plan qualifies for SPB (CREATION). But load API returned no plans.';
            l_message2 := 'MSG-02025: sqlset='||l_sqlset_name||', min_snap_id='||l_min_snap_id_sts||', max_snap_id:'||l_max_snap_id;
          END IF;
        ELSE -- l_spb_created_count_t > k_create_spm_limit OR k_report_only = 'Y'
          l_message1 := 'MSG-02030: Plan qualifies for SPB (CREATION).';
        END IF; -- l_spb_created_count_t < k_create_spm_limit
      END IF; -- c_rec.first_load_time > SYSDATE - k_first_load_time_days
    END IF; -- If there exists a SQL Plan Baseline (SPB) for candidate 
    /* -------------------------------------------------------------------------------- */  
    -- Output cursor details
    IF k_repo_rejected_candidates = 'Y' OR 
       k_repo_non_promoted_spb = 'Y'    OR 
       k_repo_fixed_spb = 'Y'           OR 
       l_candidate_was_accepted         OR 
       l_spb_demotion_was_accepted      OR 
       l_spb_promotion_was_accepted 
    THEN
      output(RPAD('+', gk_output_part_1_length + 5 + gk_output_part_2_length, '-'));
      output('|');
      output('FPZ Aggressiveness',            k_aggressiveness||' (1-5) 1=conservative, 3=moderate, 5=aggressive');
      output('Candidate Number',              l_candidate_count_t);
      output('Plugable Database (PDB)',       c_rec.pdb_name||' ('||c_rec.con_id||')');
      output('KIEV PDB',                      c_rec.kiev_pdb);      
      output('Parsing Schema Name',           c_rec.parsing_schema_name);
      output('Application Category',          c_rec.application_category);
      output('SQL ID',                        c_rec.sql_id);
      output('SQL Text',                      REPLACE(REPLACE(c_rec.sql_text, CHR(10), CHR(32)), CHR(9), CHR(32)));
      output('Plan Hash Value (PHV)',         c_rec.plan_hash_value);
      output('Metrics Source',                c_rec.metrics_source);
      IF c_rec.metrics_source = k_source_mem THEN
        output('Child Cursors',               c_rec.child_cursors);
        IF c_rec.child_cursors > 1 THEN
          output('Min Child Number',          c_rec.min_child_number);
          output('Max Child Number',          c_rec.max_child_number);
        END IF;
      END IF;
      output('Executions',                    c_rec.executions);
      output('Buffer Gets',                   c_rec.buffer_gets);
      output('Disk Reads',                    c_rec.disk_reads);
      output('Rows Processed',                c_rec.rows_processed);
      output('Shared Memory (bytes)',         c_rec.sharable_mem);
      output('Elapsed Time (us)',             c_rec.elapsed_time);
      output('CPU Time (us)',                 c_rec.cpu_time);
      output('User I/O Wait Time (us)',       c_rec.user_io_wait_time);
      output('Application Wait Time (us)',    c_rec.application_wait_time);
      output('Concurrency Wait Time (us)',    c_rec.concurrency_wait_time);
      IF NVL(c_rec.min_optimizer_cost, -1) <> NVL(c_rec.max_optimizer_cost, -2) THEN
        output('Min Optimizer Cost',          c_rec.min_optimizer_cost);
        output('Max Optimizer Cost',          c_rec.max_optimizer_cost);
      ELSE
        output('Optimizer Cost',              c_rec.min_optimizer_cost);
      END IF;
      output('Module',                        c_rec.module);
      output('Action',                        c_rec.action);
      output('Last Active Time (Plan)',       TO_CHAR(c_rec.last_active_time, gk_date_format));
      output('Last Load Time',                TO_CHAR(c_rec.last_load_time, gk_date_format));
      output('First Load Time',               TO_CHAR(c_rec.first_load_time, gk_date_format));
      output('Exact Matching Signature',      l_signature);
      output('SQL Handle',                    l_sql_handle);
      output('SQL Plan Baseline (SPB)',       c_rec.sql_plan_baseline);
      output('SQL Profile',                   c_rec.sql_profile);
      output('SQL Patch',                     c_rec.sql_patch);
      output('|');
      output('Critical Application',          c_rec.critical_application);
      output('Executions Threshold',          c_rec.executions_threshold||' (category range:0-'||c_rec.executions_threshold_max||')');
      output('Time per Exec Threshold (ms)',  TO_CHAR(c_rec.secs_per_exec_threshold * 1e3, 'FM999,990.000')||' (ms) (category range:0-'||
                                              TO_CHAR(c_rec.secs_per_exec_threshold_max * 1e3, 'FM999,990.000')||')');
      output('Min Rows Threshold',            c_rec.num_rows_min_main_table);
      output('|');
      output('Main Table - Owner',            l_owner);
      output('Main Table - Name',             l_table_name);
      output('Main Table - Temporary',        l_temporary);
      output('Main Table - Blocks',           l_blocks);
      output('Main Table - Num Rows',         l_num_rows);
      output('Main Table - Avg Row Len',      l_avg_row_len);
      output('Main Table - Last Analyzed',    TO_CHAR(l_last_analyzed, gk_date_format));
      -- Output plan performance metrics
      IF c_rec.mr_snap_id IS NOT NULL THEN
        output('|');
        output('Oldest Snap ID for plan',     c_rec.phv_min_snap_id);
        --output('Max Snap ID',                 c_rec.phv_max_snap_id);
        output('Most Recent Snap ID (mrs)',   c_rec.mr_snap_id);      
        output('Begin Interval Time (mrs)',   TO_CHAR(c_rec.mr_begin_interval_time, gk_date_format));      
        output('End Interval Time (mrs)',     TO_CHAR(c_rec.mr_end_interval_time, gk_date_format));      
        output('Interval in Seconds (mrs)',   ROUND(c_rec.mr_interval_secs)||'s');      
      END IF;
      output('|');
      output(
        'Plan Performance Metrics',
        'MEM Avg',
        'SNAP:'||NVL(TO_CHAR(c_rec.mr_snap_id), 'NA'),
        'SPB Avg',
        'AWR Avg',
        'Median',
        '90th Pctl',
        '95th Pctl',
        '97th Pctl',
        '99th Pctl',
        'Maximum'
      );
      output(
        '(with '||TRIM(TO_CHAR(NVL(c_rec.awr_snapshots, 0), 'FM99,990'))||' AWR snapshots)',
        LPAD('-', gk_output_metrics_length, '-'),        
        LPAD('-', gk_output_metrics_length, '-'),        
        LPAD('-', gk_output_metrics_length, '-'),        
        LPAD('-', gk_output_metrics_length, '-'),        
        LPAD('-', gk_output_metrics_length, '-'),        
        LPAD('-', gk_output_metrics_length, '-'),        
        LPAD('-', gk_output_metrics_length, '-'),        
        LPAD('-', gk_output_metrics_length, '-'),        
        LPAD('-', gk_output_metrics_length, '-'),        
        LPAD('-', gk_output_metrics_length, '-')
      );      
      output(
        'Avg Elapsed Time per Exec (ms)',
        TO_CHAR(ROUND(l_us_per_exec_c / 1e3, 3), 'FM999,999,990.000'),
        TO_CHAR(ROUND(c_rec.mr_avg_et_us / 1e3, 3), 'FM999,999,990.000'),
        TO_CHAR(ROUND(b_rec.elapsed_time / GREATEST(b_rec.executions, 1) / 1e3, 3), 'FM999,999,990.000'),
        TO_CHAR(ROUND(c_rec.avg_avg_et_us / 1e3, 3), 'FM999,999,990.000'),
        TO_CHAR(ROUND(c_rec.med_avg_et_us / 1e3, 3), 'FM999,999,990.000'),
        TO_CHAR(ROUND(c_rec.p90_avg_et_us / 1e3, 3), 'FM999,999,990.000'),
        TO_CHAR(ROUND(c_rec.p95_avg_et_us / 1e3, 3), 'FM999,999,990.000'),
        TO_CHAR(ROUND(c_rec.p97_avg_et_us / 1e3, 3), 'FM999,999,990.000'),
        TO_CHAR(ROUND(c_rec.p99_avg_et_us / 1e3, 3), 'FM999,999,990.000'),
        TO_CHAR(ROUND(c_rec.max_avg_et_us / 1e3, 3), 'FM999,999,990.000')
        );
      output(
        'Avg CPU Time per Exec (ms)',
        TO_CHAR(ROUND(c_rec.cpu_time / GREATEST(c_rec.executions, 1) / 1e3, 3), 'FM999,999,990.000'),
        TO_CHAR(ROUND(c_rec.mr_avg_cpu_us / 1e3, 3), 'FM999,999,990.000'),
        TO_CHAR(ROUND(b_rec.cpu_time / GREATEST(b_rec.executions, 1) / 1e3, 3), 'FM999,999,990.000'),
        TO_CHAR(ROUND(c_rec.avg_avg_cpu_us / 1e3, 3), 'FM999,999,990.000'),
        TO_CHAR(ROUND(c_rec.med_avg_cpu_us / 1e3, 3), 'FM999,999,990.000'),
        TO_CHAR(ROUND(c_rec.p90_avg_cpu_us / 1e3, 3), 'FM999,999,990.000'),
        TO_CHAR(ROUND(c_rec.p95_avg_cpu_us / 1e3, 3), 'FM999,999,990.000'),
        TO_CHAR(ROUND(c_rec.p97_avg_cpu_us / 1e3, 3), 'FM999,999,990.000'),
        TO_CHAR(ROUND(c_rec.p99_avg_cpu_us / 1e3, 3), 'FM999,999,990.000'),
        TO_CHAR(ROUND(c_rec.max_avg_cpu_us / 1e3, 3), 'FM999,999,990.000')
        );
      output(
        'Avg User I/O Time per Exec (ms)',
        TO_CHAR(ROUND(c_rec.user_io_wait_time / GREATEST(c_rec.executions, 1) / 1e3, 3), 'FM999,999,990.000'),
        TO_CHAR(ROUND(c_rec.mr_avg_user_io_us / 1e3, 3), 'FM999,999,990.000'),
        NULL,
        TO_CHAR(ROUND(c_rec.avg_avg_user_io_us / 1e3, 3), 'FM999,999,990.000'),
        TO_CHAR(ROUND(c_rec.med_avg_user_io_us / 1e3, 3), 'FM999,999,990.000'),
        TO_CHAR(ROUND(c_rec.p90_avg_user_io_us / 1e3, 3), 'FM999,999,990.000'),
        TO_CHAR(ROUND(c_rec.p95_avg_user_io_us / 1e3, 3), 'FM999,999,990.000'),
        TO_CHAR(ROUND(c_rec.p97_avg_user_io_us / 1e3, 3), 'FM999,999,990.000'),
        TO_CHAR(ROUND(c_rec.p99_avg_user_io_us / 1e3, 3), 'FM999,999,990.000'),
        TO_CHAR(ROUND(c_rec.max_avg_user_io_us / 1e3, 3), 'FM999,999,990.000')
        );
      output(
        'Avg Appl Time per Exec (ms)',
        TO_CHAR(ROUND(c_rec.application_wait_time / GREATEST(c_rec.executions, 1) / 1e3, 3), 'FM999,999,990.000'),
        TO_CHAR(ROUND(c_rec.mr_avg_application_us / 1e3, 3), 'FM999,999,990.000'),
        NULL,
        TO_CHAR(ROUND(c_rec.avg_avg_application_us / 1e3, 3), 'FM999,999,990.000'),
        TO_CHAR(ROUND(c_rec.med_avg_application_us / 1e3, 3), 'FM999,999,990.000'),
        TO_CHAR(ROUND(c_rec.p90_avg_application_us / 1e3, 3), 'FM999,999,990.000'),
        TO_CHAR(ROUND(c_rec.p95_avg_application_us / 1e3, 3), 'FM999,999,990.000'),
        TO_CHAR(ROUND(c_rec.p97_avg_application_us / 1e3, 3), 'FM999,999,990.000'),
        TO_CHAR(ROUND(c_rec.p99_avg_application_us / 1e3, 3), 'FM999,999,990.000'),
        TO_CHAR(ROUND(c_rec.max_avg_application_us / 1e3, 3), 'FM999,999,990.000')
        );
      output(
        'Avg Conc Time per Exec (ms)',
        TO_CHAR(ROUND(c_rec.concurrency_wait_time / GREATEST(c_rec.executions, 1) / 1e3, 3), 'FM999,999,990.000'),
        TO_CHAR(ROUND(c_rec.mr_avg_concurrency_us / 1e3, 3), 'FM999,999,990.000'),
        NULL,
        TO_CHAR(ROUND(c_rec.avg_avg_concurrency_us / 1e3, 3), 'FM999,999,990.000'),
        TO_CHAR(ROUND(c_rec.med_avg_concurrency_us / 1e3, 3), 'FM999,999,990.000'),
        TO_CHAR(ROUND(c_rec.p90_avg_concurrency_us / 1e3, 3), 'FM999,999,990.000'),
        TO_CHAR(ROUND(c_rec.p95_avg_concurrency_us / 1e3, 3), 'FM999,999,990.000'),
        TO_CHAR(ROUND(c_rec.p97_avg_concurrency_us / 1e3, 3), 'FM999,999,990.000'),
        TO_CHAR(ROUND(c_rec.p99_avg_concurrency_us / 1e3, 3), 'FM999,999,990.000'),
        TO_CHAR(ROUND(c_rec.max_avg_concurrency_us / 1e3, 3), 'FM999,999,990.000')
        );
      output(
        'Avg Executions (per second)',
        NULL,
        TO_CHAR(ROUND(c_rec.mr_execs_per_sec, 3), 'FM999,999,990.000'),
        NULL,
        TO_CHAR(ROUND(c_rec.avg_execs_per_sec, 3), 'FM999,999,990.000'),
        TO_CHAR(ROUND(c_rec.med_execs_per_sec, 3), 'FM999,999,990.000'),
        TO_CHAR(ROUND(c_rec.p90_execs_per_sec, 3), 'FM999,999,990.000'),
        TO_CHAR(ROUND(c_rec.p95_execs_per_sec, 3), 'FM999,999,990.000'),
        TO_CHAR(ROUND(c_rec.p97_execs_per_sec, 3), 'FM999,999,990.000'),
        TO_CHAR(ROUND(c_rec.p99_execs_per_sec, 3), 'FM999,999,990.000'),
        TO_CHAR(ROUND(c_rec.max_execs_per_sec, 3), 'FM999,999,990.000')
        );
      output(
        'Avg Rows Processed per Exec',
        TO_CHAR(ROUND(c_rec.rows_processed / GREATEST(c_rec.executions, 1), 3), 'FM999,999,990.000'),
        TO_CHAR(ROUND(c_rec.mr_rows_processed_per_exec, 3), 'FM999,999,990.000'),
        TO_CHAR(ROUND(b_rec.rows_processed / GREATEST(b_rec.executions, 1), 3), 'FM999,999,990.000'),
        TO_CHAR(ROUND(c_rec.avg_rows_processed_per_exec, 3), 'FM999,999,990.000'),
        TO_CHAR(ROUND(c_rec.med_rows_processed_per_exec, 3), 'FM999,999,990.000'),
        TO_CHAR(ROUND(c_rec.p90_rows_processed_per_exec, 3), 'FM999,999,990.000'),
        TO_CHAR(ROUND(c_rec.p95_rows_processed_per_exec, 3), 'FM999,999,990.000'),
        TO_CHAR(ROUND(c_rec.p97_rows_processed_per_exec, 3), 'FM999,999,990.000'),
        TO_CHAR(ROUND(c_rec.p99_rows_processed_per_exec, 3), 'FM999,999,990.000'),
        TO_CHAR(ROUND(c_rec.max_rows_processed_per_exec, 3), 'FM999,999,990.000')
        );
      output(
        'Avg Buffer Gets per Exec',
        TO_CHAR(ROUND(c_rec.buffer_gets / GREATEST(c_rec.executions, 1)), 'FM999,999,999,990'),
        TO_CHAR(ROUND(c_rec.mr_buffer_gets_per_exec), 'FM999,999,999,990'),
        TO_CHAR(ROUND(b_rec.buffer_gets / GREATEST(b_rec.executions, 1)), 'FM999,999,999,990'),
        TO_CHAR(ROUND(c_rec.avg_buffer_gets_per_exec), 'FM999,999,999,990'),
        TO_CHAR(ROUND(c_rec.med_buffer_gets_per_exec), 'FM999,999,999,990'),
        TO_CHAR(ROUND(c_rec.p90_buffer_gets_per_exec), 'FM999,999,999,990'),
        TO_CHAR(ROUND(c_rec.p95_buffer_gets_per_exec), 'FM999,999,999,990'),
        TO_CHAR(ROUND(c_rec.p97_buffer_gets_per_exec), 'FM999,999,999,990'),
        TO_CHAR(ROUND(c_rec.p99_buffer_gets_per_exec), 'FM999,999,999,990'),
        TO_CHAR(ROUND(c_rec.max_buffer_gets_per_exec), 'FM999,999,999,990')
        );
      output(
        'Avg Disk Reads per Exec',
        TO_CHAR(ROUND(c_rec.disk_reads / GREATEST(c_rec.executions, 1)), 'FM999,999,999,990'),
        TO_CHAR(ROUND(c_rec.mr_disk_reads_per_exec), 'FM999,999,999,990'),
        TO_CHAR(ROUND(b_rec.disk_reads / GREATEST(b_rec.executions, 1)), 'FM999,999,999,990'),
        TO_CHAR(ROUND(c_rec.avg_disk_reads_per_exec), 'FM999,999,999,990'),
        TO_CHAR(ROUND(c_rec.med_disk_reads_per_exec), 'FM999,999,999,990'),
        TO_CHAR(ROUND(c_rec.p90_disk_reads_per_exec), 'FM999,999,999,990'),
        TO_CHAR(ROUND(c_rec.p95_disk_reads_per_exec), 'FM999,999,999,990'),
        TO_CHAR(ROUND(c_rec.p97_disk_reads_per_exec), 'FM999,999,999,990'),
        TO_CHAR(ROUND(c_rec.p99_disk_reads_per_exec), 'FM999,999,999,990'),
        TO_CHAR(ROUND(c_rec.max_disk_reads_per_exec), 'FM999,999,999,990')
        );
      output(
        'Sum Shared Memory (MBs)',
        TO_CHAR(ROUND(c_rec.sharable_mem / POWER(2, 20), 3), 'FM999,999,990.000'),
        TO_CHAR(ROUND(c_rec.mr_sharable_mem / POWER(2, 20), 3), 'FM999,999,990.000'),
        NULL,
        TO_CHAR(ROUND(c_rec.avg_sharable_mem / POWER(2, 20), 3), 'FM999,999,990.000'),
        TO_CHAR(ROUND(c_rec.med_sharable_mem / POWER(2, 20), 3), 'FM999,999,990.000'),
        TO_CHAR(ROUND(c_rec.p90_sharable_mem / POWER(2, 20), 3), 'FM999,999,990.000'),
        TO_CHAR(ROUND(c_rec.p95_sharable_mem / POWER(2, 20), 3), 'FM999,999,990.000'),
        TO_CHAR(ROUND(c_rec.p97_sharable_mem / POWER(2, 20), 3), 'FM999,999,990.000'),
        TO_CHAR(ROUND(c_rec.p99_sharable_mem / POWER(2, 20), 3), 'FM999,999,990.000'),
        TO_CHAR(ROUND(c_rec.max_sharable_mem / POWER(2, 20), 3), 'FM999,999,990.000')
        );
      -- pre-existing SPB valid plans
      output('|');
      output('Pre-existing SPB Plans',        l_pre_existing_plans);
      output('Pre-existing Valid SPB Plans',  l_pre_existing_valid_plans);
      output('Pre-existing Fixed SPB Plans',  l_pre_existing_fixed_plans);
      -- Output SQL Plan Baseline details
      IF b_rec.signature IS NOT NULL AND (l_spb_exists OR l_spb_demotion_was_accepted OR l_spb_promotion_was_accepted) THEN
        output('|');
        output('Signature',                   b_rec.signature);
        output('SQL Handle',                  b_rec.sql_handle);
        output('Plan Name',                   b_rec.plan_name);
        output('Plan Id',                     l_plan_id);
        output('Plan Hash',                   l_plan_hash);
        output('Plan Hash 2',                 l_plan_hash_2);
        output('Plan Hash Full',              l_plan_hash_full);
        output('Creator',                     b_rec.creator);
        output('Origin',                      b_rec.origin);
        output('Parsing Schema Name',         b_rec.parsing_schema_name);
        output('Description',                 b_rec.description);
        output('Version',                     b_rec.version);
        output('Enabled',                     b_rec.enabled);
        output('Accepted',                    b_rec.accepted);
        output('Fixed',                       b_rec.fixed);
        output('Reproduced',                  b_rec.reproduced);
        output('Autopurge',                   b_rec.autopurge);
        output('Adaptive',                    b_rec.adaptive);
        output('Executions',                  b_rec.executions);
        output('Buffer Gets',                 b_rec.buffer_gets);
        output('Disk Reads',                  b_rec.disk_reads);
        output('Rows Processed',              b_rec.rows_processed);
        output('Elapsed Time (us)',           b_rec.elapsed_time);
        output('CPU Time (us)',               b_rec.cpu_time);
        output('Optimizer Cost',              b_rec.optimizer_cost);
        output('Module',                      b_rec.module);
        output('Action',                      b_rec.action);
        output('Last Executed',               TO_CHAR(b_rec.last_executed, gk_date_format));
        output('Last Modified',               TO_CHAR(b_rec.last_modified, gk_date_format));
        output('Last Verified',               TO_CHAR(b_rec.last_verified, gk_date_format));
        output('Created',                     TO_CHAR(b_rec.created, gk_date_format));
      END IF; -- Output SQL Plan Baseline details
      IF l_message1||l_message2||l_message3 IS NOT NULL THEN
        output('|');
        output('Message',                     SUBSTR(l_message1, 1, gk_output_part_2_length));
        output(NULL,                          SUBSTR(l_message2, 1, gk_output_part_2_length));
        output(NULL,                          SUBSTR(l_message3, 1, gk_output_part_2_length));
        output(NULL,                          RPAD('~', GREATEST(LENGTH(l_message1), NVL(LENGTH(l_message2), 0), NVL(LENGTH(l_message3), 0)), '~'));
      END IF;
      IF k_display_plan = 'Y' AND c_rec.metrics_source = k_source_mem /*AND NOT l_spb_was_promoted AND NOT l_spb_was_created*/ THEN
        output('|');
        output('Child Number',                c_rec.l_child_number);
        output('Is Obsolete?',                c_rec.l_is_obsolete);
        output('Is Shareable?',               c_rec.l_is_shareable);
        output('Object Status',               c_rec.l_object_status);
        output('Last Active Time (Child)',    TO_CHAR(c_rec.l_last_active_time, gk_date_format));
        output('|');
        FOR pln_rec IN (SELECT plan_table_output FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(c_rec.sql_id, c_rec.l_child_number, k_display_plan_format)))
        LOOP
          output('| '||pln_rec.plan_table_output);
        END LOOP;
      END IF;
      IF k_display_plan = 'Y' AND c_rec.metrics_source = k_source_awr THEN
        output('|');
        FOR pln_rec IN (SELECT plan_table_output FROM TABLE(DBMS_XPLAN.DISPLAY_AWR(c_rec.sql_id, c_rec.plan_hash_value, l_dbid, k_display_plan_format, c_rec.con_id)))
        LOOP
          output('| '||pln_rec.plan_table_output);
        END LOOP;
      END IF;
      --IF k_display_plan = 'Y' AND (l_spb_exists OR l_spb_demotion_was_accepted OR l_spb_promotion_was_accepted) AND c_rec.con_id = l_con_id THEN
      IF k_display_plan = 'Y' AND (l_spb_exists OR l_spb_demotion_was_accepted OR l_spb_promotion_was_accepted) THEN
        output('|');
        /*
        FOR pln_rec IN (SELECT plan_table_output FROM TABLE(DBMS_XPLAN.DISPLAY_SQL_PLAN_BASELINE(b_rec.sql_handle, b_rec.plan_name, k_display_plan_format)))
        LOOP
          output('| '||pln_rec.plan_table_output);
        END LOOP;
        */
        display_sql_plan_baseline (
          p_sql_handle => b_rec.sql_handle,
          p_plan_name  => b_rec.plan_name,
          p_con_name   => c_rec.pdb_name,
          r_plan_clob  => l_spb_plan
        );
        l_prior := 1;
        l_next := 1;
        WHILE l_next > 0
        LOOP
          l_next := DBMS_LOB.INSTR(l_spb_plan, CHR(10), l_prior);
          output('| '||DBMS_LOB.SUBSTR(l_spb_plan, l_next - l_prior, l_prior));
          l_prior := l_next + 1;
        END LOOP;
        --output('|');
      END IF; 
      IF k_display_plan = 'N' THEN
        output('|');
      END IF;
      output(RPAD('+', gk_output_part_1_length + 5 + gk_output_part_2_length, '-'));
    END IF; -- Output cursor details
    l_pdb_name_prior := c_rec.pdb_name;
    l_con_id_prior := c_rec.con_id;
    l_prior_sql_id := c_rec.sql_id;
    -- 
    -- persistent log
    --
    h_rec.con_id                         := c_rec.con_id;
    h_rec.sql_id                         := c_rec.sql_id;
    h_rec.snap_id                        := l_snap_id;
    h_rec.snap_time                      := SYSDATE;
    h_rec.plan_hash_value                := c_rec.plan_hash_value;
    h_rec.plan_hash_2                    := l_plan_hash_2;
    h_rec.plan_hash_full                 := l_plan_hash_full;
    h_rec.plan_id                        := l_plan_id;
    h_rec.src                            := c_rec.src;
    h_rec.parsing_schema_name            := c_rec.parsing_schema_name;
    h_rec.signature                      := NVL(c_rec.exact_matching_signature, NVL(l_signature, b_rec.signature));
    h_rec.sql_profile_name               := c_rec.sql_profile;
    h_rec.sql_patch_name                 := c_rec.sql_patch;
    h_rec.sql_handle                     := NVL(l_sql_handle, b_rec.sql_handle);
    h_rec.spb_plan_name                  := NVL(c_rec.sql_plan_baseline, NVL(l_plan_name, b_rec.plan_name));
    h_rec.spb_description                := l_description;
    h_rec.spb_created                    := b_rec.created;
    h_rec.spb_last_modified              := b_rec.last_modified;
    h_rec.spb_enabled                    := b_rec.enabled;
    h_rec.spb_accepted                   := b_rec.accepted;
    h_rec.spb_fixed                      := b_rec.fixed;
    h_rec.spb_reproduced                 := b_rec.reproduced;
    h_rec.optimizer_cost                 := NVL(b_rec.optimizer_cost, ROUND((c_rec.min_optimizer_cost + c_rec.max_optimizer_cost) / 2));
    h_rec.executions                     := c_rec.executions;
    h_rec.elapsed_time                   := c_rec.elapsed_time;
    h_rec.cpu_time                       := c_rec.cpu_time;
    h_rec.buffer_gets                    := c_rec.buffer_gets;
    h_rec.disk_reads                     := c_rec.disk_reads;
    h_rec.rows_processed                 := c_rec.rows_processed;
    h_rec.pdb_name                       := c_rec.pdb_name;
    h_rec.zapper_aggressiveness          := p_aggressiveness;
    h_rec.zapper_action                  := l_action;
    h_rec.zapper_message1                := l_message1;
    h_rec.zapper_message2                := l_message2;
    h_rec.zapper_message3                := l_message3;
    h_rec.zapper_report                  := l_zapper_report;
    l_zapper_report_enabled              := FALSE;
    INSERT INTO &&1..sql_plan_baseline_hist VALUES h_rec;
    COMMIT;
    DBMS_LOB.freetemporary(lob_loc => l_zapper_report);
    --
  END LOOP;
  --
  /* ---------------------------------------------------------------------------------- */  
  -- output footer
  IF l_candidate_count_p > 0 AND l_pdb_name_prior <> l_pdb_name AND l_pdb_name_prior <> '-666' AND NVL(k_pdb_name, 'ALL') = 'ALL' THEN
    output(RPAD('+', gk_output_part_1_length + 5 + gk_output_part_2_length, '-'));
    output('|');
    output('Plugable Database (PDB)',         l_pdb_name_prior||' ('||l_con_id_prior||')');
    output('Candidates',                      l_candidate_count_p);
    output('SPBs Qualified for Creation',     l_spb_created_qualified_p);
    output('SPBs Created',                    l_spb_created_count_p);
    output('SPBs Qualified for Promotion',    l_spb_promoted_qualified_p);
    output('SPBs Promoted',                   l_spb_promoted_count_p);
    output('SPBs Qualified for Demotion',     l_spb_disable_qualified_p);
    output('SPBs Demoted',                    l_spb_disabled_count_p);
    output('SPBs already Fixed',              l_spb_already_fixed_count_p);
    output('Date and Time',                   TO_CHAR(SYSDATE, gk_date_format));
    output('|');
    output(RPAD('+', gk_output_part_1_length + 5 + gk_output_part_2_length, '-'));
  END IF;
  output(RPAD('+', gk_output_part_1_length + 5 + gk_output_part_2_length, '-'));
  output('|');
  output('FPZ Aggressiveness',                k_aggressiveness||' (1-5) 1=conservative, 3=moderate, 5=aggressive');
  output('Candidates',                        l_candidate_count_t);
  output('SPBs Qualified for Creation',       l_spb_created_qualified_t);
  output('SPBs Created',                      l_spb_created_count_t);
  output('SPBs Qualified for Promotion',      l_spb_promoted_qualified_t);
  output('SPBs Promoted',                     l_spb_promoted_count_t);
  output('SPBs Qualified for Demotion',       l_spb_disable_qualified_t);
  output('SPBs Demoted',                      l_spb_disabled_count_t);
  output('SPBs already Fixed',                l_spb_already_fixed_count_t);
  output('Date and Time (end)',               TO_CHAR(SYSDATE, gk_date_format));
  output('Duration (secs)',                   ROUND((SYSDATE - l_start_time) * 24 * 60 * 60));
  output('|');
  output(RPAD('+', gk_output_part_1_length + 5 + gk_output_part_2_length, '-'));
  /* ---------------------------------------------------------------------------------- */  
  -- output parameters
  x_plan_candidates              := l_candidate_count_t;
  x_qualified_for_spb_creation   := l_spb_created_qualified_t;
  x_spbs_created                 := l_spb_created_count_t;
  x_qualified_for_spb_promotion  := l_spb_promoted_qualified_t;
  x_spbs_promoted                := l_spb_promoted_count_t;
  x_qualified_for_spb_demotion   := l_spb_disable_qualified_t;
  x_spbs_demoted                 := l_spb_disabled_count_t;
  x_spbs_already_fixed           := l_spb_already_fixed_count_t;
  -- look for ORA-13831 and ORA-06512 candidates
  IF gk_workaround_ora_13831 AND p_pdb_name IS NULL AND p_sql_id IS NULL AND p_aggressiveness = k_aggressiveness_upper_limit THEN
    workaround_ora_13831_internal (
      p_report_only    => p_report_only,
      x_plans_found    => l_13831_found_this_call,
      x_plans_disabled => l_13831_disabled_this_call
    );
    l_13831_found_all_calls := l_13831_found_all_calls + l_13831_found_this_call;
    l_13831_disabled_all_calls := l_13831_disabled_all_calls + l_13831_disabled_this_call;
  END IF;
    --
  IF gk_workaround_ora_06512 AND p_pdb_name IS NULL AND p_sql_id IS NULL AND p_aggressiveness = k_aggressiveness_upper_limit THEN
    workaround_ora_06512_internal (
      p_report_only    => p_report_only,
      x_plans_found    => l_06512_found_this_call,
      x_plans_disabled => l_06512_disabled_this_call
    );
    l_06512_found_all_calls := l_06512_found_all_calls + l_06512_found_this_call;
    l_06512_disabled_all_calls := l_06512_disabled_all_calls + l_06512_disabled_this_call;
  END IF;
  --
  x_found_13831_with_issues := l_13831_found_all_calls;
  x_disabled_13831_with_issues := l_13831_disabled_all_calls;
  x_found_06512_with_issues := l_06512_found_all_calls;
  x_disabled_06512_with_issues := l_06512_disabled_all_calls;
  DBMS_APPLICATION_INFO.SET_MODULE(NULL,NULL);
END maintain_plans_internal;
/* ------------------------------------------------------------------------------------ */
PROCEDURE maintain_plans (
  p_report_only                  IN VARCHAR2 DEFAULT NULL, -- (Y|N) when Y then only produces report and changes nothing
  p_kiev_pdbs_only               IN VARCHAR2 DEFAULT NULL, -- (Y|N) when Y then execute only on KIEV PDBs
  p_create_spm_limit             IN NUMBER   DEFAULT NULL, -- limits the number of SPMs to be created in one execution
  p_promote_spm_limit            IN NUMBER   DEFAULT NULL, -- limits the number of SPMs to be promoted to "FIXED" in one execution
  p_disable_spm_limit            IN NUMBER   DEFAULT NULL, -- limits the number of SPMs to be demoted to "DISABLE" in one execution
  p_aggressiveness               IN NUMBER   DEFAULT NULL, -- (1-5) range between 1 to 5 where 1 is conservative and 5 is aggresive
  p_repo_rejected_candidates     IN VARCHAR2 DEFAULT 'Y',  -- (Y|N) include on report rejected candidates
  p_repo_non_promoted_spb        IN VARCHAR2 DEFAULT 'Y',  -- (Y|N) include on report non-fixed SPB that is not getting promoted to "FIXED"
  p_repo_fixed_spb               IN VARCHAR2 DEFAULT 'Y',  -- (Y|N) include on report "FIXED" SPB
  p_pdb_name                     IN VARCHAR2 DEFAULT NULL, -- evaluate only this one PDB
  p_sql_id                       IN VARCHAR2 DEFAULT NULL, -- evaluate only this one SQL
  p_incl_plans_appl_1            IN VARCHAR2 DEFAULT 'Y',  -- (Y|N) include SQL from 1st application (BeginTx)
  p_incl_plans_appl_2            IN VARCHAR2 DEFAULT 'Y',  -- (Y|N) include SQL from 2nd application (CommitTx)
  p_incl_plans_appl_3            IN VARCHAR2 DEFAULT 'Y',  -- (Y|N) include SQL from 3rd application (Read)
  p_incl_plans_appl_4            IN VARCHAR2 DEFAULT 'Y',  -- (Y|N) include SQL from 4th application (GC)
  p_incl_plans_non_appl          IN VARCHAR2 DEFAULT 'Y',  -- (N|Y) consider as candidate SQL not qualified as "application module"
  p_execs_candidate              IN NUMBER   DEFAULT NULL, -- a plan must be executed these many times to be a candidate
  p_secs_per_exec_cand           IN NUMBER   DEFAULT NULL, -- a plan must perform better than this threshold to be a candidate
  p_first_load_time_days_cand    IN NUMBER   DEFAULT NULL, -- a sql must be loaded into memory at least this many days before it is considered as candidate
  p_spb_thershold_over_cat_max   IN NUMBER   DEFAULT NULL, -- plan must perform better than this many times the category max threshold
  p_spb_thershold_over_spf_perf  IN NUMBER   DEFAULT NULL, -- plan must perform better than this many times the its own performance at the time SPB was created
  p_spb_cap_over_cat_max         IN NUMBER   DEFAULT NULL, -- plan must perform better than this many times the category max threshold, regardless if fixed or number of executions
  p_spb_cap_over_spf_perf        IN NUMBER   DEFAULT NULL, -- plan must perform better than this many times the its own performance at the time SPB was created, regardless if fixed or number of executions
  p_awr_plan_days                IN NUMBER   DEFAULT NULL, -- amount of days to consider from AWR plan history assuming retention is at least this long
  p_awr_days                     IN NUMBER   DEFAULT NULL, -- amount of days to consider from AWR metrics history assuming retention is at least this long
  p_cur_days                     IN NUMBER   DEFAULT NULL  -- cursor must be active within the past k_cur_days to be considered
)
IS
  l_candidate_count_t            NUMBER := 0;
  l_spb_created_qualified_t      NUMBER := 0;
  l_spb_created_count_t          NUMBER := 0;
  l_spb_promoted_qualified_t     NUMBER := 0;
  l_spb_promoted_count_t         NUMBER := 0;
  l_spb_disable_qualified_t      NUMBER := 0;
  l_spb_disabled_count_t         NUMBER := 0;
  l_spb_already_fixed_count_t    NUMBER := 0;
  l_found_13831_with_issues      NUMBER := 0;
  l_disabled_13831_with_issues   NUMBER := 0;
  l_found_06512_with_issues      NUMBER := 0;
  l_disabled_06512_with_issues   NUMBER := 0;
/* ------------------------------------------------------------------------------------ */
BEGIN
  maintain_plans_internal (
    p_report_only                  => p_report_only                  ,
    p_kiev_pdbs_only               => p_kiev_pdbs_only               ,
    p_create_spm_limit             => p_create_spm_limit             ,
    p_promote_spm_limit            => p_promote_spm_limit            ,
    p_disable_spm_limit            => p_disable_spm_limit            ,
    p_aggressiveness               => p_aggressiveness               ,
    p_repo_rejected_candidates     => p_repo_rejected_candidates     ,
    p_repo_non_promoted_spb        => p_repo_non_promoted_spb        ,
    p_repo_fixed_spb               => p_repo_fixed_spb               ,
    p_pdb_name                     => p_pdb_name                     ,
    p_sql_id                       => p_sql_id                       ,
    p_incl_plans_appl_1            => p_incl_plans_appl_1            ,
    p_incl_plans_appl_2            => p_incl_plans_appl_2            ,
    p_incl_plans_appl_3            => p_incl_plans_appl_3            ,
    p_incl_plans_appl_4            => p_incl_plans_appl_4            ,
    p_incl_plans_non_appl          => p_incl_plans_non_appl          ,
    p_execs_candidate              => p_execs_candidate              ,
    p_secs_per_exec_cand           => p_secs_per_exec_cand           ,
    p_first_load_time_days_cand    => p_first_load_time_days_cand    ,
    p_spb_thershold_over_cat_max   => p_spb_thershold_over_cat_max   ,
    p_spb_thershold_over_spf_perf  => p_spb_thershold_over_spf_perf  ,
    p_spb_cap_over_cat_max         => p_spb_cap_over_cat_max         ,
    p_spb_cap_over_spf_perf        => p_spb_cap_over_spf_perf        ,
    p_awr_plan_days                => p_awr_plan_days                ,
    p_awr_days                     => p_awr_days                     ,
    p_cur_days                     => p_cur_days                     ,
    x_plan_candidates              => l_candidate_count_t            ,
    x_qualified_for_spb_creation   => l_spb_created_qualified_t      ,
    x_spbs_created                 => l_spb_created_count_t          ,
    x_qualified_for_spb_promotion  => l_spb_promoted_qualified_t     ,
    x_spbs_promoted                => l_spb_promoted_count_t         ,
    x_qualified_for_spb_demotion   => l_spb_disable_qualified_t      ,
    x_spbs_demoted                 => l_spb_disabled_count_t         ,
    x_spbs_already_fixed           => l_spb_already_fixed_count_t    ,
    x_found_13831_with_issues      => l_found_13831_with_issues      ,
    x_disabled_13831_with_issues   => l_disabled_13831_with_issues   ,
    x_found_06512_with_issues      => l_found_06512_with_issues      ,
    x_disabled_06512_with_issues   => l_disabled_06512_with_issues
   );
END maintain_plans;
/* ------------------------------------------------------------------------------------ */
PROCEDURE fpz (
  p_report_only                  IN VARCHAR2 DEFAULT NULL, -- (Y|N) when Y then only produces report and changes nothing
  p_kiev_pdbs_only               IN VARCHAR2 DEFAULT NULL, -- (Y|N) when Y then execute only on KIEV PDBs
  p_pdb_name                     IN VARCHAR2 DEFAULT NULL, -- evaluate only this one PDB
  p_sql_id                       IN VARCHAR2 DEFAULT NULL  -- evaluate only this one SQL
)
IS
  l_sleep_seconds                NUMBER := 0;
  l_start_time			 DATE := SYSDATE;
  l_db_name                      VARCHAR2(9);
  l_host_name                    VARCHAR2(64);
  l_candidate_count_t            NUMBER := 0;
  l_spb_created_qualified_t      NUMBER := 0;
  l_spb_created_count_t          NUMBER := 0;
  l_spb_promoted_qualified_t     NUMBER := 0;
  l_spb_promoted_count_t         NUMBER := 0;
  l_spb_disable_qualified_t      NUMBER := 0;
  l_spb_disabled_count_t         NUMBER := 0;
  l_spb_already_fixed_count_t    NUMBER := 0;
  l_candidate_count_gt           NUMBER := 0;
  l_spb_created_qualified_gt     NUMBER := 0;
  l_spb_created_count_gt         NUMBER := 0;
  l_spb_promoted_qualified_gt    NUMBER := 0;
  l_spb_promoted_count_gt        NUMBER := 0;
  l_spb_disable_qualified_gt     NUMBER := 0;
  l_spb_disabled_count_gt        NUMBER := 0;
  l_spb_already_fixed_count_gt   NUMBER := 0;
  l_found_13831_with_issues      NUMBER := 0;
  l_disabled_13831_with_issues   NUMBER := 0;
  l_found_13831_with_issues_t    NUMBER := 0;
  l_disabled_13831_with_issues_t NUMBER := 0;
  l_found_06512_with_issues      NUMBER := 0;
  l_disabled_06512_with_issues   NUMBER := 0;
  l_found_06512_with_issues_t    NUMBER := 0;
  l_disabled_06512_with_issues_t NUMBER := 0;
  l_high_value                   DATE;
/* ------------------------------------------------------------------------------------ */
BEGIN
  -- gets host name 
  SELECT host_name INTO l_host_name FROM v$instance;
  -- gets database name
  SELECT name INTO l_db_name FROM v$database;
  -- 
  IF p_sql_id IS NULL THEN -- by CDB (p_pdb_name IS NULL) or by PDB (p_pdb_name IS NOT NULL)
    -- level 1 (evaluates and reports only new spbs)
    maintain_plans_internal (
      p_report_only                  => p_report_only                  ,
      p_kiev_pdbs_only               => p_kiev_pdbs_only               ,
      p_promote_spm_limit            => 0                              ,
      --p_disable_spm_limit            => 0                              ,
      p_aggressiveness               => 1                              ,
      --p_repo_rejected_candidates     => 'N'                            ,
      --p_repo_non_promoted_spb        => 'N'                            ,
      --p_repo_fixed_spb               => 'N'                            ,
      p_pdb_name                     => p_pdb_name                     ,
      x_plan_candidates              => l_candidate_count_t            ,
      x_qualified_for_spb_creation   => l_spb_created_qualified_t      ,
      x_spbs_created                 => l_spb_created_count_t          ,
      x_qualified_for_spb_promotion  => l_spb_promoted_qualified_t     ,
      x_spbs_promoted                => l_spb_promoted_count_t         ,
      x_qualified_for_spb_demotion   => l_spb_disable_qualified_t      ,
      x_spbs_demoted                 => l_spb_disabled_count_t         ,
      x_spbs_already_fixed           => l_spb_already_fixed_count_t    ,
      x_found_13831_with_issues      => l_found_13831_with_issues      ,
      x_disabled_13831_with_issues   => l_disabled_13831_with_issues   ,
      x_found_06512_with_issues      => l_found_06512_with_issues      ,
      x_disabled_06512_with_issues   => l_disabled_06512_with_issues
    );
    l_candidate_count_gt         := l_candidate_count_gt         + l_candidate_count_t        ;
    l_spb_created_qualified_gt   := l_spb_created_qualified_gt   + l_spb_created_qualified_t  ;
    l_spb_created_count_gt       := l_spb_created_count_gt       + l_spb_created_count_t      ;
    l_spb_promoted_qualified_gt  := l_spb_promoted_qualified_gt  + l_spb_promoted_qualified_t ;
    l_spb_promoted_count_gt      := l_spb_promoted_count_gt      + l_spb_promoted_count_t     ;
    l_spb_disable_qualified_gt   := l_spb_disable_qualified_gt   + l_spb_disable_qualified_t  ;
    l_spb_disabled_count_gt      := l_spb_disabled_count_gt      + l_spb_disabled_count_t     ;
    l_spb_already_fixed_count_gt := l_spb_already_fixed_count_gt + l_spb_already_fixed_count_t;
    l_found_13831_with_issues_t  := l_found_13831_with_issues_t  + l_found_13831_with_issues;
    l_disabled_13831_with_issues_t := l_disabled_13831_with_issues_t + l_disabled_13831_with_issues;
    l_found_06512_with_issues_t  := l_found_06512_with_issues_t  + l_found_06512_with_issues;
    l_disabled_06512_with_issues_t := l_disabled_06512_with_issues_t + l_disabled_06512_with_issues;
    IF p_report_only = 'N' THEN
      DBMS_LOCK.SLEEP(l_sleep_seconds);
    END IF;
    -- level 2 (evaluates and reports only new spbs)
    maintain_plans_internal (
      p_report_only                  => p_report_only                  ,
      p_kiev_pdbs_only               => p_kiev_pdbs_only               ,
      p_promote_spm_limit            => 0                              ,
      --p_disable_spm_limit            => 0                              ,
      p_aggressiveness               => 2                              ,
      --p_repo_rejected_candidates     => 'N'                            ,
      --p_repo_non_promoted_spb        => 'N'                            ,
      --p_repo_fixed_spb               => 'N'                            ,
      p_pdb_name                     => p_pdb_name                     ,
      x_plan_candidates              => l_candidate_count_t            ,
      x_qualified_for_spb_creation   => l_spb_created_qualified_t      ,
      x_spbs_created                 => l_spb_created_count_t          ,
      x_qualified_for_spb_promotion  => l_spb_promoted_qualified_t     ,
      x_spbs_promoted                => l_spb_promoted_count_t         ,
      x_qualified_for_spb_demotion   => l_spb_disable_qualified_t      ,
      x_spbs_demoted                 => l_spb_disabled_count_t         ,
      x_spbs_already_fixed           => l_spb_already_fixed_count_t    ,
      x_found_13831_with_issues      => l_found_13831_with_issues      ,
      x_disabled_13831_with_issues   => l_disabled_13831_with_issues   ,
      x_found_06512_with_issues      => l_found_06512_with_issues      ,
      x_disabled_06512_with_issues   => l_disabled_06512_with_issues
    );
    l_candidate_count_gt         := l_candidate_count_gt         + l_candidate_count_t        ;
    l_spb_created_qualified_gt   := l_spb_created_qualified_gt   + l_spb_created_qualified_t  ;
    l_spb_created_count_gt       := l_spb_created_count_gt       + l_spb_created_count_t      ;
    l_spb_promoted_qualified_gt  := l_spb_promoted_qualified_gt  + l_spb_promoted_qualified_t ;
    l_spb_promoted_count_gt      := l_spb_promoted_count_gt      + l_spb_promoted_count_t     ;
    l_spb_disable_qualified_gt   := l_spb_disable_qualified_gt   + l_spb_disable_qualified_t  ;
    l_spb_disabled_count_gt      := l_spb_disabled_count_gt      + l_spb_disabled_count_t     ;
    l_spb_already_fixed_count_gt := l_spb_already_fixed_count_gt + l_spb_already_fixed_count_t;
    l_spb_already_fixed_count_gt := l_spb_already_fixed_count_gt + l_spb_already_fixed_count_t;
    l_found_13831_with_issues_t  := l_found_13831_with_issues_t  + l_found_13831_with_issues;
    l_disabled_13831_with_issues_t := l_disabled_13831_with_issues_t + l_disabled_13831_with_issues;
    l_found_06512_with_issues_t  := l_found_06512_with_issues_t  + l_found_06512_with_issues;
    l_disabled_06512_with_issues_t := l_disabled_06512_with_issues_t + l_disabled_06512_with_issues;
    IF p_report_only = 'N' THEN
      DBMS_LOCK.SLEEP(l_sleep_seconds);
    END IF;
    -- level 3 (evaluates and reports only new spbs)
    maintain_plans_internal (
      p_report_only                  => p_report_only                  ,
      p_kiev_pdbs_only               => p_kiev_pdbs_only               ,
      p_promote_spm_limit            => 0                              ,
      --p_disable_spm_limit            => 0                              ,
      p_aggressiveness               => 3                              ,
      --p_repo_rejected_candidates     => 'N'                            ,
      --p_repo_non_promoted_spb        => 'N'                            ,
      --p_repo_fixed_spb               => 'N'                            ,
      p_pdb_name                     => p_pdb_name                     ,
      x_plan_candidates              => l_candidate_count_t            ,
      x_qualified_for_spb_creation   => l_spb_created_qualified_t      ,
      x_spbs_created                 => l_spb_created_count_t          ,
      x_qualified_for_spb_promotion  => l_spb_promoted_qualified_t     ,
      x_spbs_promoted                => l_spb_promoted_count_t         ,
      x_qualified_for_spb_demotion   => l_spb_disable_qualified_t      ,
      x_spbs_demoted                 => l_spb_disabled_count_t         ,
      x_spbs_already_fixed           => l_spb_already_fixed_count_t    ,
      x_found_13831_with_issues      => l_found_13831_with_issues      ,
      x_disabled_13831_with_issues   => l_disabled_13831_with_issues   ,
      x_found_06512_with_issues      => l_found_06512_with_issues      ,
      x_disabled_06512_with_issues   => l_disabled_06512_with_issues
    );
    l_candidate_count_gt         := l_candidate_count_gt         + l_candidate_count_t        ;
    l_spb_created_qualified_gt   := l_spb_created_qualified_gt   + l_spb_created_qualified_t  ;
    l_spb_created_count_gt       := l_spb_created_count_gt       + l_spb_created_count_t      ;
    l_spb_promoted_qualified_gt  := l_spb_promoted_qualified_gt  + l_spb_promoted_qualified_t ;
    l_spb_promoted_count_gt      := l_spb_promoted_count_gt      + l_spb_promoted_count_t     ;
    l_spb_disable_qualified_gt   := l_spb_disable_qualified_gt   + l_spb_disable_qualified_t  ;
    l_spb_disabled_count_gt      := l_spb_disabled_count_gt      + l_spb_disabled_count_t     ;
    l_spb_already_fixed_count_gt := l_spb_already_fixed_count_gt + l_spb_already_fixed_count_t;
    l_spb_already_fixed_count_gt := l_spb_already_fixed_count_gt + l_spb_already_fixed_count_t;
    l_found_13831_with_issues_t  := l_found_13831_with_issues_t  + l_found_13831_with_issues;
    l_disabled_13831_with_issues_t := l_disabled_13831_with_issues_t + l_disabled_13831_with_issues;
    l_found_06512_with_issues_t  := l_found_06512_with_issues_t  + l_found_06512_with_issues;
    l_disabled_06512_with_issues_t := l_disabled_06512_with_issues_t + l_disabled_06512_with_issues;
    IF p_report_only = 'N' THEN
      DBMS_LOCK.SLEEP(l_sleep_seconds);
    END IF;
    -- level 4 (evaluates and reports only new spbs)
    maintain_plans_internal (
      p_report_only                  => p_report_only                  ,
      p_kiev_pdbs_only               => p_kiev_pdbs_only               ,
      p_promote_spm_limit            => 0                              ,
      --p_disable_spm_limit            => 0                              ,
      p_aggressiveness               => 4                              ,
      --p_repo_rejected_candidates     => 'N'                            ,
      --p_repo_non_promoted_spb        => 'N'                            ,
      --p_repo_fixed_spb               => 'N'                            ,
      p_pdb_name                     => p_pdb_name                     ,
      x_plan_candidates              => l_candidate_count_t            ,
      x_qualified_for_spb_creation   => l_spb_created_qualified_t      ,
      x_spbs_created                 => l_spb_created_count_t          ,
      x_qualified_for_spb_promotion  => l_spb_promoted_qualified_t     ,
      x_spbs_promoted                => l_spb_promoted_count_t         ,
      x_qualified_for_spb_demotion   => l_spb_disable_qualified_t      ,
      x_spbs_demoted                 => l_spb_disabled_count_t         ,
      x_spbs_already_fixed           => l_spb_already_fixed_count_t    ,
      x_found_13831_with_issues      => l_found_13831_with_issues      ,
      x_disabled_13831_with_issues   => l_disabled_13831_with_issues   ,
      x_found_06512_with_issues      => l_found_06512_with_issues      ,
      x_disabled_06512_with_issues   => l_disabled_06512_with_issues
    );
    l_candidate_count_gt         := l_candidate_count_gt         + l_candidate_count_t        ;
    l_spb_created_qualified_gt   := l_spb_created_qualified_gt   + l_spb_created_qualified_t  ;
    l_spb_created_count_gt       := l_spb_created_count_gt       + l_spb_created_count_t      ;
    l_spb_promoted_qualified_gt  := l_spb_promoted_qualified_gt  + l_spb_promoted_qualified_t ;
    l_spb_promoted_count_gt      := l_spb_promoted_count_gt      + l_spb_promoted_count_t     ;
    l_spb_disable_qualified_gt   := l_spb_disable_qualified_gt   + l_spb_disable_qualified_t  ;
    l_spb_disabled_count_gt      := l_spb_disabled_count_gt      + l_spb_disabled_count_t     ;
    l_spb_already_fixed_count_gt := l_spb_already_fixed_count_gt + l_spb_already_fixed_count_t;
    l_spb_already_fixed_count_gt := l_spb_already_fixed_count_gt + l_spb_already_fixed_count_t;
    l_found_13831_with_issues_t  := l_found_13831_with_issues_t  + l_found_13831_with_issues;
    l_disabled_13831_with_issues_t := l_disabled_13831_with_issues_t + l_disabled_13831_with_issues;
    l_found_06512_with_issues_t  := l_found_06512_with_issues_t  + l_found_06512_with_issues;
    l_disabled_06512_with_issues_t := l_disabled_06512_with_issues_t + l_disabled_06512_with_issues;
    IF p_report_only = 'N' THEN
      DBMS_LOCK.SLEEP(l_sleep_seconds);
    END IF;
    -- level 5 (evaluates new spbs, demotions and promotions; reports all)
    maintain_plans_internal (
      p_report_only                  => p_report_only                  ,
      p_kiev_pdbs_only               => p_kiev_pdbs_only               ,
      p_aggressiveness               => 5                              ,
      p_pdb_name                     => p_pdb_name                     ,
      x_plan_candidates              => l_candidate_count_t            ,
      x_qualified_for_spb_creation   => l_spb_created_qualified_t      ,
      x_spbs_created                 => l_spb_created_count_t          ,
      x_qualified_for_spb_promotion  => l_spb_promoted_qualified_t     ,
      x_spbs_promoted                => l_spb_promoted_count_t         ,
      x_qualified_for_spb_demotion   => l_spb_disable_qualified_t      ,
      x_spbs_demoted                 => l_spb_disabled_count_t         ,
      x_spbs_already_fixed           => l_spb_already_fixed_count_t    ,
      x_found_13831_with_issues      => l_found_13831_with_issues      ,
      x_disabled_13831_with_issues   => l_disabled_13831_with_issues   ,
      x_found_06512_with_issues      => l_found_06512_with_issues      ,
      x_disabled_06512_with_issues   => l_disabled_06512_with_issues
    );
    l_candidate_count_gt         := l_candidate_count_gt         + l_candidate_count_t        ;
    l_spb_created_qualified_gt   := l_spb_created_qualified_gt   + l_spb_created_qualified_t  ;
    l_spb_created_count_gt       := l_spb_created_count_gt       + l_spb_created_count_t      ;
    l_spb_promoted_qualified_gt  := l_spb_promoted_qualified_gt  + l_spb_promoted_qualified_t ;
    l_spb_promoted_count_gt      := l_spb_promoted_count_gt      + l_spb_promoted_count_t     ;
    l_spb_disable_qualified_gt   := l_spb_disable_qualified_gt   + l_spb_disable_qualified_t  ;
    l_spb_disabled_count_gt      := l_spb_disabled_count_gt      + l_spb_disabled_count_t     ;
    l_spb_already_fixed_count_gt := l_spb_already_fixed_count_gt + l_spb_already_fixed_count_t;
    l_spb_already_fixed_count_gt := l_spb_already_fixed_count_gt + l_spb_already_fixed_count_t;
    l_found_13831_with_issues_t  := l_found_13831_with_issues_t  + l_found_13831_with_issues;
    l_disabled_13831_with_issues_t := l_disabled_13831_with_issues_t + l_disabled_13831_with_issues;
    l_found_06512_with_issues_t  := l_found_06512_with_issues_t  + l_found_06512_with_issues;
    l_disabled_06512_with_issues_t := l_disabled_06512_with_issues_t + l_disabled_06512_with_issues;
    -- global summary
    output(RPAD('+', gk_output_part_1_length + 5 + gk_output_part_2_length, '-'));
    output('|');
    output('IOD SPM AUT FPZ',                   'Flipping-Plan Zapper (FPZ)');
    output('|');
    output('Database',                          l_db_name);
    output('Host',                              l_host_name);
    output('|');
    output('Candidates',                        l_candidate_count_gt);
    output('SPBs Qualified for Creation',       l_spb_created_qualified_gt);
    output('SPBs Created',                      l_spb_created_count_gt);
    output('SPBs Qualified for Promotion',      l_spb_promoted_qualified_gt);
    output('SPBs Promoted',                     l_spb_promoted_count_gt);
    output('SPBs Qualified for Demotion',       l_spb_disable_qualified_gt);
    output('SPBs Demoted',                      l_spb_disabled_count_gt);
    output('SPBs already Fixed',                l_spb_already_fixed_count_gt);
    output('Date and Time (end)',               TO_CHAR(SYSDATE, gk_date_format));
    output('Duration (secs)',                   ROUND((SYSDATE - l_start_time) * 24 * 60 * 60));
    output('|');
    output(RPAD('+', gk_output_part_1_length + 5 + gk_output_part_2_length, '-'));
    output('|');
    output('ORA-13831 PREVENTION', 'CDB SCREENING GLOBAL RESULTS');
    output('ORA-13831 Candidates Found',        l_found_13831_with_issues_t);
    output('ORA-13831 Plans Disabled',          l_disabled_13831_with_issues_t);
    output('|');
    output('ORA-06512 PREVENTION', 'CDB SCREENING GLOBAL RESULTS');
    output('ORA-06512 Candidates Found',        l_found_06512_with_issues_t);
    output('ORA-06512 Plans Disabled',          l_disabled_06512_with_issues_t);
    output('|');
    output(RPAD('+', gk_output_part_1_length + 5 + gk_output_part_2_length, '-'));
  ELSE -- p_sql_id IS NOT NULL 
    -- level 1 (evaluates and reports only new spbs, including rejected candidates)
    maintain_plans_internal (
      p_report_only                  => p_report_only                  ,
      p_kiev_pdbs_only               => p_kiev_pdbs_only               ,
      p_promote_spm_limit            => 0                              ,
      p_disable_spm_limit            => 0                              ,
      p_aggressiveness               => 1                              ,
      --p_repo_non_promoted_spb        => 'N'                            ,
      --p_repo_fixed_spb               => 'N'                            ,
      p_pdb_name                     => p_pdb_name                     ,
      p_sql_id                       => p_sql_id                       ,
      x_plan_candidates              => l_candidate_count_t            ,
      x_qualified_for_spb_creation   => l_spb_created_qualified_t      ,
      x_spbs_created                 => l_spb_created_count_t          ,
      x_qualified_for_spb_promotion  => l_spb_promoted_qualified_t     ,
      x_spbs_promoted                => l_spb_promoted_count_t         ,
      x_qualified_for_spb_demotion   => l_spb_disable_qualified_t      ,
      x_spbs_demoted                 => l_spb_disabled_count_t         ,
      x_spbs_already_fixed           => l_spb_already_fixed_count_t    ,
      x_found_13831_with_issues      => l_found_13831_with_issues      ,
      x_disabled_13831_with_issues   => l_disabled_13831_with_issues   ,
      x_found_06512_with_issues      => l_found_06512_with_issues      ,
      x_disabled_06512_with_issues   => l_disabled_06512_with_issues
    );
    /* no longer true, since same sql_id can exist on multiple pdbs */
    /* enabling it back since we are creating more than one spb (multiple levels) for a given sql */
    IF l_spb_created_count_t > 0 THEN
      RETURN;
    END IF;  
    -- level 2 (evaluates and reports only new spbs, including rejected candidates)
    maintain_plans_internal (
      p_report_only                  => p_report_only                  ,
      p_kiev_pdbs_only               => p_kiev_pdbs_only               ,
      p_promote_spm_limit            => 0                              ,
      p_disable_spm_limit            => 0                              ,
      p_aggressiveness               => 2                              ,
      --p_repo_non_promoted_spb        => 'N'                            ,
      --p_repo_fixed_spb               => 'N'                            ,
      p_pdb_name                     => p_pdb_name                     ,
      p_sql_id                       => p_sql_id                       ,
      x_plan_candidates              => l_candidate_count_t            ,
      x_qualified_for_spb_creation   => l_spb_created_qualified_t      ,
      x_spbs_created                 => l_spb_created_count_t          ,
      x_qualified_for_spb_promotion  => l_spb_promoted_qualified_t     ,
      x_spbs_promoted                => l_spb_promoted_count_t         ,
      x_qualified_for_spb_demotion   => l_spb_disable_qualified_t      ,
      x_spbs_demoted                 => l_spb_disabled_count_t         ,
      x_spbs_already_fixed           => l_spb_already_fixed_count_t    ,
      x_found_13831_with_issues      => l_found_13831_with_issues      ,
      x_disabled_13831_with_issues   => l_disabled_13831_with_issues   ,
      x_found_06512_with_issues      => l_found_06512_with_issues      ,
      x_disabled_06512_with_issues   => l_disabled_06512_with_issues
    );
    /* no longer true, since same sql_id can exist on multiple pdbs */
    /* enabling it back since we are creating more than one spb (multiple levels) for a given sql */
    IF l_spb_created_count_t > 0 THEN
      RETURN;
    END IF;   
    -- level 3 (evaluates and reports only new spbs, including rejected candidates)
    maintain_plans_internal (
      p_report_only                  => p_report_only                  ,
      p_kiev_pdbs_only               => p_kiev_pdbs_only               ,
      p_promote_spm_limit            => 0                              ,
      p_disable_spm_limit            => 0                              ,
      p_aggressiveness               => 3                              ,
      --p_repo_non_promoted_spb        => 'N'                            ,
      --p_repo_fixed_spb               => 'N'                            ,
      p_pdb_name                     => p_pdb_name                     ,
      p_sql_id                       => p_sql_id                       ,
      x_plan_candidates              => l_candidate_count_t            ,
      x_qualified_for_spb_creation   => l_spb_created_qualified_t      ,
      x_spbs_created                 => l_spb_created_count_t          ,
      x_qualified_for_spb_promotion  => l_spb_promoted_qualified_t     ,
      x_spbs_promoted                => l_spb_promoted_count_t         ,
      x_qualified_for_spb_demotion   => l_spb_disable_qualified_t      ,
      x_spbs_demoted                 => l_spb_disabled_count_t         ,
      x_spbs_already_fixed           => l_spb_already_fixed_count_t    ,
      x_found_13831_with_issues      => l_found_13831_with_issues      ,
      x_disabled_13831_with_issues   => l_disabled_13831_with_issues   ,
      x_found_06512_with_issues      => l_found_06512_with_issues      ,
      x_disabled_06512_with_issues   => l_disabled_06512_with_issues
    );
    /* no longer true, since same sql_id can exist on multiple pdbs */
    /* enabling it back since we are creating more than one spb (multiple levels) for a given sql */
    IF l_spb_created_count_t > 0 THEN
      RETURN;
    END IF;   
    -- level 4 (evaluates and reports only new spbs, including rejected candidates)
    maintain_plans_internal (
      p_report_only                  => p_report_only                  ,
      p_kiev_pdbs_only               => p_kiev_pdbs_only               ,
      p_promote_spm_limit            => 0                              ,
      p_disable_spm_limit            => 0                              ,
      p_aggressiveness               => 4                              ,
      --p_repo_non_promoted_spb        => 'N'                            ,
      --p_repo_fixed_spb               => 'N'                            ,
      p_pdb_name                     => p_pdb_name                     ,
      p_sql_id                       => p_sql_id                       ,
      x_plan_candidates              => l_candidate_count_t            ,
      x_qualified_for_spb_creation   => l_spb_created_qualified_t      ,
      x_spbs_created                 => l_spb_created_count_t          ,
      x_qualified_for_spb_promotion  => l_spb_promoted_qualified_t     ,
      x_spbs_promoted                => l_spb_promoted_count_t         ,
      x_qualified_for_spb_demotion   => l_spb_disable_qualified_t      ,
      x_spbs_demoted                 => l_spb_disabled_count_t         ,
      x_spbs_already_fixed           => l_spb_already_fixed_count_t    ,
      x_found_13831_with_issues      => l_found_13831_with_issues      ,
      x_disabled_13831_with_issues   => l_disabled_13831_with_issues   ,
      x_found_06512_with_issues      => l_found_06512_with_issues      ,
      x_disabled_06512_with_issues   => l_disabled_06512_with_issues
    );
    /* no longer true, since same sql_id can exist on multiple pdbs */
    /* enabling it back since we are creating more than one spb (multiple levels) for a given sql */
    IF l_spb_created_count_t > 0 THEN
      RETURN;
    END IF;    
    -- level 5 (evaluates new spbs, demotions and promotions; reports all)
    maintain_plans_internal (
      p_report_only                  => p_report_only                  ,
      p_kiev_pdbs_only               => p_kiev_pdbs_only               ,
      p_aggressiveness               => 5                              ,
      p_pdb_name                     => p_pdb_name                     ,
      p_sql_id                       => p_sql_id                       ,
      p_execs_candidate              => 0                              , -- laxed
      p_secs_per_exec_cand           => 60                             , -- laxed
      p_first_load_time_days_cand    => 0                              , -- laxed
      x_plan_candidates              => l_candidate_count_t            ,
      x_qualified_for_spb_creation   => l_spb_created_qualified_t      ,
      x_spbs_created                 => l_spb_created_count_t          ,
      x_qualified_for_spb_promotion  => l_spb_promoted_qualified_t     ,
      x_spbs_promoted                => l_spb_promoted_count_t         ,
      x_qualified_for_spb_demotion   => l_spb_disable_qualified_t      ,
      x_spbs_demoted                 => l_spb_disabled_count_t         ,
      x_spbs_already_fixed           => l_spb_already_fixed_count_t    ,
      x_found_13831_with_issues      => l_found_13831_with_issues      ,
      x_disabled_13831_with_issues   => l_disabled_13831_with_issues   ,
      x_found_06512_with_issues      => l_found_06512_with_issues      ,
      x_disabled_06512_with_issues   => l_disabled_06512_with_issues
    );
  END IF;  
  --  
  IF p_report_only = 'N' AND p_pdb_name IS NULL AND p_sql_id IS NULL THEN
    -- drop partitions with data older than 2 months (i.e. preserve between 2 and 3 months of history)
    FOR i IN (
      SELECT partition_name, high_value, blocks
        FROM dba_tab_partitions
       WHERE table_owner = UPPER('&&1.')
         AND table_name = 'SQL_PLAN_BASELINE_HIST'
       ORDER BY
             partition_name
    )
    LOOP
      EXECUTE IMMEDIATE 'SELECT '||i.high_value||' FROM DUAL' INTO l_high_value;
      IF l_high_value <= ADD_MONTHS(TRUNC(SYSDATE, 'MM'), -2) THEN
        output('PARTITION:'||RPAD(SUBSTR(i.partition_name, 1, 30), 32)||'HIGH_VALUE:'||TO_CHAR(l_high_value, gk_date_format)||'  BLOCKS:'||i.blocks);
        output('&&1..IOD_SPM.fpz: ALTER TABLE &&1..sql_plan_baseline_hist DROP PARTITION '||i.partition_name, p_alert_log => TRUE);
        EXECUTE IMMEDIATE q'[ALTER TABLE &&1..sql_plan_baseline_hist SET INTERVAL (NUMTOYMINTERVAL(1,'MONTH'))]';
        --
        DECLARE
         last_partition EXCEPTION;
         PRAGMA EXCEPTION_INIT(last_partition, -14758); -- ORA-14758: Last partition in the range section cannot be dropped
        BEGIN
          EXECUTE IMMEDIATE 'ALTER TABLE &&1..sql_plan_baseline_hist DROP PARTITION '||i.partition_name;
        EXCEPTION 
          WHEN last_partition THEN
            output('** '||SQLERRM);
        END;
      END IF;
    END LOOP;
    --
  END IF;
END fpz;
/* ------------------------------------------------------------------------------------ */
PROCEDURE sentinel (
  p_report_only                  IN VARCHAR2 DEFAULT NULL, -- (Y|N) when Y then only produces report and changes nothing
  p_kiev_pdbs_only               IN VARCHAR2 DEFAULT NULL, -- (Y|N) when Y then execute only on KIEV PDBs
  p_pdb_name                     IN VARCHAR2 DEFAULT NULL, -- evaluate only this one PDB
  p_sql_id                       IN VARCHAR2 DEFAULT NULL  -- evaluate only this one SQL
)
IS
  l_candidate_count_t            NUMBER := 0;
  l_spb_created_qualified_t      NUMBER := 0;
  l_spb_created_count_t          NUMBER := 0;
  l_spb_promoted_qualified_t     NUMBER := 0;
  l_spb_promoted_count_t         NUMBER := 0;
  l_spb_disable_qualified_t      NUMBER := 0;
  l_spb_disabled_count_t         NUMBER := 0;
  l_spb_already_fixed_count_t    NUMBER := 0;
  l_found_13831_with_issues      NUMBER := 0;
  l_disabled_13831_with_issues   NUMBER := 0;
  l_found_06512_with_issues      NUMBER := 0;
  l_disabled_06512_with_issues   NUMBER := 0;
/* ------------------------------------------------------------------------------------ */
BEGIN
  -- only demotions
    maintain_plans_internal (
      p_report_only                  => p_report_only                  ,
      p_kiev_pdbs_only               => p_kiev_pdbs_only               ,
      p_create_spm_limit             => 0                              , 
      p_promote_spm_limit            => 0                              , 
      p_aggressiveness               => 5                              ,
      p_repo_rejected_candidates     => 'N'                            ,
      p_repo_non_promoted_spb        => 'N'                            , 
      p_repo_fixed_spb               => 'N'                            ,
      p_pdb_name                     => p_pdb_name                     ,
      p_sql_id                       => p_sql_id                       ,
      p_execs_candidate              => 0                              , -- laxed
      p_secs_per_exec_cand           => 900                            , -- very laxed
      p_first_load_time_days_cand    => 0                              , -- laxed
      p_spb_thershold_over_cat_max   => 2                              , -- aggresive
      p_spb_thershold_over_spf_perf  => 20                             , -- aggresive
      p_spb_cap_over_cat_max         => 40                             , -- aggresive
      p_spb_cap_over_spf_perf        => 400                            , -- aggresive
      x_plan_candidates              => l_candidate_count_t            ,
      x_qualified_for_spb_creation   => l_spb_created_qualified_t      ,
      x_spbs_created                 => l_spb_created_count_t          ,
      x_qualified_for_spb_promotion  => l_spb_promoted_qualified_t     ,
      x_spbs_promoted                => l_spb_promoted_count_t         ,
      x_qualified_for_spb_demotion   => l_spb_disable_qualified_t      ,
      x_spbs_demoted                 => l_spb_disabled_count_t         ,
      x_spbs_already_fixed           => l_spb_already_fixed_count_t    ,
      x_found_13831_with_issues      => l_found_13831_with_issues      ,
      x_disabled_13831_with_issues   => l_disabled_13831_with_issues   ,
      x_found_06512_with_issues      => l_found_06512_with_issues      ,
      x_disabled_06512_with_issues   => l_disabled_06512_with_issues
    );
    output(RPAD('+', gk_output_part_1_length + 5 + gk_output_part_2_length, '-'));
    output('|');
    output('ORA-13831 PREVENTION', 'CDB SCREENING GLOBAL RESULTS');
    output('ORA-13831 Candidates Found',        l_found_13831_with_issues);
    output('ORA-13831 Plans Disabled',          l_disabled_13831_with_issues);
    output('|');
    output('ORA-06512 PREVENTION', 'CDB SCREENING GLOBAL RESULTS');
    output('ORA-06512 Candidates Found',        l_found_06512_with_issues);
    output('ORA-06512 Plans Disabled',          l_disabled_06512_with_issues);
    output('|');
    output(RPAD('+', gk_output_part_1_length + 5 + gk_output_part_2_length, '-'));
  --
END sentinel;
/* ------------------------------------------------------------------------------------ */
END iod_spm;
/
