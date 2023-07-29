-- cs_fs_internal_query_5.sql: called by cs_fs.sql
SET HEA OFF PAGES 0;
PRO 
PRO SQL Text dba_hist_sqltext (may include SYS parsing schema)
PRO ~~~~~~~~
WITH
FUNCTION /* cs_fs_internal_query_5 */ get_sql_hv (p_sqltext IN CLOB)
RETURN VARCHAR2
IS
  l_sqltext CLOB := REGEXP_REPLACE(p_sqltext, '/\* REPO_[A-Z0-9]{1,25} \*/ '); -- removes "/* REPO_IFCDEXZQGAYDAMBQHAYQ */ " DBPERF-8819
BEGIN
  IF l_sqltext LIKE '%/* %(%,%)% [%] */%' THEN l_sqltext := REGEXP_REPLACE(l_sqltext, '\[([[:digit:]]{4,5})\] '); END IF; -- removes bucket_id "[1001] "
  RETURN LPAD(MOD(DBMS_SQLTUNE.sqltext_to_signature(l_sqltext),100000),5,'0');
END get_sql_hv;
/****************************************************************************************/
FUNCTION get_first_rows_candidacy (p_sqltext IN CLOB)
RETURN VARCHAR2
IS
  l_or_count NUMBER;
  l_ic_count NUMBER;
  l_ep_count NUMBER;
  /**************************************************************************************/
  FUNCTION get_or_count (p2_sqltext IN CLOB)
  RETURN NUMBER
  IS
    l2_or_count NUMBER := TO_NUMBER(NULL);
  BEGIN
    IF p2_sqltext LIKE '%/* performScanQuery(%,%) %' THEN
      -- returns count of OR predicates such as ' < :5 ) OR'
      -- when > 0 then this is a pagination (continue) scan, and when = 0 then this is a begin scan
      SELECT REGEXP_COUNT(p2_sqltext, '( >=? | <=? ):\d+ \) OR ?$', 1, 'cm') INTO l2_or_count FROM DUAL;
    END IF;  
    RETURN l2_or_count; 
  END get_or_count;
  /**************************************************************************************/
  FUNCTION get_ic_count (p2_sqltext IN CLOB)
  RETURN NUMBER
  IS
    l2_ic_count NUMBER := TO_NUMBER(NULL);
  BEGIN
    IF p2_sqltext LIKE '%/* performScanQuery(%,%) %' THEN
      -- gets position of 1st character after 2nd ORDER BY
      -- then counts columns referenced by the main query's ORDER BY
      SELECT REGEXP_COUNT(p2_sqltext, ' (ASC|DESC)(,|$)', REGEXP_INSTR(p2_sqltext, 'ORDER BY', 1, 2, 1, 'c'), 'cm') INTO l2_ic_count FROM DUAL;
    END IF;  
    RETURN l2_ic_count; 
  END get_ic_count;
  /**************************************************************************************/
  FUNCTION get_ep_count (p2_sqltext IN CLOB)
  RETURN NUMBER
  IS
    l2_ep_count NUMBER := TO_NUMBER(NULL);
  BEGIN
    IF p2_sqltext LIKE '%/* performScanQuery(%,%) %' THEN
      -- counts "greater than" (or "less than") operands
      -- then computes position of first character ')' after bind reference of last "greater than" (or "less than") operand
      -- returning the nunber of equality predicates on the prefix portion of the filters (i.e.: after all pagination predicates)
      SELECT REGEXP_COUNT(p2_sqltext, '\(\w+ = :\d+ \)', GREATEST(REGEXP_INSTR(p2_sqltext, '( > | < ):\d+ ', 1, GREATEST(REGEXP_COUNT(p2_sqltext, '( > | < ):\d+ '), 1), 1), 1)) INTO l2_ep_count FROM DUAL;
    END IF;   
    RETURN l2_ep_count;
  END get_ep_count;
  /**************************************************************************************/
