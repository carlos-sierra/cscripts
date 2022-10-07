MERGE INTO C##IOD.zapper_sql_patch_cbo_hints t
  USING (SELECT q'[/* performScanQuery(workRequestIdempotency,HashRangeIndex)]' AS sql_text, q'[FIRST_ROWS(1) OPT_PARAM('_fix_control' '5922070:OFF') LEADING(@SEL$1 KIEV_TABLE_NAME)]' AS hint_text, q'[DBPERF-8480]' AS reference FROM DUAL
         UNION
         SELECT q'[/* performScanQuery(workRequests,wrCmptIdTimeAcceptedIdx)]' AS sql_text, q'[FIRST_ROWS(1) OPT_PARAM('_fix_control' '5922070:OFF') LEADING(@SEL$1 KIEV_TABLE_NAME)]' AS hint_text, q'[DBPERF-8480]' AS reference FROM DUAL
        ) s
  ON (t.sql_text = s.sql_text)
WHEN MATCHED THEN
  UPDATE SET t.hint_text = s.hint_text, t.reference = s.reference
WHEN NOT MATCHED THEN
  INSERT (sql_text, hint_text, reference, creation)
  VALUES (s.sql_text, s.hint_text, s.reference, SYSDATE)
/
COMMIT
/