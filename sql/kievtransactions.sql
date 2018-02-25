WHENEVER SQLERROR EXIT SUCCESS;
PRO
PRO Error "ORA-01476: divisor is equal to zero" just means v$database.open_mode is not "READ WRITE"
SELECT CASE open_mode WHEN 'READ WRITE' THEN open_mode ELSE TO_CHAR(1/0) END open_mode FROM v$database;

SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;

COL pdb_name FOR A30;
COL kt_owner FOR A30;
COL kt_total FOR 999,990.000 HEA 'KT_SPACE|TOTAL|(GBs)';
COL kt_optimal FOR 999,990.000 HEA 'KT_SPACE|OPTIMAL|(GBs)';
COL kt_overhead_percent FOR 990.0 HEA 'KT_OVERHEAD|PERCENT';
COL kt_table FOR 999,990.000 HEA 'KT_SPACE|TABLE|(GBs)';
COL kt_indexes FOR 999,990.000 HEA 'KT_SPACE|INDEXES|(GBs)';
COL num_rows FOR 999,999,999,999;
COL avg_row_len FOR 999,999,999;
COL tablespace_name FOR A30;
COL ts_used_space_gb FOR 999,990.000 HEA 'TABLESPACE|USED_SPACE|(GBs)';
COL kt_ts_percent FOR 990.0 HEA 'KT|PERCENT|TABLESPACE';
COL tablespace_size_gb FOR 999,990.000 HEA 'TABLESPACE|ALLOC_SIZE|(GBs)';
COL ts_used_percent FOR 990.0 HEA 'TABLESPACE|USED|PERCENT';
COL dummy_nopri NOPRI;

BRE ON dummy_nopri;
COMP SUM LAB 'TOTAL' OF kt_total kt_optimal kt_table kt_indexes num_rows ts_used_space_gb tablespace_size_gb ON dummy_nopri;

COL current_time NEW_V current_time FOR A15;
SELECT 'current_time: ' x, TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') current_time FROM DUAL;
COL x_host_name NEW_V x_host_name;
SELECT host_name x_host_name FROM v$instance;
COL x_db_name NEW_V x_db_name;
SELECT name x_db_name FROM v$database;
COL x_container NEW_V x_container;
SELECT 'NONE' x_container FROM DUAL;
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') x_container FROM DUAL;

SPO kievtransactions_&&current_time..txt;
PRO HOST: &&x_host_name.
PRO DATABASE: &&x_db_name.
PRO CONTAINER: &&x_container.

