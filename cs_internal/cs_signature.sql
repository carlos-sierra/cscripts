COL cs_signature NEW_V cs_signature FOR A20 NOPRI;
COL cs_sql_hv NEW_V cs_sql_hv FOR A5 NOPRI;
COL cs_sql_handle NEW_V cs_sql_handle FOR A20 NOPRI;
COL cs_zapper_managed_sql NEW_V cs_zapper_managed_sql NOPRI;
DEF cs_parsing_schema_name = '';
COL cs_parsing_schema_name NEW_V cs_parsing_schema_name FOR A128 NOPRI;
DEF cs_first_rows_candidacy = 'Candidacy only applies to KIEV performScanQuery';
COL cs_first_rows_candidacy NEW_V cs_first_rows_candidacy NOPRI;
DEF cs_application_category = 'UN';
COL cs_application_category NEW_V cs_application_category NOPRI;
--
VAR cs_signature NUMBER;
VAR cs_sql_id VARCHAR2(13);
VAR cs_sql_text CLOB;
VAR cs_sql_text_1000 VARCHAR2(1000);
VAR cs_parsing_schema_name VARCHAR2(128);
--
-- some times sql in v$sqlstats show a signature with value of 0 (e.g. /* populateBucketGCWorkspace */ KPT-35), so we get signature and sql_text from v$sql
BEGIN
  IF :cs_signature IS NULL THEN
    SELECT sql_id, exact_matching_signature, sql_fulltext, parsing_schema_name INTO :cs_sql_id, :cs_signature, :cs_sql_text, :cs_parsing_schema_name FROM v$sql WHERE sql_id = '&&cs_sql_id.' AND ROWNUM = 1;
    IF :cs_signature = 0 THEN
      :cs_signature := DBMS_SQLTUNE.SQLTEXT_TO_SIGNATURE(:cs_sql_text);
    END IF;  
  END IF;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    :cs_sql_id := NULL;
    :cs_signature := NULL;
    :cs_sql_text := NULL;
    :cs_parsing_schema_name := NULL;
END;
/
-- sometimes sql is not in memory but on awr, so we get sql_text from awr and we compute signature
BEGIN
  IF :cs_signature IS NULL THEN
    SELECT sql_id, sql_text INTO :cs_sql_id, :cs_sql_text FROM dba_hist_sqltext WHERE sql_id = '&&cs_sql_id.' AND ROWNUM = 1;
    :cs_signature := DBMS_SQLTUNE.SQLTEXT_TO_SIGNATURE(:cs_sql_text);
  END IF;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    :cs_sql_id := NULL;
    :cs_signature := NULL;
    :cs_sql_text := NULL;
END;
/
-- most times sql is in memory, so we get signature and sql_text from v$sqlstats
-- some times sql in v$sqlstats show a signature with value of 0 (e.g. /* populateBucketGCWorkspace */ KPT-35), so we compute signature if 0
-- moving this block to end
BEGIN
  IF :cs_signature IS NULL THEN
    SELECT sql_id, exact_matching_signature, sql_fulltext INTO :cs_sql_id, :cs_signature, :cs_sql_text FROM v$sqlstats WHERE sql_id = '&&cs_sql_id.' AND ROWNUM = 1;
    IF :cs_signature = 0 THEN
      :cs_signature := DBMS_SQLTUNE.SQLTEXT_TO_SIGNATURE(:cs_sql_text);
    END IF;  
  END IF;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    :cs_sql_id := NULL;
    :cs_signature := NULL;
    :cs_sql_text := NULL;
END;
/
-- next we try to get signature from an existing sql plan baseline
BEGIN
  IF :cs_signature IS NULL THEN
    SELECT SUBSTR(description, INSTR(description, 'SQL_ID=') + 7, 13), signature, sql_text, parsing_schema_name INTO :cs_sql_id, :cs_signature, :cs_sql_text, :cs_parsing_schema_name FROM dba_sql_plan_baselines WHERE SUBSTR(description, INSTR(description, 'SQL_ID=') + 7, 13) = '&&cs_sql_id.' AND ROWNUM = 1;
    IF :cs_signature = 0 THEN
      :cs_signature := DBMS_SQLTUNE.SQLTEXT_TO_SIGNATURE(:cs_sql_text);
    END IF;  
  END IF;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    :cs_sql_id := NULL;
    :cs_signature := NULL;
    :cs_sql_text := NULL;
    :cs_parsing_schema_name := NULL;
END;
/
-- remove trim spaces from sql_text and get first 1000 characters
BEGIN
  :cs_sql_text := TRIM(:cs_sql_text);
  :cs_sql_text_1000 := SUBSTR(REGEXP_REPLACE(:cs_sql_text, '[^[:print:]]', ''), 1, 1000);
