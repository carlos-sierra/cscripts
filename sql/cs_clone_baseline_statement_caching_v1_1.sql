SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
PRO
PRO Report Only: [{Y}|N]
DEF p_report_only = '&1.';
UNDEF 1;
COL v_report_only NEW_V v_report_only NOPRI;
SELECT CASE WHEN SUBSTR(UPPER(TRIM('&&p_report_only.')), 1, 1) IN ('N', 'Y') THEN SUBSTR(UPPER(TRIM('&&p_report_only.')), 1, 1) ELSE 'Y' END AS v_report_only FROM DUAL
/
--
SET SERVEROUT ON HEA OFF PAGES 0;
--
VAR b_report_only VARCHAR2(1);
VAR x_output CLOB;
--
EXEC :b_report_only := '&&v_report_only.';
--
/* ------------------------------------------------------------------------------------ */
DECLARE /* CLONE_SC v1.1 STATEMENT_CACHING */
    -- input and output variables
    l_report_only                 VARCHAR2(1)     := :b_report_only; /* [N|Y] */
    x_output                      CLOB            := NULL;
    -- staging variables
    l_time                        DATE;
    l_plans                       NUMBER;
    l_description                 VARCHAR2(500);
    l_ORA_13831                   VARCHAR2(1); /* [N|Y] */
    l_ORA_06512                   VARCHAR2(1); /* [N|Y] */
    -- staging arrays with selected plans for baseline creation
    TYPE t_clob_array IS TABLE OF CLOB INDEX BY BINARY_INTEGER;
    l_t_sql_fulltext              t_clob_array;               -- associative array
    l_t_sql_text                  DBMS_UTILITY.lname_array;   -- associative array
    l_t_sql_id                    DBMS_UTILITY.name_array;    -- associative array
    l_t_signature                 DBMS_UTILITY.number_array;  -- associative array
    l_s_sql_id                    DBMS_UTILITY.name_array;    -- associative array
    l_s_plan_hash_value           DBMS_UTILITY.number_array;  -- associative array
    --
    PROCEDURE output_line (
      p_line       IN VARCHAR2,
      p_spool_file IN VARCHAR2 DEFAULT 'Y',
      p_alert_log  IN VARCHAR2 DEFAULT 'N'
    ) 
    IS
    BEGIN
      IF p_spool_file = 'Y' THEN
        x_output := x_output||TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS')||' '||p_line||CHR(10); -- return clob
      END IF;
      IF p_alert_log = 'Y' THEN
        SYS.DBMS_SYSTEM.KSDWRT(dest => 2, tst => TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS')||' '||p_line); -- write to alert log
      END IF;
    END output_line;
BEGIN
    SELECT s.sql_id AS s_sql_id, s.plan_hash_value AS s_plan_hash_value, t.exact_matching_signature AS t_signature, t.sql_id AS t_sql_id, t.sql_text AS t_sql_text, t.sql_fulltext AS t_sql_fulltext
    BULK COLLECT INTO l_s_sql_id, l_s_plan_hash_value, l_t_signature, l_t_sql_id, l_t_sql_text, l_t_sql_fulltext
    FROM
    (   -- source: application scans with a baseline
        SELECT  s.exact_matching_signature, s.sql_id, s.plan_hash_value,
                DBMS_SQLTUNE.sqltext_to_signature (
                    sql_text => 
                    CASE 
                        WHEN INSTR(s.sql_fulltext, '[') = 0 AND INSTR(s.sql_fulltext, ']') = 0 THEN s.sql_fulltext
                        ELSE SUBSTR(s.sql_fulltext, 1, INSTR(s.sql_fulltext, '[') - 1) || SUBSTR(s.sql_fulltext, INSTR(s.sql_fulltext, ']') + 2) 
                    END
                ) AS normalized_signature, -- after removing an optional bucket id from sql decoration
                ROW_NUMBER() OVER (PARTITION BY s.sql_id ORDER BY s.cpu_time / s.executions ASC) AS rn -- deduplication on sql_id selecting better performing cursor
        FROM    v$sql s
        WHERE   s.sql_plan_baseline IS NOT NULL 
        AND     s.sql_text LIKE '/* %(%,%)% */%'
        AND     SUBSTR(s.sql_text, INSTR(s.sql_text, '/* ') + 3, INSTR(s.sql_text, '(') - INSTR(s.sql_text, '/*') - 3) IN ('performScanQuery','performSegmentedScanQuery','getValues')
        AND     s.parsing_user_id > 0 -- exclude SYS
        AND     s.parsing_schema_id > 0 -- exclude SYS
        AND     s.parsing_schema_name NOT LIKE 'C##%'
        AND     s.plan_hash_value > 0
        AND     s.exact_matching_signature > 0 -- INSERT from values has 0 on signature
        AND     s.cpu_time > 0
        AND     s.buffer_gets > 0
        AND     s.executions > 0
        AND     s.object_status = 'VALID'
        AND     s.is_obsolete = 'N'
        AND     s.is_shareable = 'Y'
        AND     s.is_bind_aware = 'N' -- to ignore cursors using adaptive cursor sharing ACS as per CHANGE-190522
        AND     s.is_resolved_adaptive_plan IS NULL -- to ignore adaptive plans which cause trouble when combined with SPM
        AND     s.is_reoptimizable = 'N' -- to ignore cursors which require adjustments as per cardinality feedback
    ) s,
    (   -- target: application scans without a baseline
        SELECT  t.exact_matching_signature, t.sql_id, t.sql_text, t.sql_fulltext,
                DBMS_SQLTUNE.sqltext_to_signature (
                    sql_text => 
                    CASE 
                        WHEN INSTR(t.sql_fulltext, '[') = 0 AND INSTR(t.sql_fulltext, ']') = 0 THEN t.sql_fulltext
                        ELSE SUBSTR(t.sql_fulltext, 1, INSTR(t.sql_fulltext, '[') - 1) || SUBSTR(t.sql_fulltext, INSTR(t.sql_fulltext, ']') + 2) 
                    END
                ) AS normalized_signature, -- after removing an optional bucket id from sql decoration
                ROW_NUMBER() OVER (PARTITION BY t.sql_id ORDER BY t.last_active_time DESC) AS rn -- deduplication on sql_id selecting most recent cursor
        FROM    v$sql t
        WHERE   t.sql_plan_baseline IS NULL 
        AND     t.sql_text LIKE '/* %(%,%)% */%'
        AND     SUBSTR(t.sql_text, INSTR(t.sql_text, '/* ') + 3, INSTR(t.sql_text, '(') - INSTR(t.sql_text, '/*') - 3) IN ('performScanQuery','performSegmentedScanQuery','getValues')
        AND     t.parsing_user_id > 0 -- exclude SYS
        AND     t.parsing_schema_id > 0 -- exclude SYS
        AND     t.parsing_schema_name NOT LIKE 'C##%'
        AND     t.plan_hash_value > 0
        AND     t.exact_matching_signature > 0 -- INSERT from values has 0 on signature
        AND     t.cpu_time > 0
        AND     t.buffer_gets > 0
        AND     t.executions > 0
        AND     t.object_status = 'VALID'
        AND     t.is_obsolete = 'N'
        AND     t.is_shareable = 'Y'
        AND     t.is_bind_aware = 'N' -- to ignore cursors using adaptive cursor sharing ACS as per CHANGE-190522
        AND     t.is_resolved_adaptive_plan IS NULL -- to ignore adaptive plans which cause trouble when combined with SPM
        AND     t.is_reoptimizable = 'N' -- to ignore cursors which require adjustments as per cardinality feedback
        AND     NOT EXISTS 
                (   -- exclude sql if there is already a baseline in use for it
                    SELECT NULL
                    FROM v$sql t2
                    WHERE   t2.exact_matching_signature = t.exact_matching_signature
                    AND     t2.sql_id = t.sql_id
                    AND     t2.sql_plan_baseline IS NOT NULL
                    AND     t2.object_status = 'VALID'
                    AND     t2.is_obsolete = 'N'
                    AND     t2.is_shareable = 'Y'
                )
    ) t
    WHERE s.rn = 1 -- deduplication on sql_id selecting better performing cursor
      AND t.normalized_signature = s.normalized_signature -- match sql by text after removing an optional bucket id from sql decoration
      AND t.exact_matching_signature <> s.exact_matching_signature -- since we do not invalidate nor obsolete cursors when a baseline is created we do not want to create baselines from itself
      AND t.rn = 1  -- deduplication on sql_id selecting most recent cursor
    ORDER BY 
          s.sql_id, s.plan_hash_value, t.sql_id;
    --
    IF l_s_sql_id.LAST >= l_s_sql_id.FIRST THEN -- cursors found
        FOR i IN l_s_sql_id.FIRST .. l_s_sql_id.LAST
        LOOP
            output_line('SRC:'||l_s_sql_id(i)||' SRC:'||l_s_plan_hash_value(i)||' TGT:'||l_t_signature(i)||' TGT:'||l_t_sql_id(i)||' TGT:'||SUBSTR(l_t_sql_text(i), 1, INSTR(l_t_sql_text(i), '*/') + 1));
            IF l_report_only = 'N' THEN
                l_time := SYSDATE - (1/24/3600); -- horizon 1 second back, else we may not find new plan(s)
                l_plans := DBMS_SPM.load_plans_from_cursor_cache(sql_id => l_s_sql_id(i), plan_hash_value => l_s_plan_hash_value(i), sql_text => l_t_sql_fulltext(i));
                --
                IF l_plans > 0 THEN
                    -- assembly description
                    l_description := 'CLONE_SC SQL_ID='||l_t_sql_id(i)||' PHV='||l_s_plan_hash_value(i)||' SRC='||l_s_sql_id(i)||' CREATED='||TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS');
                    -- validate for portantial bugs and update description of plan just created
                    FOR j IN (SELECT sql_handle, plan_name FROM dba_sql_plan_baselines WHERE signature = l_t_signature(i) AND origin LIKE 'MANUAL-LOAD%' AND created >= l_time AND description IS NULL)
                    LOOP
                        -- detects if new plan can cause ORA-13831
                        SELECT CASE COUNT(*) WHEN 0 THEN 'N' ELSE 'Y' END INTO l_ORA_13831 
                        FROM sys.sqlobj$plan p 
                        WHERE p.signature = l_t_signature(i) AND p.obj_type = 2 AND p.id = 1 AND p.other_xml IS NOT NULL 
                        AND p.plan_id <> CASE WHEN p.other_xml IS NOT NULL THEN TO_NUMBER(extractvalue(xmltype(p.other_xml),'/*/info[@type = "plan_hash_2"]')) END;
                        -- detects if new plan can cause ORA-06512
                        SELECT CASE COUNT(*) WHEN 0 THEN 'N' ELSE 'Y' END INTO l_ORA_06512
                        FROM sys.sqlobj$ o 
                        WHERE o.signature = l_t_signature(i) AND o.obj_type = 2 
                        AND NOT EXISTS (
                          SELECT NULL FROM sys.sqlobj$plan p
                          WHERE p.signature = o.signature
                          AND p.obj_type = o.obj_type
                          AND p.plan_id = o.plan_id
                        );
                        -- disables plan if at risk of ORA-13831 or ORA-06512
                        IF l_ORA_13831 = 'Y' OR l_ORA_06512 = 'Y' THEN
                          l_plans := DBMS_SPM.alter_sql_plan_baseline(sql_handle => j.sql_handle, plan_name => j.plan_name, attribute_name => 'enabled', attribute_value => 'NO');
                          -- update description
                          IF l_ORA_13831 = 'Y' THEN l_description := l_description||' ORA-13831'; END IF;
                          IF l_ORA_06512 = 'Y' THEN l_description := l_description||' ORA-06512'; END IF;
                          l_description := l_description||' DISABLED='||TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS');
                        END IF;
                        output_line(j.sql_handle||' '||j.plan_name||' '||l_description);
                        -- update description on baseline
                        l_plans := DBMS_SPM.alter_sql_plan_baseline(sql_handle => j.sql_handle, plan_name => j.plan_name, attribute_name => 'description', attribute_value => l_description);
                    END LOOP;
                END IF;
            END IF;
        END LOOP;
    END IF;
    --
    :x_output := x_output;
END;
/* ------------------------------------------------------------------------------------ */
/
--
PRINT :x_output;
--
SET HEA ON PAGES 100;
--
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS.FF6';
--
COL created FOR A19 TRUNC;
COL sql_handle FOR A20;
COL plan_name FOR A30;
COL origin FOR A29;
COL description FOR A100;
--
SELECT created, signature, sql_handle, plan_name, origin, description
  FROM dba_sql_plan_baselines
 WHERE created >= SYSDATE - (1/24/60) -- last 1 min
 ORDER BY
       created, signature, sql_handle, plan_name, origin, description
/