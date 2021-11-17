/* -------------------------------------------------------------------------------------- */
--
-- File name:   /tmp/DBPERF-7399_2021-07-21T22.46.19Z_OC1_ICN_RGN_KIEV02RG_NETWORK_CONTROL_PLANE_cs_sprf_export_IMPLEMENT.sql
--
-- Purpose:     Implements Execution Plans for some SQL_ID or all SQL on a PDB using SQL Profile(s)
--
-- Author:      Carlos Sierra
--
-- Version:     2021/05/12
--
-- Usage:       Connecting into PDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @/tmp/DBPERF-7399_2021-07-21T22.46.19Z_OC1_ICN_RGN_KIEV02RG_NETWORK_CONTROL_PLANE_cs_sprf_export_IMPLEMENT.sql
--
/* -------------------------------------------------------------------------------------- */
-- exit if executed on standby or from CDB$ROOT
WHENEVER SQLERROR EXIT FAILURE;
DECLARE
l_is_primary VARCHAR2(5);
BEGIN
SELECT CASE WHEN open_mode = 'READ WRITE' AND database_role = 'PRIMARY' THEN 'TRUE' ELSE 'FALSE' END AS is_primary INTO l_is_primary FROM v$database;
IF l_is_primary = 'FALSE' THEN raise_application_error(-20000, '*** MUST EXECUTE ON READ WRITE PRIMARY ***'); END IF;
IF SYS_CONTEXT('USERENV', 'CON_NAME') = 'CDB$ROOT' THEN raise_application_error(-20000, '*** MUST EXECUTE ON PDB AND NOT ON CDB$ROOT ***'); END IF;
END;
/
WHENEVER SQLERROR CONTINUE;
--
SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
SET SERVEROUT ON;
COL report_time NEW_V report_time NOPRI;
SELECT TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24.MI.SS') AS report_time FROM DUAL;
--
SPO /tmp/DBPERF-7399_2021-07-21T22.46.19Z_OC1_ICN_RGN_KIEV02RG_NETWORK_CONTROL_PLANE_cs_sprf_export_IMPLEMENT_&&report_time..txt;
PRO PRO
PRO PRO /tmp/DBPERF-7399_2021-07-21T22.46.19Z_OC1_ICN_RGN_KIEV02RG_NETWORK_CONTROL_PLANE_cs_sprf_export_IMPLEMENT_&&report_time..txt
PRO PRO
--
VAR v_implemented NUMBER;
EXEC :v_implemented := 0;
--
DEF kievbuckets_owner = '';
COL kievbuckets_owner NEW_V kievbuckets_owner NOPRI;
SELECT owner AS kievbuckets_owner FROM dba_tables WHERE table_name = 'KIEVDATASTOREMETADATA' AND owner NOT IN ('PDBADMIN') ORDER BY last_analyzed DESC NULLS LAST FETCH FIRST 1 ROW ONLY;
--
PRO
PRO /* performScanQuery(JOB,jobParentIdIndex) [1002] */ SELECT  *  FROM JOB WHERE (id, KievTxnID, 1) IN
PRO [5094257668851906943][2zzngv5xvprca][3179989519][2893715078][JOB][1002][BUCKET]
DECLARE
l_plan_name          VARCHAR2(30);
l_description        VARCHAR2(500);
l_count              NUMBER;
l_plans              NUMBER;
l_target_bucket_id   VARCHAR2(6);
l_target_signature   NUMBER;
l_sql_text_clob      CLOB;
l_profile_attr       SYS.SQLPROF_ATTR;
PROCEDURE o(p_line IN VARCHAR2) IS BEGIN DBMS_OUTPUT.put_line(p_line); END;
BEGIN
-- sql_text
l_sql_text_clob := q'[
/* performScanQuery(JOB,jobParentIdIndex) [1002] */ SELECT  *
FROM JOB
WHERE (id, KievTxnID, 1) IN (
SELECT id, KievTxnID, ROW_NUMBER() OVER (PARTITION BY
id
ORDER BY KievTxnID DESC) rn
FROM JOB
WHERE KievTxnID <= :1
)
AND KievLive = 'Y'
AND (parentJobId = :2 )
ORDER BY parentJobId ASC, id ASC
FETCH FIRST :3  ROWS ONLY
]';
-- hints
l_profile_attr := SYS.SQLPROF_ATTR(
q'[BEGIN_OUTLINE_DATA]',
q'[IGNORE_OPTIM_EMBEDDED_HINTS]',
q'[OPTIMIZER_FEATURES_ENABLE('12.1.0.2')]',
q'[DB_VERSION('12.1.0.2')]',
q'[OPT_PARAM('_optimizer_extended_cursor_sharing' 'none')]',
q'[OPT_PARAM('_optimizer_extended_cursor_sharing_rel' 'none')]',
q'[OPT_PARAM('_optimizer_adaptive_cursor_sharing' 'false')]',
q'[OPT_PARAM('_px_adaptive_dist_method' 'off')]',
q'[OPT_PARAM('_optimizer_strans_adaptive_pruning' 'false')]',
q'[OPT_PARAM('_optimizer_nlj_hj_adaptive_join' 'false')]',
q'[ALL_ROWS]',
q'[OUTLINE_LEAF(@"SEL$C6423BE4")]',
q'[PUSH_PRED(@"SEL$5DA710D3" "VW_NSO_1"@"SEL$5DA710D3" 2)]',
q'[OUTLINE_LEAF(@"SEL$5DA710D3")]',
q'[UNNEST(@"SEL$2" UNNEST_INNERJ_DISTINCT_VIEW)]',
q'[OUTLINE_LEAF(@"SEL$3")]',
q'[OUTLINE(@"SEL$683B0107")]',
q'[OUTLINE(@"SEL$5DA710D3")]',
q'[UNNEST(@"SEL$2" UNNEST_INNERJ_DISTINCT_VIEW)]',
q'[OUTLINE(@"SEL$1")]',
q'[OUTLINE(@"SEL$2")]',
q'[NO_ACCESS(@"SEL$3" "from$_subquery$_003"@"SEL$3")]',
q'[INDEX_RS_ASC(@"SEL$5DA710D3" "JOB"@"SEL$1" ("JOB"."PARENTJOBID" "JOB"."ID" "JOB"."KIEVTXNID"))]',
q'[NO_ACCESS(@"SEL$5DA710D3" "VW_NSO_1"@"SEL$5DA710D3")]',
q'[LEADING(@"SEL$5DA710D3" "JOB"@"SEL$1" "VW_NSO_1"@"SEL$5DA710D3")]',
q'[USE_NL(@"SEL$5DA710D3" "VW_NSO_1"@"SEL$5DA710D3")]',
q'[INDEX_DESC(@"SEL$C6423BE4" "JOB"@"SEL$2" ("JOB"."ID" "JOB"."KIEVTXNID"))]',
q'[END_OUTLINE_DATA]'
);
-- transformations
IF '1002' IS NOT NULL THEN -- KIEV Statement Caching specific
EXECUTE IMMEDIATE 'SELECT TO_CHAR(bucketid) AS bucket_id FROM &&kievbuckets_owner..kievbuckets WHERE UPPER(name) = UPPER(''JOB'')' INTO l_target_bucket_id;
END IF;
IF l_target_bucket_id IS NOT NULL THEN
l_sql_text_clob := REPLACE(l_sql_text_clob, '[1002]', '['||l_target_bucket_id||']');
l_target_signature := DBMS_SQLTUNE.sqltext_to_signature (sql_text => l_sql_text_clob);
ELSE
l_target_signature := 5094257668851906943;
END IF;
o('['||l_target_signature||']['||l_target_bucket_id||']');
l_plan_name := 'exp_2zzngv5xvprca_210721224646';
l_description := '['||l_target_signature||'][3179989519][2893715078][5094257668851906943][2zzngv5xvprca][JOB][1002][ICN][KIEV02RG][NETWORK_CONTROL_PLANE][EXP][BUCKET][DBPERF-7399]';
-- disable prior sql_profile
FOR i IN (SELECT p.name FROM dba_sql_profiles p WHERE p.signature = l_target_signature AND p.category = 'DEFAULT' AND p.status = 'ENABLED' AND NVL(p.description, 'NULL') NOT LIKE '%][EXP][%' AND NOT EXISTS (SELECT NULL FROM dba_sql_profiles e WHERE e.name = p.name AND e.category = 'BACKUP'))
LOOP
o('SPRF disable: '||i.name);
DBMS_SQLTUNE.alter_sql_profile(name => i.name, attribute_name => 'CATEGORY', value => 'BACKUP');
END LOOP;
-- create new sql_profile
SELECT COUNT(*) INTO l_count FROM dba_sql_profiles WHERE name = l_plan_name;
IF l_count = 0 THEN
o('SPRF create: '||l_plan_name||' '||l_description);
DBMS_SQLTUNE.import_sql_profile(sql_text => l_sql_text_clob, profile => l_profile_attr, name => l_plan_name, description => l_description, replace => TRUE);
:v_implemented := :v_implemented + 1;
END IF;
-- disable prior sql_patch
FOR i IN (SELECT p.name FROM dba_sql_patches p WHERE p.signature = l_target_signature AND p.category = 'DEFAULT' AND p.status = 'ENABLED' AND NOT EXISTS (SELECT NULL FROM dba_sql_patches e WHERE e.name = p.name AND e.category = 'BACKUP'))
LOOP
o('SPCH disable: '||i.name);
$IF DBMS_DB_VERSION.ver_le_12_1
$THEN
DBMS_SQLDIAG.alter_sql_patch(name => i.name, attribute_name => 'CATEGORY', value => 'BACKUP');
$ELSE
DBMS_SQLDIAG.alter_sql_patch(name => i.name, attribute_name => 'CATEGORY', attribute_value => 'BACKUP');
$END
END LOOP;
-- disable prior sql_plan_baseline
FOR i IN (SELECT p.sql_handle, p.plan_name, p.description FROM dba_sql_plan_baselines p WHERE p.signature = l_target_signature AND p.enabled = 'YES' AND p.accepted = 'YES')
LOOP
o('SPBL disable: '||i.sql_handle||' '||i.plan_name||' '||i.description);
l_plans := DBMS_SPM.alter_sql_plan_baseline(sql_handle => i.sql_handle, plan_name => i.plan_name, attribute_name => 'ENABLED', attribute_value => 'NO');
IF NVL(i.description, 'NULL') NOT LIKE '%[210721224646]%' THEN
IF LENGTH(i.description) > 470 THEN
l_plans := DBMS_SPM.alter_sql_plan_baseline(sql_handle => i.sql_handle, plan_name => i.plan_name, attribute_name => 'DESCRIPTION', attribute_value => '[EXP][210721224646]');
ELSE
l_plans := DBMS_SPM.alter_sql_plan_baseline(sql_handle => i.sql_handle, plan_name => i.plan_name, attribute_name => 'DESCRIPTION', attribute_value => i.description||' [EXP][210721224646]');
END IF;
o('SPBL update: [EXP][210721224646]');
END IF;
END LOOP;
END;
/
--
PRO
PRO /* performScanQuery(JOB,jobTypeAndDateIndex) [1002] */ SELECT  *  FROM JOB WHERE (id, KievTxnID, 1)
PRO [6900342116756419201][gg0htavf17kt7][2958071133][1258764101][JOB][1002][BUCKET]
DECLARE
l_plan_name          VARCHAR2(30);
l_description        VARCHAR2(500);
l_count              NUMBER;
l_plans              NUMBER;
l_target_bucket_id   VARCHAR2(6);
l_target_signature   NUMBER;
l_sql_text_clob      CLOB;
l_profile_attr       SYS.SQLPROF_ATTR;
PROCEDURE o(p_line IN VARCHAR2) IS BEGIN DBMS_OUTPUT.put_line(p_line); END;
BEGIN
-- sql_text
l_sql_text_clob := q'[
/* performScanQuery(JOB,jobTypeAndDateIndex) [1002] */ SELECT  *
FROM JOB
WHERE (id, KievTxnID, 1) IN (
SELECT id, KievTxnID, ROW_NUMBER() OVER (PARTITION BY
id
ORDER BY KievTxnID DESC) rn
FROM JOB
WHERE KievTxnID <= :1
)
AND KievLive = 'Y'
AND ( ( (jobType = :2 ) AND (addedDate <= :3 ) OR
(jobType < :4 ) ) ) AND ((jobType = :5 ))
ORDER BY jobType DESC, addedDate DESC, id DESC
FETCH FIRST :6  ROWS ONLY
]';
-- hints
l_profile_attr := SYS.SQLPROF_ATTR(
q'[BEGIN_OUTLINE_DATA]',
q'[IGNORE_OPTIM_EMBEDDED_HINTS]',
q'[OPTIMIZER_FEATURES_ENABLE('12.1.0.2')]',
q'[DB_VERSION('12.1.0.2')]',
q'[OPT_PARAM('_optimizer_extended_cursor_sharing' 'none')]',
q'[OPT_PARAM('_optimizer_extended_cursor_sharing_rel' 'none')]',
q'[OPT_PARAM('_optimizer_adaptive_cursor_sharing' 'false')]',
q'[OPT_PARAM('_px_adaptive_dist_method' 'off')]',
q'[OPT_PARAM('_optimizer_strans_adaptive_pruning' 'false')]',
q'[OPT_PARAM('_optimizer_nlj_hj_adaptive_join' 'false')]',
q'[ALL_ROWS]',
q'[OUTLINE_LEAF(@"SEL$C6423BE4")]',
q'[PUSH_PRED(@"SEL$5DA710D3" "VW_NSO_1"@"SEL$5DA710D3" 2)]',
q'[OUTLINE_LEAF(@"SEL$5DA710D3")]',
q'[UNNEST(@"SEL$2" UNNEST_INNERJ_DISTINCT_VIEW)]',
q'[OUTLINE_LEAF(@"SEL$3")]',
q'[OUTLINE(@"SEL$683B0107")]',
q'[OUTLINE(@"SEL$5DA710D3")]',
q'[UNNEST(@"SEL$2" UNNEST_INNERJ_DISTINCT_VIEW)]',
q'[OUTLINE(@"SEL$1")]',
q'[OUTLINE(@"SEL$2")]',
q'[NO_ACCESS(@"SEL$3" "from$_subquery$_003"@"SEL$3")]',
q'[INDEX_RS_DESC(@"SEL$5DA710D3" "JOB"@"SEL$1" ("JOB"."JOBTYPE" "JOB"."ADDEDDATE" "JOB"."ID" "JOB"."KIEVTXNID"))]',
q'[NO_ACCESS(@"SEL$5DA710D3" "VW_NSO_1"@"SEL$5DA710D3")]',
q'[LEADING(@"SEL$5DA710D3" "JOB"@"SEL$1" "VW_NSO_1"@"SEL$5DA710D3")]',
q'[USE_NL(@"SEL$5DA710D3" "VW_NSO_1"@"SEL$5DA710D3")]',
q'[INDEX_DESC(@"SEL$C6423BE4" "JOB"@"SEL$2" ("JOB"."ID" "JOB"."KIEVTXNID"))]',
q'[END_OUTLINE_DATA]'
);
-- transformations
IF '1002' IS NOT NULL THEN -- KIEV Statement Caching specific
EXECUTE IMMEDIATE 'SELECT TO_CHAR(bucketid) AS bucket_id FROM &&kievbuckets_owner..kievbuckets WHERE UPPER(name) = UPPER(''JOB'')' INTO l_target_bucket_id;
END IF;
IF l_target_bucket_id IS NOT NULL THEN
l_sql_text_clob := REPLACE(l_sql_text_clob, '[1002]', '['||l_target_bucket_id||']');
l_target_signature := DBMS_SQLTUNE.sqltext_to_signature (sql_text => l_sql_text_clob);
ELSE
l_target_signature := 6900342116756419201;
END IF;
o('['||l_target_signature||']['||l_target_bucket_id||']');
l_plan_name := 'exp_gg0htavf17kt7_210721224646';
l_description := '['||l_target_signature||'][2958071133][1258764101][6900342116756419201][gg0htavf17kt7][JOB][1002][ICN][KIEV02RG][NETWORK_CONTROL_PLANE][EXP][BUCKET][DBPERF-7399]';
-- disable prior sql_profile
FOR i IN (SELECT p.name FROM dba_sql_profiles p WHERE p.signature = l_target_signature AND p.category = 'DEFAULT' AND p.status = 'ENABLED' AND NVL(p.description, 'NULL') NOT LIKE '%][EXP][%' AND NOT EXISTS (SELECT NULL FROM dba_sql_profiles e WHERE e.name = p.name AND e.category = 'BACKUP'))
LOOP
o('SPRF disable: '||i.name);
DBMS_SQLTUNE.alter_sql_profile(name => i.name, attribute_name => 'CATEGORY', value => 'BACKUP');
END LOOP;
-- create new sql_profile
SELECT COUNT(*) INTO l_count FROM dba_sql_profiles WHERE name = l_plan_name;
IF l_count = 0 THEN
o('SPRF create: '||l_plan_name||' '||l_description);
DBMS_SQLTUNE.import_sql_profile(sql_text => l_sql_text_clob, profile => l_profile_attr, name => l_plan_name, description => l_description, replace => TRUE);
:v_implemented := :v_implemented + 1;
END IF;
-- disable prior sql_patch
FOR i IN (SELECT p.name FROM dba_sql_patches p WHERE p.signature = l_target_signature AND p.category = 'DEFAULT' AND p.status = 'ENABLED' AND NOT EXISTS (SELECT NULL FROM dba_sql_patches e WHERE e.name = p.name AND e.category = 'BACKUP'))
LOOP
o('SPCH disable: '||i.name);
$IF DBMS_DB_VERSION.ver_le_12_1
$THEN
DBMS_SQLDIAG.alter_sql_patch(name => i.name, attribute_name => 'CATEGORY', value => 'BACKUP');
$ELSE
DBMS_SQLDIAG.alter_sql_patch(name => i.name, attribute_name => 'CATEGORY', attribute_value => 'BACKUP');
$END
END LOOP;
-- disable prior sql_plan_baseline
FOR i IN (SELECT p.sql_handle, p.plan_name, p.description FROM dba_sql_plan_baselines p WHERE p.signature = l_target_signature AND p.enabled = 'YES' AND p.accepted = 'YES')
LOOP
o('SPBL disable: '||i.sql_handle||' '||i.plan_name||' '||i.description);
l_plans := DBMS_SPM.alter_sql_plan_baseline(sql_handle => i.sql_handle, plan_name => i.plan_name, attribute_name => 'ENABLED', attribute_value => 'NO');
IF NVL(i.description, 'NULL') NOT LIKE '%[210721224646]%' THEN
IF LENGTH(i.description) > 470 THEN
l_plans := DBMS_SPM.alter_sql_plan_baseline(sql_handle => i.sql_handle, plan_name => i.plan_name, attribute_name => 'DESCRIPTION', attribute_value => '[EXP][210721224646]');
ELSE
l_plans := DBMS_SPM.alter_sql_plan_baseline(sql_handle => i.sql_handle, plan_name => i.plan_name, attribute_name => 'DESCRIPTION', attribute_value => i.description||' [EXP][210721224646]');
END IF;
o('SPBL update: [EXP][210721224646]');
END IF;
END LOOP;
END;
/
--
PRO
PRO /* performScanQuery(JOB,jobParentIdIndex) [1002] */ SELECT  *  FROM JOB WHERE (id, KievTxnID, 1) IN
PRO [7822196138731412303][8x47cnrx6m623][3179989519][2893715078][JOB][1002][BUCKET]
DECLARE
l_plan_name          VARCHAR2(30);
l_description        VARCHAR2(500);
l_count              NUMBER;
l_plans              NUMBER;
l_target_bucket_id   VARCHAR2(6);
l_target_signature   NUMBER;
l_sql_text_clob      CLOB;
l_profile_attr       SYS.SQLPROF_ATTR;
PROCEDURE o(p_line IN VARCHAR2) IS BEGIN DBMS_OUTPUT.put_line(p_line); END;
BEGIN
-- sql_text
l_sql_text_clob := q'[
/* performScanQuery(JOB,jobParentIdIndex) [1002] */ SELECT  *
FROM JOB
WHERE (id, KievTxnID, 1) IN (
SELECT id, KievTxnID, ROW_NUMBER() OVER (PARTITION BY
id
ORDER BY KievTxnID DESC) rn
FROM JOB
WHERE KievTxnID <= :1
)
AND KievLive = 'Y'
AND ( ( (parentJobId = :2 ) AND (id > :3 ) OR
(parentJobId IS NULL OR parentJobId > :4 ) ) ) AND ((parentJobId = :5 ))
ORDER BY parentJobId ASC, id ASC
FETCH FIRST :6  ROWS ONLY
]';
-- hints
l_profile_attr := SYS.SQLPROF_ATTR(
q'[BEGIN_OUTLINE_DATA]',
q'[IGNORE_OPTIM_EMBEDDED_HINTS]',
q'[OPTIMIZER_FEATURES_ENABLE('12.1.0.2')]',
q'[DB_VERSION('12.1.0.2')]',
q'[OPT_PARAM('_optimizer_extended_cursor_sharing' 'none')]',
q'[OPT_PARAM('_optimizer_extended_cursor_sharing_rel' 'none')]',
q'[OPT_PARAM('_optimizer_adaptive_cursor_sharing' 'false')]',
q'[OPT_PARAM('_px_adaptive_dist_method' 'off')]',
q'[OPT_PARAM('_optimizer_strans_adaptive_pruning' 'false')]',
q'[OPT_PARAM('_optimizer_nlj_hj_adaptive_join' 'false')]',
q'[ALL_ROWS]',
q'[OUTLINE_LEAF(@"SEL$C6423BE4")]',
q'[PUSH_PRED(@"SEL$5DA710D3" "VW_NSO_1"@"SEL$5DA710D3" 2)]',
q'[OUTLINE_LEAF(@"SEL$5DA710D3")]',
q'[UNNEST(@"SEL$2" UNNEST_INNERJ_DISTINCT_VIEW)]',
q'[OUTLINE_LEAF(@"SEL$3")]',
q'[OUTLINE(@"SEL$683B0107")]',
q'[OUTLINE(@"SEL$5DA710D3")]',
q'[UNNEST(@"SEL$2" UNNEST_INNERJ_DISTINCT_VIEW)]',
q'[OUTLINE(@"SEL$1")]',
q'[OUTLINE(@"SEL$2")]',
q'[NO_ACCESS(@"SEL$3" "from$_subquery$_003"@"SEL$3")]',
q'[INDEX_RS_ASC(@"SEL$5DA710D3" "JOB"@"SEL$1" ("JOB"."PARENTJOBID" "JOB"."ID" "JOB"."KIEVTXNID"))]',
q'[NO_ACCESS(@"SEL$5DA710D3" "VW_NSO_1"@"SEL$5DA710D3")]',
q'[LEADING(@"SEL$5DA710D3" "JOB"@"SEL$1" "VW_NSO_1"@"SEL$5DA710D3")]',
q'[USE_NL(@"SEL$5DA710D3" "VW_NSO_1"@"SEL$5DA710D3")]',
q'[INDEX_DESC(@"SEL$C6423BE4" "JOB"@"SEL$2" ("JOB"."ID" "JOB"."KIEVTXNID"))]',
q'[END_OUTLINE_DATA]'
);
-- transformations
IF '1002' IS NOT NULL THEN -- KIEV Statement Caching specific
EXECUTE IMMEDIATE 'SELECT TO_CHAR(bucketid) AS bucket_id FROM &&kievbuckets_owner..kievbuckets WHERE UPPER(name) = UPPER(''JOB'')' INTO l_target_bucket_id;
END IF;
IF l_target_bucket_id IS NOT NULL THEN
l_sql_text_clob := REPLACE(l_sql_text_clob, '[1002]', '['||l_target_bucket_id||']');
l_target_signature := DBMS_SQLTUNE.sqltext_to_signature (sql_text => l_sql_text_clob);
ELSE
l_target_signature := 7822196138731412303;
END IF;
o('['||l_target_signature||']['||l_target_bucket_id||']');
l_plan_name := 'exp_8x47cnrx6m623_210721224646';
l_description := '['||l_target_signature||'][3179989519][2893715078][7822196138731412303][8x47cnrx6m623][JOB][1002][ICN][KIEV02RG][NETWORK_CONTROL_PLANE][EXP][BUCKET][DBPERF-7399]';
-- disable prior sql_profile
FOR i IN (SELECT p.name FROM dba_sql_profiles p WHERE p.signature = l_target_signature AND p.category = 'DEFAULT' AND p.status = 'ENABLED' AND NVL(p.description, 'NULL') NOT LIKE '%][EXP][%' AND NOT EXISTS (SELECT NULL FROM dba_sql_profiles e WHERE e.name = p.name AND e.category = 'BACKUP'))
LOOP
o('SPRF disable: '||i.name);
DBMS_SQLTUNE.alter_sql_profile(name => i.name, attribute_name => 'CATEGORY', value => 'BACKUP');
END LOOP;
-- create new sql_profile
SELECT COUNT(*) INTO l_count FROM dba_sql_profiles WHERE name = l_plan_name;
IF l_count = 0 THEN
o('SPRF create: '||l_plan_name||' '||l_description);
DBMS_SQLTUNE.import_sql_profile(sql_text => l_sql_text_clob, profile => l_profile_attr, name => l_plan_name, description => l_description, replace => TRUE);
:v_implemented := :v_implemented + 1;
END IF;
-- disable prior sql_patch
FOR i IN (SELECT p.name FROM dba_sql_patches p WHERE p.signature = l_target_signature AND p.category = 'DEFAULT' AND p.status = 'ENABLED' AND NOT EXISTS (SELECT NULL FROM dba_sql_patches e WHERE e.name = p.name AND e.category = 'BACKUP'))
LOOP
o('SPCH disable: '||i.name);
$IF DBMS_DB_VERSION.ver_le_12_1
$THEN
DBMS_SQLDIAG.alter_sql_patch(name => i.name, attribute_name => 'CATEGORY', value => 'BACKUP');
$ELSE
DBMS_SQLDIAG.alter_sql_patch(name => i.name, attribute_name => 'CATEGORY', attribute_value => 'BACKUP');
$END
END LOOP;
-- disable prior sql_plan_baseline
FOR i IN (SELECT p.sql_handle, p.plan_name, p.description FROM dba_sql_plan_baselines p WHERE p.signature = l_target_signature AND p.enabled = 'YES' AND p.accepted = 'YES')
LOOP
o('SPBL disable: '||i.sql_handle||' '||i.plan_name||' '||i.description);
l_plans := DBMS_SPM.alter_sql_plan_baseline(sql_handle => i.sql_handle, plan_name => i.plan_name, attribute_name => 'ENABLED', attribute_value => 'NO');
IF NVL(i.description, 'NULL') NOT LIKE '%[210721224646]%' THEN
IF LENGTH(i.description) > 470 THEN
l_plans := DBMS_SPM.alter_sql_plan_baseline(sql_handle => i.sql_handle, plan_name => i.plan_name, attribute_name => 'DESCRIPTION', attribute_value => '[EXP][210721224646]');
ELSE
l_plans := DBMS_SPM.alter_sql_plan_baseline(sql_handle => i.sql_handle, plan_name => i.plan_name, attribute_name => 'DESCRIPTION', attribute_value => i.description||' [EXP][210721224646]');
END IF;
o('SPBL update: [EXP][210721224646]');
END IF;
END LOOP;
END;
/
--
PRO
PRO /* getValues(JOB,HashRangeIndex) [1002] */ SELECT * FROM JOB WHERE  JOB.KievTxnID = (SELECT MAX(Kiev
PRO [8028427714232115828][bba6bd7s49na1][2491600063][3449945667][JOB][1002][BUCKET]
DECLARE
l_plan_name          VARCHAR2(30);
l_description        VARCHAR2(500);
l_count              NUMBER;
l_plans              NUMBER;
l_target_bucket_id   VARCHAR2(6);
l_target_signature   NUMBER;
l_sql_text_clob      CLOB;
l_profile_attr       SYS.SQLPROF_ATTR;
PROCEDURE o(p_line IN VARCHAR2) IS BEGIN DBMS_OUTPUT.put_line(p_line); END;
BEGIN
-- sql_text
l_sql_text_clob := q'[
/* getValues(JOB,HashRangeIndex) [1002] */ SELECT *
FROM JOB
WHERE
JOB.KievTxnID = (SELECT MAX(KievTxnID) FROM JOB KIT WHERE KievTxnID <= :1   AND KIT.id = JOB.id
AND id = :2 )
AND
JOB.KievTxnID = (SELECT MAX(KievTxnID) FROM JOB KIT WHERE KievTxnID <= :3   AND KIT.id = JOB.id
)
AND KievLive = 'Y'
AND id = :4
FETCH FIRST :5  ROWS ONLY
]';
-- hints
l_profile_attr := SYS.SQLPROF_ATTR(
q'[BEGIN_OUTLINE_DATA]',
q'[IGNORE_OPTIM_EMBEDDED_HINTS]',
q'[OPTIMIZER_FEATURES_ENABLE('12.1.0.2')]',
q'[DB_VERSION('12.1.0.2')]',
q'[OPT_PARAM('_optimizer_extended_cursor_sharing' 'none')]',
q'[OPT_PARAM('_optimizer_extended_cursor_sharing_rel' 'none')]',
q'[OPT_PARAM('_optimizer_adaptive_cursor_sharing' 'false')]',
q'[OPT_PARAM('_px_adaptive_dist_method' 'off')]',
q'[OPT_PARAM('_optimizer_strans_adaptive_pruning' 'false')]',
q'[OPT_PARAM('_optimizer_nlj_hj_adaptive_join' 'false')]',
q'[ALL_ROWS]',
q'[OUTLINE_LEAF(@"SEL$2")]',
q'[OUTLINE_LEAF(@"SEL$291F8F59")]',
q'[OUTLINE_LEAF(@"SEL$B9151BA2")]',
q'[UNNEST(@"SEL$3")]',
q'[OUTLINE_LEAF(@"SEL$4")]',
q'[OUTLINE(@"SEL$3")]',
q'[OUTLINE(@"SEL$BD9E0841")]',
q'[OUTLINE(@"SEL$1")]',
q'[NO_ACCESS(@"SEL$4" "from$_subquery$_004"@"SEL$4")]',
q'[NO_ACCESS(@"SEL$B9151BA2" "VW_SQ_1"@"SEL$BD9E0841")]',
q'[INDEX(@"SEL$B9151BA2" "JOB"@"SEL$1" ("JOB"."ID" "JOB"."KIEVTXNID"))]',
q'[LEADING(@"SEL$B9151BA2" "VW_SQ_1"@"SEL$BD9E0841" "JOB"@"SEL$1")]',
q'[USE_NL(@"SEL$B9151BA2" "JOB"@"SEL$1")]',
q'[NLJ_BATCHING(@"SEL$B9151BA2" "JOB"@"SEL$1")]',
q'[PUSH_SUBQ(@"SEL$2")]',
q'[INDEX(@"SEL$291F8F59" "KIT"@"SEL$3" ("JOB"."ID" "JOB"."KIEVTXNID"))]',
q'[USE_HASH_AGGREGATION(@"SEL$291F8F59")]',
q'[INDEX(@"SEL$2" "KIT"@"SEL$2" ("JOB"."ID" "JOB"."KIEVTXNID"))]',
q'[END_OUTLINE_DATA]'
);
-- transformations
IF '1002' IS NOT NULL THEN -- KIEV Statement Caching specific
EXECUTE IMMEDIATE 'SELECT TO_CHAR(bucketid) AS bucket_id FROM &&kievbuckets_owner..kievbuckets WHERE UPPER(name) = UPPER(''JOB'')' INTO l_target_bucket_id;
END IF;
IF l_target_bucket_id IS NOT NULL THEN
l_sql_text_clob := REPLACE(l_sql_text_clob, '[1002]', '['||l_target_bucket_id||']');
l_target_signature := DBMS_SQLTUNE.sqltext_to_signature (sql_text => l_sql_text_clob);
ELSE
l_target_signature := 8028427714232115828;
END IF;
o('['||l_target_signature||']['||l_target_bucket_id||']');
l_plan_name := 'exp_bba6bd7s49na1_210721224646';
l_description := '['||l_target_signature||'][2491600063][3449945667][8028427714232115828][bba6bd7s49na1][JOB][1002][ICN][KIEV02RG][NETWORK_CONTROL_PLANE][EXP][BUCKET][DBPERF-7399]';
-- disable prior sql_profile
FOR i IN (SELECT p.name FROM dba_sql_profiles p WHERE p.signature = l_target_signature AND p.category = 'DEFAULT' AND p.status = 'ENABLED' AND NVL(p.description, 'NULL') NOT LIKE '%][EXP][%' AND NOT EXISTS (SELECT NULL FROM dba_sql_profiles e WHERE e.name = p.name AND e.category = 'BACKUP'))
LOOP
o('SPRF disable: '||i.name);
DBMS_SQLTUNE.alter_sql_profile(name => i.name, attribute_name => 'CATEGORY', value => 'BACKUP');
END LOOP;
-- create new sql_profile
SELECT COUNT(*) INTO l_count FROM dba_sql_profiles WHERE name = l_plan_name;
IF l_count = 0 THEN
o('SPRF create: '||l_plan_name||' '||l_description);
DBMS_SQLTUNE.import_sql_profile(sql_text => l_sql_text_clob, profile => l_profile_attr, name => l_plan_name, description => l_description, replace => TRUE);
:v_implemented := :v_implemented + 1;
END IF;
-- disable prior sql_patch
FOR i IN (SELECT p.name FROM dba_sql_patches p WHERE p.signature = l_target_signature AND p.category = 'DEFAULT' AND p.status = 'ENABLED' AND NOT EXISTS (SELECT NULL FROM dba_sql_patches e WHERE e.name = p.name AND e.category = 'BACKUP'))
LOOP
o('SPCH disable: '||i.name);
$IF DBMS_DB_VERSION.ver_le_12_1
$THEN
DBMS_SQLDIAG.alter_sql_patch(name => i.name, attribute_name => 'CATEGORY', value => 'BACKUP');
$ELSE
DBMS_SQLDIAG.alter_sql_patch(name => i.name, attribute_name => 'CATEGORY', attribute_value => 'BACKUP');
$END
END LOOP;
-- disable prior sql_plan_baseline
FOR i IN (SELECT p.sql_handle, p.plan_name, p.description FROM dba_sql_plan_baselines p WHERE p.signature = l_target_signature AND p.enabled = 'YES' AND p.accepted = 'YES')
LOOP
o('SPBL disable: '||i.sql_handle||' '||i.plan_name||' '||i.description);
l_plans := DBMS_SPM.alter_sql_plan_baseline(sql_handle => i.sql_handle, plan_name => i.plan_name, attribute_name => 'ENABLED', attribute_value => 'NO');
IF NVL(i.description, 'NULL') NOT LIKE '%[210721224646]%' THEN
IF LENGTH(i.description) > 470 THEN
l_plans := DBMS_SPM.alter_sql_plan_baseline(sql_handle => i.sql_handle, plan_name => i.plan_name, attribute_name => 'DESCRIPTION', attribute_value => '[EXP][210721224646]');
ELSE
l_plans := DBMS_SPM.alter_sql_plan_baseline(sql_handle => i.sql_handle, plan_name => i.plan_name, attribute_name => 'DESCRIPTION', attribute_value => i.description||' [EXP][210721224646]');
END IF;
o('SPBL update: [EXP][210721224646]');
END IF;
END LOOP;
END;
/
--
PRO
PRO /* performScanQuery(JOB,jobStateIndex) [1002] */ SELECT  *  FROM JOB WHERE (id, KievTxnID, 1) IN (
PRO [10423669244867253574][6s0xxt9qz0utz][3621166190][3467459516][JOB][1002][BUCKET]
DECLARE
l_plan_name          VARCHAR2(30);
l_description        VARCHAR2(500);
l_count              NUMBER;
l_plans              NUMBER;
l_target_bucket_id   VARCHAR2(6);
l_target_signature   NUMBER;
l_sql_text_clob      CLOB;
l_profile_attr       SYS.SQLPROF_ATTR;
PROCEDURE o(p_line IN VARCHAR2) IS BEGIN DBMS_OUTPUT.put_line(p_line); END;
BEGIN
-- sql_text
l_sql_text_clob := q'[
/* performScanQuery(JOB,jobStateIndex) [1002] */ SELECT  *
FROM JOB
WHERE (id, KievTxnID, 1) IN (
SELECT id, KievTxnID, ROW_NUMBER() OVER (PARTITION BY
id
ORDER BY KievTxnID DESC) rn
FROM JOB
WHERE KievTxnID <= :1
)
AND KievLive = 'Y'
AND ( ( (state = :2 ) AND (id > :3 ) OR
(state > :4 ) ) ) AND ((state = :5 ))
ORDER BY state ASC, id ASC
FETCH FIRST :6  ROWS ONLY
]';
-- hints
l_profile_attr := SYS.SQLPROF_ATTR(
q'[BEGIN_OUTLINE_DATA]',
q'[IGNORE_OPTIM_EMBEDDED_HINTS]',
q'[OPTIMIZER_FEATURES_ENABLE('12.1.0.2')]',
q'[DB_VERSION('12.1.0.2')]',
q'[OPT_PARAM('_optimizer_extended_cursor_sharing' 'none')]',
q'[OPT_PARAM('_optimizer_extended_cursor_sharing_rel' 'none')]',
q'[OPT_PARAM('_optimizer_adaptive_cursor_sharing' 'false')]',
q'[OPT_PARAM('_px_adaptive_dist_method' 'off')]',
q'[OPT_PARAM('_optimizer_strans_adaptive_pruning' 'false')]',
q'[OPT_PARAM('_optimizer_nlj_hj_adaptive_join' 'false')]',
q'[ALL_ROWS]',
q'[OUTLINE_LEAF(@"SEL$C6423BE4")]',
q'[PUSH_PRED(@"SEL$5DA710D3" "VW_NSO_1"@"SEL$5DA710D3" 2)]',
q'[OUTLINE_LEAF(@"SEL$5DA710D3")]',
q'[UNNEST(@"SEL$2" UNNEST_INNERJ_DISTINCT_VIEW)]',
q'[OUTLINE_LEAF(@"SEL$3")]',
q'[OUTLINE(@"SEL$683B0107")]',
q'[OUTLINE(@"SEL$5DA710D3")]',
q'[UNNEST(@"SEL$2" UNNEST_INNERJ_DISTINCT_VIEW)]',
q'[OUTLINE(@"SEL$1")]',
q'[OUTLINE(@"SEL$2")]',
q'[NO_ACCESS(@"SEL$3" "from$_subquery$_003"@"SEL$3")]',
q'[INDEX_RS_ASC(@"SEL$5DA710D3" "JOB"@"SEL$1" ("JOB"."STATE" "JOB"."ID" "JOB"."KIEVTXNID"))]',
q'[NO_ACCESS(@"SEL$5DA710D3" "VW_NSO_1"@"SEL$5DA710D3")]',
q'[LEADING(@"SEL$5DA710D3" "JOB"@"SEL$1" "VW_NSO_1"@"SEL$5DA710D3")]',
q'[USE_NL(@"SEL$5DA710D3" "VW_NSO_1"@"SEL$5DA710D3")]',
q'[INDEX_DESC(@"SEL$C6423BE4" "JOB"@"SEL$2" ("JOB"."ID" "JOB"."KIEVTXNID"))]',
q'[END_OUTLINE_DATA]'
);
-- transformations
IF '1002' IS NOT NULL THEN -- KIEV Statement Caching specific
EXECUTE IMMEDIATE 'SELECT TO_CHAR(bucketid) AS bucket_id FROM &&kievbuckets_owner..kievbuckets WHERE UPPER(name) = UPPER(''JOB'')' INTO l_target_bucket_id;
END IF;
IF l_target_bucket_id IS NOT NULL THEN
l_sql_text_clob := REPLACE(l_sql_text_clob, '[1002]', '['||l_target_bucket_id||']');
l_target_signature := DBMS_SQLTUNE.sqltext_to_signature (sql_text => l_sql_text_clob);
ELSE
l_target_signature := 10423669244867253574;
END IF;
o('['||l_target_signature||']['||l_target_bucket_id||']');
l_plan_name := 'exp_6s0xxt9qz0utz_210721224646';
l_description := '['||l_target_signature||'][3621166190][3467459516][10423669244867253574][6s0xxt9qz0utz][JOB][1002][ICN][KIEV02RG][NETWORK_CONTROL_PLANE][EXP][BUCKET][DBPERF-7399]';
-- disable prior sql_profile
FOR i IN (SELECT p.name FROM dba_sql_profiles p WHERE p.signature = l_target_signature AND p.category = 'DEFAULT' AND p.status = 'ENABLED' AND NVL(p.description, 'NULL') NOT LIKE '%][EXP][%' AND NOT EXISTS (SELECT NULL FROM dba_sql_profiles e WHERE e.name = p.name AND e.category = 'BACKUP'))
LOOP
o('SPRF disable: '||i.name);
DBMS_SQLTUNE.alter_sql_profile(name => i.name, attribute_name => 'CATEGORY', value => 'BACKUP');
END LOOP;
-- create new sql_profile
SELECT COUNT(*) INTO l_count FROM dba_sql_profiles WHERE name = l_plan_name;
IF l_count = 0 THEN
o('SPRF create: '||l_plan_name||' '||l_description);
DBMS_SQLTUNE.import_sql_profile(sql_text => l_sql_text_clob, profile => l_profile_attr, name => l_plan_name, description => l_description, replace => TRUE);
:v_implemented := :v_implemented + 1;
END IF;
-- disable prior sql_patch
FOR i IN (SELECT p.name FROM dba_sql_patches p WHERE p.signature = l_target_signature AND p.category = 'DEFAULT' AND p.status = 'ENABLED' AND NOT EXISTS (SELECT NULL FROM dba_sql_patches e WHERE e.name = p.name AND e.category = 'BACKUP'))
LOOP
o('SPCH disable: '||i.name);
$IF DBMS_DB_VERSION.ver_le_12_1
$THEN
DBMS_SQLDIAG.alter_sql_patch(name => i.name, attribute_name => 'CATEGORY', value => 'BACKUP');
$ELSE
DBMS_SQLDIAG.alter_sql_patch(name => i.name, attribute_name => 'CATEGORY', attribute_value => 'BACKUP');
$END
END LOOP;
-- disable prior sql_plan_baseline
FOR i IN (SELECT p.sql_handle, p.plan_name, p.description FROM dba_sql_plan_baselines p WHERE p.signature = l_target_signature AND p.enabled = 'YES' AND p.accepted = 'YES')
LOOP
o('SPBL disable: '||i.sql_handle||' '||i.plan_name||' '||i.description);
l_plans := DBMS_SPM.alter_sql_plan_baseline(sql_handle => i.sql_handle, plan_name => i.plan_name, attribute_name => 'ENABLED', attribute_value => 'NO');
IF NVL(i.description, 'NULL') NOT LIKE '%[210721224646]%' THEN
IF LENGTH(i.description) > 470 THEN
l_plans := DBMS_SPM.alter_sql_plan_baseline(sql_handle => i.sql_handle, plan_name => i.plan_name, attribute_name => 'DESCRIPTION', attribute_value => '[EXP][210721224646]');
ELSE
l_plans := DBMS_SPM.alter_sql_plan_baseline(sql_handle => i.sql_handle, plan_name => i.plan_name, attribute_name => 'DESCRIPTION', attribute_value => i.description||' [EXP][210721224646]');
END IF;
o('SPBL update: [EXP][210721224646]');
END IF;
END LOOP;
END;
/
--
PRO
PRO /* performScanQuery(JOB,HashRangeIndex) [1002] */ SELECT  *  FROM JOB WHERE (id, KievTxnID, 1) IN (
PRO [11209633853514319505][22qz0wrsw7nyh][1913042797][2327742259][JOB][1002][BUCKET]
DECLARE
l_plan_name          VARCHAR2(30);
l_description        VARCHAR2(500);
l_count              NUMBER;
l_plans              NUMBER;
l_target_bucket_id   VARCHAR2(6);
l_target_signature   NUMBER;
l_sql_text_clob      CLOB;
l_profile_attr       SYS.SQLPROF_ATTR;
PROCEDURE o(p_line IN VARCHAR2) IS BEGIN DBMS_OUTPUT.put_line(p_line); END;
BEGIN
-- sql_text
l_sql_text_clob := q'[
/* performScanQuery(JOB,HashRangeIndex) [1002] */ SELECT  *
FROM JOB
WHERE (id, KievTxnID, 1) IN (
SELECT id, KievTxnID, ROW_NUMBER() OVER (PARTITION BY
id
ORDER BY KievTxnID DESC) rn
FROM JOB
WHERE KievTxnID <= :1
)
AND KievLive = 'Y'
AND (1 = 1)
ORDER BY id ASC
FETCH FIRST :2  ROWS ONLY
]';
-- hints
l_profile_attr := SYS.SQLPROF_ATTR(
q'[BEGIN_OUTLINE_DATA]',
q'[IGNORE_OPTIM_EMBEDDED_HINTS]',
q'[OPTIMIZER_FEATURES_ENABLE('12.1.0.2')]',
q'[DB_VERSION('12.1.0.2')]',
q'[OPT_PARAM('_optimizer_extended_cursor_sharing' 'none')]',
q'[OPT_PARAM('_optimizer_extended_cursor_sharing_rel' 'none')]',
q'[OPT_PARAM('_optimizer_adaptive_cursor_sharing' 'false')]',
q'[OPT_PARAM('_px_adaptive_dist_method' 'off')]',
q'[OPT_PARAM('_optimizer_strans_adaptive_pruning' 'false')]',
q'[OPT_PARAM('_optimizer_nlj_hj_adaptive_join' 'false')]',
q'[OPT_PARAM('_fix_control' '5922070:0')]',
q'[FIRST_ROWS(1)]',
q'[OUTLINE_LEAF(@"SEL$C6423BE4")]',
q'[PUSH_PRED(@"SEL$5DA710D3" "VW_NSO_1"@"SEL$5DA710D3" 2)]',
q'[OUTLINE_LEAF(@"SEL$5DA710D3")]',
q'[UNNEST(@"SEL$2" UNNEST_INNERJ_DISTINCT_VIEW)]',
q'[OUTLINE_LEAF(@"SEL$3")]',
q'[OUTLINE(@"SEL$683B0107")]',
q'[OUTLINE(@"SEL$5DA710D3")]',
q'[UNNEST(@"SEL$2" UNNEST_INNERJ_DISTINCT_VIEW)]',
q'[OUTLINE(@"SEL$1")]',
q'[OUTLINE(@"SEL$2")]',
q'[NO_ACCESS(@"SEL$3" "from$_subquery$_003"@"SEL$3")]',
q'[INDEX(@"SEL$5DA710D3" "JOB"@"SEL$1" ("JOB"."ID" "JOB"."KIEVTXNID"))]',
q'[NO_ACCESS(@"SEL$5DA710D3" "VW_NSO_1"@"SEL$5DA710D3")]',
q'[LEADING(@"SEL$5DA710D3" "JOB"@"SEL$1" "VW_NSO_1"@"SEL$5DA710D3")]',
q'[USE_NL(@"SEL$5DA710D3" "VW_NSO_1"@"SEL$5DA710D3")]',
q'[INDEX_DESC(@"SEL$C6423BE4" "JOB"@"SEL$2" ("JOB"."ID" "JOB"."KIEVTXNID"))]',
q'[END_OUTLINE_DATA]'
);
-- transformations
IF '1002' IS NOT NULL THEN -- KIEV Statement Caching specific
EXECUTE IMMEDIATE 'SELECT TO_CHAR(bucketid) AS bucket_id FROM &&kievbuckets_owner..kievbuckets WHERE UPPER(name) = UPPER(''JOB'')' INTO l_target_bucket_id;
END IF;
IF l_target_bucket_id IS NOT NULL THEN
l_sql_text_clob := REPLACE(l_sql_text_clob, '[1002]', '['||l_target_bucket_id||']');
l_target_signature := DBMS_SQLTUNE.sqltext_to_signature (sql_text => l_sql_text_clob);
ELSE
l_target_signature := 11209633853514319505;
END IF;
o('['||l_target_signature||']['||l_target_bucket_id||']');
l_plan_name := 'exp_22qz0wrsw7nyh_210721224646';
l_description := '['||l_target_signature||'][1913042797][2327742259][11209633853514319505][22qz0wrsw7nyh][JOB][1002][ICN][KIEV02RG][NETWORK_CONTROL_PLANE][EXP][BUCKET][DBPERF-7399]';
-- disable prior sql_profile
FOR i IN (SELECT p.name FROM dba_sql_profiles p WHERE p.signature = l_target_signature AND p.category = 'DEFAULT' AND p.status = 'ENABLED' AND NVL(p.description, 'NULL') NOT LIKE '%][EXP][%' AND NOT EXISTS (SELECT NULL FROM dba_sql_profiles e WHERE e.name = p.name AND e.category = 'BACKUP'))
LOOP
o('SPRF disable: '||i.name);
DBMS_SQLTUNE.alter_sql_profile(name => i.name, attribute_name => 'CATEGORY', value => 'BACKUP');
END LOOP;
-- create new sql_profile
SELECT COUNT(*) INTO l_count FROM dba_sql_profiles WHERE name = l_plan_name;
IF l_count = 0 THEN
o('SPRF create: '||l_plan_name||' '||l_description);
DBMS_SQLTUNE.import_sql_profile(sql_text => l_sql_text_clob, profile => l_profile_attr, name => l_plan_name, description => l_description, replace => TRUE);
:v_implemented := :v_implemented + 1;
END IF;
-- disable prior sql_patch
FOR i IN (SELECT p.name FROM dba_sql_patches p WHERE p.signature = l_target_signature AND p.category = 'DEFAULT' AND p.status = 'ENABLED' AND NOT EXISTS (SELECT NULL FROM dba_sql_patches e WHERE e.name = p.name AND e.category = 'BACKUP'))
LOOP
o('SPCH disable: '||i.name);
$IF DBMS_DB_VERSION.ver_le_12_1
$THEN
DBMS_SQLDIAG.alter_sql_patch(name => i.name, attribute_name => 'CATEGORY', value => 'BACKUP');
$ELSE
DBMS_SQLDIAG.alter_sql_patch(name => i.name, attribute_name => 'CATEGORY', attribute_value => 'BACKUP');
$END
END LOOP;
-- disable prior sql_plan_baseline
FOR i IN (SELECT p.sql_handle, p.plan_name, p.description FROM dba_sql_plan_baselines p WHERE p.signature = l_target_signature AND p.enabled = 'YES' AND p.accepted = 'YES')
LOOP
o('SPBL disable: '||i.sql_handle||' '||i.plan_name||' '||i.description);
l_plans := DBMS_SPM.alter_sql_plan_baseline(sql_handle => i.sql_handle, plan_name => i.plan_name, attribute_name => 'ENABLED', attribute_value => 'NO');
IF NVL(i.description, 'NULL') NOT LIKE '%[210721224646]%' THEN
IF LENGTH(i.description) > 470 THEN
l_plans := DBMS_SPM.alter_sql_plan_baseline(sql_handle => i.sql_handle, plan_name => i.plan_name, attribute_name => 'DESCRIPTION', attribute_value => '[EXP][210721224646]');
ELSE
l_plans := DBMS_SPM.alter_sql_plan_baseline(sql_handle => i.sql_handle, plan_name => i.plan_name, attribute_name => 'DESCRIPTION', attribute_value => i.description||' [EXP][210721224646]');
END IF;
o('SPBL update: [EXP][210721224646]');
END IF;
END LOOP;
END;
/
--
PRO
PRO /* performScanQuery(JOB,jobStateIndex) [1002] */ SELECT  *  FROM JOB WHERE (id, KievTxnID, 1) IN (
PRO [14623511363650319057][7amt7kx1ptzhr][3621166190][3467459516][JOB][1002][BUCKET]
DECLARE
l_plan_name          VARCHAR2(30);
l_description        VARCHAR2(500);
l_count              NUMBER;
l_plans              NUMBER;
l_target_bucket_id   VARCHAR2(6);
l_target_signature   NUMBER;
l_sql_text_clob      CLOB;
l_profile_attr       SYS.SQLPROF_ATTR;
PROCEDURE o(p_line IN VARCHAR2) IS BEGIN DBMS_OUTPUT.put_line(p_line); END;
BEGIN
-- sql_text
l_sql_text_clob := q'[
/* performScanQuery(JOB,jobStateIndex) [1002] */ SELECT  *
FROM JOB
WHERE (id, KievTxnID, 1) IN (
SELECT id, KievTxnID, ROW_NUMBER() OVER (PARTITION BY
id
ORDER BY KievTxnID DESC) rn
FROM JOB
WHERE KievTxnID <= :1
)
AND KievLive = 'Y'
AND (state = :2 )
ORDER BY state ASC, id ASC
FETCH FIRST :3  ROWS ONLY
]';
-- hints
l_profile_attr := SYS.SQLPROF_ATTR(
q'[BEGIN_OUTLINE_DATA]',
q'[IGNORE_OPTIM_EMBEDDED_HINTS]',
q'[OPTIMIZER_FEATURES_ENABLE('12.1.0.2')]',
q'[DB_VERSION('12.1.0.2')]',
q'[OPT_PARAM('_optimizer_extended_cursor_sharing' 'none')]',
q'[OPT_PARAM('_optimizer_extended_cursor_sharing_rel' 'none')]',
q'[OPT_PARAM('_optimizer_adaptive_cursor_sharing' 'false')]',
q'[OPT_PARAM('_px_adaptive_dist_method' 'off')]',
q'[OPT_PARAM('_optimizer_strans_adaptive_pruning' 'false')]',
q'[OPT_PARAM('_optimizer_nlj_hj_adaptive_join' 'false')]',
q'[ALL_ROWS]',
q'[OUTLINE_LEAF(@"SEL$C6423BE4")]',
q'[PUSH_PRED(@"SEL$5DA710D3" "VW_NSO_1"@"SEL$5DA710D3" 2)]',
q'[OUTLINE_LEAF(@"SEL$5DA710D3")]',
q'[UNNEST(@"SEL$2" UNNEST_INNERJ_DISTINCT_VIEW)]',
q'[OUTLINE_LEAF(@"SEL$3")]',
q'[OUTLINE(@"SEL$683B0107")]',
q'[OUTLINE(@"SEL$5DA710D3")]',
q'[UNNEST(@"SEL$2" UNNEST_INNERJ_DISTINCT_VIEW)]',
q'[OUTLINE(@"SEL$1")]',
q'[OUTLINE(@"SEL$2")]',
q'[NO_ACCESS(@"SEL$3" "from$_subquery$_003"@"SEL$3")]',
q'[INDEX_RS_ASC(@"SEL$5DA710D3" "JOB"@"SEL$1" ("JOB"."STATE" "JOB"."ID" "JOB"."KIEVTXNID"))]',
q'[NO_ACCESS(@"SEL$5DA710D3" "VW_NSO_1"@"SEL$5DA710D3")]',
q'[LEADING(@"SEL$5DA710D3" "JOB"@"SEL$1" "VW_NSO_1"@"SEL$5DA710D3")]',
q'[USE_NL(@"SEL$5DA710D3" "VW_NSO_1"@"SEL$5DA710D3")]',
q'[INDEX_DESC(@"SEL$C6423BE4" "JOB"@"SEL$2" ("JOB"."ID" "JOB"."KIEVTXNID"))]',
q'[END_OUTLINE_DATA]'
);
-- transformations
IF '1002' IS NOT NULL THEN -- KIEV Statement Caching specific
EXECUTE IMMEDIATE 'SELECT TO_CHAR(bucketid) AS bucket_id FROM &&kievbuckets_owner..kievbuckets WHERE UPPER(name) = UPPER(''JOB'')' INTO l_target_bucket_id;
END IF;
IF l_target_bucket_id IS NOT NULL THEN
l_sql_text_clob := REPLACE(l_sql_text_clob, '[1002]', '['||l_target_bucket_id||']');
l_target_signature := DBMS_SQLTUNE.sqltext_to_signature (sql_text => l_sql_text_clob);
ELSE
l_target_signature := 14623511363650319057;
END IF;
o('['||l_target_signature||']['||l_target_bucket_id||']');
l_plan_name := 'exp_7amt7kx1ptzhr_210721224646';
l_description := '['||l_target_signature||'][3621166190][3467459516][14623511363650319057][7amt7kx1ptzhr][JOB][1002][ICN][KIEV02RG][NETWORK_CONTROL_PLANE][EXP][BUCKET][DBPERF-7399]';
-- disable prior sql_profile
FOR i IN (SELECT p.name FROM dba_sql_profiles p WHERE p.signature = l_target_signature AND p.category = 'DEFAULT' AND p.status = 'ENABLED' AND NVL(p.description, 'NULL') NOT LIKE '%][EXP][%' AND NOT EXISTS (SELECT NULL FROM dba_sql_profiles e WHERE e.name = p.name AND e.category = 'BACKUP'))
LOOP
o('SPRF disable: '||i.name);
DBMS_SQLTUNE.alter_sql_profile(name => i.name, attribute_name => 'CATEGORY', value => 'BACKUP');
END LOOP;
-- create new sql_profile
SELECT COUNT(*) INTO l_count FROM dba_sql_profiles WHERE name = l_plan_name;
IF l_count = 0 THEN
o('SPRF create: '||l_plan_name||' '||l_description);
DBMS_SQLTUNE.import_sql_profile(sql_text => l_sql_text_clob, profile => l_profile_attr, name => l_plan_name, description => l_description, replace => TRUE);
:v_implemented := :v_implemented + 1;
END IF;
-- disable prior sql_patch
FOR i IN (SELECT p.name FROM dba_sql_patches p WHERE p.signature = l_target_signature AND p.category = 'DEFAULT' AND p.status = 'ENABLED' AND NOT EXISTS (SELECT NULL FROM dba_sql_patches e WHERE e.name = p.name AND e.category = 'BACKUP'))
LOOP
o('SPCH disable: '||i.name);
$IF DBMS_DB_VERSION.ver_le_12_1
$THEN
DBMS_SQLDIAG.alter_sql_patch(name => i.name, attribute_name => 'CATEGORY', value => 'BACKUP');
$ELSE
DBMS_SQLDIAG.alter_sql_patch(name => i.name, attribute_name => 'CATEGORY', attribute_value => 'BACKUP');
$END
END LOOP;
-- disable prior sql_plan_baseline
FOR i IN (SELECT p.sql_handle, p.plan_name, p.description FROM dba_sql_plan_baselines p WHERE p.signature = l_target_signature AND p.enabled = 'YES' AND p.accepted = 'YES')
LOOP
o('SPBL disable: '||i.sql_handle||' '||i.plan_name||' '||i.description);
l_plans := DBMS_SPM.alter_sql_plan_baseline(sql_handle => i.sql_handle, plan_name => i.plan_name, attribute_name => 'ENABLED', attribute_value => 'NO');
IF NVL(i.description, 'NULL') NOT LIKE '%[210721224646]%' THEN
IF LENGTH(i.description) > 470 THEN
l_plans := DBMS_SPM.alter_sql_plan_baseline(sql_handle => i.sql_handle, plan_name => i.plan_name, attribute_name => 'DESCRIPTION', attribute_value => '[EXP][210721224646]');
ELSE
l_plans := DBMS_SPM.alter_sql_plan_baseline(sql_handle => i.sql_handle, plan_name => i.plan_name, attribute_name => 'DESCRIPTION', attribute_value => i.description||' [EXP][210721224646]');
END IF;
o('SPBL update: [EXP][210721224646]');
END IF;
END LOOP;
END;
/
--
PRO
PRO /* performScanQuery(JOB,HashRangeIndex) [1002] */ SELECT  *  FROM JOB WHERE (id, KievTxnID, 1) IN (
PRO [16719391725860692357][dr76db54pt53k][1636412406][2735441510][JOB][1002][BUCKET]
DECLARE
l_plan_name          VARCHAR2(30);
l_description        VARCHAR2(500);
l_count              NUMBER;
l_plans              NUMBER;
l_target_bucket_id   VARCHAR2(6);
l_target_signature   NUMBER;
l_sql_text_clob      CLOB;
l_profile_attr       SYS.SQLPROF_ATTR;
PROCEDURE o(p_line IN VARCHAR2) IS BEGIN DBMS_OUTPUT.put_line(p_line); END;
BEGIN
-- sql_text
l_sql_text_clob := q'[
/* performScanQuery(JOB,HashRangeIndex) [1002] */ SELECT  *
FROM JOB
WHERE (id, KievTxnID, 1) IN (
SELECT id, KievTxnID, ROW_NUMBER() OVER (PARTITION BY
id
ORDER BY KievTxnID DESC) rn
FROM JOB
WHERE KievTxnID <= :1
)
AND KievLive = 'Y'
AND  ( (id > :2 ) )
ORDER BY id ASC
FETCH FIRST :3  ROWS ONLY
]';
-- hints
l_profile_attr := SYS.SQLPROF_ATTR(
q'[BEGIN_OUTLINE_DATA]',
q'[IGNORE_OPTIM_EMBEDDED_HINTS]',
q'[OPTIMIZER_FEATURES_ENABLE('12.1.0.2')]',
q'[DB_VERSION('12.1.0.2')]',
q'[OPT_PARAM('_optimizer_extended_cursor_sharing' 'none')]',
q'[OPT_PARAM('_optimizer_extended_cursor_sharing_rel' 'none')]',
q'[OPT_PARAM('_optimizer_adaptive_cursor_sharing' 'false')]',
q'[OPT_PARAM('_px_adaptive_dist_method' 'off')]',
q'[OPT_PARAM('_optimizer_strans_adaptive_pruning' 'false')]',
q'[OPT_PARAM('_optimizer_nlj_hj_adaptive_join' 'false')]',
q'[OPT_PARAM('_fix_control' '5922070:0')]',
q'[FIRST_ROWS(1)]',
q'[OUTLINE_LEAF(@"SEL$C6423BE4")]',
q'[PUSH_PRED(@"SEL$5DA710D3" "VW_NSO_1"@"SEL$5DA710D3" 2)]',
q'[OUTLINE_LEAF(@"SEL$5DA710D3")]',
q'[UNNEST(@"SEL$2" UNNEST_INNERJ_DISTINCT_VIEW)]',
q'[OUTLINE_LEAF(@"SEL$3")]',
q'[OUTLINE(@"SEL$683B0107")]',
q'[OUTLINE(@"SEL$5DA710D3")]',
q'[UNNEST(@"SEL$2" UNNEST_INNERJ_DISTINCT_VIEW)]',
q'[OUTLINE(@"SEL$1")]',
q'[OUTLINE(@"SEL$2")]',
q'[NO_ACCESS(@"SEL$3" "from$_subquery$_003"@"SEL$3")]',
q'[INDEX_RS_ASC(@"SEL$5DA710D3" "JOB"@"SEL$1" ("JOB"."ID" "JOB"."KIEVTXNID"))]',
q'[NO_ACCESS(@"SEL$5DA710D3" "VW_NSO_1"@"SEL$5DA710D3")]',
q'[LEADING(@"SEL$5DA710D3" "JOB"@"SEL$1" "VW_NSO_1"@"SEL$5DA710D3")]',
q'[USE_NL(@"SEL$5DA710D3" "VW_NSO_1"@"SEL$5DA710D3")]',
q'[INDEX_DESC(@"SEL$C6423BE4" "JOB"@"SEL$2" ("JOB"."ID" "JOB"."KIEVTXNID"))]',
q'[END_OUTLINE_DATA]'
);
-- transformations
IF '1002' IS NOT NULL THEN -- KIEV Statement Caching specific
EXECUTE IMMEDIATE 'SELECT TO_CHAR(bucketid) AS bucket_id FROM &&kievbuckets_owner..kievbuckets WHERE UPPER(name) = UPPER(''JOB'')' INTO l_target_bucket_id;
END IF;
IF l_target_bucket_id IS NOT NULL THEN
l_sql_text_clob := REPLACE(l_sql_text_clob, '[1002]', '['||l_target_bucket_id||']');
l_target_signature := DBMS_SQLTUNE.sqltext_to_signature (sql_text => l_sql_text_clob);
ELSE
l_target_signature := 16719391725860692357;
END IF;
o('['||l_target_signature||']['||l_target_bucket_id||']');
l_plan_name := 'exp_dr76db54pt53k_210721224646';
l_description := '['||l_target_signature||'][1636412406][2735441510][16719391725860692357][dr76db54pt53k][JOB][1002][ICN][KIEV02RG][NETWORK_CONTROL_PLANE][EXP][BUCKET][DBPERF-7399]';
-- disable prior sql_profile
FOR i IN (SELECT p.name FROM dba_sql_profiles p WHERE p.signature = l_target_signature AND p.category = 'DEFAULT' AND p.status = 'ENABLED' AND NVL(p.description, 'NULL') NOT LIKE '%][EXP][%' AND NOT EXISTS (SELECT NULL FROM dba_sql_profiles e WHERE e.name = p.name AND e.category = 'BACKUP'))
LOOP
o('SPRF disable: '||i.name);
DBMS_SQLTUNE.alter_sql_profile(name => i.name, attribute_name => 'CATEGORY', value => 'BACKUP');
END LOOP;
-- create new sql_profile
SELECT COUNT(*) INTO l_count FROM dba_sql_profiles WHERE name = l_plan_name;
IF l_count = 0 THEN
o('SPRF create: '||l_plan_name||' '||l_description);
DBMS_SQLTUNE.import_sql_profile(sql_text => l_sql_text_clob, profile => l_profile_attr, name => l_plan_name, description => l_description, replace => TRUE);
:v_implemented := :v_implemented + 1;
END IF;
-- disable prior sql_patch
FOR i IN (SELECT p.name FROM dba_sql_patches p WHERE p.signature = l_target_signature AND p.category = 'DEFAULT' AND p.status = 'ENABLED' AND NOT EXISTS (SELECT NULL FROM dba_sql_patches e WHERE e.name = p.name AND e.category = 'BACKUP'))
LOOP
o('SPCH disable: '||i.name);
$IF DBMS_DB_VERSION.ver_le_12_1
$THEN
DBMS_SQLDIAG.alter_sql_patch(name => i.name, attribute_name => 'CATEGORY', value => 'BACKUP');
$ELSE
DBMS_SQLDIAG.alter_sql_patch(name => i.name, attribute_name => 'CATEGORY', attribute_value => 'BACKUP');
$END
END LOOP;
-- disable prior sql_plan_baseline
FOR i IN (SELECT p.sql_handle, p.plan_name, p.description FROM dba_sql_plan_baselines p WHERE p.signature = l_target_signature AND p.enabled = 'YES' AND p.accepted = 'YES')
LOOP
o('SPBL disable: '||i.sql_handle||' '||i.plan_name||' '||i.description);
l_plans := DBMS_SPM.alter_sql_plan_baseline(sql_handle => i.sql_handle, plan_name => i.plan_name, attribute_name => 'ENABLED', attribute_value => 'NO');
IF NVL(i.description, 'NULL') NOT LIKE '%[210721224646]%' THEN
IF LENGTH(i.description) > 470 THEN
l_plans := DBMS_SPM.alter_sql_plan_baseline(sql_handle => i.sql_handle, plan_name => i.plan_name, attribute_name => 'DESCRIPTION', attribute_value => '[EXP][210721224646]');
ELSE
l_plans := DBMS_SPM.alter_sql_plan_baseline(sql_handle => i.sql_handle, plan_name => i.plan_name, attribute_name => 'DESCRIPTION', attribute_value => i.description||' [EXP][210721224646]');
END IF;
o('SPBL update: [EXP][210721224646]');
END IF;
END LOOP;
END;
/
--
PRINT v_implemented;
PRO PRO
PRO PRO /tmp/DBPERF-7399_2021-07-21T22.46.19Z_OC1_ICN_RGN_KIEV02RG_NETWORK_CONTROL_PLANE_cs_sprf_export_IMPLEMENT_&&report_time..txt
PRO PRO
SPO OFF;
SET SERVEROUT OFF;
--
-- /tmp/DBPERF-7399_2021-07-21T22.46.19Z_OC1_ICN_RGN_KIEV02RG_NETWORK_CONTROL_PLANE_cs_sprf_export_IMPLEMENT.sql
--
HOS ls -l /tmp/DBPERF-7399_2021-07-21T22.46.19Z_OC1_ICN_RGN_KIEV02RG_NETWORK_CONTROL_PLANE_cs_sprf_export_IMPLEMENT*
