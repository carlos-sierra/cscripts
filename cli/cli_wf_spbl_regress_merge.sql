MERGE INTO C##IOD.zapper_ignore_sql_text o
  USING (SELECT '/* performScanQuery(REPLICATION_LOG,HashRangeIndex)' AS sql_text,'DBPERF-6545' reference FROM DUAL
          UNION
         SELECT '/* performScanQuery(REPLICATION_LOG_V2,HashRangeIndex)' AS sql_text,'DBPERF-6545' reference FROM DUAL
          UNION
         SELECT 'performScanQuery(leaseDecorators,ae_timestamp_index)%(1 = 1)%ASC' AS sql_text,'DBPERF-7419' reference FROM DUAL
          UNION
         SELECT 'performScanQuery(workflowInstances,I_GC_INDEX)%(1 = 1)%ASC' AS sql_text,'DBPERF-7419' reference FROM DUAL
          UNION
         SELECT 'performScanQuery(futureWork,resumptionTimestamp)%(1 = 1)%ASC' AS sql_text,'DBPERF-7419' reference FROM DUAL
          UNION
         SELECT 'populateBucketGCWorkspace%MAPPING_UPDATES_rgn%ASC' AS sql_text,'DBPERF-7419' reference FROM DUAL
          UNION
         SELECT 'populateBucketGCWorkspace%EVENTS_V2_rgn%ASC' AS sql_text,'DBPERF-7513' reference FROM DUAL
        ) i
  ON (o.sql_text = i.sql_text)
-- WHEN MATCHED THEN
--   UPDATE SET o.reference = i.reference
WHEN NOT MATCHED THEN
  INSERT (sql_text, reference)
  VALUES (i.sql_text, i.reference)
/

COMMIT
/