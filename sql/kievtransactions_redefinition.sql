SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;

COL x_container NEW_V x_container;
SELECT 'NONE' x_container FROM DUAL;
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') x_container FROM DUAL;

COL owner FOR A30;
COL segment_name FOR A30;
COL size_gbs FOR 999,990.000;
COL kt_owner NEW_V kt_owner FOR A30;
COL kt_size_gbs FOR 999,990.000;
COL tablespace_name FOR A30;
COL free_percent FOR 990.0 HEA 'FREE|PERCENT';
COL free_space_gb FOR 999,990.000 HEA 'FREE_SPACE|(GBs)';
COL used_percent FOR 990.0 HEA 'USED|PERCENT';
COL used_space_gb FOR 999,990.000 HEA 'USED_SPACE|(GBs)';
COL tablespace_size_gb FOR 999,990.000 HEA 'ALLOC_SIZE|(GBs)';
COL optimal_space_gb FOR 999,990.000 HEA 'OPTIMAL|SPACE|(GBs)';
COL free_space_required_gb FOR 999,990.000 HEA 'FREE|SPACE|REQUIRED|(GBs)';

SELECT owner,
       segment_name,
       ROUND(bytes / POWER(2, 30), 3) size_gbs
  FROM dba_segments
 WHERE segment_name LIKE 'KIEVTRANSACTIONS%'
   AND segment_type IN ('TABLE', 'INDEX')
 ORDER BY
       owner,
       segment_name
/

SELECT ROUND(bytes / POWER(2, 30), 3) kt_size_gbs,
       owner kt_owner
  FROM dba_segments
 WHERE segment_name = 'KIEVTRANSACTIONS'
   AND segment_type = 'TABLE'
 ORDER BY
       bytes DESC
/

COL tablespace_name NEW_V tablespace_name;
SELECT tablespace_name, owner kt_owner
  FROM dba_segments
 WHERE segment_name = 'KIEVTRANSACTIONS'
   AND segment_type = 'TABLE'
   AND owner = UPPER(TRIM('&owner.'))
/

SPO kievtransactions_redefinition_&&x_container._&&kt_owner..txt;

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
usage_metrics AS (
SELECT SUBSTR(c.pdb_name, 1, 30) pdb_name,
       m.tablespace_name,
       ROUND(m.tablespace_size * p.block_size / POWER(2,30), 3) tablespace_size_gb,
       ROUND(m.used_space * p.block_size / POWER(2,30), 3) used_space_gb,
       ROUND(m.used_percent, 1) used_percent,
       m.tablespace_size,
       m.used_space
  FROM cdb_tablespace_usage_metrics m,
       cdb_pdbs c,
       cdb_tablespaces p
 WHERE 1 = 1
   --AND m.tablespace_name NOT IN ('SYSAUX', 'SYSTEM', 'TEMP', 'UNDOTBS1', 'USERS')
   AND c.con_id = m.con_id
   AND p.con_id = m.con_id
   AND p.tablespace_name = m.tablespace_name
)
SELECT --o.name pdb_name,
       o.tablespace_name,
       ROUND((o.allocated_space - o.used_space)/1024, 3) free_space_gb,
       ROUND(o.used_space/1024, 3) used_space_gb,
       ROUND(o.allocated_space/1024, 3) tablespace_size_gb,
       ROUND(100 * (o.allocated_space - o.used_space) / o.allocated_space, 1) free_percent,
       ROUND(100 * o.used_space / o.allocated_space, 1) used_percent
       --m.used_percent max_used_percent,
       --m.used_space_gb max_used_space_gb,
       --m.tablespace_size_gb max_tablespace_size_gb
  FROM oem_tablespaces_query o,
       usage_metrics m
 WHERE m.pdb_name = o.name
   AND m.tablespace_name = o.tablespace_name
   AND o.tablespace_name = '&&tablespace_name.'
 ORDER BY
       o.name,
       o.tablespace_name
/

SELECT ROUND(1 * num_rows * avg_row_len / POWER(2, 30), 3) optimal_space_gb,
       ROUND(3 * num_rows * avg_row_len / POWER(2, 30), 3) free_space_required_gb
  FROM dba_tables
 WHERE owner = '&&kt_owner.'
   AND table_name = 'KIEVTRANSACTIONS'
/

PRO 
PRO Verify TABLESPACE FREE_SPACE > FREE SPACE REQUIRED then hit return key, else <ctrl>-c
PAUSE 

SELECT segment_name,
       ROUND(bytes / POWER(2, 30), 3) size_gbs
  FROM dba_segments
 WHERE segment_name LIKE 'KIEVTRANSACTIONS%'
   AND segment_type IN ('TABLE', 'INDEX')
   AND owner = '&&kt_owner.'
 ORDER BY
       segment_name
/

COL sysdate_before NEW_V sysdate_before;
SELECT TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS') sysdate_before FROM DUAL;

