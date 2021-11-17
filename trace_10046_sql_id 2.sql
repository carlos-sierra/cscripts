-- trace_10046_sql_id.sql - Turn ON and OFF SQL Trace EVENT 10046 LEVEL 12 on given SQL_ID
SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
PRO
PRO 1. SQL_ID:
DEF sql_id = '&1.';
UNDEF 1;
--
COL host_name NEW_V host_name NOPRI;
COL trace_dir NEW_V trace_dir NOPRI;
SELECT host_name, value AS trace_dir FROM v$instance, v$diag_info WHERE name = 'Diag Trace';
--
ALTER SYSTEM SET EVENTS='RDBMS.sql_trace off' ;
ALTER SYSTEM SET EVENTS='RDBMS.sql_trace[SQL:&&sql_id.] {occurence: start_after 1, end_after 101} plan_stat=all_executions, bind=true, wait=true' ;
PRO
PAUSE Tracing &&sql_id.. Press RETURN to stop tracing (after enought time for &&sql_id. to execute).
PRO
ALTER SYSTEM SET EVENTS='RDBMS.sql_trace[SQL:&&sql_id.] off' ;
--
HOS mkdir -p /tmp/SQL_ID_&&sql_id.
--*/
PRO please wait...
HOS find &&trace_dir./ -mmin -60 | grep trc | xargs grep -i "sqlid='&&sql_id.'" | awk -F: '{print $1}' | sort | uniq | xargs -I{} mv "{}" /tmp/SQL_ID_&&sql_id.
--*/
HOS rename ora EVENT_10046_&&sql_id. /tmp/SQL_ID_&&sql_id./*ora*.trc
--*/
HOS chmod 644 /tmp/SQL_ID_&&sql_id./*EVENT_10046_&&sql_id.*.trc
--*/
HOS ls -lt /tmp/SQL_ID_&&sql_id./*EVENT_10046_&&sql_id.*.trc
--*/
PRO
PRO If you want to preserve traces, execute scp command below, from a TERM session running on your Mac/PC:
PRO scp &&host_name.:/tmp/SQL_ID_&&sql_id./*EVENT_10046_&&sql_id.*.trc .
--*/
PRO