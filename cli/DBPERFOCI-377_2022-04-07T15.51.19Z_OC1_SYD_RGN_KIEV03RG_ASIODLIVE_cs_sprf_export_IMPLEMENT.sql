/* -------------------------------------------------------------------------------------- */
--
-- File name:   /tmp/DBPERFOCI-377_2022-04-07T15.51.19Z_OC1_SYD_RGN_KIEV03RG_ASIODLIVE_cs_sprf_export_IMPLEMENT.sql
--
-- Purpose:     Implements Execution Plans for some SQL_ID or all SQL on a PDB using SQL Profile(s)
--
-- Author:      Carlos Sierra
--
-- Version:     2022/02/22
--
-- Usage:       Connecting into PDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @/tmp/DBPERFOCI-377_2022-04-07T15.51.19Z_OC1_SYD_RGN_KIEV03RG_ASIODLIVE_cs_sprf_export_IMPLEMENT.sql
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
SPO /tmp/DBPERFOCI-377_2022-04-07T15.51.19Z_OC1_SYD_RGN_KIEV03RG_ASIODLIVE_cs_sprf_export_IMPLEMENT_&&report_time..txt;
PRO PRO
PRO PRO /tmp/DBPERFOCI-377_2022-04-07T15.51.19Z_OC1_SYD_RGN_KIEV03RG_ASIODLIVE_cs_sprf_export_IMPLEMENT_&&report_time..txt
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
PRO select distinct announceme0_.id as col_0_0_, announceme0_.timeCreated as col_1_0_ from AS_DATA.ANNOU
PRO [602600164369465624][1kwqff5hagc6x][2262204949][2169562146][][][NORMAL][APP_USER]
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
select distinct announceme0_.id as col_0_0_, announceme0_.timeCreated as col_1_0_ from AS_DATA.ANNOUNCEMENTS announceme0_ where announceme0_.deleted=:1  and announceme0_.compartmentId=:2  and ((announceme0_.timeOneValue is null) and (announceme0_.timeTwoValue is null) or (announceme0_.timeTwoValue is not null) and announceme0_.timeTwoValue>=:3  or announceme0_.timeOneType=:4  and announceme0_.timeOneValue>=:5  or announceme0_.timeOneType<>:6  and (announceme0_.timeTwoValue is null)) order by announceme0_.timeCreated desc nulls last fetch first :7  rows only
]';
-- hints
l_profile_attr := SYS.SQLPROF_ATTR(
q'[BEGIN_OUTLINE_DATA]',
q'[IGNORE_OPTIM_EMBEDDED_HINTS]',
q'[OPTIMIZER_FEATURES_ENABLE('19.1.0')]',
q'[DB_VERSION('19.1.0')]',
q'[OPT_PARAM('_optimizer_extended_cursor_sharing' 'none')]',
q'[OPT_PARAM('_optimizer_extended_cursor_sharing_rel' 'none')]',
q'[OPT_PARAM('_optimizer_adaptive_cursor_sharing' 'false')]',
q'[OPT_PARAM('_px_adaptive_dist_method' 'off')]',
q'[OPT_PARAM('_optimizer_strans_adaptive_pruning' 'false')]',
q'[OPT_PARAM('_optimizer_nlj_hj_adaptive_join' 'false')]',
q'[ALL_ROWS]',
q'[OUTLINE_LEAF(@"SEL$58A6D7F6")]',
q'[MERGE(@"SEL$1" >"SEL$2")]',
q'[OUTLINE_LEAF(@"SEL$3")]',
q'[OUTLINE(@"SEL$2")]',
q'[OUTLINE(@"SEL$1")]',
q'[NO_ACCESS(@"SEL$3" "from$_subquery$_003"@"SEL$3")]',
q'[INDEX_RS_ASC(@"SEL$58A6D7F6" "ANNOUNCEME0_"@"SEL$1" ("ANNOUNCEMENTS"."COMPARTMENTID"))]',
q'[BATCH_TABLE_ACCESS_BY_ROWID(@"SEL$58A6D7F6" "ANNOUNCEME0_"@"SEL$1")]',
q'[END_OUTLINE_DATA]'
);
-- transformations
IF '' IS NOT NULL THEN -- KIEV Statement Caching specific
EXECUTE IMMEDIATE 'SELECT TO_CHAR(bucketid) AS bucket_id FROM &&kievbuckets_owner..kievbuckets WHERE UPPER(name) = UPPER('''')' INTO l_target_bucket_id;
END IF;
IF l_target_bucket_id IS NOT NULL THEN
l_sql_text_clob := REPLACE(l_sql_text_clob, '[]', '['||l_target_bucket_id||']');
END IF;
IF '&&kievbuckets_owner.' IS NOT NULL THEN -- KIEV Bucket Owner
l_sql_text_clob := REPLACE(l_sql_text_clob, '#kievbuckets_owner#', '&&kievbuckets_owner.');
END IF;
l_target_signature := DBMS_SQLTUNE.sqltext_to_signature (sql_text => l_sql_text_clob);
o('['||l_target_signature||']['||l_target_bucket_id||']');
l_plan_name := 'exp_1kwqff5hagc6x_220407155144';
l_description := '['||l_target_signature||'][2262204949][2169562146][602600164369465624][1kwqff5hagc6x][][][SYD][KIEV03RG][ASIODLIVE][EXP][NORMAL][DBPERFOCI-377]';
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
ELSE
SELECT COUNT(*) INTO l_count FROM dba_sql_profiles WHERE name = l_plan_name AND status = 'DISABLED';
IF l_count > 0 THEN
o('SPRF enable: '||l_plan_name||' '||l_description);
DBMS_SQLTUNE.alter_sql_profile(name => l_plan_name, attribute_name => 'STATUS', value => 'ENABLED');
:v_implemented := :v_implemented + 1;
END IF;
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
IF NVL(i.description, 'NULL') NOT LIKE '%[220407155144]%' THEN
IF LENGTH(i.description) > 470 THEN
l_plans := DBMS_SPM.alter_sql_plan_baseline(sql_handle => i.sql_handle, plan_name => i.plan_name, attribute_name => 'DESCRIPTION', attribute_value => '[EXP][220407155144]');
ELSE
l_plans := DBMS_SPM.alter_sql_plan_baseline(sql_handle => i.sql_handle, plan_name => i.plan_name, attribute_name => 'DESCRIPTION', attribute_value => i.description||' [EXP][220407155144]');
END IF;
o('SPBL update: [EXP][220407155144]');
END IF;
END LOOP;
END;
/
--
PRINT v_implemented;
PRO PRO
PRO PRO /tmp/DBPERFOCI-377_2022-04-07T15.51.19Z_OC1_SYD_RGN_KIEV03RG_ASIODLIVE_cs_sprf_export_IMPLEMENT_&&report_time..txt
PRO PRO
SPO OFF;
SET SERVEROUT OFF;
--
-- /tmp/DBPERFOCI-377_2022-04-07T15.51.19Z_OC1_SYD_RGN_KIEV03RG_ASIODLIVE_cs_sprf_export_IMPLEMENT.sql
--
HOS ls -l /tmp/DBPERFOCI-377_2022-04-07T15.51.19Z_OC1_SYD_RGN_KIEV03RG_ASIODLIVE_cs_sprf_export_IMPLEMENT*