BEGIN
  IF p_sqltext NOT LIKE '%/* performScanQuery(%,%) %' THEN
    RETURN 'Candidacy only applies to KIEV performScanQuery';
  -- ELSIF p_sqltext LIKE '%(futureWork,resumptionTimestamp)%'
  --    OR p_sqltext LIKE '%(leaseDecorators,ae_timestamp_index)%'
  --    OR p_sqltext LIKE '%(WORK_PARTITIONS_BUCKET,WORK_PARTITIONS_BUCKETIdx)%' -- KIEV99A2 FLAMINGOCPDB d41w5f7gnhg2b
  --    OR p_sqltext LIKE '%(LEASE,state_index)%' -- KIEV99RG IDENTITY_R1_ALPHA an1n9htmx7wss
  -- THEN 
  --   RETURN 'Bad CANDIDATE: Known SQL, which requires a specific execution plan';
  ELSIF p_sqltext LIKE '%AND (1 = 1)%' THEN 
    RETURN 'Good CANDIDATE: Non-prefixed begin scan (expect a leading full index scan)';
  END IF;
  --
  l_or_count := get_or_count(p2_sqltext => p_sqltext);
  l_ic_count := get_ic_count(p2_sqltext => p_sqltext);
  l_ep_count := get_ep_count(p2_sqltext => p_sqltext);
  --
  IF l_or_count = 0 THEN 
    RETURN 'Good CANDIDATE: Prefixed begin scan or simple continue scan without or_operands (expect a leading range index scan)';
  ELSIF l_ic_count = l_ep_count + 1 THEN
    RETURN 'Good CANDIDATE: Continue scan with: or_operands = '||TRIM(l_or_count)||', order-by_index_columns = '||TRIM(l_ic_count)||', prefixed_equality_predicates = '||TRIM(l_ep_count)||' (expect a leading range index scan)';
  ELSIF l_ep_count > 0 THEN 
    RETURN 'Poor Candidate: Continue scan with: or_operands = '||TRIM(l_or_count)||', order-by_index_columns = '||TRIM(l_ic_count)||', prefixed_equality_predicates = '||TRIM(l_ep_count)||' (a leading range index scan might be possible but not necessarily efficient)';
  ELSIF l_ic_count <> l_ep_count + 1 THEN
    RETURN 'Bad CANDIDATE: Continue scan with: or_operands = '||TRIM(l_or_count)||', order-by_index_columns = '||TRIM(l_ic_count)||', prefixed_equality_predicates = '||TRIM(l_ep_count)||' (expect some suboptimal plan with a full scan)';
  ELSE
    RETURN 'Unexpected';
  END IF;
END get_first_rows_candidacy;
/****************************************************************************************/
awr AS (
SELECT x.sql_id,
       get_sql_hv(x.sql_text) AS sql_hv,
       get_first_rows_candidacy(x.sql_text) AS first_rows_candidacy,
       x.sql_text,
       c.name AS pdb_name
  FROM dba_hist_sqltext x, v$containers c
--   OUTER APPLY ( -- super slow!
--          SELECT v.parsing_schema_name
--            FROM dba_hist_sqlstat v
--           WHERE 1 = 1
--             AND v.sql_id = x.sql_id
--             AND v.con_id = x.con_id
--             AND v.dbid = x.dbid
--             AND v.instance_number = TO_NUMBER('&&cs_instance_number.') 
--             AND v.optimizer_cost > 0 -- if 0 or null then whole row is suspected bogus
--           ORDER BY 
--                 v.snap_id DESC NULLS LAST
--           FETCH FIRST 1 ROW ONLY
--        ) v
 WHERE 1 = 1
   AND TO_NUMBER('&&cs_awr_search_days.') > 0
   AND x.dbid = TO_NUMBER('&&cs_dbid.') 
   AND ('&&cs_include_sys.' = 'Y' OR (
       x.sql_text NOT LIKE '/* SQL Analyze(%'
   AND x.sql_text NOT LIKE '%/* cli_%'
   AND x.sql_text NOT LIKE '%/* cs_%'
   AND x.sql_text NOT LIKE '%FUNCTION application_category%'
   AND x.sql_text NOT LIKE '%MATERIALIZE NO_MERGE%'
   AND x.sql_text NOT LIKE '%NO_STATEMENT_QUEUING%'
   AND x.sql_text NOT LIKE 'SELECT /* &&cs_script_name. */%'
   ))
   AND CASE 
         WHEN LENGTH('&&cs_search_string.') = 5 AND TRIM(TRANSLATE('&&cs_search_string.', ' 0123456789', ' ')) IS NULL /* number */ AND TO_CHAR(get_sql_hv(x.sql_text)) = '&&cs_search_string.' THEN 1
         WHEN LENGTH('&&cs_search_string.') = 13 AND TRIM(TRANSLATE('&&cs_search_string.', ' 0123456789', ' ')) IS NOT NULL /* alpha */ AND LOWER('&&cs_search_string.') = '&&cs_search_string.' AND x.sql_id = '&&cs_search_string.' THEN 1
         WHEN UPPER(x.sql_text) LIKE UPPER('%&&cs_search_string.%') THEN 1
        END = 1
--    AND ('&&cs_include_sys.' = 'Y' OR NVL(v.parsing_schema_name, '-666') <> 'SYS') -- super slow!
   AND c.con_id = x.con_id
   AND ROWNUM >= 1 -- materialize
)
/****************************************************************************************/
SELECT /*+ MONITOR GATHER_PLAN_STATISTICS */
       CHR(10)||
       'SQL_HV     : '||sql_hv||CHR(10)||
       'SQL_ID     : '||sql_id||CHR(10)||
       'FIRST_ROWS : '||first_rows_candidacy||CHR(10)||
       'PDB_NAME   : '||pdb_name||CHR(10)||
       CHR(10)||sql_text AS pretty_unique_name 
  FROM awr 
 ORDER BY
       sql_hv, sql_id
/
--
SET HEA ON PAGES 100;
