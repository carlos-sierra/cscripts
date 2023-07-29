-- cs_gv_sql_stability.sql: called by cs_planx.sql, cs_sqlperf.sql and cs_purge_cursor.sql 
@@cs_sqlstat_cols.sql
PRO 
PRO PLAN STABILITY - CURRENT BY CHILD CURSOR (gv$sql) 
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
/****************************************************************************************/
WITH 
FUNCTION /* cs_gv_sql_stability */ get_pdb_name (p_con_id IN VARCHAR2)
RETURN VARCHAR2
IS
  l_pdb_name VARCHAR2(4000);
BEGIN
  SELECT name
    INTO l_pdb_name
    FROM v$containers
   WHERE con_id = TO_NUMBER(p_con_id);
  --
  RETURN l_pdb_name;
END get_pdb_name;
/****************************************************************************************/
FUNCTION get_sql_hv (p_sqltext IN CLOB)
RETURN VARCHAR2
IS
  l_sqltext CLOB := REGEXP_REPLACE(p_sqltext, '/\* REPO_[A-Z0-9]{1,25} \*/ '); -- removes "/* REPO_IFCDEXZQGAYDAMBQHAYQ */ " DBPERF-8819
BEGIN
  IF l_sqltext LIKE '%/* %(%,%)% [%] */%' THEN l_sqltext := REGEXP_REPLACE(l_sqltext, '\[([[:digit:]]{4,5})\] '); END IF; -- removes bucket_id "[1001] "
  RETURN LPAD(MOD(DBMS_SQLTUNE.sqltext_to_signature(l_sqltext),100000),5,'0');
END get_sql_hv;
/****************************************************************************************/
sql_metrics AS (
SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS MONITOR */
       s.*,
       get_sql_hv(s.sql_fulltext) AS sqlid
  FROM gv$sql s
 WHERE &&cs_filter_1.
   AND ('&&cs2_sql_text_piece.' IS NULL OR UPPER(s.sql_text) LIKE CHR(37)||UPPER('&&cs2_sql_text_piece.')||CHR(37))
   AND ROWNUM >= 1 -- materialize
)
/****************************************************************************************/
SELECT /*+ MONITOR GATHER_PLAN_STATISTICS */
       '!' AS sep0,
       s.last_active_time,
       REPLACE(s.last_load_time, '/', 'T') AS last_load_time,
       REPLACE(s.first_load_time, '/', 'T') AS first_load_time,
       s.sqlid,
       s.sql_id,
       s.inst_id,
       s.child_number,
       s.plan_hash_value,
       s.full_plan_hash_value,
       '!' AS sep1,
       s.executions,
       s.loaded_versions,
       s.loads,
       s.invalidations,
       s.object_status,  
       '!' AS sep2,
       s.is_obsolete,
       s.is_shareable,
       s.is_bind_sensitive,
       s.is_bind_aware,
       '!' AS sep3,
       s.sql_plan_baseline,
       CASE WHEN s.sql_plan_baseline IS NOT NULL THEN (SELECT p.created FROM dba_sql_plan_baselines p WHERE p.plan_name = s.sql_plan_baseline AND p.signature = :cs_signature AND ROWNUM = 1) END AS spbl_created,
       s.sql_profile,
       CASE WHEN s.sql_profile IS NOT NULL THEN (SELECT p.created FROM dba_sql_profiles p WHERE p.name = s.sql_profile AND p.signature = :cs_signature AND ROWNUM = 1) END AS sprf_created,
       s.sql_patch,
       CASE WHEN s.sql_patch IS NOT NULL THEN (SELECT p.created FROM dba_sql_patches p WHERE p.name = s.sql_patch AND p.signature = :cs_signature AND ROWNUM = 1) END AS spch_created,
       '!' AS sep4,
       s.sql_text,
       s.module,
       CASE SYS_CONTEXT('USERENV', 'CON_ID') WHEN '1' THEN get_pdb_name(s.con_id) ELSE s.parsing_schema_name END AS pdb_or_parsing_schema_name
  FROM sql_metrics s
 ORDER BY
       s.last_active_time,
       s.sqlid,
       s.sql_id,
       s.inst_id,
       s.plan_hash_value,
       CASE SYS_CONTEXT('USERENV', 'CON_ID') WHEN '1' THEN get_pdb_name(s.con_id) ELSE s.parsing_schema_name END,
       s.module
/
--
@@cs_sqlstat_clear.sql
