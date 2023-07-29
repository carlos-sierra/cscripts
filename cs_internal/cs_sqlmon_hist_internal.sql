COL sql_exec_start FOR A19 HEA 'SQL Exec Start';
COL last_refresh_time FOR A19 HEA 'Last Refresh Time';
COL report_id NEW_V report_id FOR 999999999 HEA 'Report ID';
COL status FOR A20 HEA 'Status';
COL duration FOR 999,990 HEA 'Duration';
COL plan_hash FOR 9999999999 HEA 'Plan Hash';
COL elapsed_time FOR 999,990.000 HEA 'Elapsed Time';
COL cpu_time FOR 999,990.000 HEA 'CPU Time';
COL user_io_wait_time FOR 999,990.000 HEA 'User IO Time';
COL concurrency_wait_time FOR 999,990.000 HEA 'Concurrency';
COL application_wait_time FOR 999,990.000 HEA 'Application';
COL plsql_exec_time FOR 999,990.000 HEA 'PL/SQL';
COL user_fetch_count FOR 999,990 HEA 'Fetches';
COL buffer_gets FOR 999,999,999,990 HEA 'Buffer Gets';
COL read_reqs FOR 999,999,990 HEA 'Read Reqs';
COL read_bytes FOR 999,999,999,999,990 HEA 'Read Bytes';
COL sid_serial FOR A15 HEA 'Sid,Serial';
COL pdb_name FOR A30 TRUNC HEA 'PDB Name';
COL user_name FOR A30 TRUNC HEA 'User Name';
COL module FOR A40 TRUNC HEA 'Module';
COL service FOR A40 TRUNC HEA 'Service';
COL program FOR A40 TRUNC HEA 'Program';
COL rn_sql_exec_start FOR 999,990 HEA 'Sta RN';
COL rn_duration FOR 999,990 HEA 'Dur RN';
--
PRO
PRO SQL MONITOR REPORTS (dba_hist_reports) top &&cs_sqlmon_top. and &&cs_sqlmon_top. most recent
PRO ~~~~~~~~~~~~~~~~~~~
WITH
sql_mon_hist_reports AS (
SELECT /*+ OPT_PARAM('_newsort_enabled' 'FALSE') OPT_PARAM('_adaptive_fetch_enabled' 'FALSE') OPT_PARAM('query_rewrite_enabled' 'FALSE') */ /* ORA-00600: internal error code, arguments: [15851], [3], [2], [1], [1] */ 
       r.snap_id, 
       r.dbid, 
       r.instance_number, 
       r.report_id, 
       r.component_id, 
       r.session_id, 
       r.session_serial#, 
       r.period_start_time, 
       r.period_end_time, 
       r.generation_time, 
       r.report_parameters, 
       r.key1                                                                 AS 
       sql_id, 
       r.con_dbid, 
       r.con_id, 
       --xt.sql_id, 
       To_date(xt.sql_exec_start, 'MM/DD/YYYY HH24:MI:SS')                    AS 
       sql_exec_start, 
       ROW_NUMBER() OVER(ORDER BY To_date(xt.sql_exec_start, 'MM/DD/YYYY HH24:MI:SS') DESC NULLS LAST/*, To_number(Extractvalue(Xmltype(r.report_summary), '//stat[@name = "duration"]')) DESC NULLS LAST*/) AS rn_sql_exec_start,
       xt.sql_exec_id, 
       Xmltype(r.report_summary).extract('//status/text()')                   AS 
       status, 
       Xmltype(r.report_summary).extract('//sql_text/text()')                 AS 
       sql_text, 
       To_date(Xmltype(r.report_summary).extract('//first_refresh_time/text()'), 
       'MM/DD/YYYY HH24:MI:SS')                                               AS 
       first_refresh_time, 
       To_date(Xmltype(r.report_summary).extract('//last_refresh_time/text()'), 
       'MM/DD/YYYY HH24:MI:SS')                                               AS 
       last_refresh_time, 
       To_number(Xmltype(r.report_summary).extract('//refresh_count/text()')) AS 
       refresh_count, 
       To_number(Xmltype(r.report_summary).extract('//inst_id/text()'))       AS 
       inst_id, 
       --TO_NUMBER(xmltype(r.report_summary).extract('//session_id/text()')) AS session_id, 
       --TO_NUMBER(xmltype(r.report_summary).extract('//session_serial/text()')) AS session_serial, 
       To_number(Xmltype(r.report_summary).extract('//user_id/text()'))       AS 
       user_id, 
       Xmltype(r.report_summary).extract('//user/text()')                     AS 
       user_name, 
       --TO_NUMBER(xmltype(r.report_summary).extract('//con_id/text()')) AS con_id, 
       Xmltype(r.report_summary).extract('//con_name/text()')                 AS 
       con_name, 
       Xmltype(r.report_summary).extract('//module/text()')                   AS 
       MODULE, 
       Xmltype(r.report_summary).extract('//service/text()')                  AS 
       service, 
       Xmltype(r.report_summary).extract('//program/text()')                  AS 
       program, 
       To_number(Xmltype(r.report_summary).extract('//plan_hash/text()'))     AS 
       plan_hash, 
       Xmltype(r.report_summary).extract('//is_cross_instance/text()')        AS 
       is_cross_instance, 
       To_number(Extractvalue(Xmltype(r.report_summary), 
                 '//stat[@name = "duration"]')) 
                                      AS duration, 
       ROW_NUMBER() OVER(ORDER BY To_number(Extractvalue(Xmltype(r.report_summary), '//stat[@name = "duration"]')) DESC NULLS LAST/*, To_date(xt.sql_exec_start, 'MM/DD/YYYY HH24:MI:SS') DESC NULLS LAST*/) AS rn_duration,
       To_number(Extractvalue(Xmltype(r.report_summary), 
                 '//stat[@name = "elapsed_time"]'))                           AS 
       elapsed_time, 
       To_number(Extractvalue(Xmltype(r.report_summary), 
                 '//stat[@name = "cpu_time"]')) 
                                      AS cpu_time, 
       To_number(Extractvalue(Xmltype(r.report_summary), 
                 '//stat[@name = "user_io_wait_time"]'))                      AS 
       user_io_wait_time, 
       To_number(Extractvalue(Xmltype(r.report_summary), 
                           '//stat[@name = "concurrency_wait_time"]'))        AS 
       concurrency_wait_time, 
       To_number(Extractvalue(Xmltype(r.report_summary), 
                           '//stat[@name = "application_wait_time"]'))        AS 
       application_wait_time, 
       To_number(Extractvalue(Xmltype(r.report_summary), 
                           '//stat[@name = "plsql_exec_time"]'))              AS 
       plsql_exec_time,
       To_number(Extractvalue(Xmltype(r.report_summary), 
                 '//stat[@name = "user_fetch_count"]'))                       AS 
       user_fetch_count, 
       To_number(Extractvalue(Xmltype(r.report_summary), 
                 '//stat[@name = "buffer_gets"]'))                            AS 
       buffer_gets, 
       To_number(Extractvalue(Xmltype(r.report_summary), 
                 '//stat[@name = "read_reqs"]') 
       )                                                                      AS 
       read_reqs, 
       To_number(Extractvalue(Xmltype(r.report_summary), 
                 '//stat[@name = "read_bytes"]' 
                 ))                                                           AS 
       read_bytes 
FROM   cdb_hist_reports r, 
       XMLTABLE('//sql' passing xmltype(r.report_summary) 
       COLUMNS 
              sql_id VARCHAR2(13) path '@sql_id', 
              sql_exec_start VARCHAR2(19) path '@sql_exec_start', 
              sql_exec_id NUMBER path '@sql_exec_id' 
       ) xt 
WHERE  (r.period_end_time BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.') OR r.period_start_time BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.'))
       AND r.component_name = 'sqlmonitor' 
       AND r.report_name = 'main' 
       AND r.key1 = '&&cs_sql_id.' 
