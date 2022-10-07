DELETE C##IOD.zapper_sprf_export_implement WHERE sql_text_string = 'performScanQuery(WORK_REQUEST,WR_CI_AT_IDX)%AND (compartmentId = :2 )%ASC'
/
MERGE INTO C##IOD.zapper_sql_patch_cbo_hints t
  USING (SELECT q'[/* performScanQuery(WORK_REQUEST,WR_CI_AT_IDX)%AND (compartmentId = :2 )]' AS sql_text, q'[FIRST_ROWS(1) OPT_PARAM('_fix_control' '5922070:OFF') LEADING(@SEL$1 KIEV_TABLE_NAME)]' AS hint_text, q'[DBPERF-8462]' AS reference FROM DUAL
         UNION
         SELECT q'[/* performScanQuery(WORK_REQUEST,HashRangeIndex)]' AS sql_text, q'[FIRST_ROWS(1) OPT_PARAM('_fix_control' '5922070:OFF') LEADING(@SEL$1 KIEV_TABLE_NAME)]' AS hint_text, q'[DBPERF-8462]' AS reference FROM DUAL
         UNION
         SELECT q'[/* performScanQuery(WORK_REQUEST_RESOURCE,HashRangeIndex)]' AS sql_text, q'[FIRST_ROWS(1) OPT_PARAM('_fix_control' '5922070:OFF') LEADING(@SEL$1 KIEV_TABLE_NAME)]' AS hint_text, q'[DBPERF-8482]' AS reference FROM DUAL
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