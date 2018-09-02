-- most times sql is in memory, so we get signature and sql_text from v$sql
BEGIN
  SELECT exact_matching_signature, sql_fulltext INTO :cs_signature, :cs_sql_text FROM v$sql WHERE sql_id = '&&cs_sql_id.' AND ROWNUM = 1;
END;
/
-- sometimes sql is not in memory but on awr, so we get sql_text from awr and we compute signature
BEGIN
  IF :cs_signature IS NULL THEN
    SELECT sql_text INTO :cs_sql_text FROM dba_hist_sqltext WHERE sql_id = '&&cs_sql_id.' AND ROWNUM = 1;
    :cs_signature := DBMS_SQLTUNE.SQLTEXT_TO_SIGNATURE(:cs_sql_text);
  END IF;
END;
/
--
SELECT TO_CHAR(:cs_signature) cs_signature FROM DUAL;
SELECT sql_handle cs_sql_handle FROM dba_sql_plan_baselines WHERE signature = :cs_signature AND ROWNUM = 1;
--