WITH
oem_tablespaces_query AS (
-- this is OEM SQL_ID cudu43xrkjnd2 captured from R1 RGN (replaced hints and added con_id)
SELECT  /*+ MATERIALIZE NO_MERGE */ -- added these hints 
        /* + first_rows */ -- removed hint first_rows
        ts.con_id                               , -- added this column to projection
        pdb.name                                ,
        ts.tablespace_name                      ,
        NVL(t.bytes/1024/1024,0) allocated_space,
        NVL(DECODE(un.bytes,NULL,DECODE(ts.contents,'TEMPORARY', DECODE(ts.extent_management,'LOCAL',u.bytes,t.bytes - NVL(u.bytes, 0)), t.bytes - NVL(u.bytes, 0)), un.bytes)/1024/1024,0) used_space
FROM    cdb_tablespaces ts,
        v$containers pdb  ,
        (
                SELECT  con_id         ,
                        tablespace_name,
                        SUM(bytes) bytes
                FROM    cdb_free_space
                GROUP BY con_id,
                        tablespace_name
                UNION ALL
                SELECT  con_id         ,
                        tablespace_name,
                        NVL(SUM(bytes_used), 0)
                FROM    gv$temp_extent_pool
                GROUP BY con_id,
                        tablespace_name
        )
        u,
        (
                SELECT  con_id         ,
                        tablespace_name,
                        SUM(NVL(bytes, 0)) bytes
                FROM    cdb_data_files
                GROUP BY con_id,
                        tablespace_name
                UNION ALL
                SELECT  con_id         ,
                        tablespace_name,
                        SUM(NVL(bytes, 0)) bytes
                FROM    cdb_temp_files
                GROUP BY con_id,
                        tablespace_name
        )
        t,
        (
                SELECT  ts.con_id         ,
                        ts.tablespace_name,
                        NVL(um.used_space*ts.block_size, 0) bytes
                FROM    cdb_tablespaces ts,
                        cdb_tablespace_usage_metrics um
                WHERE   ts.tablespace_name = um.tablespace_name(+)
                        AND ts.con_id      = um.con_id(+)
                        AND ts.contents    ='UNDO'
        )
        un
WHERE   ts.tablespace_name     = t.tablespace_name(+)
        AND ts.tablespace_name = u.tablespace_name(+)
        AND ts.tablespace_name = un.tablespace_name(+)
        AND ts.con_id          = pdb.con_id
        AND ts.con_id          = u.con_id(+)
        AND ts.con_id          = t.con_id(+)
        AND ts.con_id          = un.con_id(+)
),
appl_tablespaces AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       con_id,
       name pdb_name,
       tablespace_name,
       ROUND(allocated_space/1024, 3) tablespace_size_gb,
       ROUND(used_space/1024, 3) used_space_gb,
       ROUND(100 * used_space / allocated_space, 1) used_percent
  FROM oem_tablespaces_query
 WHERE 1 = 1
   AND tablespace_name NOT IN ('SYSAUX', 'SYSTEM', 'TEMP', 'UNDOTBS1', 'USERS')
),
kievtransactions_seg AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       con_id,
       owner,
       segment_type,
       segment_name,
       tablespace_name,
       bytes
  FROM cdb_segments
 WHERE segment_type IN ('TABLE', 'INDEX')
   AND segment_name LIKE 'KIEVTRANSACTIONS'||CHR(37)
),
kievtransactions_pivot AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       con_id,
       owner,
       tablespace_name,
       SUM(CASE WHEN segment_type = 'TABLE' AND segment_name = 'KIEVTRANSACTIONS' THEN bytes ELSE 0 END) kievtransactions,
       SUM(CASE WHEN segment_type = 'INDEX' AND segment_name = 'KIEVTRANSACTIONS_PK' THEN bytes ELSE 0 END) kievtransactions_pk,
       SUM(CASE WHEN segment_type = 'INDEX' AND segment_name = 'KIEVTRANSACTIONS_AK' THEN bytes ELSE 0 END) kievtransactions_ak,
       SUM(CASE WHEN segment_type = 'INDEX' AND segment_name = 'KIEVTRANSACTIONS_AK2' THEN bytes ELSE 0 END) kievtransactions_ak2,
       SUM(CASE WHEN segment_type = 'INDEX' AND segment_name = 'KIEVTRANSACTIONS_AK3' THEN bytes ELSE 0 END) kievtransactions_ak3
  FROM kievtransactions_seg
 GROUP BY
       con_id,
       owner,
       tablespace_name
),
tables_cdb AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       con_id,
       owner,
       tablespace_name,
       num_rows,
       avg_row_len,
       (num_rows * avg_row_len) optimal_space
  FROM cdb_tables
 WHERE table_name = 'KIEVTRANSACTIONS'
),
kievtransactions_metrics AS (
SELECT s.con_id,
       ts.pdb_name,
       s.tablespace_name,
       ts.tablespace_size_gb,
       ts.used_space_gb,
       ts.used_percent,
       s.owner,
       s.kievtransactions,
       s.kievtransactions_pk,
       s.kievtransactions_ak,
       s.kievtransactions_ak2,
       s.kievtransactions_ak3,
       s.kievtransactions + s.kievtransactions_pk + s.kievtransactions_ak + s.kievtransactions_ak2 + s.kievtransactions_ak3 kievtransactions_tot,
       s.kievtransactions_pk + s.kievtransactions_ak + s.kievtransactions_ak2 + s.kievtransactions_ak3 kievtransactions_idx,
       t.num_rows,
       t.avg_row_len,
       t.optimal_space
  FROM kievtransactions_pivot s,
       tables_cdb t,
       appl_tablespaces ts
 WHERE t.con_id = s.con_id
   AND t.owner = s.owner
   AND t.tablespace_name = s.tablespace_name
   AND ts.con_id = s.con_id
   AND ts.tablespace_name = s.tablespace_name
)
SELECT 1 dummy_nopri,
       ROUND(kievtransactions_tot / POWER(2, 30), 3) kt_total,
       ROUND(optimal_space / POWER(2, 30), 3) kt_optimal,
       ROUND(100 * (kievtransactions_tot - optimal_space) / kievtransactions_tot, 1) kt_overhead_percent,
       ROUND(100 * kievtransactions_tot / POWER(2, 30) / used_space_gb) kt_ts_percent,   
       pdb_name,
       owner kt_owner,
       ROUND(kievtransactions / POWER(2, 30), 3) kt_table,
       ROUND(kievtransactions_idx / POWER(2, 30), 3) kt_indexes,
       num_rows,
       avg_row_len,
       tablespace_name,
       used_space_gb ts_used_space_gb,
       tablespace_size_gb,
       used_percent ts_used_percent
  FROM kievtransactions_metrics
 ORDER BY
       kievtransactions_tot DESC,
       optimal_space DESC,
       used_space_gb DESC,
       pdb_name,
       owner
/

SPO OFF;