ALTER SESSION SET tracefile_identifier = '&&x_container._&&kt_owner.';
ALTER SESSION SET EVENTS '10046 TRACE NAME CONTEXT FOREVER, LEVEL 12';
EXEC DBMS_REDEFINITION.REDEF_TABLE(uname=>'&&kt_owner.', tname=>'KIEVTRANSACTIONS', table_part_tablespace=>'&&tablespace_name.');
ALTER SESSION SET SQL_TRACE = FALSE;

COL sysdate_after NEW_V sysdate_after;
SELECT TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS') sysdate_after FROM DUAL;

SELECT segment_name,
       ROUND(bytes / POWER(2, 30), 3) size_gbs
  FROM dba_segments
 WHERE segment_name LIKE 'KIEVTRANSACTIONS%'
   AND segment_type IN ('TABLE', 'INDEX')
   AND owner = '&&kt_owner.'
 ORDER BY
       segment_name
/

COL trace NEW_V trace;
SELECT value trace FROM v$diag_info WHERE name = 'Default Trace File';
HOS cp &&trace. .
HOS tkprof &&trace. tkprof_&&x_container._&&kt_owner..txt
HOS tkprof &&trace. tkprof_sort_&&x_container._&&kt_owner..txt sort=prsela exeela fchela 

SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
SET PAGES 200;

COL current_time NEW_V current_time FOR A15;
SELECT 'current_time: ' x, TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') current_time FROM DUAL;
COL x_host_name NEW_V x_host_name;
SELECT host_name x_host_name FROM v$instance;
COL x_db_name NEW_V x_db_name;
SELECT name x_db_name FROM v$database;
COL x_container NEW_V x_container;
SELECT 'NONE' x_container FROM DUAL;
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') x_container FROM DUAL;
COL num_cpu_cores NEW_V num_cpu_cores;
SELECT TO_CHAR(value) num_cpu_cores FROM v$osstat WHERE stat_name = 'NUM_CPU_CORES';

CL BREAK
COL sql_text_100_only FOR A100 HEA 'SQL Text';
COL sample_date_time FOR A20 HEA 'Sample Date and Time';
COL samples FOR 9999,999 HEA 'Sessions';
COL on_cpu_or_wait_class FOR A14 HEA 'ON CPU or|Wait Class';
COL on_cpu_or_wait_event FOR A50 HEA 'ON CPU or Timed Event';
COL session_serial FOR A16 HEA 'Session,Serial';
COL blocking_session_serial FOR A16 HEA 'Blocking|Session,Serial';
COL machine FOR A60 HEA 'Application Server';
COL con_id FOR 999999;
COL plans FOR 99999 HEA 'Plans';
COL sessions FOR 9999,999 HEA 'Sessions|this SQL';

--SPO ash_mem_sample_&&current_time..txt;
PRO HOST: &&x_host_name.
PRO CORES: &&num_cpu_cores.
PRO DATABASE: &&x_db_name.
PRO CONTAINER: &&x_container.
PRO SAMPLE_TIME_FROM: &&sysdate_before.
PRO SAMPLE_TIME_TO: &&sysdate_after.

PRO
PRO ASH spikes by sample time and top SQL (spikes higher than &&num_cpu_cores. cores)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

WITH 
ash_by_sample_and_sql AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.sample_time,
       h.sql_id,
       h.con_id,
       COUNT(*) samples,
       COUNT(DISTINCT h.sql_plan_hash_value) plans,
       ROW_NUMBER () OVER (PARTITION BY h.sample_time ORDER BY COUNT(*) DESC NULLS LAST, h.sql_id) row_number
  FROM v$active_session_history h
 WHERE CAST(h.sample_time AS DATE) BETWEEN TO_DATE('&&sysdate_before.', 'YYYY-MM-DD"T"HH24:MI:SS') AND TO_DATE('&&sysdate_after.', 'YYYY-MM-DD"T"HH24:MI:SS')
 GROUP BY
       h.sample_time,
       h.sql_id,
       h.con_id
)
SELECT TO_CHAR(CAST(h.sample_time AS DATE), 'YYYY-MM-DD"T"HH24:MI:SS') sample_date_time,
       SUM(h.samples) samples,
       MAX(CASE h.row_number WHEN 1 THEN h.sql_id END) sql_id,
       SUM(CASE h.row_number WHEN 1 THEN h.samples ELSE 0 END) sessions,
       MAX(CASE WHEN h.row_number = 1 AND h.sql_id IS NOT NULL THEN h.plans END) plans,
       MAX(CASE h.row_number WHEN 1 THEN h.con_id END) con_id,       
       MAX(CASE WHEN h.row_number = 1 AND h.sql_id IS NOT NULL THEN (SELECT SUBSTR(q.sql_text, 1, 100) FROM v$sql q WHERE q.sql_id = h.sql_id AND ROWNUM = 1) END) sql_text_100_only
  FROM ash_by_sample_and_sql h
 GROUP BY
       h.sample_time
HAVING SUM(h.samples) >= &&num_cpu_cores.
 ORDER BY
       h.sample_time
