----------------------------------------------------------------------------------------
--
-- File name:   cs_sprf_export.sql
--
-- Purpose:     Exports Execution Plans for some SQL_ID or all SQL on a PDB using SQL Profile(s)
--
-- Author:      Carlos Sierra
--
-- Version:     2023/01/04
--
-- Usage:       Connecting into PDB.
--
--              Enter optional SQL Text Piece or SQL_ID when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_sprf_export.sql
--
-- Notes:       Developed and tested on 12.1.0.2 and 19c.
--              Application agnostic
--              KIEV aware
--              KIEV Statement Caching aware
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_sprf_export';
--
COL parsing_schema_name FOR A30;
WITH 
u AS 
(SELECT /*+ MATERIALIZE NO_MERGE */ user_id, username FROM dba_users WHERE oracle_maintained = 'N' AND common = 'NO' AND ROWNUM >= 1 /* MATERIALIZE NO_MERGE */)
SELECT  s.parsing_schema_name, COUNT(*) AS sql_statements
  FROM  v$sql s, u
WHERE   s.plan_hash_value > 0 -- e.g.: PL/SQL has 0 on PHV
AND     s.exact_matching_signature > 0 -- INSERT from values has 0 on signature
AND     s.executions > 0
AND     s.cpu_time > 0
AND     s.buffer_gets > 0
AND     s.object_status = 'VALID'
AND     s.is_obsolete = 'N'
AND     s.is_shareable = 'Y'
AND     s.is_resolved_adaptive_plan IS NULL -- to ignore adaptive plans which cause trouble when combined with SPM
AND     s.last_active_time > SYSDATE - 1
AND     s.parsing_user_id > 0 -- ddl and stats gathering have parsing_user_id = 0
AND     u.username = s.parsing_schema_name
GROUP BY
        s.parsing_schema_name
ORDER BY
        s.parsing_schema_name
/
PRO
PRO 1. Parsing Schema Name: (opt)
DEF cs_parsing_schema_name = '&1.';
UNDEF 1;
--
PRO
PRO 2. SQL Text piece (e.g.: ScanQuery, getValues, TableName, IndexName): (opt)
DEF cs2_sql_text_piece = '&2.';
UNDEF 2;
--
PRO
PRO 3. SQL_ID: (opt)
DEF cs_sql_id = '&3.';
UNDEF 3;
--
SELECT '&&cs_file_prefix._&&cs_script_name.' AS cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_parsing_schema_name." "&&cs2_sql_text_piece." "&&cs_sql_id."  
@@cs_internal/cs_spool_id.sql
--
PRO SCHEMA_NAME  : "&&cs_parsing_schema_name."
PRO SQL_TEXT     : "&&cs2_sql_text_piece."
PRO SQL_ID       : "&&cs_sql_id."
--
COL export_version NEW_V export_version NOPRI;
SELECT TO_CHAR(SYSDATE, 'HH24MISS') AS export_version FROM DUAL;
VAR v_exported NUMBER;
EXEC :v_exported := 0;
--
PRO please wait...
SET HEA OFF PAGES 0 TERM OFF SERVEROUT ON;
/* ========================================================================================== */
-- IMPLEMENT scrip
SPO &&cs_file_name._IMPLEMENT.sql;
DECLARE
    l_pos               INTEGER;
    l_pos2              INTEGER;
    l_hint              VARCHAR2(4000);
    --
    PROCEDURE o(p_line IN VARCHAR2) IS BEGIN DBMS_OUTPUT.put_line(p_line); END;