-- ORDER BY r.period_end_time - r.period_start_time DESC, r.period_start_time DESC
-- FETCH FIRST &&cs_sqlmon_top. ROWS ONLY
)
SELECT  r.sql_exec_start,
        r.rn_sql_exec_start,
        r.last_refresh_time,
        r.report_id,
        r.status,
        r.plan_hash,
        r.duration,
        r.rn_duration,
        ROUND(r.elapsed_time / POWER(10, 6), 3) AS elapsed_time,
        ROUND(r.cpu_time / POWER(10, 6), 3) AS cpu_time,
        ROUND(r.user_io_wait_time / POWER(10, 6), 3) AS user_io_wait_time,
        ROUND(r.concurrency_wait_time / POWER(10, 6), 3) AS concurrency_wait_time,
        ROUND(r.application_wait_time / POWER(10, 6), 3) AS application_wait_time,
        ROUND(r.plsql_exec_time / POWER(10, 6), 3) AS plsql_exec_time,
        r.user_fetch_count,
        r.buffer_gets,
        r.read_reqs,
        r.read_bytes,
        LPAD(r.session_id,5)||','||r.session_serial# AS sid_serial,
        r.con_name AS pdb_name,
        r.user_name,
        r.module,
        r.program,
        r.service
  FROM  sql_mon_hist_reports r
 WHERE r.rn_sql_exec_start <= &&cs_sqlmon_top. OR r.rn_duration <= &&cs_sqlmon_top.
 ORDER BY
        r.sql_exec_start, r.rn_sql_exec_start
/