/

PRO
PRO ASH by sample time and top SQL
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

WITH 
ash_by_sample_and_sql AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.sample_time,
       h.sql_id,
       h.con_id,
       COUNT(*) samples,
       COUNT(DISTINCT h.sql_plan_hash_value) plans,
       ROW_NUMBER () OVER (PARTITION BY h.sample_time ORDER BY COUNT(*) DESC NULLS LAST, h.sql_id) row_number
  FROM v$active_session_history h
 WHERE CAST(h.sample_time AS DATE) BETWEEN TO_DATE('&&sysdate_before.', 'YYYY-MM-DD"T"HH24:MI:SS') AND TO_DATE('&&sysdate_after.', 'YYYY-MM-DD"T"HH24:MI:SS')
 GROUP BY
       h.sample_time,
       h.sql_id,
       h.con_id
)
SELECT TO_CHAR(CAST(h.sample_time AS DATE), 'YYYY-MM-DD"T"HH24:MI:SS') sample_date_time,
       SUM(h.samples) samples,
       MAX(CASE h.row_number WHEN 1 THEN h.sql_id END) sql_id,
       SUM(CASE h.row_number WHEN 1 THEN h.samples ELSE 0 END) sessions,
       MAX(CASE WHEN h.row_number = 1 AND h.sql_id IS NOT NULL THEN h.plans END) plans,
       MAX(CASE h.row_number WHEN 1 THEN h.con_id END) con_id,       
       MAX(CASE WHEN h.row_number = 1 AND h.sql_id IS NOT NULL THEN (SELECT SUBSTR(q.sql_text, 1, 100) FROM v$sql q WHERE q.sql_id = h.sql_id AND ROWNUM = 1) END) sql_text_100_only
  FROM ash_by_sample_and_sql h
 GROUP BY
       h.sample_time
 ORDER BY
       h.sample_time
/

BREAK ON sample_date_time SKIP 1;
PRO
PRO ASH by sample time, SQL_ID and timed class
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

SELECT TO_CHAR(CAST(h.sample_time AS DATE), 'YYYY-MM-DD"T"HH24:MI:SS') sample_date_time,
       COUNT(*) samples, 
       h.sql_id, 
       h.con_id,
       CASE h.session_state WHEN 'ON CPU' THEN h.session_state ELSE h.wait_class END on_cpu_or_wait_class,
       (SELECT SUBSTR(q.sql_text, 1, 100) FROM v$sql q WHERE q.sql_id = h.sql_id AND q.con_id = h.con_id AND ROWNUM = 1) sql_text_100_only
  FROM v$active_session_history h
 WHERE CAST(h.sample_time AS DATE) BETWEEN TO_DATE('&&sysdate_before.', 'YYYY-MM-DD"T"HH24:MI:SS') AND TO_DATE('&&sysdate_after.', 'YYYY-MM-DD"T"HH24:MI:SS')
 GROUP BY
       CAST(h.sample_time AS DATE),
       h.sql_id, 
       h.con_id,
       CASE h.session_state WHEN 'ON CPU' THEN h.session_state ELSE h.wait_class END
 ORDER BY
       CAST(h.sample_time AS DATE),
       samples DESC,
       h.sql_id,
       h.con_id,
       CASE h.session_state WHEN 'ON CPU' THEN h.session_state ELSE h.wait_class END
/

BREAK ON sample_date_time SKIP PAGE ON machine SKIP 1;
PRO
PRO ASH by sample time, appl server, session and SQL_ID
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

SELECT TO_CHAR(CAST(h.sample_time AS DATE), 'YYYY-MM-DD"T"HH24:MI:SS') sample_date_time,
       h.machine,
       h.session_id||','||h.session_serial# session_serial,
       h.blocking_session||','||h.blocking_session_serial# blocking_session_serial,
       h.sql_id,
       h.sql_plan_hash_value,
       h.sql_child_number,
       h.sql_exec_id,
       h.con_id,
       CASE h.session_state WHEN 'ON CPU' THEN h.session_state ELSE h.wait_class||' - '||h.event END on_cpu_or_wait_event,
       (SELECT SUBSTR(q.sql_text, 1, 100) FROM v$sql q WHERE q.sql_id = h.sql_id AND q.con_id = h.con_id AND ROWNUM = 1) sql_text_100_only,
       h.current_obj#,
       h.current_file#,
       h.current_block#,
       h.current_row#,
       h.in_parse,
       h.in_hard_parse
  FROM v$active_session_history h
 WHERE CAST(h.sample_time AS DATE) BETWEEN TO_DATE('&&sysdate_before.', 'YYYY-MM-DD"T"HH24:MI:SS') AND TO_DATE('&&sysdate_after.', 'YYYY-MM-DD"T"HH24:MI:SS')
 ORDER BY
       CAST(h.sample_time AS DATE),
       h.machine,
       h.session_id,
       h.session_serial#,
       h.sql_id
/

SPO OFF;



