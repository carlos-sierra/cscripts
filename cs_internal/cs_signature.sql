COL cs_signature NEW_V cs_signature FOR A20 NOPRI;
COL cs_normalized_signature NEW_V cs_normalized_signature FOR A20 NOPRI;
COL cs_sqlid NEW_V cs_sqlid FOR A5 NOPRI;
COL cs_sql_handle NEW_V cs_sql_handle FOR A20 NOPRI;
DEF cs_parsing_schema_name = '';
COL cs_parsing_schema_name NEW_V cs_parsing_schema_name FOR A128 NOPRI;
--
VAR cs_signature NUMBER;
VAR cs_sql_text CLOB;
VAR cs_sql_text_1000 VARCHAR2(1000);
VAR cs_parsing_schema_name VARCHAR2(128);
--
-- some times sql in v$sqlstats show a signature with value of 0 (e.g. /* populateBucketGCWorkspace */ KPT-35), so we get signature and sql_text from v$sql
BEGIN
  IF :cs_signature IS NULL THEN
    SELECT exact_matching_signature, sql_fulltext, parsing_schema_name INTO :cs_signature, :cs_sql_text, :cs_parsing_schema_name FROM v$sql WHERE sql_id = '&&cs_sql_id.' AND ROWNUM = 1;
    IF :cs_signature = 0 THEN
      :cs_signature := DBMS_SQLTUNE.SQLTEXT_TO_SIGNATURE(:cs_sql_text);
    END IF;  
  END IF;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    :cs_signature := NULL;
    :cs_sql_text := NULL;
    :cs_parsing_schema_name := NULL;
END;
/
-- sometimes sql is not in memory but on awr, so we get sql_text from awr and we compute signature
BEGIN
  IF :cs_signature IS NULL THEN
    SELECT sql_text INTO :cs_sql_text FROM dba_hist_sqltext WHERE sql_id = '&&cs_sql_id.' AND ROWNUM = 1;
    :cs_signature := DBMS_SQLTUNE.SQLTEXT_TO_SIGNATURE(:cs_sql_text);
  END IF;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    :cs_signature := NULL;
    :cs_sql_text := NULL;
END;
/
-- most times sql is in memory, so we get signature and sql_text from v$sqlstats
-- some times sql in v$sqlstats show a signature with value of 0 (e.g. /* populateBucketGCWorkspace */ KPT-35), so we compute signature if 0
-- moving this block to end
BEGIN
  IF :cs_signature IS NULL THEN
    SELECT exact_matching_signature, sql_fulltext INTO :cs_signature, :cs_sql_text FROM v$sqlstats WHERE sql_id = '&&cs_sql_id.' AND ROWNUM = 1;
    IF :cs_signature = 0 THEN
      :cs_signature := DBMS_SQLTUNE.SQLTEXT_TO_SIGNATURE(:cs_sql_text);
    END IF;  
  END IF;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    :cs_signature := NULL;
    :cs_sql_text := NULL;
END;
/
-- next we try to get signature from an existing sql plan baseline
BEGIN
  IF :cs_signature IS NULL THEN
    SELECT signature, sql_text, parsing_schema_name INTO :cs_signature, :cs_sql_text, :cs_parsing_schema_name FROM dba_sql_plan_baselines WHERE SUBSTR(description, INSTR(description, 'SQL_ID=') + 7, 13) = '&&cs_sql_id.' AND ROWNUM = 1;
    IF :cs_signature = 0 THEN
      :cs_signature := DBMS_SQLTUNE.SQLTEXT_TO_SIGNATURE(:cs_sql_text);
    END IF;  
  END IF;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    :cs_signature := NULL;
    :cs_sql_text := NULL;
    :cs_parsing_schema_name := NULL;
END;
/
-- get first 1000 
BEGIN
  :cs_sql_text_1000 :=  SUBSTR(REGEXP_REPLACE(:cs_sql_text, '[^[:print:]]', ''), 1, 1000);
END;
/
-- compute cs_normalized_signature
SELECT DBMS_SQLTUNE.sqltext_to_signature(REPLACE(CASE WHEN :cs_sql_text LIKE '/* %(%,%)% [____] */%' THEN REGEXP_REPLACE(:cs_sql_text, '\[([[:digit:]]{4})\] ') ELSE :cs_sql_text END,:cs_parsing_schema_name)) AS cs_normalized_signature FROM DUAL
/
SELECT LPAD(MOD(TO_NUMBER('&&cs_normalized_signature.'),100000),5,'0') AS cs_sqlid FROM DUAL
/ 
--
SELECT TO_CHAR(:cs_signature) AS cs_signature FROM DUAL;
SELECT sql_handle AS cs_sql_handle FROM dba_sql_plan_baselines WHERE signature = :cs_signature AND ROWNUM = 1;
SELECT :cs_parsing_schema_name AS cs_parsing_schema_name FROM DUAL;
--
DEF cs_application_category = 'UN';
COL cs_application_category NEW_V cs_application_category NOPRI;
COL dummy NOPRI;
@@&&cs_set_container_to_cdb_root.
SELECT dummy
       &&cs_skip.,&&cs_tools_schema..IOD_SPM.application_category(p_sql_text => DBMS_LOB.substr(:cs_sql_text, 1000)) AS cs_application_category 
  FROM DUAL
/
@@&&cs_set_container_to_curr_pdb.
--
DEF cs_kiev_table_name = '';
COL cs_kiev_table_name NEW_V cs_kiev_table_name NOPRI;
SELECT SUBSTR(:cs_sql_text, INSTR(:cs_sql_text, '(') + 1, INSTR(:cs_sql_text, ',') - INSTR(:cs_sql_text, '(') - 1) AS cs_kiev_table_name FROM DUAL WHERE :cs_sql_text LIKE '%performScanQuery%';
--