END;
/
-- compute sql_hv (to be moved to "connects to cdb, execute iod apis, and reconnect to pdb")
WITH
FUNCTION get_sql_hv (p_sqltext IN CLOB)
RETURN VARCHAR2
IS
  l_sqltext CLOB := REGEXP_REPLACE(p_sqltext, '/\* REPO_[A-Z0-9]{1,25} \*/ '); -- removes "/* REPO_IFCDEXZQGAYDAMBQHAYQ */ " DBPERF-8819
BEGIN
  IF l_sqltext LIKE '%/* %(%,%)% [%] */%' THEN l_sqltext := REGEXP_REPLACE(l_sqltext, '\[([[:digit:]]{4,5})\] '); END IF; -- removes bucket_id "[1001] "
  RETURN LPAD(MOD(DBMS_SQLTUNE.sqltext_to_signature(l_sqltext),100000),5,'0');
END get_sql_hv;
SELECT get_sql_hv(:cs_sql_text) AS cs_sql_hv FROM DUAL
/
--
-- get signature, sql_handle and parsing_schema into sql variables 
SELECT TO_CHAR(:cs_signature) AS cs_signature FROM DUAL;
SELECT sql_handle AS cs_sql_handle FROM dba_sql_plan_baselines WHERE signature = :cs_signature AND ROWNUM = 1;
SELECT :cs_parsing_schema_name AS cs_parsing_schema_name FROM DUAL;
--
-- get first_rows optimzation candidacy for kiev scans
WITH
kiev_scan AS (
SELECT
  -- returns count of OR predicates such as ' < :5 ) OR'
  -- when > 0 then this is a pagination (continue) scan, and when = 0 then this is a begin scan
  REGEXP_COUNT(:cs_sql_text, '( >=? | <=? ):\d+ \) OR ?$', 1, 'cm') AS or_count,
  -- gets position of 1st character after 2nd ORDER BY
  -- then counts columns referenced by the main query's ORDER BY
  REGEXP_COUNT(:cs_sql_text, ' (ASC|DESC)(,|$)', REGEXP_INSTR(:cs_sql_text, 'ORDER BY', 1, 2, 1, 'c'), 'cm') AS ic_count,
  -- counts "greater than" (or "less than") operands
  -- then computes position of first character ')' after bind reference of last "greater than" (or "less than") operand
  -- returning the nunber of equality predicates on the prefix portion of the filters (i.e.: after all pagination predicates)
  REGEXP_COUNT(:cs_sql_text, '\(\w+ = :\d+ \)', GREATEST(REGEXP_INSTR(:cs_sql_text, '( > | < ):\d+ ', 1, GREATEST(REGEXP_COUNT(:cs_sql_text, '( > | < ):\d+ '), 1), 1), 1)) AS ep_count
FROM DUAL
WHERE :cs_sql_text LIKE '%/* performScanQuery(%,%) %'
)
SELECT CASE
        --  WHEN :cs_sql_text LIKE '%(futureWork,resumptionTimestamp)%'
        --    OR :cs_sql_text LIKE '%(leaseDecorators,ae_timestamp_index)%'
        --    OR :cs_sql_text LIKE '%(WORK_PARTITIONS_BUCKET,WORK_PARTITIONS_BUCKETIdx)%' -- KIEV99A2 FLAMINGOCPDB d41w5f7gnhg2b
        --    OR :cs_sql_text LIKE '%(LEASE,state_index)%' -- KIEV99RG IDENTITY_R1_ALPHA an1n9htmx7wss
        --  THEN 'Bad CANDIDATE: Known SQL, which requires a specific execution plan'
         WHEN :cs_sql_text LIKE '%AND (1 = 1)%' THEN 'Good CANDIDATE: Non-prefixed begin scan (expect a leading full index scan)'
         WHEN or_count = 0 THEN 'Good CANDIDATE: Prefixed begin scan or simple continue scan without or_operands (expect a leading range index scan)'
         WHEN ic_count = ep_count + 1 THEN 'Good CANDIDATE: Continue scan with: or_operands = '||TRIM(or_count)||', order-by_index_columns = '||TRIM(ic_count)||', prefixed_equality_predicates = '||TRIM(ep_count)||' (expect a leading range index scan)'
         WHEN ep_count > 0 THEN 'Poor Candidate: Continue scan with: or_operands = '||TRIM(or_count)||', order-by_index_columns = '||TRIM(ic_count)||', prefixed_equality_predicates = '||TRIM(ep_count)||' (a leading range index scan might be possible but not necessarily efficient)'
         WHEN ic_count <> ep_count + 1 THEN 'Bad CANDIDATE: Continue scan with: or_operands = '||TRIM(or_count)||', order-by_index_columns = '||TRIM(ic_count)||', prefixed_equality_predicates = '||TRIM(ep_count)||' (expect some suboptimal plan with a full scan)'
         ELSE 'Unexpected'
       END AS cs_first_rows_candidacy
  FROM kiev_scan
