CREATE OR REPLACE PACKAGE BODY &&1..iod_spm AS
/* $Header: iod_spm.pkb.sql &&library_version. carlos.sierra $ */
/* ------------------------------------------------------------------------------------ */  
gk_tool_name                   CONSTANT VARCHAR2(30) := 'ZAPPER';
gk_date_format                 CONSTANT VARCHAR2(30) := 'YYYY-MM-DD"T"HH24:MI:SS';
gk_output_part_1_length        CONSTANT INTEGER := 35;
gk_output_metrics_length       CONSTANT INTEGER := 15;                  
gk_output_part_2_length        CONSTANT INTEGER := 10 * (gk_output_metrics_length + 1);                  
/* ------------------------------------------------------------------------------------ */  
FUNCTION application_category (p_sql_text IN VARCHAR2)
RETURN VARCHAR2
IS
  k_appl_handle_prefix CONSTANT VARCHAR2(30) := '/*'||CHR(37);
  k_appl_handle_suffix CONSTANT VARCHAR2(30) := CHR(37)||'*/'||CHR(37);
BEGIN
  IF    p_sql_text LIKE k_appl_handle_prefix||'Transaction Processing'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'addTransactionRow'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'checkEndRowValid'||k_appl_handle_suffix
    OR  p_sql_text LIKE k_appl_handle_prefix||'checkStartRowValid'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'deleteValue'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'exists'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch commit by idempotency token'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch latest transactions for cache'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Find lower commit id for transaction cache warm up'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'findMatchingRow'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getMaxTransactionCommitID'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getNewTransactionID'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getTransactionProgress'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'lockForCommit'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'lockKievTransactor'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'putBucket'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'readTransactionsSince'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'recordTransactionState'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'setValue'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'SPM:CP'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'updateIdentityValue'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'updateNextKievTransID'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'updateTransactorState'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'upsert_transactor_state'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'writeTransactionKeys'||k_appl_handle_suffix 
    OR  LOWER(p_sql_text) LIKE CHR(37)||'lock table kievtransactions'||CHR(37) 
  THEN RETURN 'TP'; /* Transaction Processing */
  --
  ELSIF p_sql_text LIKE k_appl_handle_prefix||'Read Only'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'bucketIndexSelect'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'bucketKeySelect'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'bucketValueSelect'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'countTransactions'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch snapshots'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Get system time'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getAutoSequences'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getNextIdentityValue'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getValues'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Lock row Bucket_Snapshot'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'longFromDual'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'performContinuedScanValues'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'performFirstRowsScanQuery'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'performScanQuery'||k_appl_handle_suffix
    OR  p_sql_text LIKE k_appl_handle_prefix||'performSnapshotScanQuery'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'performStartScanValues'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'selectBuckets'||k_appl_handle_suffix 
  THEN RETURN 'RO'; /* Read Only */
  --
  ELSIF p_sql_text LIKE k_appl_handle_prefix||'Background'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Bootstrap snapshot table Kiev_S'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'bucketIdentitySelect'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'checkMissingTables'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'countAllBuckets'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'countAllRows'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'countKievTransactionRows'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'countKtkRows'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Delete garbage'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Delete rows from'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'deleteBucketGarbage'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'enumerateSequences'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch config'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'fetch_leader_heartbeat'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'gcEventMaxId'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'gcEventTryInsert'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Get txn at time'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get_leader'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getCurEndTime'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getDBSchemaVersion'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getEndTimeOlderThan'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getGCLogEntries'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getMaxTransactionOlderThan'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getSchemaMetadata'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getSupportedLibVersions'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'hashBucket'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'hashSnapshot'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Populate workspace'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'populateBucketGCWorkspace'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'primeTxCache'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'readOnlyRoleExists'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Row count between transactions'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'secondsSinceLastGcEvent'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'sync_leadership'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Test if table Kiev_S'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Update snapshot metadata'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'update_heartbeat'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'validateIfWorkspaceEmpty'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'verify_is_leader'||k_appl_handle_suffix 
  THEN RETURN 'BG'; /* Background */
  --
  ELSIF p_sql_text LIKE k_appl_handle_prefix||'Ignore'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'enumerateKievPdbs'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getJDBCSuffix'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'MV_REFRESH'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'null'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'selectColumnsForTable'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'selectDatastoreMd'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'SQL Analyze('||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'validateDataStoreId'||k_appl_handle_suffix 
    OR  p_sql_text LIKE CHR(37)||k_appl_handle_prefix||'OPT_DYN_SAMP'||k_appl_handle_suffix 
  THEN RETURN 'IG'; /* Ignore */
  --
  ELSE RETURN 'UN'; /* Unknown */
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
  p_report_only    IN  VARCHAR2 DEFAULT 'N', -- (Y|N) when Y then only produces report and changes nothing
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
  p_report_only IN VARCHAR2 DEFAULT 'N' -- (Y|N) when Y then only produces report and changes nothing
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
  p_report_only    IN  VARCHAR2 DEFAULT 'N', -- (Y|N) when Y then only produces report and changes nothing
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
  p_report_only IN VARCHAR2 DEFAULT 'N' -- (Y|N) when Y then only produces report and changes nothing
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
  p_report_only                  IN VARCHAR2 DEFAULT 'N',    -- (Y|N) when Y then only produces report and changes nothing
  p_aggressiveness               IN NUMBER   DEFAULT 1,      -- (1 .. N) 1=conservative, 2, 3=moderate, 4, ..., N=aggressive
  p_pdb_name                     IN VARCHAR2 DEFAULT gk_all, -- evaluate only this one PDB
  p_sql_id                       IN VARCHAR2 DEFAULT gk_all, -- evaluate only this one SQL
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
  k_source_mem                   CONSTANT VARCHAR2(30) := 'v$sql';
  /* ---------------------------------------------------------------------------------- */
  l_pdb_id                       NUMBER;
  l_candidate_was_accepted       BOOLEAN;
  l_spb_promotion_was_accepted   BOOLEAN;
  l_spb_demotion_was_accepted    BOOLEAN;
  l_spb_exists                   BOOLEAN;
  l_spb_was_promoted             BOOLEAN;
  l_spb_was_created              BOOLEAN;
  l_cursor_details_section       BOOLEAN := FALSE;
  l_message_section              BOOLEAN := FALSE;
  l_cursor_heading_section       BOOLEAN := FALSE;
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
  l_message0                     VARCHAR2(1000);
  l_message1                     VARCHAR2(1000);
  l_message2                     VARCHAR2(1000);
  l_message3                     VARCHAR2(1000);
  l_messaget                     VARCHAR2(1000); -- temporary message
  l_messaged                     VARCHAR2(1000); -- message for debugging
  l_cur_ms                       VARCHAR2(1000);
  l_mrs_ms                       VARCHAR2(1000); -- most recent snapshot
  l_cat_ms                       VARCHAR2(1000);
  l_spb_ms                       VARCHAR2(1000);
  l_cat_cap_ms                   VARCHAR2(1000);
  l_spb_cap_ms                   VARCHAR2(1000);
  l_within_probation_window      BOOLEAN;
  l_within_monitoring_window     BOOLEAN;
  l_cur_slower_than_cat          BOOLEAN;
  l_cur_slower_than_spb          BOOLEAN;
  l_mrs_is_considered            BOOLEAN;
  l_mrs_slower_than_cat          BOOLEAN;
  l_mrs_slower_than_spb          BOOLEAN;
  l_cur_violates_cat_cap         BOOLEAN;
  l_cur_violates_spb_cap         BOOLEAN;
  l_mrs_violates_cat_cap         BOOLEAN;
  l_mrs_violates_spb_cap         BOOLEAN;
  l_cur_in_probation_compliance  BOOLEAN;
  l_cur_in_monitoring_compliance  BOOLEAN;
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
  l_persist_zapper_report        BOOLEAN := FALSE;
  l_kiev_pdbs_count              NUMBER;
  --
  gl_rec                         &&1..zapper_global%ROWTYPE;
  h_rec                          &&1..sql_plan_baseline_hist%ROWTYPE;
  b_rec                          cdb_sql_plan_baselines%ROWTYPE;
  /* ---------------------------------------------------------------------------------- */
  CURSOR candidate_cur
  IS
    WITH /*+ ZAPPER MAIN CURSOR */ -- fake hint so it remains in sql text
    pdbs AS (
    SELECT /*+ NO_MERGE MATERIALIZE QB_NAME(pdbs) */ -- disjoint for perf reasons
           c.con_id,
           c.name pdb_name,
           (SELECT /*+ NO_MERGE */
                   CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
              FROM cdb_tables t
             WHERE t.con_id = c.con_id
               AND t.table_name = 'KIEVBUCKETS') kiev_pdb
      FROM v$containers c
     WHERE c.open_mode = 'READ WRITE'
       AND (l_pdb_id IS NULL OR c.con_id = l_pdb_id)
       AND NOT EXISTS (SELECT NULL FROM &&1..zapper_quarantine_pdb q WHERE q.pdb_name = c.name)
    ),
    v_sql AS (
    -- one row per sql/phv
    -- if a sql/phv has cursors with and without spb, still aggregates them into one row and qualifies it with spb
    SELECT /*+ NO_MERGE MATERIALIZE QB_NAME(v_sql) */ -- disjoint to avoid runing into ora-1555
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
     WHERE (p_sql_id = gk_all OR c.sql_id = p_sql_id)
       AND (l_pdb_id IS NULL OR c.con_id = l_pdb_id)
       AND c.con_id > 2 -- exclude CDB$ROOT and PDB$SEED
       AND c.parsing_user_id > 0 -- exclude SYS
       AND c.parsing_schema_id > 0 -- exclude SYS
       AND c.parsing_schema_name NOT LIKE 'C##'||CHR(37)
       AND c.plan_hash_value > 0
       AND c.exact_matching_signature > 0 -- INSERT from values has 0 on signature
       AND c.executions >= 0
       AND c.cpu_time > 0
       AND c.last_active_time > SYSDATE - gl_rec.cur_days -- to ignore cursors with possible plans that haven't been executed for a while
       AND c.object_status = 'VALID'
       AND c.is_obsolete = 'N'
       AND c.is_shareable = 'Y'
       AND NOT EXISTS (SELECT NULL FROM &&1..zapper_ignore_sql i WHERE i.sql_id = c.sql_id)
     GROUP BY
           c.con_id,
           c.parsing_user_id,
           c.parsing_schema_id,
           c.parsing_schema_name,
           c.sql_id,
           SUBSTR(c.sql_text, 1, gk_output_part_2_length),
           c.plan_hash_value,
           c.exact_matching_signature
    HAVING (l_only_plan_demotions = 'N' OR MAX(c.sql_plan_baseline) IS NOT NULL) -- if l_only_plan_demotions = 'Y' then consider only cursors with spb
       AND (l_only_create_spbl = 'N' OR MAX(c.sql_plan_baseline) IS NULL) -- if l_only_create_spbl = 'Y' then consider only cursors without spb
    ),
    child AS ( /* most recent child as per last_active_time */
    SELECT /*+ NO_MERGE MATERIALIZE USE_HASH(c l) QB_NAME(latest_child) */
           l.con_id,
           l.sql_id,
           l.plan_hash_value,
           l.child_number,
           l.object_status,
           l.is_obsolete,
           l.is_shareable,
           l.last_active_time,
           ROW_NUMBER() OVER (PARTITION BY l.con_id, l.sql_id, l.plan_hash_value ORDER BY l.last_active_time DESC) row_number
      FROM v_sql c,
           v$sql l
     WHERE (p_sql_id = gk_all OR l.sql_id = p_sql_id)
       AND (l_pdb_id IS NULL OR l.con_id = l_pdb_id)
       AND l.con_id = c.con_id
       AND l.sql_id = c.sql_id
       AND l.plan_hash_value = c.plan_hash_value
       AND l.child_number BETWEEN c.min_child_number AND c.max_child_number
       AND l.object_status = 'VALID'
       AND l.is_obsolete = 'N'
       AND l.is_shareable = 'Y'
    ),
    application_users AS (
    SELECT /*+ NO_MERGE MATERIALIZE QB_NAME(application_users) */ -- disjoint for perf reasons
           con_id,
           user_id
      FROM cdb_users
     WHERE oracle_maintained = 'N'
    ),
    mem_plan_metrics AS (
    SELECT /*+ NO_MERGE MATERIALIZE ORDERED USE_HASH(c l pu ps p) QB_NAME(mem_plan_metrics) */
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
       AND l.row_number = 1 -- most recent child as per last_active_time
       AND pu.con_id = c.con_id
       AND pu.user_id = c.parsing_user_id
       AND ps.con_id = c.con_id
       AND ps.user_id = c.parsing_schema_id
       AND p.con_id = c.con_id
       AND pu.con_id = l.con_id -- transitive
       AND ps.con_id = l.con_id -- transitive
       AND p.con_id = l.con_id -- transitive
       AND ps.con_id = pu.con_id -- transitive
       AND p.con_id = pu.con_id -- transitive
       AND p.con_id = ps.con_id -- transitive
       AND CASE 
             WHEN gl_rec.kiev_pdbs_only = 'Y' AND p.kiev_pdb = 'Y' THEN 1
             WHEN gl_rec.kiev_pdbs_only = 'N' THEN 1
             ELSE 0
           END = 1
       -- subquery c1 is to skip a cursor that has no SPB yet, but there are other
       -- active cursor(s) for same SQL_ID that already has/have a SPB.
       -- if a SQL has already a SPB in use at the time this tool executes, we simply do not
       -- want to create a new plan in SPB. reason is that maybe an earlier execution of this
       -- tool with a lower aggressiveness level just created a SPB, then on a subsequent
       -- execution of this tool we don't want to create a lower-quality SPB if we already
       -- have one created by a more conservative level of execution.
       AND CASE
           WHEN c.sql_plan_baseline IS NULL THEN 
             -- verify there are no cursors for this SQL (different plan) with active SPB
             ( SELECT /*+ QB_NAME(c1) */ COUNT(*)
                 FROM v_sql c1
                WHERE c1.con_id = c.con_id
                  AND c1.parsing_user_id = c.parsing_user_id
                  AND c1.parsing_schema_id = c.parsing_schema_id
                  AND c1.sql_id = c.sql_id
                  AND c1.sql_plan_baseline IS NOT NULL
             )
           ELSE 0 -- c.sql_plan_baseline IS NOT NULL (this cursor has a SPB)
           END = 0 -- this cursor has a SPB already, or all other cursors for same SQL have no active SPB
    )
    , con_sql_phv AS (
    SELECT /*+ NO_MERGE MATERIALIZE QB_NAME(con_sql_phv) */
           DISTINCT
           p.con_id,
           p.sql_id,
           p.plan_hash_value
      FROM mem_plan_metrics p
    )
    , all_plan_perf_time_series AS (
    -- historical performance metrics for all sql grouped by sql/phv/snap.
    SELECT /*+ NO_MERGE MATERIALIZE USE_HASH(h s) QB_NAME(all_plan_perf_time) */
           h.con_id,
           h.sql_id,
           h.parsing_user_id,
           h.parsing_schema_id,
           h.plan_hash_value,
           h.snap_id,
           s.begin_interval_time,
           s.end_interval_time,
           ((CAST(s.end_interval_time AS DATE) - CAST(s.begin_interval_time AS DATE)) * 24 * 60 * 60) interval_secs,
           SUM(h.executions_delta) executions_delta,
           SUM(h.buffer_gets_delta) buffer_gets_delta,
           SUM(h.disk_reads_delta) disk_reads_delta,
           SUM(h.rows_processed_delta) rows_processed_delta,
           SUM(h.sharable_mem) sharable_mem,
           SUM(h.elapsed_time_delta) elapsed_time_delta,
           SUM(h.cpu_time_delta) cpu_time_delta,
           SUM(h.iowait_delta) iowait_delta,
           SUM(h.apwait_delta) apwait_delta,
           SUM(h.ccwait_delta) ccwait_delta,
           SUM(h.executions_delta)/((CAST(s.end_interval_time AS DATE) - CAST(s.begin_interval_time AS DATE)) * 24 * 60 * 60) execs_per_sec,
           SUM(h.buffer_gets_delta)/SUM(GREATEST(h.executions_delta, 1)) buffer_gets_per_exec,
           SUM(h.disk_reads_delta)/SUM(GREATEST(h.executions_delta, 1)) disk_reads_per_exec,
           SUM(h.rows_processed_delta)/SUM(GREATEST(h.executions_delta, 1)) rows_processed_per_exec,
           SUM(h.elapsed_time_delta)/SUM(GREATEST(h.executions_delta, 1)) avg_et_us,
           SUM(h.cpu_time_delta)/SUM(GREATEST(h.executions_delta, 1)) avg_cpu_us,
           SUM(h.iowait_delta)/SUM(GREATEST(h.executions_delta, 1)) avg_user_io_us,
           SUM(h.apwait_delta)/SUM(GREATEST(h.executions_delta, 1)) avg_application_us,
           SUM(h.ccwait_delta)/SUM(GREATEST(h.executions_delta, 1)) avg_concurrency_us,
           MIN(h.optimizer_cost) min_optimizer_cost,
           MAX(h.optimizer_cost) max_optimizer_cost,
           ROW_NUMBER() OVER (PARTITION BY h.con_id, h.sql_id, h.parsing_user_id, h.parsing_schema_id, h.plan_hash_value ORDER BY h.snap_id DESC NULLS LAST) most_recent
      FROM dba_hist_sqlstat h,
           dba_hist_snapshot s
     WHERE (p_sql_id = gk_all OR h.sql_id = p_sql_id)
       AND (l_pdb_id IS NULL OR h.con_id = l_pdb_id)
       AND h.parsing_user_id > 0 -- exclude SYS
       AND h.parsing_schema_id > 0 -- exclude SYS
       AND h.parsing_schema_name NOT LIKE 'C##'||CHR(37)
       AND h.plan_hash_value > 0
       AND h.executions_total >= 0
       AND h.cpu_time_total > 0
       AND h.dbid = l_dbid
       AND h.snap_id >= l_min_snap_id_sqlstat
       AND h.executions_delta >= 0
       AND s.snap_id = h.snap_id
       AND s.dbid = h.dbid
       AND s.instance_number = h.instance_number
       AND s.end_interval_time - s.begin_interval_time < INTERVAL '1' DAY
     GROUP BY
           h.con_id,
           h.sql_id,
           h.parsing_user_id,
           h.parsing_schema_id,
           h.plan_hash_value,
           h.snap_id,
           s.begin_interval_time,
           s.end_interval_time
    )
    , plan_performance_time_series AS (
    -- historical performance metrics for each sql/phv/snap. not all have a history!
    SELECT /*+ NO_MERGE MATERIALIZE USE_HASH(p h) QB_NAME(plan_perf_time) */
           h.con_id,
           h.sql_id,
           h.parsing_user_id,
           h.parsing_schema_id,
           h.plan_hash_value,
           h.snap_id,
           h.begin_interval_time,
           h.end_interval_time,
           h.interval_secs,
           h.executions_delta,
           h.buffer_gets_delta,
           h.disk_reads_delta,
           h.rows_processed_delta,
           h.sharable_mem,
           h.elapsed_time_delta,
           h.cpu_time_delta,
           h.iowait_delta,
           h.apwait_delta,
           h.ccwait_delta,
           h.execs_per_sec,
           h.buffer_gets_per_exec,
           h.disk_reads_per_exec,
           h.rows_processed_per_exec,
           h.avg_et_us,
           h.avg_cpu_us,
           h.avg_user_io_us,
           h.avg_application_us,
           h.avg_concurrency_us,
           h.min_optimizer_cost,
           h.max_optimizer_cost,
           h.most_recent
      FROM con_sql_phv p,
           all_plan_perf_time_series h
     WHERE h.con_id = p.con_id
       AND h.sql_id = p.sql_id
       AND h.plan_hash_value = p.plan_hash_value
    )
    , plan_performance_metrics AS (
    -- historical performance metrics for each sql/phv. not all have a history!
    SELECT /*+ NO_MERGE MATERIALIZE QB_NAME(plan_perf_metrics) */
           con_id,
           sql_id,
           plan_hash_value,
           parsing_user_id,
           parsing_schema_id,
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
           MAX(CASE most_recent WHEN 1 THEN executions_delta END) mr_executions,
           MAX(CASE most_recent WHEN 1 THEN buffer_gets_delta END) mr_buffer_gets,
           MAX(CASE most_recent WHEN 1 THEN disk_reads_delta END) mr_disk_reads,
           MAX(CASE most_recent WHEN 1 THEN rows_processed_delta END) mr_rows_processed,
           MAX(CASE most_recent WHEN 1 THEN sharable_mem END) mr_sharable_mem,
           MAX(CASE most_recent WHEN 1 THEN elapsed_time_delta END) mr_elapsed_time,
           MAX(CASE most_recent WHEN 1 THEN cpu_time_delta END) mr_cpu_time,
           MAX(CASE most_recent WHEN 1 THEN iowait_delta END) mr_iowait,
           MAX(CASE most_recent WHEN 1 THEN apwait_delta END) mr_apwait,
           MAX(CASE most_recent WHEN 1 THEN ccwait_delta END) mr_ccwait,
           MAX(CASE most_recent WHEN 1 THEN execs_per_sec END) mr_execs_per_sec,
           MAX(CASE most_recent WHEN 1 THEN buffer_gets_per_exec END) mr_buffer_gets_per_exec,
           MAX(CASE most_recent WHEN 1 THEN disk_reads_per_exec END) mr_disk_reads_per_exec,
           MAX(CASE most_recent WHEN 1 THEN rows_processed_per_exec END) mr_rows_processed_per_exec,
           MAX(CASE most_recent WHEN 1 THEN avg_et_us END) mr_avg_et_us,
           MAX(CASE most_recent WHEN 1 THEN avg_cpu_us END) mr_avg_cpu_us,
           MAX(CASE most_recent WHEN 1 THEN avg_user_io_us END) mr_avg_user_io_us,
           MAX(CASE most_recent WHEN 1 THEN avg_application_us END) mr_avg_application_us,
           MAX(CASE most_recent WHEN 1 THEN avg_concurrency_us END) mr_avg_concurrency_us
      FROM plan_performance_time_series
     GROUP BY
           con_id,
           sql_id,
           plan_hash_value,
           parsing_user_id,
           parsing_schema_id
    ) -- Categorize SQL statement
    , extended_plan_metrics AS ( -- adding application_category
    -- application catagory is a custom grouping needed to assign thresholds on this tool
    SELECT /*+ NO_MERGE MATERIALIZE USE_HASH(cm pm) QB_NAME(ext_plan_metrics) */
           cm.con_id,
           cm.pdb_name,         
           cm.kiev_pdb,
           cm.parsing_schema_name,
           cm.sql_id,
           cm.parsing_user_id,
           cm.parsing_schema_id,
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
           pm.mr_executions,
           pm.mr_buffer_gets,
           pm.mr_disk_reads,
           pm.mr_rows_processed,
           pm.mr_sharable_mem,
           pm.mr_elapsed_time,
           pm.mr_cpu_time,
           pm.mr_iowait,
           pm.mr_apwait,
           pm.mr_ccwait,
           pm.mr_execs_per_sec,
           pm.mr_buffer_gets_per_exec,
           pm.mr_disk_reads_per_exec,
           pm.mr_rows_processed_per_exec,
           pm.mr_avg_et_us,
           pm.mr_avg_cpu_us,
           pm.mr_avg_user_io_us,
           pm.mr_avg_application_us,
           pm.mr_avg_concurrency_us
      FROM mem_plan_metrics cm,
           plan_performance_metrics pm
     WHERE pm.con_id(+) = cm.con_id
       AND pm.sql_id(+) = cm.sql_id
       AND pm.plan_hash_value(+) = cm.plan_hash_value
       AND pm.parsing_user_id(+) = cm.parsing_user_id
       and pm.parsing_schema_id(+) = cm.parsing_schema_id
    )
    -- candidates include sql that may get a spb and sql that already has one
    SELECT /*+ USE_HASH(em gl ap al) QB_NAME(candidate) */
           em.con_id,
           em.pdb_name,         
           em.kiev_pdb,
           em.parsing_schema_name,
           em.sql_id,
           em.parsing_user_id,
           em.parsing_schema_id,
           em.sql_text,
           em.application_category,
           em.plan_hash_value,
           em.metrics_source,
           CASE em.metrics_source WHEN k_source_mem THEN 'MEM' ELSE 'UNKOWN' END src,
           em.child_cursors,
           em.min_child_number,
           em.max_child_number,
           em.executions,
           em.buffer_gets,
           em.disk_reads,
           em.rows_processed,
           em.sharable_mem,
           em.elapsed_time,
           em.cpu_time,
           em.user_io_wait_time,
           em.application_wait_time,
           em.concurrency_wait_time,
           em.min_optimizer_cost,
           em.max_optimizer_cost,
           em.module,
           em.action,
           em.last_active_time,
           em.last_load_time,
           em.first_load_time,
           em.sql_profile,
           em.sql_patch,
           em.sql_plan_baseline,
           em.exact_matching_signature,
           em.l_child_number,
           em.l_object_status,
           em.l_is_obsolete,
           em.l_is_shareable,
           em.l_last_active_time,
           em.awr_snapshots,
           em.phv_min_snap_id,
           em.phv_max_snap_id,
           em.avg_execs_per_sec,
           em.max_execs_per_sec,
           em.p99_execs_per_sec,
           em.p97_execs_per_sec,
           em.p95_execs_per_sec,
           em.p90_execs_per_sec,
           em.med_execs_per_sec,
           em.avg_buffer_gets_per_exec,
           em.max_buffer_gets_per_exec,
           em.p99_buffer_gets_per_exec,
           em.p97_buffer_gets_per_exec,
           em.p95_buffer_gets_per_exec,
           em.p90_buffer_gets_per_exec,
           em.med_buffer_gets_per_exec,
           em.avg_disk_reads_per_exec,
           em.max_disk_reads_per_exec,
           em.p99_disk_reads_per_exec,
           em.p97_disk_reads_per_exec,
           em.p95_disk_reads_per_exec,
           em.p90_disk_reads_per_exec,
           em.med_disk_reads_per_exec,
           em.avg_rows_processed_per_exec,
           em.max_rows_processed_per_exec,
           em.p99_rows_processed_per_exec,
           em.p97_rows_processed_per_exec,
           em.p95_rows_processed_per_exec,
           em.p90_rows_processed_per_exec,
           em.med_rows_processed_per_exec,
           em.avg_sharable_mem,
           em.max_sharable_mem,
           em.p99_sharable_mem,
           em.p97_sharable_mem,
           em.p95_sharable_mem,
           em.p90_sharable_mem,
           em.med_sharable_mem,
           em.avg_avg_et_us,
           em.max_avg_et_us,
           em.p99_avg_et_us,
           em.p97_avg_et_us,
           em.p95_avg_et_us,
           em.p90_avg_et_us,
           em.med_avg_et_us,
           em.avg_avg_cpu_us,
           em.max_avg_cpu_us,
           em.p99_avg_cpu_us,
           em.p97_avg_cpu_us,
           em.p95_avg_cpu_us,
           em.p90_avg_cpu_us,
           em.med_avg_cpu_us,
           em.avg_avg_user_io_us,
           em.max_avg_user_io_us,
           em.p99_avg_user_io_us,
           em.p97_avg_user_io_us,
           em.p95_avg_user_io_us,
           em.p90_avg_user_io_us,
           em.med_avg_user_io_us,
           em.avg_avg_application_us,
           em.max_avg_application_us,
           em.p99_avg_application_us,
           em.p97_avg_application_us,
           em.p95_avg_application_us,
           em.p90_avg_application_us,
           em.med_avg_application_us,
           em.avg_avg_concurrency_us,
           em.max_avg_concurrency_us,
           em.p99_avg_concurrency_us,
           em.p97_avg_concurrency_us,
           em.p95_avg_concurrency_us,
           em.p90_avg_concurrency_us,
           em.med_avg_concurrency_us,
           em.mr_snap_id,
           em.mr_begin_interval_time,
           em.mr_end_interval_time,
           em.mr_interval_secs,
           em.mr_executions,
           em.mr_buffer_gets,
           em.mr_disk_reads,
           em.mr_rows_processed,
           em.mr_sharable_mem,
           em.mr_elapsed_time,
           em.mr_cpu_time,
           em.mr_iowait,
           em.mr_apwait,
           em.mr_ccwait,
           em.mr_execs_per_sec,
           em.mr_buffer_gets_per_exec,
           em.mr_disk_reads_per_exec,
           em.mr_rows_processed_per_exec,
           em.mr_avg_et_us,
           em.mr_avg_cpu_us,
           em.mr_avg_user_io_us,
           em.mr_avg_application_us,
           em.mr_avg_concurrency_us,
           ap.description,
           ap.min_num_rows,
           ap.et_90th_pctl_over_avg,
           ap.et_95th_pctl_over_avg,
           ap.et_97th_pctl_over_avg,
           ap.et_99th_pctl_over_avg,
           ap.execs_to_demote,
           ap.spb_probation_days,
           ap.secs_per_exec_bar,
           ap.slow_down_factor_bar,
           ap.spb_monitoring_days_cap,
           ap.secs_per_exec_cap,
           ap.slow_down_factor_cap,
           ap.execs_per_hr_threshold,
           al.execs_candidate,
           al.execs_to_qualify,
           al.secs_per_exec_candidate,
           al.secs_per_exec_to_qualify,
           al.secs_per_exec_90th_pctl,
           al.secs_per_exec_95th_pctl,
           al.secs_per_exec_97th_pctl,
           al.secs_per_exec_99th_pctl,
           al.first_load_hours_candidate,
           al.first_load_hours_qualify,
           ORA_HASH(em.con_id||em.sql_id||em.parsing_user_id||em.parsing_schema_id||em.plan_hash_value) sql_hash
      FROM extended_plan_metrics em,
           &&1..zapper_global gl,
           &&1..zapper_application ap,
           &&1..zapper_appl_and_level al
     WHERE gl.tool_name = gk_tool_name
       AND gl.enabled = 'Y'
       AND ap.application_category = em.application_category
       AND ap.enabled = 'Y'
       AND al.application_id = ap.application_id
       AND al.aggressiveness_level = p_aggressiveness
       AND em.first_load_time < SYSDATE - (al.first_load_hours_candidate / 24)
     ORDER BY
           em.pdb_name, -- 1st since we have subtotals per PDB
           ap.application_id,
           em.sql_id, -- clustered for easier review
           em.cpu_time / GREATEST(em.executions, 1); -- average performance
  --
  c_rec candidate_cur%ROWTYPE;
  /* ---------------------------------------------------------------------------------- */  
  PROCEDURE output (p_line IN VARCHAR2, p_alert_log IN BOOLEAN DEFAULT FALSE) 
  IS
    l_line VARCHAR2(528);
  BEGIN
    l_line := SUBSTR(p_line, 1, gk_output_part_1_length + 5 + gk_output_part_2_length);
    --
    IF l_line IS NULL THEN
      RETURN;
    END IF;
    --
    IF NOT l_cursor_details_section 
       OR  l_cursor_heading_section
       OR  l_message_section
       OR  l_candidate_was_accepted 
       OR  l_spb_demotion_was_accepted 
       OR  l_spb_promotion_was_accepted 
       OR  (c_rec.sql_plan_baseline IS NULL AND NOT l_candidate_was_accepted AND gl_rec.repo_rejected_candidates = 'Y')
       OR  (c_rec.sql_plan_baseline IS NOT NULL AND NOT l_spb_demotion_was_accepted AND NOT l_spb_promotion_was_accepted AND gl_rec.repo_non_promoted_spb = 'Y')
       OR  (c_rec.sql_plan_baseline IS NOT NULL AND b_rec.fixed = 'YES' AND gl_rec.repo_fixed_spb = 'Y')
       OR  p_sql_id <> gk_all
    THEN
      DBMS_OUTPUT.PUT_LINE (a => l_line);
    END IF;
    --
    -- SQL specific zapper report (use cs_spbl_zap_hist_list.sql and cs_spbl_zap_hist_report.sql)
    IF l_persist_zapper_report AND
       (    l_cursor_heading_section 
         OR l_message_section 
         OR l_candidate_was_accepted
         OR l_spb_demotion_was_accepted
         OR l_spb_promotion_was_accepted
         OR gl_rec.persist_null_actions = 'Y'
         OR p_sql_id <> gk_all
       )
    THEN 
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
    DBMS_LOCK.SLEEP(gl_rec.secs_after_any_spm_api_call);
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
    DBMS_LOCK.SLEEP(gl_rec.secs_after_any_spm_api_call);
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
    DBMS_LOCK.SLEEP(gl_rec.secs_after_any_spm_api_call);
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
    DBMS_LOCK.SLEEP(gl_rec.secs_after_any_spm_api_call);
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
       AND (CASE p_valid_only WHEN 'Y' THEN (CASE WHEN enabled = 'YES' AND accepted = 'YES' AND reproduced = 'YES'                   THEN 1 ELSE 0 END) ELSE 1 END) = 1
       AND (CASE p_fixed_only WHEN 'Y' THEN (CASE WHEN enabled = 'YES' AND accepted = 'YES' AND reproduced = 'YES' AND fixed = 'YES' THEN 1 ELSE 0 END) ELSE 1 END) = 1;
    RETURN l_plans;
  END pre_existing_plans;
  /* ---------------------------------------------------------------------------------- */  
  PROCEDURE get_stats_main_table (p_con_id IN NUMBER, p_sql_id IN VARCHAR2, r_owner OUT VARCHAR2, r_table_name OUT VARCHAR2, r_temporary OUT VARCHAR2, r_blocks OUT NUMBER, r_num_rows OUT NUMBER, r_avg_row_len OUT NUMBER, r_last_analyzed OUT DATE)
  IS
  BEGIN  
    WITH /*+ ZAPPER GET NUM_ROWS */ -- fake hint so it remains in sql text
    v_sqlarea_m AS (
    SELECT /*+ NO_MERGE MATERIALIZE QB_NAME(sqlarea) */ 
           con_id, hash_value, address
      FROM v$sqlarea 
     WHERE con_id = p_con_id 
       AND sql_id = p_sql_id
    ),
    v_object_dependency_m AS (
    SELECT /*+ NO_MERGE MATERIALIZE QB_NAME(obj_dependency) */ 
           o.con_id, o.to_hash, o.to_address 
      FROM v$object_dependency o,
           v_sqlarea_m s
     WHERE o.con_id = s.con_id 
       AND o.from_hash = s.hash_value 
       AND o.from_address = s.address
       AND o.con_id = p_con_id
    ),
    v_db_object_cache_m AS (
    SELECT /*+ NO_MERGE MATERIALIZE QB_NAME(obj_cache) */ 
           c.con_id,
           SUBSTR(c.owner,1,30) object_owner, 
           SUBSTR(c.name,1,30) object_name 
      FROM v$db_object_cache c,
           v_object_dependency_m d
     WHERE c.con_id = d.con_id 
       AND c.type IN ('TABLE','VIEW') 
       AND c.hash_value = d.to_hash
       AND c.addr = d.to_address 
       AND c.con_id = p_con_id
    ),
    cdb_tables_m AS (
    SELECT /*+ NO_MERGE MATERIALIZE QB_NAME(cdb_tables) */ 
           t.con_id,
           t.owner, 
           t.table_name, 
           t.temporary,
           t.blocks,
           t.num_rows, 
           t.avg_row_len,
           t.last_analyzed, 
           ROW_NUMBER() OVER (ORDER BY t.num_rows DESC NULLS LAST, t.temporary) row_number 
      FROM cdb_tables t,
           v_db_object_cache_m c
     WHERE t.con_id = c.con_id 
       AND t.owner = c.object_owner
       AND t.table_name = c.object_name 
       AND t.con_id = p_con_id
    )
    SELECT /*+ QB_NAME(get_stats) */
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
  /* ---------------------------------------------------------------------------------- */  
  BEGIN -- intialize_execution
    -- gets dbid for awr
    SELECT dbid, name, open_mode INTO l_dbid, l_db_name, l_open_mode FROM v$database;
    -- to be executed on DG primary only
    IF l_open_mode <> 'READ WRITE' THEN
      output ('*** to be executed on DG primary only ***');
      RETURN;
    END IF;
    -- read zapper_global parameters
    SELECT *
      INTO gl_rec
      FROM &&1..zapper_global
     WHERE tool_name = gk_tool_name;
    -- EXIT if disabled
    IF NVL(gl_rec.enabled, 'N') <> 'Y' THEN
      output ('*** '||gk_tool_name||' is disabled ***');
      RETURN;
    END IF;
    -- EXIT if requested to execute only on KIEV PDBs, and there were none on this CDB
    IF gl_rec.kiev_pdbs_only = 'Y' THEN
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
    DBMS_APPLICATION_INFO.SET_MODULE(gk_tool_name, 'LVL='||p_aggressiveness);
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
    -- gets host name and starup time
    SELECT host_name, startup_time INTO l_host_name, l_instance_startup_time FROM v$instance;
    -- gets pdb name and con_id
    l_pdb_name := SYS_CONTEXT('USERENV', 'CON_NAME');
    l_con_id := SYS_CONTEXT('USERENV', 'CON_ID');
    -- gets pdb id if pdb_name was passed
    IF p_pdb_name <> gk_all THEN
      SELECT con_id INTO l_pdb_id FROM v$containers WHERE open_mode = 'READ WRITE' AND name = UPPER(p_pdb_name);
    END IF;
    -- is this execution only to demote plans?
    IF gl_rec.create_spm_limit = 0 AND gl_rec.promote_spm_limit = 0 AND gl_rec.disable_spm_limit > 0 THEN
      l_only_plan_demotions := 'Y';
    ELSE
      l_only_plan_demotions := 'N';
    END IF;
    -- is this execution only to create spbs?
    IF gl_rec.create_spm_limit > 0 AND gl_rec.promote_spm_limit = 0 AND gl_rec.disable_spm_limit = 0 THEN
      l_only_create_spbl := 'Y';
    ELSE
      l_only_create_spbl := 'N';
    END IF;
    -- gets min snap_id for awr 
    SELECT MAX(snap_id) INTO l_min_snap_id_sqlstat FROM dba_hist_snapshot WHERE dbid = l_dbid AND begin_interval_time < SYSTIMESTAMP - gl_rec.awr_days AND end_interval_time - begin_interval_time < INTERVAL '1' DAY;
    IF l_min_snap_id_sqlstat IS NULL THEN
      SELECT MIN(s.snap_id) INTO l_min_snap_id_sqlstat FROM dba_hist_snapshot s WHERE s.dbid = l_dbid AND s.end_interval_time - s.begin_interval_time < INTERVAL '1' DAY;
    END IF;
    SELECT MAX(s.snap_id) INTO l_min_snap_id_sts FROM dba_hist_snapshot s, v$instance i WHERE s.dbid = l_dbid AND CAST(s.begin_interval_time AS DATE) < GREATEST(SYSDATE - gl_rec.awr_days, i.startup_time) AND s.end_interval_time - s.begin_interval_time < INTERVAL '1' DAY;
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
    output('FPZ Aggressiveness',                p_aggressiveness||' (1 .. N) 1=conservative, 2, 3=moderate, 4, ..., N=aggressive');
    output('|');
    output('Database',                          l_db_name);
    output('Plugable Database (PDB)',           l_pdb_name||' ('||l_con_id||')');
    output('Host',                              l_host_name);
    output('Instance Startup Time',             TO_CHAR(l_instance_startup_time, gk_date_format));
    output('Date and Time (begin)',             TO_CHAR(SYSDATE, gk_date_format));
    output('|');
    output('PDB Name',                          p_pdb_name);
    output('SQL_ID',                            p_sql_id);
    output('Plan History Considered (days)',    gl_rec.awr_days||' (days)');
    output('Min Snap ID (DBA_HIST_SQLSTAT)',    l_min_snap_id_sqlstat);
    output('Min Snap ID (SQL Tuning Sets)',     l_min_snap_id_sts);
    output('Max Snap ID',                       l_max_snap_id);
    output('Cursor Age Considered (days)',      TO_CHAR(gl_rec.cur_days, 'FM990.00')||' (days)');
    output('|');
    output(RPAD('+', gk_output_part_1_length + 5 + gk_output_part_2_length, '-'));
    /* -------------------------------------------------------------------------------- */  
    DELETE &&1..zapper_quarantine_pdb WHERE quarantine_expire < SYSDATE;
    FOR i IN (SELECT * FROM &&1..zapper_quarantine_pdb)
    LOOP
      output('PDB '||i.pdb_name,                'On quarantine until '||TO_CHAR(i.quarantine_expire, gk_date_format));
    END LOOP;
    --
    FOR i IN (SELECT * FROM &&1..zapper_ignore_sql)
    LOOP
      output('SQL_ID '||i.sql_id,               'Excluded '||i.reference);
    END LOOP;
    output(RPAD('+', gk_output_part_1_length + 5 + gk_output_part_2_length, '-'));
    COMMIT; -- no pending transaction at CDB$ROOT
  END; -- intialize_execution
  /* ---------------------------------------------------------------------------------- */  
  BEGIN -- candidates_loop
    -- Pre-select SQL_ID/PHV candidates from shared pool
    OPEN candidate_cur;
    LOOP
      FETCH candidate_cur INTO c_rec;
      EXIT WHEN candidate_cur%NOTFOUND;
      /* ------------------------------------------------------------------------------ */  
      BEGIN -- initialize_candidate
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
        --
        IF l_pdb_name_prior <> c_rec.pdb_name THEN 
          DBMS_APPLICATION_INFO.SET_MODULE(gk_tool_name, 'LVL='||p_aggressiveness||' '||c_rec.pdb_name);
          l_candidate_count_p := 0;
          l_spb_created_qualified_p := 0;
          l_spb_promoted_qualified_p := 0;
          l_spb_created_count_p := 0;
          l_spb_promoted_count_p := 0;
          l_spb_already_fixed_count_p := 0;
          l_spb_disable_qualified_p := 0;
          l_spb_disabled_count_p := 0;
          --IF gl_rec.debugging = 'Y' THEN
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
        l_message0                   := NULL;
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
        l_within_probation_window    := FALSE;
        l_within_monitoring_window   := FALSE;
        l_cur_slower_than_cat        := FALSE;
        l_cur_slower_than_spb        := FALSE;
        l_mrs_is_considered          := NVL(c_rec.mr_end_interval_time > SYSDATE - (gl_rec.most_recent_awr_snap_hours / 24), FALSE); -- most recent snap is only considered if it is younger than threshold age
        l_mrs_slower_than_cat        := FALSE;
        l_mrs_slower_than_spb        := FALSE;
        l_cur_violates_cat_cap       := FALSE;
        l_cur_violates_spb_cap       := FALSE;
        l_mrs_violates_cat_cap       := FALSE;
        l_mrs_violates_spb_cap       := FALSE;
        l_cur_in_monitoring_compliance:= FALSE;
        l_cur_in_probation_compliance:= FALSE;
        l_plans_returned             := 0;
        b_rec                        := NULL;
        l_us_per_exec_c              := c_rec.cpu_time / GREATEST(c_rec.executions, 1);
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
        l_persist_zapper_report      := TRUE;
        l_action                     := 'NULL';
        DBMS_LOB.createtemporary(lob_loc => l_zapper_report, cache => TRUE, dur => DBMS_LOB.session);
        --
        -- print one line with basic info in case of unexpected error
        l_cursor_heading_section := TRUE;
        IF gl_rec.debugging = 'Y' THEN
          output(RPAD('+', gk_output_part_1_length + 5 + gk_output_part_2_length, '-'));
          output('|');
          output('Candidate Number',              l_candidate_count_t);
          output('Parsing Schema Name',           c_rec.parsing_schema_name);
          output('SQL Text',                      REPLACE(REPLACE(c_rec.sql_text, CHR(10), CHR(32)), CHR(9), CHR(32)));
          output('SQL ID',                        c_rec.sql_id);
          output('Plan Hash Value (PHV)',         c_rec.plan_hash_value);
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
                        TO_CHAR(SYSDATE, gk_date_format)||' '||
                        SUBSTR(LPAD(c_rec.sql_hash, 10, '0'), 1, 10)||' '||
                        c_rec.sql_id||' '||
                        c_rec.plan_hash_value||' '||
                        c_rec.exact_matching_signature||' ';
          IF c_rec.sql_plan_baseline IS NOT NULL THEN
            l_messaged := l_messaged||c_rec.sql_plan_baseline||' ';
          END IF;
          IF c_rec.sql_profile IS NOT NULL THEN
            l_messaged := l_messaged||c_rec.sql_profile||' ';
          END IF;
          IF c_rec.sql_patch IS NOT NULL THEN
            l_messaged := l_messaged||c_rec.sql_patch||' ';
          END IF;
          l_messaged := l_messaged||c_rec.application_category||' ';
          l_messaged := l_messaged||REPLACE(REPLACE(c_rec.sql_text, CHR(10), CHR(32)), CHR(9), CHR(32));
          output(l_messaged);
        END IF;
        l_cursor_heading_section := FALSE;
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
      END; -- initialize_candidate
      /* ------------------------------------------------------------------------------ */  
      BEGIN -- baseline_exists
        --
        -- If there exists a SQL Plan Baseline (SPB) for candidate 
        --
        IF c_rec.sql_plan_baseline IS NOT NULL THEN
          get_spb_rec (
            p_signature => c_rec.exact_matching_signature,
            p_plan_name => c_rec.sql_plan_baseline,
            p_con_id    => c_rec.con_id
          );
          IF b_rec.signature IS NULL THEN -- not expected 
            l_message1 := '*** ERR-00010: SPB is missing!';
          ELSIF b_rec.created IS NULL THEN -- not expected 
            l_message1 := '*** ERR-00012: SPB created is null!';
          ELSIF c_rec.spb_probation_days IS NULL THEN -- not expected 
            l_message1 := '*** ERR-00014: SPB probation days is null!';
          ELSIF c_rec.spb_monitoring_days_cap IS NULL THEN -- not expected 
            l_message1 := '*** ERR-00016: SPB monitoring days is null!';
          ELSIF b_rec.enabled = 'NO' OR b_rec.accepted = 'NO' OR b_rec.reproduced = 'NO' THEN -- not expected
            l_message1 := '*** ERR-00020: SPB is inactive: Enabled='||b_rec.enabled||' Accepted='||b_rec.accepted||' Reproduced='||b_rec.reproduced||'.';
          ELSE -- SPB record is available (as expected)
            BEGIN -- initialize_baseline
              l_spb_exists := TRUE;
              --
              BEGIN -- spb_metrics_thresholds
                -- plan performance at the time the baseline was created (be aware it could be zero)
                l_us_per_exec_b := b_rec.cpu_time / GREATEST(b_rec.executions, 1);
                -- cursor and most recent snapshot performamce
                l_cur_ms := NVL(TO_CHAR(ROUND(l_us_per_exec_c / 1e3, 3), 'FM999,999,990.000'), '?')||'ms';
                l_mrs_ms := NVL(TO_CHAR(ROUND(c_rec.mr_avg_cpu_us / 1e3, 3), 'FM999,999,990.000'), '?')||'ms';
                -- probation performance (if not compliant then warn)
                l_cat_ms := TO_CHAR(ROUND(c_rec.secs_per_exec_bar * 1e3, 3), 'FM999,999,990.000')||'ms';
                l_spb_ms := c_rec.slow_down_factor_bar||'x '||TO_CHAR(ROUND(l_us_per_exec_b / 1e3, 3), 'FM999,999,990.000')||'ms';
                -- monitoring performance (if not compliant then disable)
                l_cat_cap_ms := TO_CHAR(ROUND(c_rec.secs_per_exec_cap * 1e3, 3), 'FM999,999,990.000')||'ms';
                l_spb_cap_ms := c_rec.slow_down_factor_cap||'x '||TO_CHAR(ROUND(l_us_per_exec_b / 1e3, 3), 'FM999,999,990.000')||'ms';
              END; -- spb_metrics_thresholds
              --
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
              --
              BEGIN -- spb_windows
                -- is baseline age within probation or monitoring windows?
                l_within_probation_window := b_rec.created > SYSDATE - c_rec.spb_probation_days;
                l_within_monitoring_window := b_rec.created > SYSDATE - c_rec.spb_monitoring_days_cap;
              END; -- spb_windows
              --
              BEGIN -- probation_booleans
                -- cursor slower than max category threshold
                l_cur_slower_than_cat := NVL((l_us_per_exec_c    / 1e3 > c_rec.secs_per_exec_bar * 1e3), FALSE);
                -- cursor slower than plan when spb was created
                l_cur_slower_than_spb := NVL((l_us_per_exec_c    / 1e3 > c_rec.slow_down_factor_bar * l_us_per_exec_b / 1e3 AND l_us_per_exec_b > 0), FALSE);
                -- most recent snap slower than max category threshold
                l_mrs_slower_than_cat := NVL((c_rec.mr_avg_cpu_us / 1e3 > c_rec.secs_per_exec_bar * 1e3) AND l_mrs_is_considered, FALSE);
                -- most recent snap slower than plan when spb was created
                l_mrs_slower_than_spb := NVL((c_rec.mr_avg_cpu_us / 1e3 > c_rec.slow_down_factor_bar * l_us_per_exec_b / 1e3 AND l_us_per_exec_b > 0) AND l_mrs_is_considered, FALSE);
                -- cursor is in probation compliance if it does not violate any of these
                l_cur_in_probation_compliance := NVL(NOT l_cur_slower_than_cat AND NOT l_cur_slower_than_spb AND NOT l_mrs_slower_than_cat AND NOT l_mrs_slower_than_spb, TRUE);
              END; -- probation_booleans
              --
              BEGIN -- monitoring_booleans
                -- cursor violates laxed extended category cap 
                l_cur_violates_cat_cap := NVL((l_us_per_exec_c    / 1e3 > c_rec.secs_per_exec_cap * 1e3), FALSE);
                -- cursor violates laxed performamce cap comparing current plan performance to a threshold times the plan performance when baseline was created
                l_cur_violates_spb_cap := NVL((l_us_per_exec_c    / 1e3 > c_rec.slow_down_factor_cap * l_us_per_exec_b / 1e3 AND l_us_per_exec_b > 0), FALSE);
                -- mrs violates laxed category cap 
                l_mrs_violates_cat_cap := NVL((c_rec.mr_avg_cpu_us / 1e3 > c_rec.secs_per_exec_cap * 1e3) AND l_mrs_is_considered, FALSE);
                -- mrs violates laxed performamce cap comparing current plan performance to a threshold times the plan performance when baseline was created
                l_mrs_violates_spb_cap := NVL((c_rec.mr_avg_cpu_us / 1e3 > c_rec.slow_down_factor_cap * l_us_per_exec_b / 1e3 AND l_us_per_exec_b > 0) AND l_mrs_is_considered, FALSE);
                -- cursor is in laxed cap compliance if it does not violate category cap nor performance cap 
                l_cur_in_monitoring_compliance := NVL(NOT l_cur_violates_cat_cap AND NOT l_cur_violates_spb_cap AND NOT l_mrs_violates_cat_cap AND NOT l_mrs_violates_spb_cap, TRUE);
              END; -- monitoring_booleans
            END; -- initialize_baseline
            --
            /* ------------------------------------------------------------------------ */
            --
            -- Skip promotion or demotion if: 
            --   a) out of monitoring window; OR
            --   b) already fixed and in compliance; OR
            --   c) not enough executions to promote or demote
            --
            IF NOT l_within_monitoring_window THEN
              IF b_rec.fixed = 'YES' THEN
                l_message1 := 'MSG-00012: Skip. SPB already FIXED and '||c_rec.spb_monitoring_days_cap||' days monitoring window has closed.';
                l_spb_already_fixed_count_p := l_spb_already_fixed_count_p + 1;
                l_spb_already_fixed_count_t := l_spb_already_fixed_count_t + 1;
              ELSE
                l_message1 := 'MSG-00013: Skip. SPB '||c_rec.spb_monitoring_days_cap||' days monitoring window has closed.';
              END IF;
            -- l_within_monitoring_window
            ELSIF b_rec.fixed = 'YES' AND l_cur_in_probation_compliance THEN
              l_message1 := 'MSG-00015: Skip. SPB already FIXED and in compliance.';
              l_spb_already_fixed_count_p := l_spb_already_fixed_count_p + 1;
              l_spb_already_fixed_count_t := l_spb_already_fixed_count_t + 1;
            ELSIF b_rec.fixed = 'YES' AND l_cur_in_monitoring_compliance THEN
              l_message1 := 'MSG-00014: Skip. SPB already FIXED and in compliance.';
              l_spb_already_fixed_count_p := l_spb_already_fixed_count_p + 1;
              l_spb_already_fixed_count_t := l_spb_already_fixed_count_t + 1;
            ELSIF c_rec.avg_execs_per_sec * 3600 < c_rec.execs_per_hr_threshold THEN
              l_message1 := 'MSG-00110: Skip. Not enough execs per hour to promote or demote SPB. Threshold:'||TO_CHAR(ROUND(c_rec.execs_per_hr_threshold, 3), 'FM999,999,990.000')||'. Has:'||TO_CHAR(ROUND(c_rec.avg_execs_per_sec * 3600, 3), 'FM999,999,990.000')||' ( as per cur.)';
            ELSIF c_rec.mr_execs_per_sec * 3600 < c_rec.execs_per_hr_threshold THEN
              l_message1 := 'MSG-00120: Skip. Not enough execs per hour to promote or demote SPB. Threshold:'||TO_CHAR(ROUND(c_rec.execs_per_hr_threshold, 3), 'FM999,999,990.000')||'. Has:'||TO_CHAR(ROUND(c_rec.mr_execs_per_sec * 3600, 3), 'FM999,999,990.000')||' (as per mrs.)';        
            ELSIF c_rec.executions < c_rec.execs_to_demote THEN
              l_message1 := 'MSG-00125: Skip. Not enough executions to promote or demote SPB. Threshold:'||TO_CHAR(c_rec.execs_to_demote, 'FM999,999,990')||'. Has:'||TO_CHAR(c_rec.executions, 'FM999,999,990.');        
            /* ------------------------------------------------------------------------ */  
            ELSIF NOT l_cur_in_probation_compliance THEN
              --
              -- Warns SPB is underperforming (thus on its path to disable plan)
              -- regardless if spb is fixed or not
              --
              l_message1 := 'MSG-00029: SPB in performance regression (on its path to be disabled)';
              --
              IF    l_cur_slower_than_cat -- cursor slower than max category threshold
              THEN
                l_message2 := 'MSG-00029-1 MEM Avg CPU Time per Exec > Time per Exec Bar: '||
                              l_cur_ms||' > '||l_cat_ms;
              ELSIF l_cur_slower_than_spb -- cursor slower than plan when spb was created
              THEN
                l_message2 := 'MSG-00029-2 MEM Avg CPU Time per Exec > Slow-down Factor Bar x SPB Avg CPU Time per Exec: '||
                               l_cur_ms||' > '||l_spb_ms;
              ELSIF l_mrs_slower_than_cat -- most recent snap slower than max category threshold 
              THEN
                l_message2 := 'MSG-00029-3 SNAP:'||NVL(TO_CHAR(c_rec.mr_snap_id), 'NA')||' Avg CPU Time per Exec > Time per Exec Bar: '||
                              l_mrs_ms||' > '||l_cat_ms;
              ELSIF l_mrs_slower_than_spb -- most recent snap slower than plan when spb was created  
              THEN
                l_message2 := 'MSG-00029-4 SNAP:'||NVL(TO_CHAR(c_rec.mr_snap_id), 'NA')||' Avg CPU Time per Exec > Slow-down Factor Bar x SPB Avg CPU Time per Exec: '||
                              l_mrs_ms||' > '||l_spb_ms;
              END IF;
              --
              l_message3 := '('||
                            'cur:'||l_cur_ms||', '||
                            'mrs:'||l_mrs_ms||', '||
                            'cat:'||l_cat_ms||', '||
                            'spb:'||l_spb_ms||', '||
                            'catc:'||l_cat_cap_ms||', '||
                            'spbc:'||l_spb_cap_ms||
                            ')';
            /* ------------------------------------------------------------------------ */  
            ELSIF NOT l_cur_in_monitoring_compliance THEN
              --
              -- Demote SPB if underperforms (disable plan)
              -- regardless if SPB is fixed or not
              --
              l_spb_demotion_was_accepted := TRUE;
              l_spb_disable_qualified_p := l_spb_disable_qualified_p + 1;
              l_spb_disable_qualified_t := l_spb_disable_qualified_t + 1;
              --
              IF    l_cur_violates_cat_cap -- cursor slower than category cap
              THEN
                l_message2 := 'MSG-00020-1 MEM Avg CPU Time per Exec > Time per Exec Cap: '||
                              l_cur_ms||' > '||l_cat_cap_ms;
              ELSIF l_cur_violates_spb_cap -- cursor slower than performance cap
              THEN
                l_message2 := 'MSG-00020-2 MEM Avg CPU Time per Exec > Slow-down Factor Cap x SPB Avg CPU Time per Exec: '||
                               l_cur_ms||' > '||l_spb_cap_ms;
              ELSIF    l_mrs_violates_cat_cap -- most recent snap slower than category cap
              THEN
                l_message2 := 'MSG-00020-3 SNAP:'||NVL(TO_CHAR(c_rec.mr_snap_id), 'NA')||' Avg CPU Time per Exec > Time per Exec Cap: '||
                              l_cur_ms||' > '||l_cat_cap_ms;
              ELSIF l_mrs_violates_spb_cap -- most recent snap slower than performance cap
              THEN
                l_message2 := 'MSG-00020-4 SNAP:'||NVL(TO_CHAR(c_rec.mr_snap_id), 'NA')||' Avg CPU Time per Exec > Slow-down Factor Cap x SPB Avg CPU Time per Exec: '||
                               l_cur_ms||' > '||l_spb_cap_ms;
              END IF;
              --
              l_message3 := '('||
                            'cur:'||l_cur_ms||', '||
                            'mrs:'||l_mrs_ms||', '||
                            'cat:'||l_cat_ms||', '||
                            'spb:'||l_spb_ms||', '||
                            'catc:'||l_cat_cap_ms||', '||
                            'spbc:'||l_spb_cap_ms||
                            ')';
              --
              IF l_spb_disabled_count_t < gl_rec.disable_spm_limit AND p_report_only = 'N' THEN
                BEGIN -- disable_spb
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
                    l_description := 'IOD FPZ APPL='||c_rec.application_category||' LVL='||p_aggressiveness||' SQL_ID='||c_rec.sql_id||' PHV='||c_rec.plan_hash_value||' DISABLED='||TO_CHAR(SYSDATE, gk_date_format);
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
                  l_us_per_exec_b := b_rec.cpu_time / GREATEST(b_rec.executions, 1);
                END; -- disable_spb
              ELSE -- l_spb_disabled_count_t > gl_rec.disable_spm_limit OR p_report_only = 'Y'
                l_message1 := 'MSG-00030: SPB qualifies for demotion (DISABLE).';
              END IF; -- l_spb_disabled_count_t < gl_rec.disable_spm_limit
            /* ------------------------------------------------------------------------ */
            --
            -- Existing SPB could be bogus (trying to avoid ORA-13831 as per bug 27496360)
            -- If SPB is suspected bogus then disable it!!!
            --
            ELSIF gl_rec.workaround_ora_13831 = 'Y' AND l_plan_id <> l_plan_hash_2 THEN -- if one or both are null, then simply skip this part
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
              IF l_spb_disabled_count_t < gl_rec.disable_spm_limit AND p_report_only = 'N' THEN
                BEGIN -- disable_spb_13831
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
                    l_description := 'IOD FPZ APPL='||c_rec.application_category||' LVL='||p_aggressiveness||' SQL_ID='||c_rec.sql_id||' '||l_messaget||' DISABLED='||TO_CHAR(SYSDATE, gk_date_format);
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
                  l_us_per_exec_b := b_rec.cpu_time / GREATEST(b_rec.executions, 1);
                  l_13831_disabled_all_calls := l_13831_disabled_all_calls + 1;
                END; -- disable_spb_13831
              ELSE -- l_spb_disabled_count_t > gl_rec.disable_spm_limit OR p_report_only = 'Y'
                l_message1 := 'MSG-00150: SPB qualifies for demotion (DISABLE)';          
              END IF;
            /* ------------------------------------------------------------------------ */
            --
            -- Existing SPB could be bogus (trying to avoid ORA-06502 and ORA-06512)
            -- If SPB is suspected bogus then disable it!!!
            --
            ELSIF gl_rec.workaround_ora_06512 = 'Y' AND l_plan_id IS NULL THEN
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
              IF l_spb_disabled_count_t < gl_rec.disable_spm_limit AND p_report_only = 'N' THEN
                BEGIN -- disable_spb_06512
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
                    l_description := 'IOD FPZ APPL='||c_rec.application_category||' LVL='||p_aggressiveness||' SQL_ID='||c_rec.sql_id||' '||l_messaget||' DISABLED='||TO_CHAR(SYSDATE, gk_date_format);
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
                  l_us_per_exec_b := b_rec.cpu_time / GREATEST(b_rec.executions, 1);
                  l_06512_disabled_all_calls := l_06512_disabled_all_calls + 1;
                END; -- disable_spb_06512
              ELSE -- l_spb_disabled_count_t > gl_rec.disable_spm_limit OR p_report_only = 'Y'
                l_message1 := 'MSG-00170: SPB qualifies for demotion (DISABLE)';          
              END IF;
            /* ------------------------------------------------------------------------ */
            --
            -- If existing SQL Plan Baseline (SPB) for candidate is in compliance then
            -- Evaluate and perform conditional SPB promotion
            --
            ELSIF b_rec.fixed = 'YES' THEN 
              l_message1 := 'MSG-00016: Skip. SPB already FIXED.'; -- this should not happen (merely a precaution)
              l_spb_already_fixed_count_p := l_spb_already_fixed_count_p + 1;
              l_spb_already_fixed_count_t := l_spb_already_fixed_count_t + 1;
            ELSIF l_only_plan_demotions = 'Y' THEN
              l_message1 := 'MSG-00041: Promotion evaluation skipped. Only demotions are considered.';
              -- adjust candidate counters
              l_candidate_count_t := l_candidate_count_t - 1;
              l_candidate_count_p := l_candidate_count_p - 1;            
            ELSIF l_within_probation_window THEN
              l_message1 := 'MSG-00040: SPB promotion to "FIXED" rejected at this time. SPB needs to be older than '||c_rec.spb_probation_days||' days.';
            ELSIF l_owner IS NULL OR l_table_name IS NULL THEN
              l_message1 := 'MSG-00060: SPB promotion to "FIXED" rejected. Unknown main table.';
            ELSIF l_last_analyzed IS NULL OR l_num_rows IS NULL THEN
              l_message1 := 'MSG-00070: SPB promotion to "FIXED" rejected. Main table has no CBO statistics.';
            ELSIF l_num_rows < c_rec.min_num_rows THEN
              l_message1 := 'MSG-00080: SPB promotion to "FIXED" rejected. Number of rows on main table ('||l_num_rows||') is below required threshold ('||c_rec.min_num_rows||').';        
            /* ------------------------------------------------------------------------ */  
            ELSE -- l_within_monitoring_window
              --
              -- Promote SPB after proven performance is in compliance (thus "fix" it)
              --
              l_spb_promotion_was_accepted := TRUE;
              l_spb_promoted_qualified_p := l_spb_promoted_qualified_p + 1;
              l_spb_promoted_qualified_t := l_spb_promoted_qualified_t + 1;
              --
              IF l_spb_promoted_count_t < gl_rec.promote_spm_limit AND p_report_only = 'N' THEN
                BEGIN -- fix_spb
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
                    l_description := 'IOD FPZ APPL='||c_rec.application_category||' LVL='||p_aggressiveness||' SQL_ID='||c_rec.sql_id||' PHV='||c_rec.plan_hash_value||' FIXED='||TO_CHAR(SYSDATE, gk_date_format);
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
                  l_us_per_exec_b := b_rec.cpu_time / GREATEST(b_rec.executions, 1);
                END; -- fix_spb
              ELSE -- l_spb_promoted_count_t > gl_rec.promote_spm_limit OR p_report_only = 'Y'
                l_message1 := 'MSG-00100: SPB qualifies for promotion (FIXED).';
              END IF; -- l_spb_promoted_count_t < gl_rec.promote_spm_limit
            END IF; -- l_within_monitoring_window
          END IF; -- b_rec.signature IS NULL
        END IF; -- c_rec.sql_plan_baseline IS NOT NULL
      END; -- baseline_exists
      /* ------------------------------------------------------------------------------ */  
      BEGIN -- baseline_does_not_exist
        IF c_rec.sql_plan_baseline IS NULL THEN
          --
          -- If there does not exist a SQL Plan Baseline (SPB) for candidate
          --
          -- First, further screen candidate
          --
          IF l_us_per_exec_c / 1e6 > c_rec.secs_per_exec_candidate OR c_rec.executions < c_rec.execs_candidate THEN
            -- simply ignore. this is to make it up for adjusting predicates from plan_metrics queries on candidate_cur
            IF l_us_per_exec_c / 1e6 > c_rec.secs_per_exec_candidate THEN
              l_message1 := 'MSG-01014: Candidate rejected. '||TRIM(TO_CHAR(l_us_per_exec_c/1e3,'999,999,990.000'))||' ms per exec > '||TRIM(TO_CHAR(c_rec.secs_per_exec_candidate*1e3,'999,999,990.000'))||' ms threshold.';
            ELSE
              l_message1 := 'MSG-01015: Candidate rejected. '||c_rec.executions||' execs < '||c_rec.execs_candidate||' execs threshold.';
            END IF;
            -- adjust candidate counters
            l_candidate_count_t := l_candidate_count_t - 1;
            l_candidate_count_p := l_candidate_count_p - 1;
          ELSIF p_sql_id = gk_all AND SYSDATE - l_instance_startup_time < gl_rec.instance_days THEN
            l_message1 := 'MSG-01010: SPB rejected. Instance is '||TRUNC(SYSDATE - l_instance_startup_time)||' days old. Has to be older than '||gl_rec.instance_days||' days.';
          ELSIF c_rec.first_load_time > SYSDATE - (c_rec.first_load_hours_qualify / 24) THEN
            l_message1 := 'MSG-01020: SPB rejected. SQL''s first load time is too recent. Still within the last '||c_rec.first_load_hours_qualify||' hours(s) window.';
          ELSIF c_rec.executions < c_rec.execs_to_qualify THEN
            l_message1 := 'MSG-01030: SPB rejected. '||c_rec.executions||' executions is less than '||c_rec.execs_to_qualify||' threshold for this SQL category.';
          ELSIF l_us_per_exec_c / 1e6 > c_rec.secs_per_exec_to_qualify AND c_rec.metrics_source = k_source_mem THEN
            l_message1 := 'MSG-01040: SPB rejected. "MEM Avg CPU Time per Exec" exceeds '||(c_rec.secs_per_exec_to_qualify * 1e3)||'ms threshold for this SQL category.';
          ELSIF c_rec.mr_avg_cpu_us / 1e6 > c_rec.secs_per_exec_to_qualify AND l_mrs_is_considered THEN
            l_message1 := 'MSG-01045: SPB rejected. "SNAP:'||NVL(TO_CHAR(c_rec.mr_snap_id), 'NA')||' Avg CPU Time per Exec" exceeds '||(c_rec.secs_per_exec_to_qualify * 1e3)||'ms threshold for this SQL category.';
          ELSIF c_rec.avg_avg_cpu_us / 1e6 > c_rec.secs_per_exec_to_qualify THEN
            l_message1 := 'MSG-01050: SPB rejected. "AWR Avg CPU Time per Exec" exceeds '||(c_rec.secs_per_exec_to_qualify * 1e3)||'ms threshold for this SQL category.';
          ELSIF c_rec.med_avg_cpu_us / 1e6 > c_rec.secs_per_exec_to_qualify THEN
            l_message1 := 'MSG-01060: SPB rejected. "Median CPU Time per Exec" exceeds '||(c_rec.secs_per_exec_to_qualify * 1e3)||'ms threshold for this SQL category.';
          ELSIF c_rec.p90_avg_cpu_us / 1e6 > c_rec.secs_per_exec_90th_pctl THEN
            l_message1 := 'MSG-01070: SPB rejected. "90th Pctl CPU Time per Exec" exceeds '||(c_rec.secs_per_exec_90th_pctl * 1e3)||'ms threshold for this SQL category.';
          ELSIF c_rec.p95_avg_cpu_us / 1e6 > c_rec.secs_per_exec_95th_pctl THEN
            l_message1 := 'MSG-01080: SPB rejected. "95th Pctl CPU Time per Exec" exceeds '||(c_rec.secs_per_exec_95th_pctl * 1e3)||'ms threshold for this SQL category.';
          ELSIF c_rec.p97_avg_cpu_us / 1e6 > c_rec.secs_per_exec_97th_pctl THEN
            l_message1 := 'MSG-01090: SPB rejected. "97th Pctl CPU Time per Exec" exceeds '||(c_rec.secs_per_exec_97th_pctl * 1e3)||'ms threshold for this SQL category.';
          ELSIF c_rec.p99_avg_cpu_us / 1e6 > c_rec.secs_per_exec_99th_pctl THEN
            l_message1 := 'MSG-01100: SPB rejected. "99th Pctl CPU Time per Exec" exceeds '||(c_rec.secs_per_exec_99th_pctl * 1e3)||'ms threshold for this SQL category.';
          ELSIF c_rec.p90_avg_cpu_us > c_rec.et_90th_pctl_over_avg * l_us_per_exec_c     AND c_rec.p90_avg_cpu_us / 1e6 > c_rec.secs_per_exec_to_qualify AND c_rec.metrics_source = k_source_mem THEN
            l_message1 := 'MSG-01110: SPB rejected. "90th Pctl CPU Time per Exec" exceeds '||c_rec.et_90th_pctl_over_avg||'x "MEM Avg CPU Time per Exec" threshold.';
          ELSIF c_rec.p90_avg_cpu_us > c_rec.et_90th_pctl_over_avg * c_rec.avg_avg_cpu_us AND c_rec.p90_avg_cpu_us / 1e6 > c_rec.secs_per_exec_to_qualify THEN
            l_message1 := 'MSG-01120: SPB rejected. "90th Pctl CPU Time per Exec" exceeds '||c_rec.et_90th_pctl_over_avg||'x "AWR Avg CPU Time per Exec" threshold.';
          ELSIF c_rec.p90_avg_cpu_us > c_rec.et_90th_pctl_over_avg * c_rec.med_avg_cpu_us AND c_rec.p90_avg_cpu_us / 1e6 > c_rec.secs_per_exec_to_qualify THEN
            l_message1 := 'MSG-01130: SPB rejected. "90th Pctl CPU Time per Exec" exceeds '||c_rec.et_90th_pctl_over_avg||'x "Median CPU Time per Exec" threshold.';
          ELSIF c_rec.p95_avg_cpu_us > c_rec.et_95th_pctl_over_avg * l_us_per_exec_c     AND c_rec.p95_avg_cpu_us / 1e6 > c_rec.secs_per_exec_to_qualify AND c_rec.metrics_source = k_source_mem THEN
            l_message1 := 'MSG-01140: SPB rejected. "95th Pctl CPU Time per Exec" exceeds '||c_rec.et_95th_pctl_over_avg||'x "MEM Avg CPU Time per Exec" threshold.';
          ELSIF c_rec.p95_avg_cpu_us > c_rec.et_95th_pctl_over_avg * c_rec.avg_avg_cpu_us AND c_rec.p95_avg_cpu_us / 1e6 > c_rec.secs_per_exec_to_qualify THEN
            l_message1 := 'MSG-01150: SPB rejected. "95th Pctl CPU Time per Exec" exceeds '||c_rec.et_95th_pctl_over_avg||'x "AWR Avg CPU Time per Exec" threshold.';
          ELSIF c_rec.p95_avg_cpu_us > c_rec.et_95th_pctl_over_avg * c_rec.med_avg_cpu_us AND c_rec.p95_avg_cpu_us / 1e6 > c_rec.secs_per_exec_to_qualify THEN
            l_message1 := 'MSG-01160: SPB rejected. "95th Pctl CPU Time per Exec" exceeds '||c_rec.et_95th_pctl_over_avg||'x "Median CPU Time per Exec" threshold.';
          ELSIF c_rec.p97_avg_cpu_us > c_rec.et_97th_pctl_over_avg * l_us_per_exec_c     AND c_rec.p97_avg_cpu_us / 1e6 > c_rec.secs_per_exec_to_qualify AND c_rec.metrics_source = k_source_mem THEN
            l_message1 := 'MSG-01170: SPB rejected. "97th Pctl CPU Time per Exec" exceeds '||c_rec.et_97th_pctl_over_avg||'x "MEM Avg CPU Time per Exec" threshold.';
          ELSIF c_rec.p97_avg_cpu_us > c_rec.et_97th_pctl_over_avg * c_rec.avg_avg_cpu_us AND c_rec.p97_avg_cpu_us / 1e6 > c_rec.secs_per_exec_to_qualify THEN
            l_message1 := 'MSG-01180: SPB rejected. "97th Pctl CPU Time per Exec" exceeds '||c_rec.et_97th_pctl_over_avg||'x "AWR Avg CPU Time per Exec" threshold.';
          ELSIF c_rec.p97_avg_cpu_us > c_rec.et_97th_pctl_over_avg * c_rec.med_avg_cpu_us AND c_rec.p97_avg_cpu_us / 1e6 > c_rec.secs_per_exec_to_qualify THEN
            l_message1 := 'MSG-01190: SPB rejected. "97th Pctl CPU Time per Exec" exceeds '||c_rec.et_97th_pctl_over_avg||'x "Median CPU Time per Exec" threshold.';
          ELSIF c_rec.p99_avg_cpu_us > c_rec.et_99th_pctl_over_avg * l_us_per_exec_c     AND c_rec.p99_avg_cpu_us / 1e6 > c_rec.secs_per_exec_to_qualify AND c_rec.metrics_source = k_source_mem THEN
            l_message1 := 'MSG-01200: SPB rejected. "99th Pctl CPU Time per Exec" exceeds '||c_rec.et_99th_pctl_over_avg||'x "MEM Avg CPU Time per Exec" threshold.';
          ELSIF c_rec.p99_avg_cpu_us > c_rec.et_99th_pctl_over_avg * c_rec.avg_avg_cpu_us AND c_rec.p99_avg_cpu_us / 1e6 > c_rec.secs_per_exec_to_qualify THEN
            l_message1 := 'MSG-01210: SPB rejected. "99th Pctl CPU Time per Exec" exceeds '||c_rec.et_99th_pctl_over_avg||'x "AWR Avg CPU Time per Exec" threshold.';
          ELSIF c_rec.p99_avg_cpu_us > c_rec.et_99th_pctl_over_avg * c_rec.med_avg_cpu_us AND c_rec.p99_avg_cpu_us / 1e6 > c_rec.secs_per_exec_to_qualify THEN
            l_message1 := 'MSG-01220: SPB rejected. "99th Pctl CPU Time per Exec" exceeds '||c_rec.et_99th_pctl_over_avg||'x "Median CPU Time per Exec" threshold.';
          ELSIF l_owner IS NULL OR l_table_name IS NULL THEN
            l_message1 := 'MSG-01240: SPB rejected. Unknown main table.';
          ELSIF l_last_analyzed IS NULL OR l_num_rows IS NULL THEN
            l_message1 := 'MSG-01250: SPB rejected. Main table has no CBO statistics.';
          ELSIF l_num_rows < c_rec.min_num_rows THEN
            l_message1 := 'MSG-01260: SPB rejected. Number of rows on main table ('||l_num_rows||') is below required threshold ('||c_rec.min_num_rows||').';        
          ELSIF c_rec.last_load_time < l_last_analyzed - 1 THEN
            l_message1 := 'MSG-01270: SPB rejected. Cursor "last load time" is prior to main table "last analyzed" time for more than 24hrs.';
          ELSIF l_pre_existing_fixed_plans > 0 THEN
            l_message1 := 'MSG-01281: SPB rejected. There are '||l_pre_existing_fixed_plans||' pre-existing fixed plans.';
          ELSIF l_pre_existing_valid_plans > 0 THEN
            l_message1 := 'MSG-01280: SPB rejected. There are '||l_pre_existing_valid_plans||' pre-existing valid plans.';
          /* -------------------------------------------------------------------------- */  
          ELSE 
            BEGIN -- create_spbl
              --
              -- Create SPB if candidate is accepted
              --
              l_spb_created_qualified_p := l_spb_created_qualified_p + 1;
              l_spb_created_qualified_t := l_spb_created_qualified_t + 1;
              l_sysdate := SYSDATE;
              l_candidate_was_accepted := TRUE;
              --
              IF l_spb_created_count_t > gl_rec.create_spm_limit OR p_report_only = 'Y' THEN
                l_message1 := 'MSG-02030: Plan qualifies for SPB (CREATION).';
              ELSE -- l_spb_created_count_t < gl_rec.create_spm_limit AND p_report_only = 'N' THEN
                -- call dbms_spm
                IF c_rec.metrics_source = k_source_mem THEN
                  IF c_rec.sql_id = l_prior_sql_id THEN
                    DBMS_LOCK.SLEEP(gl_rec.secs_before_spm_call_sql_id);
                  END IF;
                  load_plan_from_cursor_cache (
                    p_sql_id          => c_rec.sql_id, 
                    p_plan_hash_value => c_rec.plan_hash_value,
                    p_con_id          => c_rec.con_id,
                    p_con_name        => c_rec.pdb_name,
                    r_plans           => l_plans_returned
                  );
                END IF;
                --
                BEGIN -- validate_new_spb
                  IF l_plans_returned = -1 THEN
                    l_message1 := 'MSG-02022: Plan qualifies for SPB (CREATION). But there are no valid cursors as per: status, is_obsolete and is_shareable v$sql attributes.';
                  ELSIF NVL(l_plans_returned, 0) = 0 THEN
                    l_message1 := 'MSG-02020: Plan qualifies for SPB (CREATION). But load API returned no plans.';
                  ELSE -- l_plans_returned > 0 THEN
                    BEGIN -- new_spb
                      get_sql_handle_and_plan_name (
                        p_signature         => l_signature,
                        p_sysdate           => l_sysdate,
                        p_con_id            => c_rec.con_id,
                        r_sql_handle        => l_sql_handle,
                        r_plan_name         => l_plan_name
                      );
                      IF l_sql_handle IS NOT NULL AND l_plan_name IS NOT NULL THEN
                        l_description := 'IOD FPZ APPL='||c_rec.application_category||' LVL='||p_aggressiveness||' SQL_ID='||c_rec.sql_id||' PHV='||c_rec.plan_hash_value||l_message0||' CREATED='||TO_CHAR(SYSDATE, gk_date_format);
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
                      l_us_per_exec_b := b_rec.cpu_time / GREATEST(b_rec.executions, 1);
                      l_spb_created_count_p := l_spb_created_count_p + 1;
                      l_spb_created_count_t := l_spb_created_count_t + 1;
                      l_spb_exists := TRUE;
                      l_message1 := 'MSG-02010: SPB (CREATED).';
                      l_spb_was_created := TRUE;
                      /* -------------------------------------------------------------------- */
                      --
                      -- New SPB could be bogus (trying to avoid ORA-13831 as per bug 27496360)
                      -- If SPB is suspected bogus then disable it!!!
                      --
                      IF gl_rec.workaround_ora_13831 = 'Y' AND l_plan_id <> l_plan_hash_2 THEN -- if one or both are null, then simply skip this part
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
                          l_description := 'IOD FPZ APPL='||c_rec.application_category||' LVL='||p_aggressiveness||' SQL_ID='||c_rec.sql_id||' '||l_messaget||' DISABLED='||TO_CHAR(SYSDATE, gk_date_format);
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
                        l_us_per_exec_b := b_rec.cpu_time / GREATEST(b_rec.executions, 1);
                        l_13831_disabled_all_calls := l_13831_disabled_all_calls + 1;
                      END IF; -- l_plan_id <> l_plan_hash_2
                      /* -------------------------------------------------------------------- */
                      --
                      -- New SPB could be bogus (trying to avoid ORA-06502 and ORA-06512)
                      -- If SPB is suspected bogus then disable it!!!
                      --
                      IF gl_rec.workaround_ora_06512 = 'Y' AND l_plan_id IS NULL THEN
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
                          l_description := 'IOD FPZ APPL='||c_rec.application_category||' LVL='||p_aggressiveness||' SQL_ID='||c_rec.sql_id||' '||l_messaget||' DISABLED='||TO_CHAR(SYSDATE, gk_date_format);
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
                        l_us_per_exec_b := b_rec.cpu_time / GREATEST(b_rec.executions, 1);
                        l_06512_disabled_all_calls := l_06512_disabled_all_calls + 1;
                      END IF; -- NVL(l_plan_id, 666) <> NVL(l_plan_hash_2, -666)
                    END; -- new_spb
                  END IF; -- l_plans_returned > 0
                END; -- validate_new_spb
              END IF; -- l_spb_created_count_t > gl_rec.create_spm_limit OR p_report_only = 'Y'
            END; -- create_spbl
          END IF; -- l_us_per_exec_c / 1e6 > c_rec.secs_per_exec_candidate OR c_rec.executions < c_rec.execs_candidate
        END IF; -- c_rec.sql_plan_baseline IS NULL
      END; -- baseline_does_not_exist
      /* ------------------------------------------------------------------------------ */  
      BEGIN -- print_cursor
        -- Output cursor details
        l_cursor_details_section := TRUE;
        BEGIN -- Output cursor details
          output(RPAD('+', gk_output_part_1_length + 5 + gk_output_part_2_length, '-'));
          output('|');
          output('FPZ Aggressiveness',            p_aggressiveness||' (1 .. N) 1=conservative, 2, 3=moderate, 4, ..., N=aggressive');
          output('Candidate Number',              l_candidate_count_t||' '||SUBSTR(LPAD(c_rec.sql_hash, 10, '0'), 1, 10));
          output('Plugable Database (PDB)',       c_rec.pdb_name||' ('||c_rec.con_id||')');
          output('KIEV PDB',                      c_rec.kiev_pdb);      
          output('Parsing Schema Name',           c_rec.parsing_schema_name);
          output('Application Category',          c_rec.application_category||' ('||c_rec.description||')');
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
          output('Last Active Time (Plan)',       TO_CHAR(c_rec.last_active_time, gk_date_format)||' ('||TO_CHAR((SYSDATE - c_rec.last_active_time) * 24 * 3600, 'FM999,999,990.0')||' seconds ago)');
          output('Last Load Time',                TO_CHAR(c_rec.last_load_time, gk_date_format)||' ('||TO_CHAR((SYSDATE - c_rec.last_load_time) * 24, 'FM999,999,990.0')||' hours ago)');
          output('First Load Time',               TO_CHAR(c_rec.first_load_time, gk_date_format)||' ('||TO_CHAR((SYSDATE - c_rec.first_load_time) * 24, 'FM999,990.0')||' hours ago)');
          output('Exact Matching Signature',      l_signature);
          output('SQL Handle',                    l_sql_handle);
          output('SQL Plan Baseline (SPB)',       c_rec.sql_plan_baseline);
          output('SQL Profile',                   c_rec.sql_profile);
          output('SQL Patch',                     c_rec.sql_patch);
          --
          --IF c_rec.sql_plan_baseline IS NULL THEN
            output('|');
            output('Min Cursor Age Candidate (hr)', TO_CHAR(c_rec.first_load_hours_candidate, 'FM990.0')|| ' (since first load time)');
            output('Min Cursor Age to Qualify (hr)',TO_CHAR(c_rec.first_load_hours_qualify, 'FM990.0'));
            output('Executions Candidate',          c_rec.execs_candidate);
            output('Executions to Qualify',         c_rec.execs_to_qualify);
            output('Time per Exec Candidate (ms)',  TO_CHAR(c_rec.secs_per_exec_candidate * 1e3, 'FM999,990.000')||' (ms)');
            output('Time per Exec to Qualify (ms)', TO_CHAR(c_rec.secs_per_exec_to_qualify * 1e3, 'FM999,990.000')||' (ms)');
            output('Time per Exec 90th PCTL (ms)',  TO_CHAR(c_rec.secs_per_exec_90th_pctl * 1e3, 'FM999,990.000')||' (ms)');
            output('Time per Exec 95th PCTL (ms)',  TO_CHAR(c_rec.secs_per_exec_95th_pctl * 1e3, 'FM999,990.000')||' (ms)');
            output('Time per Exec 97th PCTL (ms)',  TO_CHAR(c_rec.secs_per_exec_97th_pctl * 1e3, 'FM999,990.000')||' (ms)');
            output('Time per Exec 99th PCTL (ms)',  TO_CHAR(c_rec.secs_per_exec_99th_pctl * 1e3, 'FM999,990.000')||' (ms)');
            output('90th PCTL over CPU Time',       c_rec.et_90th_pctl_over_avg);
            output('95th PCTL over CPU Time',       c_rec.et_95th_pctl_over_avg);
            output('97th PCTL over CPU Time',       c_rec.et_97th_pctl_over_avg);
            output('99th PCTL over CPU Time',       c_rec.et_99th_pctl_over_avg);
            output('|');
            output('Min Rows of Main Table',        c_rec.min_num_rows);
            output('Main Table - Owner',            l_owner);
            output('Main Table - Name',             l_table_name);
            output('Main Table - Temporary',        l_temporary);
            output('Main Table - Blocks',           l_blocks);
            output('Main Table - Num Rows',         l_num_rows);
            output('Main Table - Avg Row Len',      l_avg_row_len);
            output('Main Table - Last Analyzed',    TO_CHAR(l_last_analyzed, gk_date_format));
          --END IF;
          --
          IF c_rec.sql_plan_baseline IS NOT NULL THEN
            output('|');
            output('SPB Probation Days',            c_rec.spb_probation_days||
                                                    ' (between '||TO_CHAR(b_rec.created, gk_date_format)||
                                                    ' and '||TO_CHAR(b_rec.created + c_rec.spb_probation_days, gk_date_format)||')');
            IF l_within_probation_window THEN
               output('Within Probation Window',    'YES');
            ELSE
               output('Within Probation Window',    'NO');
            END IF;
            output('Time per Exec Bar (ms)',        TO_CHAR(c_rec.secs_per_exec_bar * 1e3, 'FM999,999,990')||' (ms)');
            output('Slow-down Factor Bar',          c_rec.slow_down_factor_bar||'x');
            IF l_cur_in_probation_compliance THEN
               output('In Probation Compliance',    'YES');
            ELSE
               output('In Probation Compliance',    'NO');
            END IF;
            output('SPB Monitoring Days Cap',       c_rec.spb_monitoring_days_cap||
                                                    ' (between '||TO_CHAR(b_rec.created + c_rec.spb_probation_days, gk_date_format)||
                                                    ' and '||TO_CHAR(b_rec.created + c_rec.spb_monitoring_days_cap, gk_date_format)||')');
            IF l_within_monitoring_window THEN
               output('Within Monitoring Window',   'YES');
            ELSE
               output('Within Monitoring Window',   'NO');
            END IF;
            output('Time per Exec Cap (ms)',        TO_CHAR(c_rec.secs_per_exec_cap * 1e3, 'FM999,999,990')||' (ms)');
            output('Slow-down Factor Cap',          c_rec.slow_down_factor_cap||'x');
            IF l_cur_in_monitoring_compliance THEN
               output('In Monitoring Compliance',   'YES');
            ELSE
               output('In Monitoring Compliance',   'NO');
            END IF;
            output('Executions to Promote/Demote',  c_rec.execs_to_demote);
            output('Executions per Hour Probation', c_rec.execs_per_hr_threshold);
          END IF;
          --
          -- Output plan performance metrics
          IF c_rec.mr_snap_id IS NOT NULL THEN
            output('|');
            output('Oldest Snap ID for plan',       c_rec.phv_min_snap_id);
            output('Most Recent Snap ID (mrs)',     c_rec.mr_snap_id);      
            output('Begin Interval Time (mrs)',     TO_CHAR(c_rec.mr_begin_interval_time, gk_date_format));      
            output('End Interval Time (mrs)',       TO_CHAR(c_rec.mr_end_interval_time, gk_date_format));      
            IF l_mrs_is_considered THEN
              output('Is this snapshot considered?','Y (i.e. within last '||gl_rec.most_recent_awr_snap_hours||' hours)');      
            ELSE
              output('Is this snapshot considered?','N (i.e. not within last '||gl_rec.most_recent_awr_snap_hours||' hours)');      
            END IF;        
            output('Interval in Seconds (mrs)',     ROUND(c_rec.mr_interval_secs)||'s');      
            output('Executions (mrs)',              c_rec.mr_executions);
            output('Buffer Gets (mrs)',             c_rec.mr_buffer_gets);
            output('Disk Reads (mrs)',              c_rec.mr_disk_reads);
            output('Rows Processed (mrs)',          c_rec.mr_rows_processed);
            output('Shared Memory (bytes) (mrs)',   c_rec.mr_sharable_mem);
            output('Elapsed Time (us) (mrs)',       c_rec.mr_elapsed_time);
            output('CPU Time (us) (mrs)',           c_rec.mr_cpu_time);
            output('User I/O Wait Time (us) (mrs)', c_rec.mr_iowait);
            output('Appl Wait Time (us) (mrs)',     c_rec.mr_apwait);
            output('Conc Wait Time (us) (mrs)',     c_rec.mr_ccwait);
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
          output('Pre-existing SPB Plans',        l_pre_existing_plans||' (simple count)');
          output('Pre-existing Valid SPB Plans',  l_pre_existing_valid_plans||' (enabled, accepted and reproduced)');
          output('Pre-existing Fixed SPB Plans',  l_pre_existing_fixed_plans||' (enabled, accepted, reproduced and fixed)');
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
            l_message_section := TRUE;
            output('Message',                     SUBSTR(l_message1, 1, gk_output_part_2_length));
            output(NULL,                          SUBSTR(l_message2, 1, gk_output_part_2_length));
            output(NULL,                          SUBSTR(l_message3, 1, gk_output_part_2_length));
            l_message_section := FALSE;
            output(NULL,                          RPAD('~', GREATEST(LENGTH(l_message1), NVL(LENGTH(l_message2), 0), NVL(LENGTH(l_message3), 0)), '~'));
          END IF;
          IF gl_rec.display_plan = 'Y' AND c_rec.metrics_source = k_source_mem /*AND NOT l_spb_was_promoted AND NOT l_spb_was_created*/ THEN
            output('|');
            output('Child Number',                c_rec.l_child_number);
            output('Last Active Time (Child)',    TO_CHAR(c_rec.l_last_active_time, gk_date_format)||' ('||TO_CHAR((SYSDATE - c_rec.l_last_active_time) * 24 * 3600, 'FM999,999,990.0')||' seconds ago)');
            output('|');
            FOR pln_rec IN (SELECT plan_table_output FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(c_rec.sql_id, c_rec.l_child_number, gl_rec.display_plan_format)))
            LOOP
              output('| '||pln_rec.plan_table_output);
            END LOOP;
          END IF;
          IF gl_rec.display_plan = 'Y' AND (l_spb_exists OR l_spb_demotion_was_accepted OR l_spb_promotion_was_accepted) THEN
            output('|');
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
          END IF; 
          IF gl_rec.display_plan = 'N' THEN
            output('|');
          END IF;
          output(RPAD('+', gk_output_part_1_length + 5 + gk_output_part_2_length, '-'));
        END; -- Output cursor details
        l_cursor_details_section := FALSE;
      END; -- print_cursor
      /* ------------------------------------------------------------------------------ */  
      BEGIN -- journal_cursor
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
        l_persist_zapper_report              := FALSE;
        INSERT INTO &&1..sql_plan_baseline_hist VALUES h_rec;
        COMMIT;
        DBMS_LOB.freetemporary(lob_loc => l_zapper_report);
        -- read zapper_global parameters
        SELECT *
          INTO gl_rec
          FROM &&1..zapper_global
         WHERE tool_name = gk_tool_name;
        -- EXIT if disabled
        IF NVL(gl_rec.enabled, 'N') <> 'Y' THEN
          output ('*** '||gk_tool_name||' is disabled ***');
          EXIT;
        END IF;
      END; -- journal_cursor
    END LOOP;
    CLOSE candidate_cur;
  END; -- candidates_loop
  /* ---------------------------------------------------------------------------------- */  
  BEGIN -- execution_closing
    -- output footer
    IF l_candidate_count_p > 0 AND l_pdb_name_prior <> l_pdb_name AND l_pdb_name_prior <> '-666' AND p_pdb_name = gk_all THEN
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
    output('FPZ Aggressiveness',                p_aggressiveness||' (1 .. N) 1=conservative, 2, 3=moderate, 4, ..., N=aggressive');
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
    /* -------------------------------------------------------------------------------- */  
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
    IF p_aggressiveness = gl_rec.aggressiveness_upper_limit AND gl_rec.workaround_ora_13831 = 'Y' AND p_pdb_name = gk_all AND p_sql_id = gk_all THEN
      workaround_ora_13831_internal (
        p_report_only    => p_report_only,
        x_plans_found    => l_13831_found_this_call,
        x_plans_disabled => l_13831_disabled_this_call
      );
      l_13831_found_all_calls := l_13831_found_all_calls + l_13831_found_this_call;
      l_13831_disabled_all_calls := l_13831_disabled_all_calls + l_13831_disabled_this_call;
    END IF;
      --
    IF p_aggressiveness = gl_rec.aggressiveness_upper_limit AND gl_rec.workaround_ora_06512 = 'Y' AND p_pdb_name = gk_all AND p_sql_id = gk_all THEN
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
  END; -- execution_closing