BEGIN
    o('/* -------------------------------------------------------------------------------------- */');
    o('--');
    o('-- File name:   &&cs_file_name._IMPLEMENT.sql');
    o('--');
    o('-- Purpose:     Implements Execution Plans for some SQL_ID or all SQL on a PDB using SQL Profile(s)');
    o('--');
    o('-- Author:      Carlos Sierra');
    o('--');
    o('-- Version:     2022/02/22');
    o('--');
    o('-- Usage:       Connecting into PDB.');
    o('--');
    o('-- Example:     $ sqlplus / as sysdba');
    o('--              SQL> @&&cs_file_name._IMPLEMENT.sql');
    o('--');
    o('/* -------------------------------------------------------------------------------------- */');
    o('-- exit if executed on standby or from CDB$ROOT');
    o('WHENEVER SQLERROR EXIT FAILURE;');
    o('DECLARE');
    o('  l_is_primary VARCHAR2(5);');
    o('BEGIN');
    o('  SELECT CASE WHEN open_mode = ''READ WRITE'' AND database_role = ''PRIMARY'' THEN ''TRUE'' ELSE ''FALSE'' END AS is_primary INTO l_is_primary FROM v$database;');
    o('  IF l_is_primary = ''FALSE'' THEN raise_application_error(-20000, ''*** MUST EXECUTE ON READ WRITE PRIMARY ***''); END IF;');
    o('  IF SYS_CONTEXT(''USERENV'', ''CON_NAME'') = ''CDB$ROOT'' THEN raise_application_error(-20000, ''*** MUST EXECUTE ON PDB AND NOT ON CDB$ROOT ***''); END IF;');
    o('END;');
    o('/');
    o('WHENEVER SQLERROR CONTINUE;');
    o('--');
    o('SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;');
    o('SET SERVEROUT ON;');
    o('COL report_time NEW_V report_time NOPRI;');
    o('SELECT TO_CHAR(SYSDATE, ''YYYY-MM-DD"T"HH24.MI.SS'') AS report_time FROM DUAL;');
    o('--');
    o('SPO &&cs_file_name._IMPLEMENT_&&double_ampersand.report_time..txt;');
    o('PRO PRO');
    o('PRO PRO &&cs_file_name._IMPLEMENT_&&double_ampersand.report_time..txt');
    o('PRO PRO');
    o('--');
    o('VAR v_implemented NUMBER;');
    o('EXEC :v_implemented := 0;');
    o('--');
    o('DEF kievbuckets_owner = '''';');
    o('COL kievbuckets_owner NEW_V kievbuckets_owner NOPRI;');
    --o('SELECT owner AS kievbuckets_owner FROM dba_tables WHERE table_name = ''KIEVDATASTOREMETADATA'' AND owner NOT IN (''APP_USER'', ''PDBADMIN'') ORDER BY last_analyzed DESC NULLS LAST FETCH FIRST 1 ROW ONLY;');
    o('SELECT owner AS kievbuckets_owner FROM dba_tables WHERE table_name = ''KIEVDATASTOREMETADATA'' AND owner NOT IN (''PDBADMIN'') ORDER BY last_analyzed DESC NULLS LAST FETCH FIRST 1 ROW ONLY;');
    -- main cursor
    FOR i IN (WITH 
              u AS 
              (SELECT /*+ MATERIALIZE NO_MERGE */ user_id, username FROM dba_users WHERE oracle_maintained = 'N' AND common = 'NO' AND ROWNUM >= 1 /* MATERIALIZE NO_MERGE */),
              s AS
              (
              SELECT  s.exact_matching_signature AS signature, s.sql_id, s.plan_hash_value, x.plan_hash_value_2, s.sql_text, 
                      CASE WHEN '&&cs_kiev_owner.' IS NOT NULL THEN REPLACE(s.sql_fulltext, s.parsing_schema_name||'.', '#kievbuckets_owner#.') ELSE s.sql_fulltext END AS sql_fulltext, 
                      s.parsing_schema_name, x.other_xml,
                      ROW_NUMBER() OVER (PARTITION BY s.exact_matching_signature, s.sql_id ORDER BY s.last_active_time DESC) AS rn,
                      -- bucket_name and bucket_id are KIEV specific, and needed to support statement caching on KIEV, which requires to embed the bucket_id into sql decoration (e.g. /* performScanQuery(NOTIFICATION_BOARD,EVENT_BY_SCHEDULED_TIME) [1002] */)
                      CASE 
                        WHEN s.sql_text LIKE '%/* %(%,%)% [%] */%' AND (s.sql_text LIKE '%performScanQuery%' OR s.sql_text LIKE '%performSegmentedScanQuery%' OR s.sql_text LIKE '%getValues%') 
                        THEN SUBSTR(s.sql_fulltext, INSTR(s.sql_fulltext, '(') + 1, INSTR(s.sql_fulltext, ',') -  INSTR(s.sql_fulltext, '(') - 1) 
                      END AS bucket_name,
                      CASE 
                        WHEN s.sql_text LIKE '%/* %(%,%)% [%] */%' AND (s.sql_text LIKE '%performScanQuery%' OR s.sql_text LIKE '%performSegmentedScanQuery%' OR s.sql_text LIKE '%getValues%') 
                        THEN SUBSTR(s.sql_fulltext, INSTR(s.sql_fulltext, '[') + 1, INSTR(s.sql_fulltext, ']') -  INSTR(s.sql_fulltext, '[') - 1) 
                      END AS bucket_id
              FROM    v$sql s, u u1, u u2
                      OUTER APPLY (
                          SELECT p.other_xml, TO_NUMBER(EXTRACTVALUE(XMLTYPE(p.other_xml),'/*/info[@type = "plan_hash_2"]')) AS plan_hash_value_2
                            FROM v$sql_plan p
                           WHERE p.address = s.address
                             AND p.hash_value = s.hash_value
                             AND p.sql_id = s.sql_id
                             AND p.plan_hash_value = s.plan_hash_value
                             AND p.child_address = s.child_address
                             AND p.child_number = s.child_number
                             AND p.other_xml IS NOT NULL
                             --AND p.id = 1
                             AND TO_NUMBER(EXTRACTVALUE(XMLTYPE(p.other_xml),'/*/info[@type = "plan_hash_2"]')) >= 0
                             AND ROWNUM = 1
                      ) x
              WHERE   s.plan_hash_value > 0 -- e.g.: PL/SQL has 0 on PHV
              AND     s.exact_matching_signature > 0 -- INSERT from values has 0 on signature
              AND     s.executions > 0
              AND     s.cpu_time > 0
              AND     s.buffer_gets > 0
              --AND     s.buffer_gets > s.executions
              AND     s.object_status = 'VALID'
              AND     s.is_obsolete = 'N'
              AND     s.is_shareable = 'Y'
            --   AND     s.is_bind_aware = 'N' -- to ignore cursors using adaptive cursor sharing ACS as per CHANGE-190522
              AND     s.is_resolved_adaptive_plan IS NULL -- to ignore adaptive plans which cause trouble when combined with SPM
              --AND     s.is_reoptimizable = 'N' -- to ignore cursors which require adjustments as per cardinality feedback  
              AND     s.parsing_user_id > 0 -- ddl and stats gathering have parsing_user_id = 0
              AND     s.last_active_time > SYSDATE - 1 -- select only sql that has been executed recently
              AND     s.parsing_schema_name = NVL(TRIM('&&cs_parsing_schema_name.'), s.parsing_schema_name)
              AND     s.sql_id = NVL(TRIM('&&cs_sql_id.'), s.sql_id)
              AND     ('&&cs2_sql_text_piece.' IS NULL OR UPPER(s.sql_text) LIKE '%'||UPPER('&&cs2_sql_text_piece.')||'%')
              AND     u1.user_id = s.parsing_user_id
              AND     u2.user_id = s.parsing_schema_id
              AND     x.plan_hash_value_2 > 0 -- (Phv2) includes the hash value of the execution(PLAN_HASH_VALUE) and the hash value of its predicate part.
              AND     ROWNUM >= 1 /* MATERIALIZE NO_MERGE */
              )
              SELECT  signature, sql_id, plan_hash_value, plan_hash_value_2, SUBSTR(sql_text, 1, 100) AS sql_text_100, sql_text, sql_fulltext, parsing_schema_name, other_xml,
                      bucket_name, bucket_id, CASE WHEN bucket_id IS NULL THEN 'NORMAL' ELSE 'BUCKET' END AS type
              FROM    s
              WHERE   rn = 1
              ORDER BY
                      signature)
    LOOP
        o('--');
        o('PRO');
        o('PRO '||i.sql_text_100);
        o('PRO ['||i.signature||']['||i.sql_id||']['||i.plan_hash_value||']['||i.plan_hash_value_2||']['||i.bucket_name||']['||i.bucket_id||']['||i.type||']['||i.parsing_schema_name||']');
        o('DECLARE');
        o('l_plan_name          VARCHAR2(30);');
        o('l_description        VARCHAR2(500);');
        o('l_count              NUMBER;');
        o('l_plans              NUMBER;');
        o('l_target_bucket_id   VARCHAR2(6);');
        o('l_target_signature   NUMBER;');
        o('l_sql_text_clob      CLOB;');
        o('l_profile_attr       SYS.SQLPROF_ATTR;');
        o('PROCEDURE o(p_line IN VARCHAR2) IS BEGIN DBMS_OUTPUT.put_line(p_line); END;');
        o('BEGIN');
        o('-- sql_text');
        o(q'{l_sql_text_clob := q'[}'); -- '
        l_pos := 1;
        WHILE l_pos > 0
        LOOP
            l_pos2 := INSTR(i.sql_fulltext||CHR(10), CHR(10), l_pos);
            o(SUBSTR(i.sql_fulltext, l_pos, l_pos2 - l_pos));
            l_pos := NULLIF(l_pos2, 0) + 1;
        END LOOP;
        o(q'{]';}'); -- '
        o('-- hints');
        o('l_profile_attr := SYS.SQLPROF_ATTR(');
        o(q'{q'[BEGIN_OUTLINE_DATA]',}');
        FOR j IN (SELECT hint FROM XMLTABLE('other_xml/outline_data/hint' PASSING XMLTYPE(i.other_xml) COLUMNS hint VARCHAR2(4000) PATH '.'))
        LOOP
            l_hint := j.hint;
            WHILE l_hint IS NOT NULL
            LOOP
                IF LENGTH(l_hint) <= 500 THEN
                    o(q'{q'[}'||l_hint||q'{]',}');
                    l_hint := NULL;
                ELSE
                    l_pos := INSTR(SUBSTR(l_hint, 1, 500), ' ', -1);
                    o(q'{q'[}'||SUBSTR(l_hint, 1, l_pos)||q'{]',}');
                    l_hint := SUBSTR(l_hint, l_pos);
                END IF;
            END LOOP;
        END LOOP;
        o(q'{q'[END_OUTLINE_DATA]'}');
        o(');');
        o('-- transformations');
        o('IF '''||i.bucket_id||''' IS NOT NULL THEN -- KIEV Statement Caching specific');
        o('EXECUTE IMMEDIATE ''SELECT TO_CHAR(bucketid) AS bucket_id FROM &&double_ampersand.kievbuckets_owner..kievbuckets WHERE UPPER(name) = UPPER('''''||i.bucket_name||''''')'' INTO l_target_bucket_id;');
        o('END IF;');
        o('IF l_target_bucket_id IS NOT NULL THEN');
        o('l_sql_text_clob := REPLACE(l_sql_text_clob, ''['||i.bucket_id||']'', ''[''||l_target_bucket_id||'']'');');
        -- o('l_target_signature := DBMS_SQLTUNE.sqltext_to_signature (sql_text => l_sql_text_clob);');
        -- o('ELSE');
        -- o('l_target_signature := '||i.signature||';');
        o('END IF;');
        o('IF ''&&double_ampersand.kievbuckets_owner.'' IS NOT NULL THEN -- KIEV Bucket Owner');
        o('l_sql_text_clob := REPLACE(l_sql_text_clob, ''#kievbuckets_owner#'', ''&&double_ampersand.kievbuckets_owner.'');');
        o('END IF;');
        o('l_target_signature := DBMS_SQLTUNE.sqltext_to_signature (sql_text => l_sql_text_clob);');
        o('o(''[''||l_target_signature||''][''||l_target_bucket_id||'']'');');
        o('l_plan_name := ''exp_'||i.sql_id||'_&&export_version.''||l_target_bucket_id;');
        o('l_description := ''[''||l_target_signature||'']['||i.plan_hash_value||']['||i.plan_hash_value_2||']['||i.signature||']['||i.sql_id||']['||i.bucket_name||']['||i.bucket_id||'][&&cs_rgn.][&&cs_db_name_u.][&&cs_con_name.][EXP]['||i.type||'][&&cs_reference.]'';');
-- DBPERF-8216 begin
        o('-- drop unexpected profile');
        o('FOR i IN (SELECT p.name FROM dba_sql_profiles p WHERE p.name = l_plan_name AND p.signature <> l_target_signature)');
        o('LOOP');
        o('o(''SPRF drop: ''||i.name);');
        o('DBMS_SQLTUNE.drop_sql_profile(name => i.name, ignore => TRUE);');
        o('END LOOP;');
-- DBPERF-8216 end
        o('-- disable prior sql_profile');
        o('FOR i IN (SELECT p.name FROM dba_sql_profiles p WHERE p.signature = l_target_signature AND p.category = ''DEFAULT'' AND p.status = ''ENABLED'' AND NVL(p.description, ''NULL'') NOT LIKE ''%][EXP][%'' AND NOT EXISTS (SELECT NULL FROM dba_sql_profiles e WHERE e.name = p.name AND e.category = ''BACKUP''))');
        o('LOOP');
        o('o(''SPRF disable: ''||i.name);');
        o('DBMS_SQLTUNE.alter_sql_profile(name => i.name, attribute_name => ''CATEGORY'', value => ''BACKUP'');');
        o('END LOOP;');
        o('-- create new sql_profile');
        o('SELECT COUNT(*) INTO l_count FROM dba_sql_profiles WHERE name = l_plan_name;');
        o('IF l_count = 0 THEN');
        o('o(''SPRF create: ''||l_plan_name||'' ''||l_description);');
        o('DBMS_SQLTUNE.import_sql_profile(sql_text => l_sql_text_clob, profile => l_profile_attr, name => l_plan_name, description => l_description, replace => TRUE);');
        o(':v_implemented := :v_implemented + 1;');
-- DBPERF-7594 begin
        o('ELSE');
        o('SELECT COUNT(*) INTO l_count FROM dba_sql_profiles WHERE name = l_plan_name AND status = ''DISABLED'';');
        o('IF l_count > 0 THEN');
        o('o(''SPRF enable: ''||l_plan_name||'' ''||l_description);');
        o('DBMS_SQLTUNE.alter_sql_profile(name => l_plan_name, attribute_name => ''STATUS'', value => ''ENABLED'');');
        o(':v_implemented := :v_implemented + 1;');
        o('END IF;');
-- DBPERF-7594 end
        o('END IF;');
        o('-- disable prior sql_patch');
        o('FOR i IN (SELECT p.name FROM dba_sql_patches p WHERE p.signature = l_target_signature AND p.category = ''DEFAULT'' AND p.status = ''ENABLED'' AND NOT EXISTS (SELECT NULL FROM dba_sql_patches e WHERE e.name = p.name AND e.category = ''BACKUP''))');
        o('LOOP');
        o('o(''SPCH disable: ''||i.name);');
        o('$IF DBMS_DB_VERSION.ver_le_12_1');
        o('$THEN');
        o('DBMS_SQLDIAG.alter_sql_patch(name => i.name, attribute_name => ''CATEGORY'', value => ''BACKUP'');');
        o('$ELSE');
        o('DBMS_SQLDIAG.alter_sql_patch(name => i.name, attribute_name => ''CATEGORY'', attribute_value => ''BACKUP'');');
        o('$END');
        o('END LOOP;');
        o('-- disable prior sql_plan_baseline');
        o('FOR i IN (SELECT p.sql_handle, p.plan_name, p.description FROM dba_sql_plan_baselines p WHERE p.signature = l_target_signature AND p.enabled = ''YES'' AND p.accepted = ''YES'')');
        o('LOOP');
        o('o(''SPBL disable: ''||i.sql_handle||'' ''||i.plan_name||'' ''||i.description);');
        o('l_plans := DBMS_SPM.alter_sql_plan_baseline(sql_handle => i.sql_handle, plan_name => i.plan_name, attribute_name => ''ENABLED'', attribute_value => ''NO'');');
        o('IF NVL(i.description, ''NULL'') NOT LIKE ''%[&&export_version.]%'' THEN');
        o('IF LENGTH(i.description) > 470 THEN');
        o('l_plans := DBMS_SPM.alter_sql_plan_baseline(sql_handle => i.sql_handle, plan_name => i.plan_name, attribute_name => ''DESCRIPTION'', attribute_value => ''[EXP][&&export_version.]'');');
        o('ELSE');
        o('l_plans := DBMS_SPM.alter_sql_plan_baseline(sql_handle => i.sql_handle, plan_name => i.plan_name, attribute_name => ''DESCRIPTION'', attribute_value => i.description||'' [EXP][&&export_version.]'');');
        o('END IF;');
        o('o(''SPBL update: [EXP][&&export_version.]'');');
        o('END IF;');
        o('END LOOP;');
        o('END;');
        o('/');
        :v_exported := :v_exported + 1;
    END LOOP;
    o('--');
    o('PRINT v_implemented;');
    o('PRO PRO');
    o('PRO PRO &&cs_file_name._IMPLEMENT_&&double_ampersand.report_time..txt');
    o('PRO PRO');
    o('SPO OFF;');
    o('SET SERVEROUT OFF;');
    o('--');
    o('-- &&cs_file_name._IMPLEMENT.sql');
    o('--');
    o('HOS ls -l &&cs_file_name._IMPLEMENT*');
END;
/
SPO OFF;
HOS chmod 644 &&cs_file_name._IMPLEMENT.sql
/* ========================================================================================== */
-- ROLLBACK scrip
SPO &&cs_file_name._ROLLBACK.sql;
DECLARE
    PROCEDURE o(p_line IN VARCHAR2) IS BEGIN DBMS_OUTPUT.put_line(p_line); END;
BEGIN
    o('/* -------------------------------------------------------------------------------------- */');
    o('--');
    o('-- File name:   &&cs_file_name._ROLLBACK.sql');
    o('--');
    o('-- Purpose:     Rollsback Execution Plans for some SQL_ID or all SQL on a PDB using SQL Profile(s)');
    o('--');
    o('-- Author:      Carlos Sierra');
    o('--');
    o('-- Version:     2022/02/14');
    o('--');
    o('-- Usage:       Connecting into PDB.');
    o('--');
    o('-- Example:     $ sqlplus / as sysdba');
    o('--              SQL> @&&cs_file_name._ROLLBACK.sql');
    o('--');
    o('/* --------------------------------------------------------------------------------------- */');
    o('-- exit if executed on standby or from CDB$ROOT');
    o('WHENEVER SQLERROR EXIT FAILURE;');
    o('DECLARE');
    o('  l_is_primary VARCHAR2(5);');
    o('BEGIN');
    o('  SELECT CASE WHEN open_mode = ''READ WRITE'' AND database_role = ''PRIMARY'' THEN ''TRUE'' ELSE ''FALSE'' END AS is_primary INTO l_is_primary FROM v$database;');
    o('  IF l_is_primary = ''FALSE'' THEN raise_application_error(-20000, ''*** MUST EXECUTE ON READ WRITE PRIMARY ***''); END IF;');
    o('  IF SYS_CONTEXT(''USERENV'', ''CON_NAME'') = ''CDB$ROOT'' THEN raise_application_error(-20000, ''*** MUST EXECUTE ON PDB AND NOT ON CDB$ROOT ***''); END IF;');
    o('END;');
    o('/');
    o('WHENEVER SQLERROR CONTINUE;');
    o('--');
    o('SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;');
    o('SET SERVEROUT ON;');
    o('COL report_time NEW_V report_time NOPRI;');
    o('SELECT TO_CHAR(SYSDATE, ''YYYY-MM-DD"T"HH24.MI.SS'') AS report_time FROM DUAL;');
    o('--');
    o('SPO &&cs_file_name._ROLLBACK_&&double_ampersand.report_time..txt;');
    o('PRO PRO');
    o('PRO PRO &&cs_file_name._ROLLBACK_&&double_ampersand.report_time..txt');
    o('PRO PRO');
    o('VAR v_rolled_back NUMBER;');
    o('EXEC :v_rolled_back := 0;');
    o('--');
    o('DECLARE');
    o('l_plans      NUMBER;');
    o('PROCEDURE o(p_line IN VARCHAR2) IS BEGIN DBMS_OUTPUT.put_line(p_line); END;');
    o('BEGIN');
    o('o(''~~~~~~~~~~~~~~~~~~~~~~~~~~'');');
    o('o(''drop imported sql_profiles'');');
    o('o(''~~~~~~~~~~~~~~~~~~~~~~~~~~'');');
    o('FOR i IN (SELECT name FROM dba_sql_profiles WHERE name LIKE ''exp_%_&&export_version.%'' AND category = ''DEFAULT'' AND status = ''ENABLED'' AND description LIKE ''%][EXP][%'')');
    o('LOOP');
    o('o(''SPRF drop: ''||i.name);');
    o('DBMS_SQLTUNE.drop_sql_profile(name => i.name);');
    o(':v_rolled_back := :v_rolled_back + 1;');
    o('END LOOP;');
    o('o(''~~~~~~~~~~~~~~~~~~~~~~~~~'');');
    o('o(''enable prior sql_profiles'');');
    o('o(''~~~~~~~~~~~~~~~~~~~~~~~~~'');');
    o('FOR i IN (SELECT name FROM dba_sql_profiles WHERE name NOT LIKE ''exp_%_&&export_version.%'' AND category = ''BACKUP'' AND status = ''ENABLED'' AND NVL(description, ''NULL'') NOT LIKE ''%][EXP][%'')');
    o('LOOP');
    o('o(''SPRF enable: ''||i.name);');
    o('DBMS_SQLTUNE.alter_sql_profile(name => i.name, attribute_name => ''CATEGORY'', value => ''DEFAULT'');');
    o('END LOOP;');
    o('o(''~~~~~~~~~~~~~~~~~~~~~~~~'');');
    o('o(''enable prior sql_patches'');');
    o('o(''~~~~~~~~~~~~~~~~~~~~~~~~'');');
    o('FOR i IN (SELECT p.name FROM dba_sql_patches p WHERE p.category = ''BACKUP'' AND p.status = ''ENABLED'' AND NOT EXISTS (SELECT NULL FROM dba_sql_patches e WHERE e.name = p.name AND e.category = ''DEFAULT''))');
    o('LOOP');
    o('o(''SPCH enable: ''||i.name);');
    o('$IF DBMS_DB_VERSION.ver_le_12_1');
    o('$THEN');
    o('DBMS_SQLDIAG.alter_sql_patch(name => i.name, attribute_name => ''CATEGORY'', value => ''DEFAULT'');');
    o('$ELSE');
    o('DBMS_SQLDIAG.alter_sql_patch(name => i.name, attribute_name => ''CATEGORY'', attribute_value => ''DEFAULT'');');
    o('$END');
    o('END LOOP;');
    o('o(''~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'');');
    o('o(''enable prior sql_plan_baselines'');');
    o('o(''~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'');');
    o('FOR i IN (SELECT p.sql_handle, p.plan_name, p.description FROM dba_sql_plan_baselines p WHERE p.enabled = ''NO'' AND p.accepted = ''YES'' AND p.description  LIKE ''%[&&export_version.]%'')');
    o('LOOP');
    o('o(''SPBL enable: ''||i.sql_handle||'' ''||i.plan_name||'' ''||i.description);');
    o('l_plans := DBMS_SPM.alter_sql_plan_baseline(sql_handle => i.sql_handle, plan_name => i.plan_name, attribute_name => ''ENABLED'', attribute_value => ''YES'');');
    o('END LOOP;');
    o('END;');
    o('/');
    o('--');
    o('PRINT v_rolled_back;');
    o('PRO PRO');
    o('PRO PRO &&cs_file_name._ROLLBACK_&&double_ampersand.report_time..txt');
    o('PRO PRO');
    o('SPO OFF;');
    o('SET SERVEROUT OFF;');
    o('--');
    o('-- &&cs_file_name._ROLLBACK.sql');
    o('--');
    o('HOS ls -l &&cs_file_name._ROLLBACK*');
END;
/
SPO OFF;
HOS chmod 644 &&cs_file_name._ROLLBACK.sql
/* ========================================================================================== */
-- VERIFY scrip
SPO &&cs_file_name._VERIFY.sql;
DECLARE
    PROCEDURE o(p_line IN VARCHAR2) IS BEGIN DBMS_OUTPUT.put_line(p_line); END;
BEGIN
    o('/* -------------------------------------------------------------------------------------- */');
    o('--');
    o('-- File name:   &&cs_file_name._VERIFY.sql');
    o('--');
    o('-- Purpose:     Verify Implemented Execution Plans for some SQL_ID or all SQL on a PDB using SQL Profile(s)');
    o('--');
    o('-- Author:      Carlos Sierra');
    o('--');
    o('-- Version:     2022/02/14');
    o('--');
    o('-- Usage:       Connecting into PDB.');
    o('--');
    o('-- Example:     $ sqlplus / as sysdba');
    o('--              SQL> @&&cs_file_name._VERIFY.sql');
    o('--');
    o('/* --------------------------------------------------------------------------------------- */');
    o('-- exit if executed on standby or from CDB$ROOT');
    o('WHENEVER SQLERROR EXIT FAILURE;');
    o('DECLARE');
    o('  l_is_primary VARCHAR2(5);');
    o('BEGIN');
    o('  SELECT CASE WHEN open_mode = ''READ WRITE'' AND database_role = ''PRIMARY'' THEN ''TRUE'' ELSE ''FALSE'' END AS is_primary INTO l_is_primary FROM v$database;');
    o('  IF l_is_primary = ''FALSE'' THEN raise_application_error(-20000, ''*** MUST EXECUTE ON READ WRITE PRIMARY ***''); END IF;');
    o('  IF SYS_CONTEXT(''USERENV'', ''CON_NAME'') = ''CDB$ROOT'' THEN raise_application_error(-20000, ''*** MUST EXECUTE ON PDB AND NOT ON CDB$ROOT ***''); END IF;');
    o('END;');
    o('/');
    o('WHENEVER SQLERROR CONTINUE;');
    o('--');
    o('SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;');
    o('SET FEED ON SERVEROUT ON;');
    o('COL report_time NEW_V report_time NOPRI;');
    o('SELECT TO_CHAR(SYSDATE, ''YYYY-MM-DD"T"HH24.MI.SS'') AS report_time FROM DUAL;');
    o('--');
    o('SPO &&cs_file_name._VERIFY_&&double_ampersand.report_time..txt;');
    o('PRO PRO');
    o('PRO PRO &&cs_file_name._VERIFY_&&double_ampersand.report_time..txt');
    o('PRO PRO');
    o('SELECT * FROM dba_sql_profiles WHERE name LIKE ''exp_%_&&export_version.%'' AND category = ''DEFAULT'' AND status = ''ENABLED'' AND description LIKE ''%][EXP][%'';');
    o('PRO PRO');
    o('PRO PRO &&cs_file_name._VERIFY_&&double_ampersand.report_time..txt');
    o('PRO PRO');
    o('SPO OFF;');
    o('SET FEED OFF SERVEROUT OFF;');
    o('--');
    o('-- &&cs_file_name._VERIFY.sql');
    o('--');
    o('HOS ls -l &&cs_file_name._VERIFY*');
END;
/
SPO OFF;
HOS chmod 644 &&cs_file_name._VERIFY.sql
/* ========================================================================================== */
SET HEA ON PAGES 100 TERM ON SERVEROUT OFF;
--
-- continues with original spool
SPO &&cs_file_name..txt APP
PRO
PRINT v_exported;
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_parsing_schema_name." "&&cs2_sql_text_piece." "&&cs_sql_id."  
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--
PRO
HOS ls -l &&cs_file_prefix._&&cs_script_name.*.*
--