/
--
COL dummy NOPRI;
--
-- connects to cdb, execute iod apis, and reconnect to pdb
--
@@&&cs_set_container_to_cdb_root.
SELECT dummy
       &&cs_skip.,&&cs_tools_schema..IOD_SPM.application_category(p_sql_text => DBMS_LOB.substr(:cs_sql_text, 1000)) AS cs_application_category
       &&cs_skip.,&&cs_tools_schema..IOD_SPM.first_rows_candidate(p_sql_text => :cs_sql_text) AS cs_first_rows_candidacy
       &&cs_skip.,&&cs_tools_schema..IOD_SPM.get_sql_hv(p_sql_text => :cs_sql_text) AS cs_sql_hv,
       CASE WHEN (SELECT COUNT(*) FROM &&cs_tools_schema..zapper_sql_plan_bank WHERE UPPER(:cs_sql_text) LIKE UPPER('%'||sql_text_string||'%')) > 0 THEN 'Y' ELSE 'N' END AS cs_zapper_managed_sql
  FROM DUAL
 WHERE :cs_sql_text IS NOT NULL
/
@@&&cs_set_container_to_curr_pdb.
--
-- gets banner message in case sql is ma managed by zapper
--
BEGIN
  IF '&&cs_zapper_managed_sql.' = 'Y' THEN
    :cs_zapper_managed_sql_banner := '***'||CHR(10)||'*** This SQL is managed by ZAPPER'||CHR(10)||'***'||CHR(10)||CHR(10)||:cs_sql_text;
  ELSE
    :cs_zapper_managed_sql_banner := :cs_sql_text;
  END IF;
END;
/
--
-- get kiev table name parsing sql_text
DEF cs_kiev_table_name = '';
COL cs_kiev_table_name NEW_V cs_kiev_table_name NOPRI;
VAR cs_kiev_table_name VARCHAR2(128);
SELECT NVL(SUBSTR(:cs_sql_text, INSTR(:cs_sql_text, '(') + 1, LEAST(INSTR(:cs_sql_text||',', ','), INSTR(:cs_sql_text||')', ')')) - INSTR(:cs_sql_text, '(') - 1), 'null') AS cs_kiev_table_name  FROM DUAL WHERE :cs_sql_text LIKE '%/* %(%) %*/%';
EXEC :cs_kiev_table_name := '&&cs_kiev_table_name.';
--
-- get table owner and name out of sql_area (object dependencies)
DEF table_owner = '';
DEF table_name = '';
COL table_owner NEW_V table_owner NOPRI;
COL table_name NEW_V table_name NOPRI;
SELECT owner AS table_owner, table_name FROM dba_tables WHERE table_name = UPPER('&&cs_kiev_table_name.') ORDER BY num_rows DESC NULLS LAST FETCH FIRST 1 ROW ONLY;
-- /* kiev SQL references one table (most of the cases). if SQL references more than one table then only was is returned */
-- SELECT d.to_owner AS table_owner, 
--         d.to_name AS table_name
--   FROM v$sqlarea a,
--       v$object_dependency d
-- WHERE '&&table_owner.' IS NULL
--   AND a.con_id = TO_NUMBER('&&cs_con_id.')
--   AND a.sql_id = '&&cs_sql_id.' 
--   AND d.from_hash = a.hash_value
--   AND d.from_address = a.address
--   AND d.con_id = a.con_id
--   AND d.to_type = 2
--   AND d.to_name <> 'KIEVGCTEMPTABLE' /* exclude this common kiev table */
-- ORDER BY d.to_owner, d.to_name -- to make this query deterministic when executed multiple times on same sql_id and con_id
-- FETCH FIRST 1 ROW ONLY; 
--
WITH /* get_table_token */
v$metricname AS (
SELECT /*+ NO_MERGE */ 
      hash_value, address
  FROM v$sqlarea 
WHERE '&&table_owner.' IS NULL
  AND sql_id = '&&cs_sql_id.' 
  AND con_id = TO_NUMBER('&&cs_con_id.')
)
SELECT o.to_owner AS table_owner, o.to_name AS table_name
  FROM v$object_dependency o,
      v$metricname s
WHERE '&&table_owner.' IS NULL
  AND o.from_hash = s.hash_value 
  AND o.from_address = s.address
  AND o.con_id = TO_NUMBER('&&cs_con_id.')
  AND o.to_type = 2 -- table
  AND o.to_name <> 'KIEVGCTEMPTABLE' /* exclude this common kiev table */
ORDER BY o.to_owner, o.to_name -- to make this query deterministic when executed multiple times on same sql_id and con_id
/* kiev SQL references one table (most of the cases). if SQL references more than one table then only was is returned */
FETCH FIRST 1 ROW ONLY; 
--
-- reset table_owner and table_name columns
COL table_owner PRI;
COL table_name PRI;
