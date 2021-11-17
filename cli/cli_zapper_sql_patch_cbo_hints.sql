SET FEED ON;
--
MERGE INTO C##IOD.zapper_sql_patch_cbo_hints t
  USING (SELECT q'[/* performScanQuery(workflowInstances,I_GC_INDEX)%AND (1 = 1)]' AS sql_text, q'[FIRST_ROWS(1) OPT_PARAM('_fix_control' '5922070:OFF')]' AS hint_text, q'[DBPERF-6724]' AS reference FROM DUAL
         UNION
         SELECT q'[/* performScanQuery(BACKUPS_TOMBSTONES,HashRangeIndex)%AND (1 = 1)]' AS sql_text, q'[FIRST_ROWS(1) OPT_PARAM('_fix_control' '5922070:OFF')]' AS hint_text, q'[DBPERF-6821]' AS reference FROM DUAL
         UNION
         SELECT q'[/* performScanQuery(WorkLog_Tombstones,HashRangeIndex)%AND (1 = 1)]' AS sql_text, q'[FIRST_ROWS(1) OPT_PARAM('_fix_control' '5922070:OFF')]' AS hint_text, q'[DBPERF-6829]' AS reference FROM DUAL
         UNION
         SELECT q'[/* performScanQuery(Img_WorkLog_Tombstones,HashRangeIndex)%AND (1 = 1)]' AS sql_text, q'[FIRST_ROWS(1) OPT_PARAM('_fix_control' '5922070:OFF')]' AS hint_text, q'[DBPERF-6829]' AS reference FROM DUAL
         UNION
         SELECT q'[/* performScanQuery(VOLUMES_TOMBSTONES,HashRangeIndex)%AND (1 = 1)]' AS sql_text, q'[FIRST_ROWS(1) OPT_PARAM('_fix_control' '5922070:OFF')]' AS hint_text, q'[DBPERF-6829]' AS reference FROM DUAL
         UNION
         SELECT q'[/* performScanQuery(BootVolume_Tombstones,HashRangeIndex)%AND (1 = 1)]' AS sql_text, q'[FIRST_ROWS(1) OPT_PARAM('_fix_control' '5922070:OFF')]' AS hint_text, q'[DBPERF-6829]' AS reference FROM DUAL
         UNION
         SELECT q'[/* performScanQuery(Images_Tombstones,HashRangeIndex)%AND (1 = 1)]' AS sql_text, q'[FIRST_ROWS(1) OPT_PARAM('_fix_control' '5922070:OFF')]' AS hint_text, q'[DBPERF-6829]' AS reference FROM DUAL
         UNION
         SELECT q'[/* performScanQuery(MESSAGE_PAYLOAD,HashRangeIndex)%AND (1 = 1)]' AS sql_text, q'[FIRST_ROWS(1) OPT_PARAM('_fix_control' '5922070:OFF')]' AS hint_text, q'[DBPERF-6840]' AS reference FROM DUAL
        ) s
  ON (t.sql_text = s.sql_text)
WHEN MATCHED THEN
  UPDATE SET t.hint_text = s.hint_text, t.reference = s.reference
WHEN NOT MATCHED THEN
  INSERT (sql_text, hint_text, reference, creation)
  VALUES (s.sql_text, s.hint_text, s.reference, SYSDATE)
/
--
COMMIT
/