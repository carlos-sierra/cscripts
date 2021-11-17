SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
--
COL table_owner FOR A30;
COL table_name FOR A30;
COL index_name FOR A30;
--
SELECT ic.table_owner, ic.table_name, ic.index_name, t.num_rows, t.last_analyzed
  FROM dba_ind_columns ic, dba_tables t
 WHERE ic.column_name = 'KIEVTXNID'
   AND ic.column_position = 1
   AND ic.index_name NOT LIKE '%KTI'
   AND ic.table_name NOT LIKE 'KIEV_S_%'
   AND t.owner = ic.table_owner
   AND t.table_name = ic.table_name
ORDER BY ic.table_owner, ic.table_name, ic.index_name
/
--
TABLE_OWNER                    TABLE_NAME                     INDEX_NAME                                 NUM_ROWS LAST_ANALYZED
------------------------------ ------------------------------ ------------------------------ -------------------- -------------------
VCNRGNR1                       DPMSGREMOVALQUEUE_RGN          DP_MESSAGE_NDX                                 5838 2021-09-13T15:42:08
VCNRGNR1                       ENTITY_CHANGE_EVENTS_RGN       SEQ_ENTITY_CHANGE_IDX                         61909 2021-09-13T15:42:16
VCNRGNR1                       EVENTS_RGN                     SEQ_EVENT_IDX                                 33118 2021-09-13T15:42:12
VCNRGNR1                       EVENTS_V2_RGN                  SEQ_EVENT_NDX                                533073 2021-09-02T22:09:48
VCNRGNR1                       MAPPINGSAD1_RGN                AD1MAPPINGSIDX                                    2 2021-06-11T21:08:42
VCNRGNR1                       MAPPINGSAD2_RGN                AD2MAPPINGSIDX                                    4 2021-06-11T19:13:16
VCNRGNR1                       MAP_STATUS_RGN                 SEQNUM_TO_MAP_STATUS_NDX                    6773314 2021-09-13T15:42:32
VCNRGNR1                       MAP_UPDATES_RGN                SEQNUM_TO_MAP_UPDATE_NDX                    1451125 2021-09-13T15:42:16
VCNRGNR1                       REPL_SRC_RGN                   PROPINPUTIDX                                   1133 2016-12-10T06:01:12
--

@cs_fs 'populateBucketGCWorkspace%MAP_STATUS_RGN';