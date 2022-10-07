DEF hints_text = "FIRST_ROWS(1) OPT_PARAM('_fix_control' '5922070:OFF') LEADING(@SEL$1 KIEV_TABLE_NAME)";
DEF hints_text = "FIRST_ROWS(1) LEADING(@SEL$1 KIEV_TABLE_NAME)";

MERGE INTO C##IOD.zapper_sql_patch_cbo_hints t
  USING (SELECT q'[/* performScanQuery(BACKUPS_TOMBSTONES,HashRangeIndex)%AND (1 = 1)]' AS sql_text, q'[&&hints_text.]' AS hint_text, q'[DBPERF-6821]' AS reference FROM DUAL
         UNION
         SELECT q'[/* performScanQuery(WorkLog_Tombstones,HashRangeIndex)%AND (1 = 1)]' AS sql_text, q'[&&hints_text.]' AS hint_text, q'[DBPERF-6829]' AS reference FROM DUAL
         UNION
         SELECT q'[/* performScanQuery(Img_WorkLog_Tombstones,HashRangeIndex)%AND (1 = 1)]' AS sql_text, q'[&&hints_text.]' AS hint_text, q'[DBPERF-6829]' AS reference FROM DUAL
         UNION
         SELECT q'[/* performScanQuery(VOLUMES_TOMBSTONES,HashRangeIndex)%AND (1 = 1)]' AS sql_text, q'[&&hints_text.]' AS hint_text, q'[DBPERF-6829]' AS reference FROM DUAL
         UNION
         SELECT q'[/* performScanQuery(BootVolume_Tombstones,HashRangeIndex)%AND (1 = 1)]' AS sql_text, q'[&&hints_text.]' AS hint_text, q'[DBPERF-6829]' AS reference FROM DUAL
         UNION
         SELECT q'[/* performScanQuery(Images_Tombstones,HashRangeIndex)%AND (1 = 1)]' AS sql_text, q'[&&hints_text.]' AS hint_text, q'[DBPERF-6829]' AS reference FROM DUAL
         UNION
         SELECT q'[/* performScanQuery(MESSAGE_PAYLOAD,HashRangeIndex)%AND (1 = 1)]' AS sql_text, q'[&&hints_text.]' AS hint_text, q'[DBPERF-6840]' AS reference FROM DUAL
         UNION
         SELECT q'[/* performScanQuery(REPLICATION_LOG,HashRangeIndex)%AND (1 = 1)]' AS sql_text, q'[&&hints_text.]' AS hint_text, q'[DBPERF-7571]' AS reference FROM DUAL
         UNION
         SELECT q'[/* performScanQuery(REPLICATION_LOG_V2,HashRangeIndex)%AND (1 = 1)]' AS sql_text, q'[&&hints_text.]' AS hint_text, q'[DBPERF-7571]' AS reference FROM DUAL
         UNION
         SELECT q'[/* performScanQuery(ID_USER,USER_SCP_OBJNAME)%(scope_id > :4 ) ) ) AND ((scope_id = :5 ))]' AS sql_text, q'[&&hints_text.]' AS hint_text, q'[DBPERF-7810]' AS reference FROM DUAL
         UNION
         SELECT q'[/* performScanQuery(ARCHIVE,arc_date_idx)]' AS sql_text, q'[&&hints_text.]' AS hint_text, q'[DBPERF-7814]' AS reference FROM DUAL
         UNION
         SELECT q'[/* performScanQuery(workflowidempotency,HashRangeIndex)]' AS sql_text, q'[&&hints_text.]' AS hint_text, q'[DBPERF-7824]' AS reference FROM DUAL
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