END maintain_plans_internal;
/* ------------------------------------------------------------------------------------ */
PROCEDURE maintain_plans (
  p_report_only    IN VARCHAR2 DEFAULT 'N',    -- (Y|N) when Y then only produces report and changes nothing
  p_aggressiveness IN NUMBER   DEFAULT 1,      -- (1 .. N) 1=conservative, 2, 3=moderate, 4, ..., N=aggressive
  p_pdb_name       IN VARCHAR2 DEFAULT gk_all, -- evaluate only this one PDB
  p_sql_id         IN VARCHAR2 DEFAULT gk_all  -- evaluate only this one SQL
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
    p_aggressiveness               => p_aggressiveness               ,
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
END maintain_plans;
/* ------------------------------------------------------------------------------------ */
PROCEDURE fpz (
  p_report_only IN VARCHAR2 DEFAULT 'N',    -- (Y|N) when Y then only produces report and changes nothing
  p_pdb_name    IN VARCHAR2 DEFAULT gk_all, -- evaluate only this one PDB
  p_sql_id      IN VARCHAR2 DEFAULT gk_all  -- evaluate only this one SQL
)
IS
  l_start_time			 DATE := SYSDATE;
  l_dbid                         NUMBER;
  l_open_mode                    VARCHAR2(20);
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
  gl_rec                         &&1..zapper_global%ROWTYPE;
/* ------------------------------------------------------------------------------------ */
BEGIN
  -- gets dbid for awr
  SELECT dbid, name, open_mode INTO l_dbid, l_db_name, l_open_mode FROM v$database;
  -- to be executed on DG primary only
  IF l_open_mode <> 'READ WRITE' THEN
    output ('*** to be executed on DG primary only ***');
    RETURN;
  END IF;
  -- read zapper_global parameters
  SELECT *
    INTO gl_rec
    FROM &&1..zapper_global
   WHERE tool_name = gk_tool_name;
  -- EXIT if disabled
  IF NVL(gl_rec.enabled, 'N') <> 'Y' THEN
    output ('*** '||gk_tool_name||' is disabled ***');
    RETURN;
  END IF;
  -- gets host name 
  SELECT host_name INTO l_host_name FROM v$instance;
  -- 
  FOR l_aggressiveness IN gl_rec.aggressiveness_lower_limit .. gl_rec.aggressiveness_upper_limit
  LOOP
    maintain_plans_internal (
      p_report_only                  => p_report_only                  ,
      p_aggressiveness               => l_aggressiveness               ,
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
    --
    IF p_sql_id <> gk_all AND l_spb_created_count_t > 0 THEN
      EXIT;
    END IF;  
    --
    IF p_sql_id = gk_all THEN
      l_candidate_count_gt           := l_candidate_count_gt           + l_candidate_count_t        ;
      l_spb_created_qualified_gt     := l_spb_created_qualified_gt     + l_spb_created_qualified_t  ;
      l_spb_created_count_gt         := l_spb_created_count_gt         + l_spb_created_count_t      ;
      l_spb_promoted_qualified_gt    := l_spb_promoted_qualified_gt    + l_spb_promoted_qualified_t ;
      l_spb_promoted_count_gt        := l_spb_promoted_count_gt        + l_spb_promoted_count_t     ;
      l_spb_disable_qualified_gt     := l_spb_disable_qualified_gt     + l_spb_disable_qualified_t  ;
      l_spb_disabled_count_gt        := l_spb_disabled_count_gt        + l_spb_disabled_count_t     ;
      l_spb_already_fixed_count_gt   := l_spb_already_fixed_count_gt   + l_spb_already_fixed_count_t;
      l_found_13831_with_issues_t    := l_found_13831_with_issues_t    + l_found_13831_with_issues;
      l_disabled_13831_with_issues_t := l_disabled_13831_with_issues_t + l_disabled_13831_with_issues;
      l_found_06512_with_issues_t    := l_found_06512_with_issues_t    + l_found_06512_with_issues;
      l_disabled_06512_with_issues_t := l_disabled_06512_with_issues_t + l_disabled_06512_with_issues;
    END IF;
  END LOOP;
  --
  IF p_sql_id = gk_all THEN
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
  END IF;
  --  
  IF p_report_only = 'N' AND p_pdb_name = gk_all AND p_sql_id = gk_all AND (l_spb_created_count_gt + l_spb_promoted_count_gt + l_spb_disabled_count_gt) > 0 THEN
    -- drop partitions with data older than 1 month (i.e. preserve between 1 and 2 months of history)
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
      IF l_high_value <= ADD_MONTHS(TRUNC(SYSDATE, 'MM'), -1) THEN
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
END iod_spm;
/
