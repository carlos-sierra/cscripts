----------------------------------------------------------------------------------------
--
-- File name:   cs_blocked_sessions_ash_awr_report.sql
--
-- Purpose:     Top Session Blockers by multiple Dimensions as per ASH from AWR (text report)
--
-- Author:      Carlos Sierra
--
-- Version:     2021/01/17
--
-- Usage:       Execute connected to CDB or PDB
--
--              Enter range of dates and filters when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_blocked_sessions_ash_awr_report.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_blocked_sessions_ash_awr_report';
DEF cs_hours_range_default = '24';
DEF cs_top_n = '20';
DEF cs_min_perc = '0.1';
--
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
--ALTER SESSION SET container = CDB$ROOT;
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." 
@@cs_internal/cs_spool_id.sql
--
@@cs_internal/cs_spool_id_sample_time.sql
--
COL time FOR A19 HEA 'SAMPLE TIME';
COL blocked FOR 999,990 HEA 'BLOCKED|SESSIONS|COUNT';
COL percent FOR 999,990.000 HEA 'CONTRIBUTION|PERCENT %'
COL blocker FOR A12 HEA 'ROOT|BLOCKER|SID_SERIAL#';
COL blocker_machine FOR A64 HEA 'ROOT BLOCKER MACHINE';
COL blocker_module FOR A64 HEA 'ROOT BLOCKER MODULE';
COL blocker_status FOR A80 HEA 'ROOT BLOCKER TIMED EVENT';
COL blocker_sql_id FOR A13 HEA 'ROOT|BLOCKER|SQL_ID';
COL blocker_sql_text FOR A80 TRUNC HEA 'ROOT BLOCKER SQL_TEXT';
COL wait_class_event FOR A80 TRUNC HEA 'BLOCKEE(S) WAIT CLASS AND EVENT';
--
BREAK ON REPORT;
COMPUTE SUM OF percent ON REPORT;
--
PRO
PRO Root Blocker contribution percent by SQL_ID (between &&cs_sample_time_from. and &&cs_sample_time_to. UTC)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SET TERM OFF;
GET cs_internal/cs_blocked_sessions_ash_awr_internal.sql NOLIST
.
666666 ,
666666 detail AS (
666666 SELECT /*+ MATERIALIZE NO_MERGE */
666666        b.time,
666666        b.sessions_blocked blocked,
666666        b.blocker_session_id||','||b.blocker_session_serial# blocker,
666666        b.machine blocker_machine,
666666        CASE b.blocker_status WHEN 'INACTIVE or UNKNOWN' THEN (CASE b.machine WHEN '&&cs_host_name.' THEN 'UNKNOWN' ELSE 'INACTIVE' END) ELSE ('ACTIVE '||CASE b.blocker_session_state WHEN 'ON CPU' THEN b.blocker_session_state ELSE 'WAITING ON '||b.blocker_wait_class||' - '||b.blocker_event END) END blocker_status,
666666        b.blocker_sql_id,
666666        (SELECT s.sql_text FROM v$sql s WHERE s.sql_id = b.blocker_sql_id AND ROWNUM = 1) blocker_sql_text
666666   FROM blockers_and_blockees b
666666  WHERE b.sessions_blocked > 0
666666 ),
666666 summary AS (
666666 SELECT /*+ MATERIALIZE NO_MERGE */
666666        100 * SUM(blocked) / SUM(SUM(blocked)) OVER () percent,
666666        blocker_sql_id,
666666        blocker_sql_text
666666   FROM detail
666666  GROUP BY
666666        blocker_sql_id,
666666        blocker_sql_text
666666 )
666666 SELECT * 
666666        FROM summary
666666  WHERE percent > &&cs_min_perc.
666666  ORDER BY
666666        1 DESC
666666 FETCH FIRST &&cs_top_n. ROWS ONLY;
SET TERM ON;
/
--
PRO
PRO Root Blocker contribution percent by Timed Event (between &&cs_sample_time_from. and &&cs_sample_time_to. UTC)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SET TERM OFF;
GET cs_internal/cs_blocked_sessions_ash_awr_internal.sql NOLIST
.
666666 ,
666666 detail AS (
666666 SELECT /*+ MATERIALIZE NO_MERGE */
666666        b.time,
666666        b.sessions_blocked blocked,
666666        b.blocker_session_id||','||b.blocker_session_serial# blocker,
666666        b.machine blocker_machine,
666666        CASE b.blocker_status WHEN 'INACTIVE or UNKNOWN' THEN (CASE b.machine WHEN '&&cs_host_name.' THEN 'UNKNOWN' ELSE 'INACTIVE' END) ELSE ('ACTIVE '||CASE b.blocker_session_state WHEN 'ON CPU' THEN b.blocker_session_state ELSE 'WAITING ON '||b.blocker_wait_class||' - '||b.blocker_event END) END blocker_status,
666666        b.blocker_sql_id,
666666        (SELECT s.sql_text FROM v$sql s WHERE s.sql_id = b.blocker_sql_id AND ROWNUM = 1) blocker_sql_text
666666   FROM blockers_and_blockees b
666666  WHERE b.sessions_blocked > 0
666666 ),
666666 summary AS (
666666 SELECT /*+ MATERIALIZE NO_MERGE */
666666        100 * SUM(blocked) / SUM(SUM(blocked)) OVER () percent,
666666        blocker_status
666666   FROM detail
666666  GROUP BY
666666        blocker_status
666666 )
666666 SELECT * 
666666        FROM summary
666666  WHERE percent > &&cs_min_perc.
666666  ORDER BY
666666        1 DESC
666666 FETCH FIRST &&cs_top_n. ROWS ONLY;
SET TERM ON;
/
--
PRO
PRO Root Blocker contribution percent by Module (between &&cs_sample_time_from. and &&cs_sample_time_to. UTC)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SET TERM OFF;
GET cs_internal/cs_blocked_sessions_ash_awr_internal.sql NOLIST
.
666666 ,
666666 detail AS (
666666 SELECT /*+ MATERIALIZE NO_MERGE */
666666        b.time,
666666        b.sessions_blocked blocked,
666666        b.blocker_session_id||','||b.blocker_session_serial# blocker,
666666        b.module blocker_module,
666666        CASE b.blocker_status WHEN 'INACTIVE or UNKNOWN' THEN ('ACTIVE '||CASE b.blocker_session_state WHEN 'ON CPU' THEN b.blocker_session_state ELSE 'WAITING ON '||b.blocker_wait_class||' - '||b.blocker_event END) END blocker_status,
666666        b.blocker_sql_id,
666666        (SELECT s.sql_text FROM v$sql s WHERE s.sql_id = b.blocker_sql_id AND ROWNUM = 1) blocker_sql_text
666666   FROM blockers_and_blockees b
666666  WHERE b.sessions_blocked > 0
666666 ),
666666 summary AS (
666666 SELECT /*+ MATERIALIZE NO_MERGE */
666666        100 * SUM(blocked) / SUM(SUM(blocked)) OVER () percent,
666666        blocker_module
666666   FROM detail
666666  GROUP BY
666666        blocker_module
666666 )
666666 SELECT * 
666666        FROM summary
666666  WHERE percent > &&cs_min_perc.
666666  ORDER BY
666666        1 DESC
666666 FETCH FIRST &&cs_top_n. ROWS ONLY;
SET TERM ON;
/
--
PRO
PRO Root Blocker contribution percent by Machine (between &&cs_sample_time_from. and &&cs_sample_time_to. UTC)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SET TERM OFF;
GET cs_internal/cs_blocked_sessions_ash_awr_internal.sql NOLIST
.
666666 ,
666666 detail AS (
666666 SELECT /*+ MATERIALIZE NO_MERGE */
666666        b.time,
666666        b.sessions_blocked blocked,
666666        b.blocker_session_id||','||b.blocker_session_serial# blocker,
666666        b.machine blocker_machine,
666666        b.module blocker_module,
666666        CASE b.blocker_status WHEN 'INACTIVE or UNKNOWN' THEN (CASE b.machine WHEN '&&cs_host_name.' THEN 'UNKNOWN' ELSE 'INACTIVE' END) ELSE ('ACTIVE '||CASE b.blocker_session_state WHEN 'ON CPU' THEN b.blocker_session_state ELSE 'WAITING ON '||b.blocker_wait_class||' - '||b.blocker_event END) END blocker_status,
666666        b.blocker_sql_id,
666666        (SELECT s.sql_text FROM v$sql s WHERE s.sql_id = b.blocker_sql_id AND ROWNUM = 1) blocker_sql_text
666666   FROM blockers_and_blockees b
666666  WHERE b.sessions_blocked > 0
666666 ),
666666 summary AS (
666666 SELECT /*+ MATERIALIZE NO_MERGE */
666666        100 * SUM(blocked) / SUM(SUM(blocked)) OVER () percent,
666666        blocker_machine
666666   FROM detail
666666  GROUP BY
666666        blocker_machine
666666 )
666666 SELECT * 
666666        FROM summary
666666  WHERE percent > &&cs_min_perc.
666666  ORDER BY
666666        1 DESC
666666 FETCH FIRST &&cs_top_n. ROWS ONLY;
SET TERM ON;
/
--
PRO
PRO Root Blocker contribution percent by SID (between &&cs_sample_time_from. and &&cs_sample_time_to. UTC)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SET TERM OFF;
GET cs_internal/cs_blocked_sessions_ash_awr_internal.sql NOLIST
.
666666 ,
666666 detail AS (
666666 SELECT /*+ MATERIALIZE NO_MERGE */
666666        b.time,
666666        b.sessions_blocked blocked,
666666        b.blocker_session_id||','||b.blocker_session_serial# blocker,
666666        b.machine blocker_machine,
666666        b.module blocker_module,
666666        CASE b.blocker_status WHEN 'INACTIVE or UNKNOWN' THEN (CASE b.machine WHEN '&&cs_host_name.' THEN 'UNKNOWN' ELSE 'INACTIVE' END) ELSE ('ACTIVE '||CASE b.blocker_session_state WHEN 'ON CPU' THEN b.blocker_session_state ELSE 'WAITING ON '||b.blocker_wait_class||' - '||b.blocker_event END) END blocker_status,
666666        b.blocker_sql_id,
666666        (SELECT s.sql_text FROM v$sql s WHERE s.sql_id = b.blocker_sql_id AND ROWNUM = 1) blocker_sql_text
666666   FROM blockers_and_blockees b
666666  WHERE b.sessions_blocked > 0
666666 ),
666666 summary AS (
666666 SELECT /*+ MATERIALIZE NO_MERGE */
666666        100 * SUM(blocked) / SUM(SUM(blocked)) OVER () percent,
666666        blocker
666666   FROM detail
666666  GROUP BY
666666        blocker
666666 )
666666 SELECT * 
666666        FROM summary
666666  WHERE percent > &&cs_min_perc.
666666  ORDER BY
666666        1 DESC
666666 FETCH FIRST &&cs_top_n. ROWS ONLY;
SET TERM ON;
/
--
PRO
PRO Root Blocker contribution percent by Timed Event and SQL_ID (between &&cs_sample_time_from. and &&cs_sample_time_to. UTC)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SET TERM OFF;
GET cs_internal/cs_blocked_sessions_ash_awr_internal.sql NOLIST
.
666666 ,
666666 detail AS (
666666 SELECT /*+ MATERIALIZE NO_MERGE */
666666        b.time,
666666        b.sessions_blocked blocked,
666666        b.blocker_session_id||','||b.blocker_session_serial# blocker,
666666        b.machine blocker_machine,
666666        CASE b.blocker_status WHEN 'INACTIVE or UNKNOWN' THEN (CASE b.machine WHEN '&&cs_host_name.' THEN 'UNKNOWN' ELSE 'INACTIVE' END) ELSE ('ACTIVE '||CASE b.blocker_session_state WHEN 'ON CPU' THEN b.blocker_session_state ELSE 'WAITING ON '||b.blocker_wait_class||' - '||b.blocker_event END) END blocker_status,
666666        b.blocker_sql_id,
666666        (SELECT s.sql_text FROM v$sql s WHERE s.sql_id = b.blocker_sql_id AND ROWNUM = 1) blocker_sql_text
666666   FROM blockers_and_blockees b
666666  WHERE b.sessions_blocked > 0
666666 ),
666666 summary AS (
666666 SELECT /*+ MATERIALIZE NO_MERGE */
666666        100 * SUM(blocked) / SUM(SUM(blocked)) OVER () percent,
666666        blocker_status,
666666        blocker_sql_id,
666666        blocker_sql_text
666666   FROM detail
666666  GROUP BY
666666        blocker_status,
666666        blocker_sql_id,
666666        blocker_sql_text
666666 )
666666 SELECT * 
666666        FROM summary
666666  WHERE percent > &&cs_min_perc.
666666  ORDER BY
666666        1 DESC
666666 FETCH FIRST &&cs_top_n. ROWS ONLY;
SET TERM ON;
/
--
PRO
PRO Root Blocker contribution percent by Module, Timed Event and SQL_ID (between &&cs_sample_time_from. and &&cs_sample_time_to. UTC)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SET TERM OFF;
GET cs_internal/cs_blocked_sessions_ash_awr_internal.sql NOLIST
.
666666 ,
666666 detail AS (
666666 SELECT /*+ MATERIALIZE NO_MERGE */
666666        b.time,
666666        b.sessions_blocked blocked,
666666        b.blocker_session_id||','||b.blocker_session_serial# blocker,
666666        b.module blocker_module,
666666        CASE b.blocker_status WHEN 'INACTIVE or UNKNOWN' THEN ('ACTIVE '||CASE b.blocker_session_state WHEN 'ON CPU' THEN b.blocker_session_state ELSE 'WAITING ON '||b.blocker_wait_class||' - '||b.blocker_event END) END blocker_status,
666666        b.blocker_sql_id,
666666        (SELECT s.sql_text FROM v$sql s WHERE s.sql_id = b.blocker_sql_id AND ROWNUM = 1) blocker_sql_text
666666   FROM blockers_and_blockees b
666666  WHERE b.sessions_blocked > 0
666666 ),
666666 summary AS (
666666 SELECT /*+ MATERIALIZE NO_MERGE */
666666        100 * SUM(blocked) / SUM(SUM(blocked)) OVER () percent,
666666        blocker_module,
666666        blocker_status,
666666        blocker_sql_id,
666666        blocker_sql_text
666666   FROM detail
666666  GROUP BY
666666        blocker_module,
666666        blocker_status,
666666        blocker_sql_id,
666666        blocker_sql_text
666666 )
666666 SELECT * 
666666        FROM summary
666666  WHERE percent > &&cs_min_perc.
666666  ORDER BY
666666        1 DESC
666666 FETCH FIRST &&cs_top_n. ROWS ONLY;
SET TERM ON;
/
--
PRO
PRO Root Blocker contribution percent by Machine, Module, Timed Event and SQL_ID (between &&cs_sample_time_from. and &&cs_sample_time_to. UTC)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SET TERM OFF;
GET cs_internal/cs_blocked_sessions_ash_awr_internal.sql NOLIST
.
666666 ,
666666 detail AS (
666666 SELECT /*+ MATERIALIZE NO_MERGE */
666666        b.time,
666666        b.sessions_blocked blocked,
666666        b.blocker_session_id||','||b.blocker_session_serial# blocker,
666666        b.machine blocker_machine,
666666        b.module blocker_module,
666666        CASE b.blocker_status WHEN 'INACTIVE or UNKNOWN' THEN (CASE b.machine WHEN '&&cs_host_name.' THEN 'UNKNOWN' ELSE 'INACTIVE' END) ELSE ('ACTIVE '||CASE b.blocker_session_state WHEN 'ON CPU' THEN b.blocker_session_state ELSE 'WAITING ON '||b.blocker_wait_class||' - '||b.blocker_event END) END blocker_status,
666666        b.blocker_sql_id,
666666        (SELECT s.sql_text FROM v$sql s WHERE s.sql_id = b.blocker_sql_id AND ROWNUM = 1) blocker_sql_text
666666   FROM blockers_and_blockees b
666666  WHERE b.sessions_blocked > 0
666666 ),
666666 summary AS (
666666 SELECT /*+ MATERIALIZE NO_MERGE */
666666        100 * SUM(blocked) / SUM(SUM(blocked)) OVER () percent,
666666        blocker_machine,
666666        blocker_module,
666666        blocker_status,
666666        blocker_sql_id,
666666        blocker_sql_text
666666   FROM detail
666666  GROUP BY
666666        blocker_machine,
666666        blocker_module,
666666        blocker_status,
666666        blocker_sql_id,
666666        blocker_sql_text
666666 )
666666 SELECT * 
666666        FROM summary
666666  WHERE percent > &&cs_min_perc.
666666  ORDER BY
666666        1 DESC
666666 FETCH FIRST &&cs_top_n. ROWS ONLY;
SET TERM ON;
/
--
PRO
PRO Root Blocker contribution percent by SID, Machine, Module, Timed Event and SQL_ID (between &&cs_sample_time_from. and &&cs_sample_time_to. UTC)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SET TERM OFF;
GET cs_internal/cs_blocked_sessions_ash_awr_internal.sql NOLIST
.
666666 ,
666666 detail AS (
666666 SELECT /*+ MATERIALIZE NO_MERGE */
666666        b.time,
666666        b.sessions_blocked blocked,
666666        b.blocker_session_id||','||b.blocker_session_serial# blocker,
666666        b.machine blocker_machine,
666666        b.module blocker_module,
666666        CASE b.blocker_status WHEN 'INACTIVE or UNKNOWN' THEN (CASE b.machine WHEN '&&cs_host_name.' THEN 'UNKNOWN' ELSE 'INACTIVE' END) ELSE ('ACTIVE '||CASE b.blocker_session_state WHEN 'ON CPU' THEN b.blocker_session_state ELSE 'WAITING ON '||b.blocker_wait_class||' - '||b.blocker_event END) END blocker_status,
666666        b.blocker_sql_id,
666666        (SELECT s.sql_text FROM v$sql s WHERE s.sql_id = b.blocker_sql_id AND ROWNUM = 1) blocker_sql_text
666666   FROM blockers_and_blockees b
666666  WHERE b.sessions_blocked > 0
666666 ),
666666 summary AS (
666666 SELECT /*+ MATERIALIZE NO_MERGE */
666666        100 * SUM(blocked) / SUM(SUM(blocked)) OVER () percent,
666666        blocker,
666666        blocker_machine,
666666        blocker_module,
666666        blocker_status,
666666        blocker_sql_id,
666666        blocker_sql_text
666666   FROM detail
666666  GROUP BY
666666        blocker,
666666        blocker_machine,
666666        blocker_module,
666666        blocker_status,
666666        blocker_sql_id,
666666        blocker_sql_text
666666 )
666666 SELECT * 
666666        FROM summary
666666  WHERE percent > &&cs_min_perc.
666666  ORDER BY
666666        1 DESC
666666 FETCH FIRST &&cs_top_n. ROWS ONLY;
SET TERM ON;
/
--
PRO
PRO Sample of Blocked Sessions (between &&cs_sample_time_from. and &&cs_sample_time_to. UTC)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~
SET TERM OFF;
GET cs_internal/cs_blocked_sessions_ash_awr_internal.sql NOLIST
.
666666 SELECT b.time,
666666        b.wait_class_event,
666666        b.sessions_blocked blocked,
666666        b.blocker_session_id||','||b.blocker_session_serial# blocker,
666666        b.machine blocker_machine,
666666        b.module blocker_module,
666666        --CASE b.blocker_status WHEN 'INACTIVE or UNKNOWN' THEN b.blocker_status ELSE ('ACTIVE '||CASE b.blocker_session_state WHEN 'ON CPU' THEN b.blocker_session_state ELSE 'WAITING ON '||b.blocker_wait_class||' - '||b.blocker_event END) END blocker_status,
666666        CASE b.blocker_status WHEN 'INACTIVE or UNKNOWN' THEN (CASE b.machine WHEN '&&cs_host_name.' THEN 'UNKNOWN' ELSE 'INACTIVE' END) ELSE ('ACTIVE '||CASE b.blocker_session_state WHEN 'ON CPU' THEN b.blocker_session_state ELSE 'WAITING ON '||b.blocker_wait_class||' - '||b.blocker_event END) END blocker_status,
666666        b.blocker_sql_id,
666666        (SELECT s.sql_text FROM v$sql s WHERE s.sql_id = b.blocker_sql_id AND ROWNUM = 1) blocker_sql_text
666666   FROM blockers_and_blockees b
666666  WHERE b.sessions_blocked > 0
666666  ORDER BY
666666        b.time,
666666        b.blocker_session_id;
SET TERM ON;
/
--
PRO
PRO "INACTIVE" means: Database is waiting for Application Host to release LOCK, while "UNKNOWN" could be a BACKGROUND session on CDB$ROOT.
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." 
--
@@cs_internal/cs_spool_tail.sql
--
--ALTER SESSION SET CONTAINER = &&cs_con_name.;
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--