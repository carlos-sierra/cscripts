/* -------------------------------------------------------------------------------------- */
--
-- File name:   /tmp/DBPERF-7513_2021-09-10T19.32.29Z_OC1_BOM_RGN_KIEV02RG_VCN_V2_cs_sprf_export_IMPLEMENT.sql
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
--              SQL> @/tmp/DBPERF-7513_2021-09-10T19.32.29Z_OC1_BOM_RGN_KIEV02RG_VCN_V2_cs_sprf_export_IMPLEMENT.sql
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
SPO /tmp/DBPERF-7513_2021-09-10T19.32.29Z_OC1_BOM_RGN_KIEV02RG_VCN_V2_cs_sprf_export_IMPLEMENT_&&report_time..txt;
PRO PRO
PRO PRO /tmp/DBPERF-7513_2021-09-10T19.32.29Z_OC1_BOM_RGN_KIEV02RG_VCN_V2_cs_sprf_export_IMPLEMENT_&&report_time..txt
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
PRO /* populateBucketGCWorkspace */ INSERT INTO APP_USER.KievGCTempTable (TxnId) SELECT DISTINCT(KievTxn
PRO [1749192160489528408][gv9ptaubzd3pf][3740437391][113743142][][][NORMAL][APP_USER]
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
/* populateBucketGCWorkspace */ INSERT INTO #kievbuckets_owner#.KievGCTempTable (TxnId)
SELECT DISTINCT(KievTxnId)
FROM
(
SELECT BI.KievTxnID
FROM EVENTS_V2_rgn BI
WHERE BI.KievTxnId <= :1
AND (BI.KievTxnId <            (SELECT MAX(BI2.KievTxnID) FROM EVENTS_V2_rgn BI2 WHERE BI2.name = BI.name AND BI2.KievTxnId <= :2 )
OR BI.KievLive = 'N')
ORDER BY BI.KievTxnID ASC
FETCH FIRST :3  ROWS ONLY)
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
q'[OUTLINE_LEAF(@"SEL$3")]',
q'[OUTLINE_LEAF(@"SEL$2")]',
q'[OUTLINE_LEAF(@"SEL$0CB1C38B")]',
q'[MERGE(@"SEL$C13F64F5")]',
q'[OUTLINE_LEAF(@"INS$1")]',
q'[OUTLINE(@"SEL$1")]',
q'[OUTLINE(@"SEL$C13F64F5")]',
q'[ELIMINATE_OBY(@"SEL$4")]',
q'[OUTLINE(@"SEL$4")]',
q'[FULL(@"INS$1" "KIEVGCTEMPTABLE"@"INS$1")]',
q'[NO_ACCESS(@"SEL$0CB1C38B" "from$_subquery$_005"@"SEL$4")]',
q'[FULL(@"SEL$2" "BI"@"SEL$2")]',
q'[PQ_FILTER(@"SEL$2" SERIAL)]',
q'[INDEX(@"SEL$3" "BI2"@"SEL$3" ("EVENTS_V2_RGN"."NAME" "EVENTS_V2_RGN"."KIEVTXNID"))]',
q'[END_OUTLINE_DATA]'
);
-- transformations
IF '' IS NOT NULL THEN -- KIEV Statement Caching specific
EXECUTE IMMEDIATE 'SELECT TO_CHAR(bucketid) AS bucket_id FROM &&kievbuckets_owner..kievbuckets WHERE UPPER(name) = UPPER('''')' INTO l_target_bucket_id;
END IF;
IF l_target_bucket_id IS NOT NULL THEN
l_sql_text_clob := REPLACE(l_sql_text_clob, '[]', '['||l_target_bucket_id||']');
END IF;
l_sql_text_clob := REPLACE(l_sql_text_clob, '#kievbuckets_owner#', '&&kievbuckets_owner.');
l_target_signature := DBMS_SQLTUNE.sqltext_to_signature (sql_text => l_sql_text_clob);
o('['||l_target_signature||']['||l_target_bucket_id||']');
l_plan_name := 'exp_gv9ptaubzd3pf_210910193242';
l_description := '['||l_target_signature||'][3740437391][113743142][1749192160489528408][gv9ptaubzd3pf][][][BOM][KIEV02RG][VCN_V2][EXP][NORMAL][DBPERF-7513]';
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
--
ELSE
SELECT COUNT(*) INTO l_count FROM dba_sql_profiles WHERE name = l_plan_name AND status = 'DISABLED';
IF l_count > 0 THEN
o('SPRF enable: '||l_plan_name||' '||l_description);
DBMS_SQLTUNE.alter_sql_profile(name => l_plan_name, attribute_name => 'STATUS', value => 'ENABLED');
:v_implemented := :v_implemented + 1;
END IF;
--
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
IF NVL(i.description, 'NULL') NOT LIKE '%[210910193242]%' THEN
IF LENGTH(i.description) > 470 THEN
l_plans := DBMS_SPM.alter_sql_plan_baseline(sql_handle => i.sql_handle, plan_name => i.plan_name, attribute_name => 'DESCRIPTION', attribute_value => '[EXP][210910193242]');
ELSE
l_plans := DBMS_SPM.alter_sql_plan_baseline(sql_handle => i.sql_handle, plan_name => i.plan_name, attribute_name => 'DESCRIPTION', attribute_value => i.description||' [EXP][210910193242]');
END IF;
o('SPBL update: [EXP][210910193242]');
END IF;
END LOOP;
END;
/
--
PRINT v_implemented;
PRO PRO
PRO PRO /tmp/DBPERF-7513_2021-09-10T19.32.29Z_OC1_BOM_RGN_KIEV02RG_VCN_V2_cs_sprf_export_IMPLEMENT_&&report_time..txt
PRO PRO
SPO OFF;
SET SERVEROUT OFF;
--
-- /tmp/DBPERF-7513_2021-09-10T19.32.29Z_OC1_BOM_RGN_KIEV02RG_VCN_V2_cs_sprf_export_IMPLEMENT.sql
--
HOS ls -l /tmp/DBPERF-7513_2021-09-10T19.32.29Z_OC1_BOM_RGN_KIEV02RG_VCN_V2_cs_sprf_export_IMPLEMENT*
