SET HEA OFF PAGES 0 ECHO OFF VER OFF FEED OFF SERVEROUT ON;
--
DEF sql_text_1 = "performScanQuery(leaseDecorators,ae_timestamp_index)%(1 = 1)%ASC";
DEF phv_1_1 = "610059206";
DEF sql_text_2 = "performScanQuery(workflowInstances,I_GC_INDEX)%(1 = 1)%ASC";
DEF phv_2_1 = "472260233";
DEF phv_2_2 = "549294716";
DEF sql_text_3 = "performScanQuery(futureWork,resumptionTimestamp)%(1 = 1)%ASC";
DEF phv_3_1 = "2784194979";
DEF sql_text_4 = "populateBucketGCWorkspace%MAPPING_UPDATES_rgn%ASC";
DEF phv_4_1 = "1172229985";
DEF phv_4_2 = "1742292103";
DEF sql_text_5 = "populateBucketGCWorkspace%EVENTS_V2_rgn%ASC";
DEF phv_5_1 = "3740437391";
--
DECLARE
    l_count INTEGER := 0;
    PROCEDURE o(p_line IN VARCHAR2) IS BEGIN DBMS_OUTPUT.put_line(p_line); END;
    PROCEDURE o(p_column IN VARCHAR2, p_value IN VARCHAR2) IS BEGIN o('-- '||LPAD(p_column, 30, ' ')||' : '||p_value); END;
BEGIN
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
    WHERE   (UPPER(s.sql_text) LIKE UPPER('%&&sql_text_1.%') OR UPPER(s.sql_text) LIKE UPPER('%&&sql_text_2.%') OR UPPER(s.sql_text) LIKE UPPER('%&&sql_text_3.%') OR UPPER(s.sql_text) LIKE UPPER('%&&sql_text_5.%') OR UPPER(s.sql_text) LIKE UPPER('%&&sql_text_5.%'))
    AND     s.plan_hash_value > 0 -- e.g.: PL/SQL has 0 on PHV
    AND     s.exact_matching_signature > 0 -- INSERT from values has 0 on signature
    AND     s.executions > 0
    AND     s.elapsed_time > 0
    AND     s.cpu_time > 0
    AND     s.buffer_gets > 0
    AND     s.object_status = 'VALID'
    AND     s.is_obsolete = 'N'
    AND     s.is_shareable = 'Y'
    -- AND     s.is_bind_aware = 'N' -- to ignore cursors using adaptive cursor sharing ACS as per CHANGE-190522
    AND     s.is_resolved_adaptive_plan IS NULL -- to ignore adaptive plans which cause trouble when combined with SPM
    AND     s.last_active_time > SYSDATE - 1
    AND     s.con_id > 2
    AND     s.parsing_schema_name <> 'SYS'
    AND     ROWNUM >= 1 /* MATERIALIZE NO_MERGE */
    )
    SELECT  c.name AS pdb_name, s.signature, s.sql_id, s.plan_hash_value, s.sql_profile, s.sql_patch, s.sql_plan_baseline, 
            s.executions, s.elapsed_time, s.cpu_time, s.buffer_gets, s.rows_processed, 
            s.bucket_name, s.bucket_id, s.last_active_time, s.parsing_schema_name, s.sql_text                      
    -- BULK COLLECT INTO 
    --         l_pdb_name, l_signature, l_sql_id, l_plan_hash_value, l_sql_profile, l_sql_patch, l_sql_plan_baseline, 
    --         l_executions, l_elapsed_time, l_cpu_time, l_buffer_gets, l_rows_processed,
    --         l_bucket_name, l_bucket_id, l_last_active_time, l_parsing_schema_name
    FROM    s, v$containers c
    WHERE   s.rn = 1
      AND   CASE 
              WHEN UPPER(s.sql_text) LIKE UPPER('%&&sql_text_1.%') AND NOT (s.plan_hash_value IN (&&phv_1_1.) AND s.sql_profile IS NOT NULL) THEN 1
              WHEN UPPER(s.sql_text) LIKE UPPER('%&&sql_text_2.%') AND NOT (s.plan_hash_value IN (&&phv_2_1., &&phv_2_2.) AND s.sql_profile IS NOT NULL) THEN 1
              WHEN UPPER(s.sql_text) LIKE UPPER('%&&sql_text_3.%') AND NOT (s.plan_hash_value IN (&&phv_3_1.) AND s.sql_profile IS NOT NULL) THEN 1
              WHEN UPPER(s.sql_text) LIKE UPPER('%&&sql_text_4.%') AND NOT (s.plan_hash_value IN (&&phv_4_1., &&phv_4_2.) AND s.sql_profile IS NOT NULL) THEN 1
              WHEN UPPER(s.sql_text) LIKE UPPER('%&&sql_text_5.%') AND NOT (s.plan_hash_value IN (&&phv_5_1.) AND s.sql_profile IS NOT NULL) THEN 1
            ELSE 0 END = 1
      -- AND   NOT (s.plan_hash_value IN (p_plan_hash_value_1, p_plan_hash_value_2) AND s.sql_profile IS NOT NULL)
      -- AND   (p_pdb_name IS NULL OR UPPER(p_pdb_name) IN ('ALL', 'CDB$ROOT') OR UPPER(c.name) = UPPER(p_pdb_name))
      -- AND   s.sql_id = NVL(NULLIF(p_sql_id, 'ALL'), s.sql_id))
      AND   c.con_id = s.con_id
    ORDER BY
            s.elapsed_time / s.executions DESC,
            s.elapsed_time DESC
    )
    LOOP
        l_count := l_count + 1;
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
        o('sql_text', i.sql_text);
        o('--');
    END LOOP;
    --
    IF l_count > 0 THEN
        o('-- --------------------------------');
        o('-- ');
        o('-- Execute once cs_sprf_implement_wf.sql');
        o('-- ');
        o('-- --------------------------------');
    ELSE
        o('-- --------------------------------');
        o('-- ');
        o('-- Skip cs_sprf_implement_wf.sql');
        o('-- ');
        o('-- --------------------------------');
    END IF;
END;
/
--
SET HEA ON PAGES 100 SERVEROUT OFF;