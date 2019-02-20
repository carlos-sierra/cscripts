-- most times sql is in memory, so we get signature and sql_text from v$sqlstats
-- some times sql in v$sqlstats show a signature with value of 0 (e.g. /* populateBucketGCWorkspace */ KPT-35), so we compute signature if 0
BEGIN
  SELECT exact_matching_signature, sql_fulltext INTO :cs_signature, :cs_sql_text FROM v$sqlstats WHERE sql_id = '&&cs_sql_id.' AND ROWNUM = 1;
  IF :cs_signature = 0 THEN
    :cs_signature := DBMS_SQLTUNE.SQLTEXT_TO_SIGNATURE(:cs_sql_text);
  END IF;  
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    :cs_signature := NULL;
    :cs_sql_text := NULL;
END;
/
-- some times sql in v$sqlstats show a signature with value of 0 (e.g. /* populateBucketGCWorkspace */ KPT-35), so we get signature and sql_text from v$sql
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
--
SELECT TO_CHAR(:cs_signature) cs_signature FROM DUAL;
SELECT sql_handle cs_sql_handle FROM dba_sql_plan_baselines WHERE signature = :cs_signature AND ROWNUM = 1;
--
