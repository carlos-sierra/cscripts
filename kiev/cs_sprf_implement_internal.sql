SET HEA OFF PAGES 0 TERM OFF SERVEROUT ON;
/* ========================================================================================== */
-- IMPLEMENT scrip
SPO &&cs_file_name._IMPLEMENT.sql;
DECLARE
    PROCEDURE o(p_line IN VARCHAR2) IS BEGIN DBMS_OUTPUT.put_line(p_line); END;
    PROCEDURE o(p_column IN VARCHAR2, p_value IN VARCHAR2) IS BEGIN o('-- '||LPAD(p_column, 30, ' ')||' : '||p_value); END;
BEGIN
    o('/* -------------------------------------------------------------------------------------- */');
    o('--');
    o('-- File name:   &&cs_file_name._IMPLEMENT.sql');
    o('--');
    o('-- Purpose:     Implements Plan &&phv_to_pin. for all SQL decoracted with &&sql_decoration. on all PDBs using SQL Profiles');
    o('--');
    o('-- Author:      Carlos Sierra');
    o('--');
    o('-- Version:     2021/05/15');
    o('--');
    o('-- Usage:       Connecting into CDB.');
    o('--');
    o('-- Example:     $ sqlplus / as sysdba');
    o('--              SQL> @&&cs_file_name._IMPLEMENT.sql');
    o('--');
    o('/* -------------------------------------------------------------------------------------- */');
    o('ALTER SESSION SET CONTAINER = CDB$ROOT;');
    o('-- exit if executed on standby or from some PDB');
    o('WHENEVER SQLERROR EXIT FAILURE;');
    o('DECLARE');
    o('  l_is_primary VARCHAR2(5);');
    o('BEGIN');
    o('  SELECT CASE WHEN open_mode = ''READ WRITE'' AND database_role = ''PRIMARY'' THEN ''TRUE'' ELSE ''FALSE'' END AS is_primary INTO l_is_primary FROM v$database;');
    o('  IF l_is_primary = ''FALSE'' THEN raise_application_error(-20000, ''*** MUST EXECUTE ON READ WRITE PRIMARY ***''); END IF;');
    o('  IF SYS_CONTEXT(''USERENV'', ''CON_NAME'') <> ''CDB$ROOT'' THEN raise_application_error(-20000, ''*** MUST EXECUTE ON CDB$ROOT ***''); END IF;');
    o('END;');
    o('/');
    o('WHENEVER SQLERROR CONTINUE;');
    o('--');
    -- main cursor
    FOR i IN (
    WITH /*+ IOD_SPM.SPRF_IMPORT */
    s AS
    (
    SELECT  /* MATERIALIZE NO_MERGE */
            s.con_id, s.exact_matching_signature AS signature, s.sql_id, s.plan_hash_value, s.sql_profile, s.sql_patch, s.sql_plan_baseline,
            s.executions, s.elapsed_time, s.cpu_time, s.buffer_gets, s.rows_processed, 
            s.object_status, s.is_obsolete, s.is_shareable, s.is_bind_aware, s.is_resolved_adaptive_plan, s.is_reoptimizable, s.last_active_time,
            s.sql_text, s.sql_fulltext, s.parsing_schema_name,
            ROW_NUMBER() OVER (PARTITION BY s.con_id, s.exact_matching_signature, s.sql_id ORDER BY s.last_active_time DESC) AS rn,
            -- bucket_name and bucket_id are KIEV specific, and needed to support statement caching on KIEV, which requires to embed the bucket_id into sql decoration (e.g. /* performScanQuery(NOTIFICATION_BOARD,EVENT_BY_SCHEDULED_TIME) [1002] */)
            CASE 
              WHEN s.sql_text LIKE '/* %(%,%)% [%] */%' AND SUBSTR(s.sql_text, INSTR(s.sql_text, '/* ') + 3, INSTR(s.sql_text, '(') - INSTR(s.sql_text, '/*') - 3) IN ('performScanQuery','performSegmentedScanQuery','getValues') 
              THEN SUBSTR(s.sql_fulltext, INSTR(s.sql_fulltext, '(') + 1, INSTR(s.sql_fulltext, ',') -  INSTR(s.sql_fulltext, '(') - 1) 
            END AS bucket_name,
            CASE 
              WHEN s.sql_text LIKE '/* %(%,%)% [%] */%' AND SUBSTR(s.sql_text, INSTR(s.sql_text, '/* ') + 3, INSTR(s.sql_text, '(') - INSTR(s.sql_text, '/*') - 3) IN ('performScanQuery','performSegmentedScanQuery','getValues') 
              THEN SUBSTR(s.sql_fulltext, INSTR(s.sql_fulltext, '[') + 1, INSTR(s.sql_fulltext, ']') -  INSTR(s.sql_fulltext, '[') - 1) 
            END AS bucket_id
    FROM    v$sql s
    WHERE   UPPER(s.sql_text) LIKE UPPER('%&&sql_decoration.%')
    AND     s.plan_hash_value > 0 -- e.g.: PL/SQL has 0 on PHV
    AND     s.exact_matching_signature > 0 -- INSERT from values has 0 on signature
    AND     s.executions > 0
    AND     s.elapsed_time > 0
    AND     s.cpu_time > 0
    AND     s.buffer_gets > 0
    AND     s.object_status = 'VALID'
    AND     s.is_obsolete = 'N'
    AND     s.is_shareable = 'Y'
    AND     s.is_bind_aware = 'N' -- to ignore cursors using adaptive cursor sharing ACS as per CHANGE-190522
    AND     s.is_resolved_adaptive_plan IS NULL -- to ignore adaptive plans which cause trouble when combined with SPM
    AND     s.last_active_time > SYSDATE - 1
    AND     s.con_id > 2
    AND     s.parsing_schema_name <> 'SYS'
    AND     ROWNUM >= 1 /* MATERIALIZE NO_MERGE */
    )
    SELECT  c.name AS pdb_name, s.signature, s.sql_id, s.plan_hash_value, s.sql_profile, s.sql_patch, s.sql_plan_baseline, 
            s.executions, s.elapsed_time, s.cpu_time, s.buffer_gets, s.rows_processed, 
            s.bucket_name, s.bucket_id, s.last_active_time, s.parsing_schema_name                      
    -- BULK COLLECT INTO 
    --         l_pdb_name, l_signature, l_sql_id, l_plan_hash_value, l_sql_profile, l_sql_patch, l_sql_plan_baseline, 
    --         l_executions, l_elapsed_time, l_cpu_time, l_buffer_gets, l_rows_processed,
    --         l_bucket_name, l_bucket_id, l_last_active_time, l_parsing_schema_name
    FROM    s, v$containers c
    WHERE   s.rn = 1
      AND   NOT (s.plan_hash_value = &&phv_to_pin. AND s.sql_profile IS NOT NULL)
      -- AND   NOT (s.plan_hash_value IN (p_plan_hash_value_1, p_plan_hash_value_2) AND s.sql_profile IS NOT NULL)
      -- AND   (p_pdb_name IS NULL OR UPPER(p_pdb_name) IN ('ALL', 'CDB$ROOT') OR UPPER(c.name) = UPPER(p_pdb_name))
      -- AND   s.sql_id = NVL(NULLIF(p_sql_id, 'ALL'), s.sql_id))
      AND   c.con_id = s.con_id
    ORDER BY
            s.elapsed_time / s.executions DESC,
            s.elapsed_time DESC
    )
    LOOP
        o('-- --------------------------------');
        o('--');
        o('pdb_name', i.pdb_name);
        o('signature', i.signature);
        o('sql_id', i.sql_id);
        o('plan_hash_value', i.plan_hash_value);
        o('sql_profile', i.sql_profile);
        o('sql_plan_baseline', i.sql_plan_baseline);
        o('executions', i.executions);
        o('elapsed_time', i.elapsed_time);
        o('cpu_time', i.cpu_time);
        o('buffer_gets', i.buffer_gets);
        o('rows_processed', i.rows_processed);
        o('bucket_name', i.bucket_name);
        o('bucket_id', i.bucket_id);
        o('last_active_time', i.last_active_time);
        o('parsing_schema_name', i.parsing_schema_name);
        o('--');
        o('PRO');
        o('PRO '||i.pdb_name||' '||i.sql_id);
        o('PRO');
        o('EXEC DBMS_LOCK.sleep(1);');
        o('ALTER SESSION SET CONTAINER = '||i.pdb_name||';');
        -- o('PRO');
        -- o('PRO Searching for "&&sql_decoration." in '||i.pdb_name||' BEFORE implementing SQL Profile');
        -- o('PRO');
        -- o('@@kiev/kiev_fs_internal.sql "&&sql_decoration."');
        o('PRO');
        o('PRO Implementing plan "&&phv_to_pin." for "&&sql_decoration." in '||i.pdb_name);
        o('PRO');
        o('@@kiev/&&implementation_script.');
        -- o('PRO');
        -- o('PRO Searching for "&&sql_decoration." in '||i.pdb_name||' AFTER implementing SQL Profile. Expecting plan "&&phv_to_pin."');
        -- o('PRO');
        -- o('@@kiev/kiev_fs_internal.sql "&&sql_decoration."');
        -- o('PRO');
        -- o('PRO If you need to rollback on this one '||i.pdb_name||' PDB, then Ctrl-C and execute @kiev/&&rollback_script.');
        -- o('PRO');
        -- o('PAUSE Else, hit "return" to continue implementation until done with all PDBs');
        o('--');
        :sql_to_be_fixed := :sql_to_be_fixed + 1;
    END LOOP;
    o('-- --------------------------------');
    o('--');
    o('PRO');
    o('PRO Done with all PDBs');
    o('ALTER SESSION SET CONTAINER = CDB$ROOT;');
    -- IF :sql_to_be_fixed > 0 THEN
    --     o('PRO');
    --     o('PRO Searching for "&&sql_decoration." in CDB to verify: all use "&&phv_to_pin." now, they have a SQL Profile, and their performance is reasonable');
    --     o('PRO');
    --     o('PRO please wait...');
    --     o('PRO');
    --     o('@@kiev/kiev_fs_internal.sql "&&sql_decoration."');
    --     o('PRO');
    --     o('PRO Searching again for "&&sql_decoration." in CDB to verify: all use "&&phv_to_pin." now, they have a SQL Profile, and their performance is reasonable');
    --     o('PRO');
    --     o('PRO please wait 10 seconds...');
    --     o('PRO');
    --     o('EXEC DBMS_LOCK.sleep(10);');
    -- END IF;
    o('--');
    o('-- &&cs_file_name._IMPLEMENT.sql');
    o('--');
END;
/
SPO OFF;
HOS chmod 644 &&cs_file_name._IMPLEMENT.sql
/* ========================================================================================== */
SET HEA ON PAGES 100 TERM ON SERVEROUT OFF;