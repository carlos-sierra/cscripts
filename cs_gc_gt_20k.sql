SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
--
COL owner FOR A30;
COL table_name FOR A30;
COL region_acronym FOR A6 HEA 'REGION';
COL num_rows FOR 999,999,999,990;
COL size_gb FOR 999,990.0;
--
SPO /tmp/cs_gc_gt_20k_rows.txt
SELECT num_rows,
       blocks * 1024 * 8 / POWER(10,9) AS size_gb,
       db_name,
       pdb_name,
       region_acronym,
       locale,
       owner,
       table_name,
       gc_status,
       host_name
  FROM c##iod.gc_gt_20k
 WHERE version = TO_DATE('2021-04-30', 'YYYY-MM-DD')
   AND num_rows > POWER(10,6)
 ORDER BY
       num_rows DESC, blocks DESC
/
SPO OFF;
--
SPO /tmp/cs_gc_gt_20k_pdb.txt
SELECT pdb_name,
       owner,
       table_name,
       num_rows,
       blocks * 1024 * 8 / POWER(10,9) AS size_gb,
       db_name,
       region_acronym,
       locale,
       gc_status,
       host_name
  FROM c##iod.gc_gt_20k
 WHERE version = TO_DATE('2021-04-30', 'YYYY-MM-DD')
   AND num_rows > POWER(10,6)
 ORDER BY
       pdb_name, owner, table_name, num_rows DESC, blocks DESC
/
SPO OFF;
--
SPO /tmp/cs_gc_gt_20k_storage.txt
SELECT pdb_name,
       owner,
       table_name,
       num_rows,
       blocks * 1024 * 8 / POWER(10,9) AS size_gb,
       db_name,
       region_acronym,
       locale,
       gc_status,
       host_name
  FROM c##iod.gc_gt_20k
 WHERE version = TO_DATE('2021-04-30', 'YYYY-MM-DD')
   --AND num_rows > POWER(10,6)
   AND table_name IN (
'ADAPTIVE_CLONES',
'BACKUPS_TOMBSTONES',
'BACKUP_BOOTVOLMETA_TOMB',
'BACKUP_COPY_EVENTS',
'BACKUP_COPY_HISTORY',
'COMPARTMENT_USAGE',
'RETRYTOKENSNEW',
'TENANT_USAGE_AUDIT',
'VOLGRP_BACKUPS_TOMBSTONE',
'BACKUP_GBHOUR_METERING_V2',
'ATTACHMENTS_HISTORY',
'WORKLOG_TOMBSTONES',
'BSFD_JOB_HISTORY',
'BOOTVOLUMESMETADATA',
'VOLUMES_TOMBSTONES',
'VOL_RECLAIM_AUDIT',
'BOOTVOLUME_TOMBSTONES',
'IMG_WORKLOG_IDX',
'IMG_WORKLOG_TOMBSTONES'
   )
 ORDER BY
       pdb_name, owner, table_name, num_rows DESC, blocks DESC
/
SPO OFF;
