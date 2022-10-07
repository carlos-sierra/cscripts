----------------------------------------------------------------------------------------
--
-- File name:   aa.sql | cs_ash_analytics.sql
--
-- Purpose:     Poor-man's version of ASH Analytics for all Timed Events (Average Active Sessions AAS)
--
-- Author:      Carlos Sierra
--
-- Version:     2022/06/15
--
-- Usage:       Execute connected to CDB or PDB
--
--              Enter range of dates and filters when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_ash_analytics.sql
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
DEF cs_script_name = 'cs_ash_analytics';
DEF cs_script_acronym = 'aa.sql | ';
--
DEF cs_hours_range_default = '3';
--
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
--@@cs_internal/&&cs_set_container_to_cdb_root.
--
COL cs_ash_cut_off_date NEW_V cs_ash_cut_off_date NOPRI;
SELECT TO_CHAR(CAST(PERCENTILE_DISC(0.05) WITHIN GROUP (ORDER BY sample_time) AS DATE) + (1/24), 'YYYY-MM-DD"T"HH24:MI') AS cs_ash_cut_off_date FROM v$active_session_history;
--SELECT TO_CHAR(TRUNC(TRUNC(SYSDATE, 'HH') + FLOOR(TO_NUMBER(TO_CHAR(SYSDATE, 'MI')) / 15) * 15 / (24*60), 'MI'), 'YYYY-MM-DD"T"HH24:MI') AS cs_ash_cut_off_date FROM DUAL;
--
COL cs2_granularity_list NEW_V cs2_granularity_list NOPRI;
COL cs2_default_granularity NEW_V cs2_default_granularity NOPRI;
SELECT CASE 
         WHEN TO_NUMBER('&&cs_from_to_seconds.') / 3660 <= 0.2 AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.') < TO_DATE('&&cs_ash_cut_off_date.', 'YYYY-MM-DD"T"HH24:MI') THEN '[{10s}|1s|5s|10s|15s|1m|5m|15m|1h|1d|s|m|h|d]'  -- < 12m (up to 72 samples)
         WHEN TO_NUMBER('&&cs_from_to_seconds.') / 3660 <= 0.2 THEN '[{1s}|1s|5s|10s|15s|1m|5m|15m|1h|1d|s|m|h|d]'  -- < 12m (up to 720 samples)
         WHEN TO_NUMBER('&&cs_from_to_seconds.') / 3600 <= 1   AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.') < TO_DATE('&&cs_ash_cut_off_date.', 'YYYY-MM-DD"T"HH24:MI') THEN '[{10s}|1s|5s|10s|15s|1m|5m|15m|1h|1d|s|m|h|d]'  -- < 1h (up to 360 samples)
         WHEN TO_NUMBER('&&cs_from_to_seconds.') / 3600 <= 1   THEN '[{5s}|1s|5s|10s|15s|1m|5m|15m|1h|1d|s|m|h|d]'  -- < 1h (up to 720 samples)
         WHEN TO_NUMBER('&&cs_from_to_seconds.') / 3600 <= 2   THEN '[{10s}|1s|5s|10s|15s|1m|5m|15m|1h|1d|s|m|h|d]' -- < 2h (up to 720 samples)
         WHEN TO_NUMBER('&&cs_from_to_seconds.') / 3600 <= 3   THEN '[{15s}|1s|5s|10s|15s|1m|5m|15m|1h|1d|s|m|h|d]' -- < 3h (up to 720 samples)
         WHEN TO_NUMBER('&&cs_from_to_seconds.') / 3600 <= 12  THEN '[{1m}|1s|5s|10s|15s|1m|5m|15m|1h|1d|s|m|h|d]'  -- < 12h (up to 720 samples)
         WHEN TO_NUMBER('&&cs_from_to_seconds.') / 3600 <= 60  THEN '[{5m}|1s|5s|10s|15s|1m|5m|15m|1h|1d|s|m|h|d]'  -- < 60h (2.5d) (up to 720 samples)
         WHEN TO_NUMBER('&&cs_from_to_seconds.') / 3600 <= 180 THEN '[{15m}|1s|5s|10s|15s|1m|5m|15m|1h|1d|s|m|h|d]' -- < 180h (7.5d) (up to 720 samples)
         WHEN TO_NUMBER('&&cs_from_to_seconds.') / 3600 <= 720 THEN '[{1h}|1s|5s|10s|15s|1m|5m|15m|1h|1d|s|m|h|d]'  -- < 720h (30d) (up to 720 samples)
         ELSE '[{1d}|1s|5s|10s|15s|1m|5m|15m|1h|1d|s|m|h|d]'
       END AS cs2_granularity_list,
       CASE 
         WHEN TO_NUMBER('&&cs_from_to_seconds.') / 3600 <= 0.2 AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.') < TO_DATE('&&cs_ash_cut_off_date.', 'YYYY-MM-DD"T"HH24:MI') THEN '10s'  -- < 12m (up to 72 samples)
         WHEN TO_NUMBER('&&cs_from_to_seconds.') / 3600 <= 0.2 THEN '1s'  -- < 12m (up to 720 samples)
         WHEN TO_NUMBER('&&cs_from_to_seconds.') / 3600 <= 1   AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.') < TO_DATE('&&cs_ash_cut_off_date.', 'YYYY-MM-DD"T"HH24:MI') THEN '10s'  -- < 1h (up to 360 samples)
         WHEN TO_NUMBER('&&cs_from_to_seconds.') / 3600 <= 1   THEN '5s'  -- < 1h (up to 720 samples)
         WHEN TO_NUMBER('&&cs_from_to_seconds.') / 3600 <= 2   THEN '10s' -- < 2h (up to 720 samples)
         WHEN TO_NUMBER('&&cs_from_to_seconds.') / 3600 <= 3   THEN '15s' -- < 3h (up to 720 samples)
         WHEN TO_NUMBER('&&cs_from_to_seconds.') / 3600 <= 12  THEN '1m'  -- < 12h (up to 720 samples)
         WHEN TO_NUMBER('&&cs_from_to_seconds.') / 3600 <= 60  THEN '5m'  -- < 60h (2.5d) (up to 720 samples)
         WHEN TO_NUMBER('&&cs_from_to_seconds.') / 3600 <= 180 THEN '15m' -- < 180h (7.5d) (up to 720 samples)
         WHEN TO_NUMBER('&&cs_from_to_seconds.') / 3600 <= 720 THEN '1h'  -- < 720h (30d) (up to 720 samples)
         ELSE '1d'
       END AS cs2_default_granularity
  FROM DUAL
/
PRO
PRO 3. Granularity: &&cs2_granularity_list.
DEF cs2_granularity = '&3.';
UNDEF 3;
COL cs2_granularity NEW_V cs2_granularity NOPRI;
SELECT NVL(LOWER(TRIM('&&cs2_granularity.')), '&&cs2_default_granularity.') cs2_granularity FROM DUAL;
SELECT CASE 
         WHEN '&&cs2_granularity.' = 's' THEN '1s'
         WHEN '&&cs2_granularity.' = 'm' THEN '1m'
         WHEN '&&cs2_granularity.' = 'h' THEN '1h'
         WHEN '&&cs2_granularity.' = 'd' THEN '1d'
         WHEN '&&cs2_granularity.' IN ('1s', '5s', '10s', '15s', '1m', '5m', '15m', '1h', '1d') THEN '&&cs2_granularity.' 
         ELSE '&&cs2_default_granularity.' 
       END cs2_granularity 
  FROM DUAL
/
--
COL cs2_fmt NEW_V cs2_fmt NOPRI;
SELECT CASE '&&cs2_granularity.' 
         WHEN '1s'  THEN 'SS' -- (1/24/3600) 1 second
         WHEN '5s'  THEN 'SS' -- (5/24/3600) 5 seconds
         WHEN '10s' THEN 'SS' -- (10/24/3600) 10 seconds
         WHEN '15s' THEN 'SS' -- (15/24/3600) 15 seconds
         WHEN '1m'  THEN 'MI' -- (1/24/60) 1 minute
         WHEN '5m'  THEN 'MI' -- (5/24/60) 5 minutes
         WHEN '15m' THEN 'MI' -- (15/24/60) 15 minutes
         WHEN '1h'  THEN 'HH' -- (1/24) 1 hour
         WHEN '1d'  THEN 'DD' -- 1 day
         ELSE 'XX' -- error
       END cs2_fmt 
  FROM DUAL
/
--
COL cs2_plus_days NEW_V cs2_plus_days NOPRI;
SELECT CASE '&&cs2_granularity.' 
         WHEN '1s'  THEN '(1/24/3600)' -- (1/24/3600) 1 second
         WHEN '5s'  THEN '(5/24/3600)' -- (5/24/3600) 5 seconds
         WHEN '10s' THEN '(10/24/3600)' -- (10/24/3600) 10 seconds
         WHEN '15s' THEN '(15/24/3600)' -- (15/24/3600) 15 seconds
         WHEN '1m'  THEN '(1/24/60)' -- (1/24/60) 1 minute
         WHEN '5m'  THEN '(5/24/60)' -- (5/24/60) 5 minutes
         WHEN '15m' THEN '(15/24/60)' -- (15/24/60) 15 minutes
         WHEN '1h'  THEN '(1/24)' -- (1/24) 1 hour
         WHEN '1d'  THEN '1' -- 1 day
         ELSE 'XX' -- error
       END cs2_plus_days 
  FROM DUAL
/
--
COL cs2_samples NEW_V cs2_samples NOPRI;
SELECT TO_CHAR(CEIL((TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.') - TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.')) / &&cs2_plus_days.)) AS cs2_samples FROM DUAL
/
--
PRO
PRO 4. Reporting Dimension: [{event}|wait_class|machine|sql_id|plan_hash_value|top_level_sql_id|sid|blocking_session|current_obj#|module|program|sql_opname|appl_cat|pdb_name|p1|p2|p3]
DEF cs2_dimension = '&4.';
UNDEF 4;
COL cs2_dimension NEW_V cs2_dimension NOPRI;
-- SELECT NVL(LOWER(TRIM('&&cs2_dimension.')), 'event') cs2_dimension FROM DUAL;
SELECT CASE WHEN LOWER(TRIM('&&cs2_dimension.')) IN ('event', 'wait_class', 'machine', 'sql_id', 'plan_hash_value', 'top_level_sql_id', 'sid', 'blocking_session', 'current_obj#', 'module', 'program', 'sql_opname', 'appl_cat', 'pdb_name', 'p1', 'p2', 'p3') THEN LOWER(TRIM('&&cs2_dimension.')) ELSE 'event' END cs2_dimension FROM DUAL;
--
COL use_oem_colors_series NEW_V use_oem_colors_series NOPRI;
SELECT CASE '&&cs2_dimension.' WHEN 'wait_class' THEN NULL ELSE '//' END AS use_oem_colors_series FROM DUAL;
--
COL aas FOR 999,990.000 HEA 'Average Active|Sessions (AAS)';
COL db_seconds FOR 999,999,990 HEA 'DB Seconds';
COL session_state FOR A13 HEA 'Session|State';
BREAK ON REPORT;
COMPUTE SUM OF aas db_seconds ON REPORT;
--
WITH
ash_awr AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.session_state,
       10 * COUNT(*) AS db_seconds
  FROM dba_hist_active_sess_history h
 WHERE h.sample_time <= TO_TIMESTAMP('&&cs_ash_cut_off_date.', 'YYYY-MM-DD"T"HH24:MI')
   AND h.sample_time >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND h.sample_time < TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND h.dbid = TO_NUMBER('&&cs_dbid.')
   AND h.instance_number = TO_NUMBER('&&cs_instance_number.')
   AND h.snap_id BETWEEN TO_NUMBER('&&cs_snap_id_from.') AND TO_NUMBER('&&cs_snap_id_to.') + 1
 GROUP BY
       h.session_state
),
ash_mem AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.session_state,
       1 * COUNT(*) AS db_seconds
  FROM v$active_session_history h
 WHERE h.sample_time > TO_TIMESTAMP('&&cs_ash_cut_off_date.', 'YYYY-MM-DD"T"HH24:MI')
   AND h.sample_time >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND h.sample_time < TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
 GROUP BY
       h.session_state
), 
ash_all AS (
SELECT session_state, db_seconds FROM ash_awr
 UNION ALL
SELECT session_state, db_seconds FROM ash_mem
)
SELECT ROUND(SUM(db_seconds) / TO_NUMBER('&&cs_from_to_seconds.'), 3) AS aas,
       SUM(db_seconds) AS db_seconds,
       session_state
  FROM ash_all
 GROUP BY
       session_state
 ORDER BY
       1 DESC
/
--
PRO
PRO 5. Session State (opt):
DEF cs2_session_state = '&5.';
UNDEF 5;
DEF cs2_instruct_to_skip = '(opt)';
COL cs2_instruct_to_skip NEW_V cs2_instruct_to_skip NOPRI;
SELECT '(hit "Return" to skip this patameter since Session State is "ON CPU")' AS cs2_instruct_to_skip FROM DUAL WHERE '&&cs2_session_state.' = 'ON CPU'
/
--
COL wait_class HEA 'Wait Class';
--
WITH
ash_awr AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.session_state,
       h.wait_class,
       10 * COUNT(*) AS db_seconds
  FROM dba_hist_active_sess_history h
 WHERE h.sample_time <= TO_TIMESTAMP('&&cs_ash_cut_off_date.', 'YYYY-MM-DD"T"HH24:MI')
   AND h.sample_time >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND h.sample_time < TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND h.dbid = TO_NUMBER('&&cs_dbid.')
   AND h.instance_number = TO_NUMBER('&&cs_instance_number.')
   AND h.snap_id BETWEEN TO_NUMBER('&&cs_snap_id_from.') AND TO_NUMBER('&&cs_snap_id_to.') + 1
   AND ('&&cs2_session_state.' IS NULL OR h.session_state = '&&cs2_session_state.')
   AND NVL('&&cs2_session_state.', 'X') <> 'ON CPU'
 GROUP BY
       h.session_state,
       h.wait_class
),
ash_mem AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.session_state,
       h.wait_class,
       1 * COUNT(*) AS db_seconds
  FROM v$active_session_history h
 WHERE h.sample_time > TO_TIMESTAMP('&&cs_ash_cut_off_date.', 'YYYY-MM-DD"T"HH24:MI')
   AND h.sample_time >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND h.sample_time < TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND ('&&cs2_session_state.' IS NULL OR h.session_state = '&&cs2_session_state.')
   AND NVL('&&cs2_session_state.', 'X') <> 'ON CPU'
 GROUP BY
       h.session_state,
       h.wait_class
), 
ash_all AS (
SELECT session_state, wait_class, db_seconds FROM ash_awr
 UNION ALL
SELECT session_state, wait_class, db_seconds FROM ash_mem
)
SELECT ROUND(SUM(db_seconds) / TO_NUMBER('&&cs_from_to_seconds.'), 3) AS aas,
       SUM(db_seconds) AS db_seconds,
       wait_class,
       session_state
  FROM ash_all
 GROUP BY
       wait_class,
       session_state
 ORDER BY
       1 DESC
/
--
PRO
PRO 6. Wait Class &&cs2_instruct_to_skip.:
DEF cs2_wait_class = '&6.';
UNDEF 6;
--
COL cs2_group NEW_V cs2_group NOPRI;
SELECT CASE '&&cs2_dimension.'
         WHEN 'wait_class' THEN q'[CASE h.session_state WHEN 'ON CPU' THEN h.session_state ELSE h.wait_class END]'
         WHEN 'event' THEN CASE WHEN '&&cs2_wait_class.' IS NULL THEN q'[CASE h.session_state WHEN 'ON CPU' THEN h.session_state ELSE h.wait_class||' - '||h.event END]' ELSE q'[h.event]' END
         WHEN 'machine' THEN q'[h.machine]' 
         WHEN 'sql_id' THEN q'[h.sql_id]' 
         WHEN 'plan_hash_value' THEN q'[TO_CHAR(h.sql_plan_hash_value)]' 
         WHEN 'top_level_sql_id' THEN q'[h.top_level_sql_id]' 
         WHEN 'sid' THEN q'[TO_CHAR(h.session_id)]' 
        --  WHEN 'blocking_session' THEN q'[h.blocking_session||CASE WHEN h.blocking_session IS NOT NULL THEN ','||h.blocking_session_serial# END]'  -- 19c: ORA-00979: not a GROUP BY expression
         WHEN 'blocking_session' THEN q'[TO_CHAR(h.blocking_session)]' 
        --  WHEN 'current_obj#' THEN q'[h.current_obj#||CASE WHEN h.current_obj# IS NOT NULL THEN ' ('||h.con_id||')' END]' -- 19c: ORA-00979: not a GROUP BY expression
         WHEN 'current_obj#' THEN q'[TO_CHAR(h.current_obj#)]'
         WHEN 'module' THEN q'[h.module]' 
         WHEN 'program' THEN q'[h.program]' 
         WHEN 'sql_opname' THEN q'[h.sql_opname]' 
         WHEN 'appl_cat' THEN q'[application_category(t.sql_text, h.sql_opname)]' 
         WHEN 'pdb_name' THEN q'[TO_CHAR(h.con_id)]'
         WHEN 'p1' THEN q'[h.p1text||':'||h.p1]'
         WHEN 'p2' THEN q'[h.p2text||':'||h.p2]'
         WHEN 'p3' THEN q'[h.p3text||':'||h.p3]'
       END AS cs2_group
  FROM DUAL
/
--
COL event HEA 'Event';
--
WITH
ash_awr AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.event,
       h.wait_class,
       h.session_state,
       10 * COUNT(*) AS db_seconds
  FROM dba_hist_active_sess_history h
 WHERE h.sample_time <= TO_TIMESTAMP('&&cs_ash_cut_off_date.', 'YYYY-MM-DD"T"HH24:MI')
   AND h.sample_time >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND h.sample_time < TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND h.dbid = TO_NUMBER('&&cs_dbid.')
   AND h.instance_number = TO_NUMBER('&&cs_instance_number.')
   AND h.snap_id BETWEEN TO_NUMBER('&&cs_snap_id_from.') AND TO_NUMBER('&&cs_snap_id_to.') + 1
   AND ('&&cs2_session_state.' IS NULL OR h.session_state = '&&cs2_session_state.')
   AND NVL('&&cs2_session_state.', 'X') <> 'ON CPU'
   AND ('&&cs2_wait_class.' IS NULL OR h.wait_class = '&&cs2_wait_class.')
 GROUP BY
       h.event,
       h.wait_class,
       h.session_state
),
ash_mem AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.event,
       h.wait_class,
       h.session_state,
       1 * COUNT(*) AS db_seconds
  FROM v$active_session_history h
 WHERE h.sample_time > TO_TIMESTAMP('&&cs_ash_cut_off_date.', 'YYYY-MM-DD"T"HH24:MI')
   AND h.sample_time >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND h.sample_time < TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND ('&&cs2_session_state.' IS NULL OR h.session_state = '&&cs2_session_state.')
   AND NVL('&&cs2_session_state.', 'X') <> 'ON CPU'
   AND ('&&cs2_wait_class.' IS NULL OR h.wait_class = '&&cs2_wait_class.')
 GROUP BY
       h.event,
       h.wait_class,
       h.session_state
), 
ash_all AS (
SELECT event, wait_class, session_state, db_seconds FROM ash_awr
 UNION ALL
SELECT event, wait_class, session_state, db_seconds FROM ash_mem
)
SELECT ROUND(SUM(db_seconds) / TO_NUMBER('&&cs_from_to_seconds.'), 3) AS aas,
       SUM(db_seconds) AS db_seconds,
       event,
       wait_class,
       session_state
  FROM ash_all
 GROUP BY
       event,
       wait_class,
       session_state
 ORDER BY
       1 DESC
 FETCH FIRST 30 ROWS ONLY
/
--
PRO
PRO 7. Event &&cs2_instruct_to_skip.:
DEF cs2_event = '&7.';
UNDEF 7;
--
COL machine HEA 'Machine';
--
WITH
ash_awr AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.machine,
       10 * COUNT(*) AS db_seconds
  FROM dba_hist_active_sess_history h
 WHERE h.sample_time <= TO_TIMESTAMP('&&cs_ash_cut_off_date.', 'YYYY-MM-DD"T"HH24:MI')
   AND h.sample_time >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND h.sample_time < TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND h.dbid = TO_NUMBER('&&cs_dbid.')
   AND h.instance_number = TO_NUMBER('&&cs_instance_number.')
   AND h.snap_id BETWEEN TO_NUMBER('&&cs_snap_id_from.') AND TO_NUMBER('&&cs_snap_id_to.') + 1
   AND ('&&cs2_session_state.' IS NULL OR h.session_state = '&&cs2_session_state.')
   AND ('&&cs2_wait_class.' IS NULL OR h.wait_class = '&&cs2_wait_class.')
   AND ('&&cs2_event.' IS NULL OR h.event LIKE CHR(37)||'&&cs2_event.'||CHR(37))
 GROUP BY
       h.machine
),
ash_mem AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.machine,
       1 * COUNT(*) AS db_seconds
  FROM v$active_session_history h
 WHERE h.sample_time > TO_TIMESTAMP('&&cs_ash_cut_off_date.', 'YYYY-MM-DD"T"HH24:MI')
   AND h.sample_time >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND h.sample_time < TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND ('&&cs2_session_state.' IS NULL OR h.session_state = '&&cs2_session_state.')
   AND ('&&cs2_wait_class.' IS NULL OR h.wait_class = '&&cs2_wait_class.')
   AND ('&&cs2_event.' IS NULL OR h.event LIKE CHR(37)||'&&cs2_event.'||CHR(37))
 GROUP BY
       h.machine
), 
ash_all AS (
SELECT machine, db_seconds FROM ash_awr
 UNION ALL
SELECT machine, db_seconds FROM ash_mem
)
SELECT ROUND(SUM(db_seconds) / TO_NUMBER('&&cs_from_to_seconds.'), 3) AS aas,
       SUM(db_seconds) AS db_seconds,
       machine
  FROM ash_all
 GROUP BY
       machine
 ORDER BY
       1 DESC
 FETCH FIRST 30 ROWS ONLY
/
--
PRO
PRO 8. Machine (opt):
DEF cs2_machine = '&8.';
UNDEF 8;
--
PRO
PRO 9. SQL Text piece (e.g.: ScanQuery, getValues, TableName, IndexName):
DEF cs2_sql_text_piece = '&9.';
UNDEF 9;
--
COL sql_text FOR A60 TRUNC;
--
WITH
sql_txt AS (
  SELECT /*+ MATERIALIZE NO_MERGE */ sql_id, MAX(sql_text) AS sql_text
  FROM (
          SELECT sql_id, REPLACE(REPLACE(SUBSTR(sql_text, 1, 100), CHR(10), CHR(32)), CHR(9), CHR(32)) AS sql_text
            FROM v$sql
          WHERE '&&cs2_sql_text_piece.' IS NOT NULL
            AND UPPER(sql_text) LIKE CHR(37)||UPPER('&&cs2_sql_text_piece.')||CHR(37)
            AND ROWNUM >= 1
          UNION ALL
          SELECT sql_id, REPLACE(REPLACE(DBMS_LOB.substr(sql_text, 100), CHR(10), CHR(32)), CHR(9), CHR(32)) AS sql_text
            FROM dba_hist_sqltext
          WHERE '&&cs2_sql_text_piece.' IS NOT NULL
            AND UPPER(DBMS_LOB.substr(sql_text, 1000)) LIKE CHR(37)||UPPER('&&cs2_sql_text_piece.')||CHR(37)
            AND dbid = &&cs_dbid.
            AND ROWNUM >= 1
  )
  GROUP BY sql_id
),
ash_awr AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.sql_id,
       10 * COUNT(*) AS db_seconds
  FROM dba_hist_active_sess_history h
 WHERE h.sample_time <= TO_TIMESTAMP('&&cs_ash_cut_off_date.', 'YYYY-MM-DD"T"HH24:MI')
   AND h.sample_time >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND h.sample_time < TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND h.dbid = TO_NUMBER('&&cs_dbid.')
   AND h.instance_number = TO_NUMBER('&&cs_instance_number.')
   AND h.snap_id BETWEEN TO_NUMBER('&&cs_snap_id_from.') AND TO_NUMBER('&&cs_snap_id_to.') + 1
   AND ('&&cs2_session_state.' IS NULL OR h.session_state = '&&cs2_session_state.')
   AND ('&&cs2_wait_class.' IS NULL OR h.wait_class = '&&cs2_wait_class.')
   AND ('&&cs2_event.' IS NULL OR h.event LIKE CHR(37)||'&&cs2_event.'||CHR(37))
   AND ('&&cs2_machine.' IS NULL OR h.machine LIKE CHR(37)||'&&cs2_machine.'||CHR(37))
   AND ('&&cs2_sql_text_piece.' IS NULL OR h.sql_id IN (SELECT /*+ NO_MERGE */ t.sql_id FROM sql_txt t))
 GROUP BY
       h.sql_id
),
ash_mem AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.sql_id,
       1 * COUNT(*) AS db_seconds
  FROM v$active_session_history h
 WHERE h.sample_time > TO_TIMESTAMP('&&cs_ash_cut_off_date.', 'YYYY-MM-DD"T"HH24:MI')
   AND h.sample_time >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND h.sample_time < TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND ('&&cs2_session_state.' IS NULL OR h.session_state = '&&cs2_session_state.')
   AND ('&&cs2_wait_class.' IS NULL OR h.wait_class = '&&cs2_wait_class.')
   AND ('&&cs2_event.' IS NULL OR h.event LIKE CHR(37)||'&&cs2_event.'||CHR(37))
   AND ('&&cs2_machine.' IS NULL OR h.machine LIKE CHR(37)||'&&cs2_machine.'||CHR(37))
   AND ('&&cs2_sql_text_piece.' IS NULL OR h.sql_id IN (SELECT /*+ NO_MERGE */ t.sql_id FROM sql_txt t))
 GROUP BY
       h.sql_id
), 
ash_all AS (
SELECT sql_id, db_seconds FROM ash_awr
 UNION ALL
SELECT sql_id, db_seconds FROM ash_mem
)
SELECT ROUND(SUM(db_seconds) / TO_NUMBER('&&cs_from_to_seconds.'), 3) AS aas,
       SUM(db_seconds) AS db_seconds,
       sql_id,
       (SELECT s.sql_text FROM sql_txt s WHERE s.sql_id = a.sql_id AND ROWNUM = 1) AS sql_text
  FROM ash_all a
 GROUP BY
       sql_id
 ORDER BY
       1 DESC
 FETCH FIRST 30 ROWS ONLY
/
--
PRO
PRO 10. SQL_ID (opt):
DEF cs2_sql_id = '&10.';
UNDEF 10;
--
DEF spool_id_chart_footer_script = 'cs_ash_analytics_footer.sql';
COL rn FOR 999;
COL dimension_group FOR A64 TRUNC;
DEF series_01 = ' ';
DEF series_02 = ' ';
DEF series_03 = ' ';
DEF series_04 = ' ';
DEF series_05 = ' ';
DEF series_06 = ' ';
DEF series_07 = ' ';
DEF series_08 = ' ';
DEF series_09 = ' ';
DEF series_10 = ' ';
DEF series_11 = ' ';
DEF series_12 = ' ';
DEF series_13 = ' ';
COL series_01 NEW_V series_01 FOR A64 TRUNC NOPRI;
COL series_02 NEW_V series_02 FOR A64 TRUNC NOPRI;
COL series_03 NEW_V series_03 FOR A64 TRUNC NOPRI;
COL series_04 NEW_V series_04 FOR A64 TRUNC NOPRI;
COL series_05 NEW_V series_05 FOR A64 TRUNC NOPRI;
COL series_06 NEW_V series_06 FOR A64 TRUNC NOPRI;
COL series_07 NEW_V series_07 FOR A64 TRUNC NOPRI;
COL series_08 NEW_V series_08 FOR A64 TRUNC NOPRI;
COL series_09 NEW_V series_09 FOR A64 TRUNC NOPRI;
COL series_10 NEW_V series_10 FOR A64 TRUNC NOPRI;
COL series_11 NEW_V series_11 FOR A64 TRUNC NOPRI;
COL series_12 NEW_V series_12 FOR A64 TRUNC NOPRI;
COL series_13 NEW_V series_13 FOR A64 TRUNC NOPRI;
DEF aas_01 = '         ';
DEF aas_02 = '         ';
DEF aas_03 = '         ';
DEF aas_04 = '         ';
DEF aas_05 = '         ';
DEF aas_06 = '         ';
DEF aas_07 = '         ';
DEF aas_08 = '         ';
DEF aas_09 = '         ';
DEF aas_10 = '         ';
DEF aas_11 = '         ';
DEF aas_12 = '         ';
DEF aas_13 = '         ';
COL aas_01 NEW_V aas_01 FOR A9 TRUNC NOPRI;
COL aas_02 NEW_V aas_02 FOR A9 TRUNC NOPRI;
COL aas_03 NEW_V aas_03 FOR A9 TRUNC NOPRI;
COL aas_04 NEW_V aas_04 FOR A9 TRUNC NOPRI;
COL aas_05 NEW_V aas_05 FOR A9 TRUNC NOPRI;
COL aas_06 NEW_V aas_06 FOR A9 TRUNC NOPRI;
COL aas_07 NEW_V aas_07 FOR A9 TRUNC NOPRI;
COL aas_08 NEW_V aas_08 FOR A9 TRUNC NOPRI;
COL aas_09 NEW_V aas_09 FOR A9 TRUNC NOPRI;
COL aas_10 NEW_V aas_10 FOR A9 TRUNC NOPRI;
COL aas_11 NEW_V aas_11 FOR A9 TRUNC NOPRI;
COL aas_12 NEW_V aas_12 FOR A9 TRUNC NOPRI;
COL aas_13 NEW_V aas_13 FOR A9 TRUNC NOPRI;
--
WITH
FUNCTION get_sql_text (p_sql_id IN VARCHAR2)
RETURN VARCHAR2
IS
  l_sql_text VARCHAR2(4000);
BEGIN
  SELECT MAX(REPLACE(REPLACE(SUBSTR(sql_text, 1, 100), CHR(10), CHR(32)), CHR(9), CHR(32))) AS sql_text
    INTO l_sql_text
    FROM v$sql
   WHERE sql_id = p_sql_id
     AND ROWNUM = 1;
  -- 
  IF l_sql_text IS NOT NULL THEN
    RETURN REPLACE(REPLACE(l_sql_text, ':'), '''');
  END IF;
  --
  SELECT MAX(REPLACE(REPLACE(DBMS_LOB.substr(sql_text, 100), CHR(10), CHR(32)), CHR(9), CHR(32))) AS sql_text
    INTO l_sql_text
    FROM dba_hist_sqltext
   WHERE sql_id = p_sql_id
     AND dbid = &&cs_dbid.
     AND ROWNUM = 1;
  --
  RETURN REPLACE(REPLACE(l_sql_text, ':'), '''');
END get_sql_text;
--
FUNCTION get_pdb_name (p_con_id IN VARCHAR2)
RETURN VARCHAR2
IS
  l_pdb_name VARCHAR2(4000);
BEGIN
  SELECT name
    INTO l_pdb_name
    FROM v$containers
   WHERE con_id = TO_NUMBER(p_con_id);
  --
  RETURN l_pdb_name;
END get_pdb_name;
--
FUNCTION application_category (
  p_sql_text     IN VARCHAR2, 
  p_command_name IN VARCHAR2 DEFAULT NULL
)
RETURN VARCHAR2
IS
  k_appl_handle_prefix CONSTANT VARCHAR2(30) := '/*'||CHR(37);
  k_appl_handle_suffix CONSTANT VARCHAR2(30) := CHR(37)||'*/'||CHR(37);
BEGIN
  IF    p_sql_text LIKE k_appl_handle_prefix||'Transaction Processing'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'addTransactionRow'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'checkEndRowValid'||k_appl_handle_suffix
    OR  p_sql_text LIKE k_appl_handle_prefix||'checkStartRowValid'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'deleteValue'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'exists'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch commit by idempotency token'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch latest transactions for cache'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Find lower commit id for transaction cache warm up'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'findMatchingRow'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getMaxTransactionCommitID'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getNewTransactionID'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getTransactionProgress'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'lockForCommit'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'lockKievTransactor'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'putBucket'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'readTransactionsSince'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'recordTransactionState'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'setValue'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'SPM:CP'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'updateIdentityValue'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'updateNextKievTransID'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'updateTransactorState'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'upsert_transactor_state'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'writeTransactionKeys'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'QueryTransactorHosts'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'WriteBucketValues'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'batch commit'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'batch mutation log'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'fetchAllIdentities'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'fetch_epoch'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'readFromTxorStateBeginTxn'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'readOnlyBeginTxn'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'validateTransactorState'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getDataStoreMaxTransaction'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'legacyGetDataStoreMaxTransaction'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'isPartitionDropDisabled'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getWithVersionOffsetSql'||k_appl_handle_suffix 
    OR  LOWER(p_sql_text) LIKE CHR(37)||'lock table kievtransactions'||CHR(37) 
    --
    OR  p_sql_text LIKE k_appl_handle_prefix||'Set ddl lock timeout for session'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'delete.leases'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'delete.workflow_instances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'delete.step_instances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'delete.historical_assignments'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'delete.workflow_definitions'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'delete.step_definitions'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'delete.leases_types'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getForUpdate.dataplane_alias'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'insert.leases_types'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'insert.leases'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'insert.workflow_instances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'insert.step_instances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'insert.historical_assignments'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'insert.workflow_definitions'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'insert.step_definitions'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'update.dataplane_alias'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'update.leases'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'update.workflow_instances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'update.step_instances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'update.historical_assignments'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'update.workflow_definitions'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Drop partition'||k_appl_handle_suffix 
  THEN RETURN 'TP'; /* Transaction Processing */
  --
  ELSIF p_sql_text LIKE k_appl_handle_prefix||'Read Only'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'bucketIndexSelect'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'bucketKeySelect'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'bucketValueSelect'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'countTransactions'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch snapshots'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Get system time'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getAutoSequences'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getNextIdentityValue'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getValues'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Lock row Bucket_Snapshot'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'longFromDual'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'performContinuedScanValues'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'performFirstRowsScanQuery'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'performScanQuery'||k_appl_handle_suffix
    OR  p_sql_text LIKE k_appl_handle_prefix||'performSnapshotScanQuery'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'performStartScanValues'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'selectBuckets'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch latest revisions'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch max sequence for'||k_appl_handle_suffix -- streaming
    OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch partition interval for'||k_appl_handle_suffix -- streaming
    OR  p_sql_text LIKE k_appl_handle_prefix||'Find High value for'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Find partitions for'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Init lock name for snapshot'||k_appl_handle_suffix -- snapshot
    OR  p_sql_text LIKE k_appl_handle_prefix||'List snapshot tables.'||k_appl_handle_suffix -- snapshot
    OR  p_sql_text LIKE k_appl_handle_prefix||'Tail read bucket'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'performSegmentedScanQuery'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'listArchiveStatusByIndexName'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'listAssignmentsByIndexName'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'listHosts'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'updateHost'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'updateArchiveStatus'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'updateOperationLock'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get KIEVWORKFLOWS table indexes'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'GetOldestLsn'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'GetStreamRecords'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Check if another workflow is running'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Delete old workflows from'||k_appl_handle_suffix 
    --
    OR  p_sql_text LIKE k_appl_handle_prefix||'getFutureWorkflowDefinition'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getPriorWorkflowDefinition'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'enumerateLeases'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'enumerateLeaseTypes'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getHistoricalAssignments'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getAllWorkflowDefinitions'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getVersionHistory'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getInstances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Find interval partitions for schema'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getStepInstances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getOldestGcWorkflowInstance'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getNextRecordID'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get.dataplane_alias'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getLeaseNonce'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get.leases_types'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get.leases'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get.workflow_instances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getByKey.workflow_instances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getRecordId.workflow_instances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getLast.historical_assignments'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get.historical_assignments'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'isPartitionDropDisabled'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Check if there are active rows for partition'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getRunningInstancesCount'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get.workflow_definitions'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getLatestWorkflowDefinition'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getLast.step_instances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get.workflow_instances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get.step_instances'||k_appl_handle_suffix 
  THEN RETURN 'RO'; /* Read Only */
  --
  ELSIF p_sql_text LIKE k_appl_handle_prefix||'Background'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Bootstrap snapshot table Kiev_S'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'bucketIdentitySelect'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'checkMissingTables'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'countAllBuckets'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'countAllRows'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'countKievTransactionRows'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'countKtkRows'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Delete garbage'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Delete rows from'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'deleteBucketGarbage'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'enumerateSequences'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch config'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'fetch_leader_heartbeat'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'gcEventMaxId'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'gcEventTryInsert'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Get txn at time'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get_leader'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getCurEndTime'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getDBSchemaVersion'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getEndTimeOlderThan'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getGCLogEntries'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getMaxTransactionOlderThan'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getSchemaMetadata'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getSupportedLibVersions'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'hashBucket'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'hashSnapshot'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Populate workspace'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'populateBucketGCWorkspace'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'primeTxCache'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'readOnlyRoleExists'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Row count between transactions'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'secondsSinceLastGcEvent'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'sync_leadership'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Test if table Kiev_S'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Update snapshot metadata'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'update_heartbeat'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'validateIfWorkspaceEmpty'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'verify_is_leader'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Checking existence of Mutation Log Table'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Checks if KIEVTRANSACTIONKEYS table is empty'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Checks if KIEVTRANSACTIONS table is empty'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch partition interval for KT'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch partition interval for KTK'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Insert dynamic config'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'createProxyUser'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'createSequence'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'deregister_host'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'dropAutoSequenceMetadata'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'dropBucketFromMetadata'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'dropSequenceMetadata'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get KievTransactionKeys table indexes'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get KievTransactions table indexes'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get session count'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'initializeMetadata'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'isKtPartitioned'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'isPartitioned'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'log'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'register_host'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'updateSchemaVersionInDB'||k_appl_handle_suffix 
    --
    OR  p_sql_text LIKE k_appl_handle_prefix||'getUnownedLeases'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getFutureWorks'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getMinorVersionsAtAndAfter'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getLeaseDecorators'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getUnownedLeasesByFiFo'||k_appl_handle_suffix 
  THEN RETURN 'BG'; /* Background */
  --
  ELSIF p_sql_text LIKE k_appl_handle_prefix||'Ignore'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'enumerateKievPdbs'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getJDBCSuffix'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'MV_REFRESH'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'null'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'selectColumnsForTable'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'selectDatastoreMd'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'SQL Analyze('||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'validateDataStoreId'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'countMetadata'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'countSequenceInstances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'iod-telemetry'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'insert snapshot metadata'||k_appl_handle_suffix 
    OR  p_sql_text LIKE CHR(37)||k_appl_handle_prefix||'OPT_DYN_SAMP'||k_appl_handle_suffix 
  THEN RETURN 'IG'; /* Ignore */
  --
  ELSIF p_command_name IN ('INSERT', 'UPDATE')
  THEN RETURN 'TP'; /* Transaction Processing */
  --
  ELSIF p_command_name = 'DELETE'
  THEN RETURN 'BG'; /* Background */
  --
  ELSIF p_command_name = 'SELECT'
  THEN RETURN 'RO'; /* Read Only */
  --
  ELSE RETURN 'UN'; /* Unknown */
  END IF;
END application_category;
--
wait_classes AS (
      SELECT  1 AS rn, 'ON CPU'         AS dimension_group FROM DUAL
UNION SELECT  2 AS rn, 'User I/O'       AS dimension_group FROM DUAL
UNION SELECT  3 AS rn, 'System I/O'     AS dimension_group FROM DUAL
UNION SELECT  4 AS rn, 'Cluster'        AS dimension_group FROM DUAL
UNION SELECT  5 AS rn, 'Commit'         AS dimension_group FROM DUAL
UNION SELECT  6 AS rn, 'Concurrency'    AS dimension_group FROM DUAL
UNION SELECT  7 AS rn, 'Application'    AS dimension_group FROM DUAL
UNION SELECT  8 AS rn, 'Administrative' AS dimension_group FROM DUAL
UNION SELECT  9 AS rn, 'Configuration'  AS dimension_group FROM DUAL
UNION SELECT 10 AS rn, 'Network'        AS dimension_group FROM DUAL
UNION SELECT 11 AS rn, 'Queueing'       AS dimension_group FROM DUAL
UNION SELECT 12 AS rn, 'Scheduler'      AS dimension_group FROM DUAL
UNION SELECT 13 AS rn, 'Other'          AS dimension_group FROM DUAL
),
sql_txt AS (
  SELECT /*+ MATERIALIZE NO_MERGE */ sql_id, MAX(sql_text) AS sql_text
  FROM (
          SELECT /*+ MATERIALIZE NO_MERGE */ sql_id, REPLACE(REPLACE(SUBSTR(sql_text, 1, 100), CHR(10), CHR(32)), CHR(9), CHR(32)) AS sql_text
            FROM v$sql
          WHERE '&&cs2_sql_text_piece.' IS NOT NULL
            AND UPPER(sql_text) LIKE CHR(37)||UPPER('&&cs2_sql_text_piece.')||CHR(37)
            AND ROWNUM >= 1
          UNION ALL
          SELECT /*+ MATERIALIZE NO_MERGE */ sql_id, REPLACE(REPLACE(DBMS_LOB.substr(sql_text, 100), CHR(10), CHR(32)), CHR(9), CHR(32)) AS sql_text
            FROM dba_hist_sqltext
          WHERE '&&cs2_sql_text_piece.' IS NOT NULL
            AND UPPER(DBMS_LOB.substr(sql_text, 1000)) LIKE CHR(37)||UPPER('&&cs2_sql_text_piece.')||CHR(37)
            AND dbid = &&cs_dbid.
            AND ROWNUM >= 1
  )
  GROUP BY sql_id
),
ash_awr AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       &&cs2_group. AS dimension_group,
       10 * COUNT(*) AS db_seconds
  FROM dba_hist_active_sess_history h,
       sql_txt t
 WHERE h.sample_time <= TO_TIMESTAMP('&&cs_ash_cut_off_date.', 'YYYY-MM-DD"T"HH24:MI')
   AND h.sample_time >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND h.sample_time < TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND h.dbid = TO_NUMBER('&&cs_dbid.')
   AND h.instance_number = TO_NUMBER('&&cs_instance_number.')
   AND h.snap_id BETWEEN TO_NUMBER('&&cs_snap_id_from.') AND TO_NUMBER('&&cs_snap_id_to.') + 1
   AND ('&&cs2_session_state.' IS NULL OR h.session_state = '&&cs2_session_state.')
   AND ('&&cs2_wait_class.' IS NULL OR h.wait_class = '&&cs2_wait_class.')
   AND ('&&cs2_event.' IS NULL OR h.event LIKE CHR(37)||'&&cs2_event.'||CHR(37))
   AND ('&&cs2_machine.' IS NULL OR h.machine LIKE CHR(37)||'&&cs2_machine.'||CHR(37))
   AND ('&&cs2_sql_text_piece.' IS NULL OR h.sql_id IN (SELECT /*+ NO_MERGE */ t.sql_id FROM sql_txt t))
   AND ('&&cs2_sql_id.' IS NULL OR h.sql_id = '&&cs2_sql_id.')
   AND t.sql_id(+) = h.sql_id
   AND ROWNUM >= 1 /* MATERIALIZE */
 GROUP BY
       &&cs2_group.
),
ash_mem AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       &&cs2_group. AS dimension_group,
       1 * COUNT(*) AS db_seconds
  FROM v$active_session_history h,
       sql_txt t
 WHERE h.sample_time > TO_TIMESTAMP('&&cs_ash_cut_off_date.', 'YYYY-MM-DD"T"HH24:MI')
   AND h.sample_time >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND h.sample_time < TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND ('&&cs2_session_state.' IS NULL OR h.session_state = '&&cs2_session_state.')
   AND ('&&cs2_wait_class.' IS NULL OR h.wait_class = '&&cs2_wait_class.')
   AND ('&&cs2_event.' IS NULL OR h.event LIKE CHR(37)||'&&cs2_event.'||CHR(37))
   AND ('&&cs2_machine.' IS NULL OR h.machine LIKE CHR(37)||'&&cs2_machine.'||CHR(37))
   AND ('&&cs2_sql_text_piece.' IS NULL OR h.sql_id IN (SELECT /*+ NO_MERGE */ t.sql_id FROM sql_txt t))
   AND ('&&cs2_sql_id.' IS NULL OR h.sql_id = '&&cs2_sql_id.')
   AND t.sql_id(+) = h.sql_id
   AND ROWNUM >= 1 /* MATERIALIZE */
 GROUP BY
       &&cs2_group.
), 
ash_all AS (
SELECT dimension_group, db_seconds FROM ash_awr
 UNION ALL
SELECT dimension_group, db_seconds FROM ash_mem
),
ash_by_dim AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       ROUND(SUM(db_seconds) / TO_NUMBER('&&cs_from_to_seconds.'), 3) AS aas,
       SUM(db_seconds) AS db_seconds,
       dimension_group,
       ROW_NUMBER() OVER(ORDER BY SUM(db_seconds) DESC) AS rn
  FROM ash_all a
 GROUP BY
       dimension_group
),
top AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       rn, -- up to 12
       aas,
       db_seconds,
       SUBSTR(CASE
         WHEN TRIM(dimension_group) IS NULL /*OR TRIM(dimension_group) = ','*/ THEN '"null"'
         WHEN '&&cs2_dimension.' IN ('sql_id', 'top_level_sql_id') THEN dimension_group||' '||get_sql_text(dimension_group)
         WHEN '&&cs2_dimension.' = 'pdb_name' THEN dimension_group||' '||get_pdb_name(dimension_group)
         ELSE dimension_group
       END, 1, 64) AS dimension_group
  FROM ash_by_dim
 WHERE rn < (SELECT MAX(rn) FROM wait_classes) -- 13
),
max_top AS (
SELECT /*+ MATERIALIZE NO_MERGE */ MAX(rn) AS max_rn FROM top
),
bottom AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       (1 + max_top.max_rn) AS bottom_rn, -- up to 13
       ROUND(SUM(a.db_seconds) / TO_NUMBER('&&cs_from_to_seconds.'), 3) AS aas,
       SUM(a.db_seconds) AS db_seconds,
       '"all others"' AS dimension_group
  FROM ash_by_dim a, max_top
 WHERE a.rn >= max_top.max_rn
 GROUP BY
       max_top.max_rn
),
wait_classes2 AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       w.rn,
       NVL(t.aas, 0) AS aas,
       NVL(t.db_seconds, 0) AS db_seconds,
       w.dimension_group
  FROM wait_classes w,
       top t
 WHERE '&&cs2_dimension.' = 'wait_class'
   AND t.dimension_group(+) = w.dimension_group
),
top_and_bottom AS (
SELECT rn, aas, db_seconds, dimension_group
  FROM top
 WHERE '&&cs2_dimension.' <> 'wait_class'
 UNION ALL
SELECT rn, aas, db_seconds, dimension_group
  FROM wait_classes2
 WHERE '&&cs2_dimension.' = 'wait_class'
 UNION ALL
SELECT bottom_rn AS rn, aas, db_seconds, dimension_group
  FROM bottom
 WHERE '&&cs2_dimension.' <> 'wait_class'
),
list AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       rn, LPAD(TRIM(TO_CHAR(ROUND(aas, 3), '9,990.000')), 9) AS aas, db_seconds, dimension_group
  FROM top_and_bottom
)
SELECT rn, aas, db_seconds, dimension_group,
       COALESCE((SELECT dimension_group FROM list WHERE rn =  1), ' ') AS series_01,
       COALESCE((SELECT dimension_group FROM list WHERE rn =  2), ' ') AS series_02,
       COALESCE((SELECT dimension_group FROM list WHERE rn =  3), ' ') AS series_03,
       COALESCE((SELECT dimension_group FROM list WHERE rn =  4), ' ') AS series_04,
       COALESCE((SELECT dimension_group FROM list WHERE rn =  5), ' ') AS series_05,
       COALESCE((SELECT dimension_group FROM list WHERE rn =  6), ' ') AS series_06,
       COALESCE((SELECT dimension_group FROM list WHERE rn =  7), ' ') AS series_07,
       COALESCE((SELECT dimension_group FROM list WHERE rn =  8), ' ') AS series_08,
       COALESCE((SELECT dimension_group FROM list WHERE rn =  9), ' ') AS series_09,
       COALESCE((SELECT dimension_group FROM list WHERE rn = 10), ' ') AS series_10,
       COALESCE((SELECT dimension_group FROM list WHERE rn = 11), ' ') AS series_11,
       COALESCE((SELECT dimension_group FROM list WHERE rn = 12), ' ') AS series_12,
       COALESCE((SELECT dimension_group FROM list WHERE rn = 13), ' ') AS series_13,
       (SELECT aas FROM list WHERE rn =  1) AS aas_01,
       (SELECT aas FROM list WHERE rn =  2) AS aas_02,
       (SELECT aas FROM list WHERE rn =  3) AS aas_03,
       (SELECT aas FROM list WHERE rn =  4) AS aas_04,
       (SELECT aas FROM list WHERE rn =  5) AS aas_05,
       (SELECT aas FROM list WHERE rn =  6) AS aas_06,
       (SELECT aas FROM list WHERE rn =  7) AS aas_07,
       (SELECT aas FROM list WHERE rn =  8) AS aas_08,
       (SELECT aas FROM list WHERE rn =  9) AS aas_09,
       (SELECT aas FROM list WHERE rn = 10) AS aas_10,
       (SELECT aas FROM list WHERE rn = 11) AS aas_11,
       (SELECT aas FROM list WHERE rn = 12) AS aas_12,
       (SELECT aas FROM list WHERE rn = 13) AS aas_13
  FROM list
 ORDER BY
       rn
/
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
DEF report_title = 'Average Active Sessions by "&&cs2_dimension." between &&cs_sample_time_from. and &&cs_sample_time_to. UTC';
DEF chart_title = '&&report_title.';
DEF vaxis_title = 'Average Active Sessions (AAS)';
DEF xaxis_title = '';
--
COL xaxis_title NEW_V xaxis_title NOPRI;
SELECT
'RGN:"&&cs_rgn." '||
CASE WHEN '&&cs_con_name.' = 'CDB$ROOT' THEN UPPER('CDB:"&&cs_db_name." ') ELSE 'PDB:"&&cs_con_name." ' END||
CASE WHEN '&&cs2_session_state.' IS NOT NULL THEN 'State:"&&cs2_session_state." ' END||
CASE WHEN '&&cs2_wait_class.' IS NOT NULL THEN 'Wait:"&&cs2_wait_class." ' END||
CASE WHEN '&&cs2_event.' IS NOT NULL THEN 'Event:"%&&cs2_event.%" ' END||
CASE WHEN '&&cs2_machine.' IS NOT NULL THEN 'Machine:"%&&cs2_machine.%" ' END||
CASE WHEN '&&cs2_sql_text_piece.' IS NOT NULL THEN 'Text:"%&&cs2_sql_text_piece.%" ' END||
CASE WHEN '&&cs2_sql_id.' IS NOT NULL THEN 'SQL_ID:"&&cs2_sql_id." ' END AS xaxis_title
FROM DUAL;
--
-- (isStacked is true and baseline is null) or (not isStacked and baseline >= 0)
--DEF is_stacked = "isStacked: false,";
DEF is_stacked = "isStacked: true,";
--DEF vaxis_baseline = ", baseline:&&cs_num_cpu_cores., baselineColor:'red'";
DEF vaxis_baseline = "";
--DEF chart_foot_note_2 = "<br>2)";
DEF chart_foot_note_2 = '<br>2) &&xaxis_title.';
DEF chart_foot_note_3 = "<br>";
DEF chart_foot_note_4 = "";
DEF report_foot_note = 'SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&cs2_granularity." "&&cs2_dimension." "&&cs2_session_state." "&&cs2_wait_class." "&&cs2_event." "&&cs2_machine." "&&cs2_sql_text_piece." "&&cs2_sql_id."';
--
@@cs_internal/cs_spool_head_chart.sql
--
PRO ,{label:'&&series_01.', id:'01', type:'number'}
PRO ,{label:'&&series_02.', id:'02', type:'number'}
PRO ,{label:'&&series_03.', id:'03', type:'number'}
PRO ,{label:'&&series_04.', id:'04', type:'number'}
PRO ,{label:'&&series_05.', id:'05', type:'number'}
PRO ,{label:'&&series_06.', id:'06', type:'number'}
PRO ,{label:'&&series_07.', id:'07', type:'number'}
PRO ,{label:'&&series_08.', id:'08', type:'number'}
PRO ,{label:'&&series_09.', id:'09', type:'number'}
PRO ,{label:'&&series_10.', id:'10', type:'number'}
PRO ,{label:'&&series_11.', id:'11', type:'number'}
PRO ,{label:'&&series_12.', id:'12', type:'number'}
PRO ,{label:'&&series_13.', id:'13', type:'number'}     
PRO ]
SET HEA OFF PAGES 0;
/****************************************************************************************/
WITH
FUNCTION num_format (p_number IN NUMBER, p_round IN NUMBER DEFAULT 0) 
RETURN VARCHAR2 IS
BEGIN
  IF p_number IS NULL OR ROUND(p_number, p_round) <= 0 THEN
    RETURN 'null';
  ELSE
    RETURN TO_CHAR(ROUND(p_number, p_round));
  END IF;
END num_format;
/****************************************************************************************/
FUNCTION ceil_timestamp (p_timestamp IN TIMESTAMP)
RETURN DATE
IS
BEGIN
  IF '&&cs2_granularity.' = '1s' THEN
    RETURN CAST(p_timestamp AS DATE);
  ELSIF '&&cs2_granularity.' = '5s' THEN
    RETURN TRUNC(CAST(p_timestamp AS DATE), 'MI') + FLOOR(TO_NUMBER(TO_CHAR(CAST(p_timestamp AS DATE), '&&cs2_fmt.')) / 5) * 5 / (24 * 60 * 60) + &&cs2_plus_days.;
  ELSIF '&&cs2_granularity.' = '10s' THEN
    RETURN TRUNC(CAST(p_timestamp AS DATE), 'MI') + FLOOR(TO_NUMBER(TO_CHAR(CAST(p_timestamp AS DATE), '&&cs2_fmt.')) / 10) * 10 / (24 * 60 * 60) + &&cs2_plus_days.;
  ELSIF '&&cs2_granularity.' = '15s' THEN
    RETURN TRUNC(CAST(p_timestamp AS DATE), 'MI') + FLOOR(TO_NUMBER(TO_CHAR(CAST(p_timestamp AS DATE), '&&cs2_fmt.')) / 15) * 15 / (24 * 60 * 60) + &&cs2_plus_days.;
  ELSIF '&&cs2_granularity.' = '5m' THEN
    RETURN TRUNC(CAST(p_timestamp AS DATE), 'HH') + FLOOR(TO_NUMBER(TO_CHAR(CAST(p_timestamp AS DATE), '&&cs2_fmt.')) / 5) * 5 / (24 * 60) + &&cs2_plus_days.;
  ELSIF '&&cs2_granularity.' = '15m' THEN
    RETURN TRUNC(CAST(p_timestamp AS DATE), 'HH') + FLOOR(TO_NUMBER(TO_CHAR(CAST(p_timestamp AS DATE), '&&cs2_fmt.')) / 15) * 15 / (24 * 60) + &&cs2_plus_days.;
  ELSE -- 1s, 1m, 1h, 1d
    RETURN TRUNC(CAST(p_timestamp AS DATE) + &&cs2_plus_days., '&&cs2_fmt.');
  END IF;
END ceil_timestamp;
/****************************************************************************************/
FUNCTION get_sql_text (p_sql_id IN VARCHAR2)
RETURN VARCHAR2
IS
  l_sql_text VARCHAR2(4000);
BEGIN
  SELECT MAX(REPLACE(REPLACE(SUBSTR(sql_text, 1, 100), CHR(10), CHR(32)), CHR(9), CHR(32))) AS sql_text
    INTO l_sql_text
    FROM v$sql
   WHERE sql_id = p_sql_id
     AND ROWNUM = 1;
  -- 
  IF l_sql_text IS NOT NULL THEN
    RETURN REPLACE(REPLACE(l_sql_text, ':'), '''');
  END IF;
  --
  SELECT MAX(REPLACE(REPLACE(DBMS_LOB.substr(sql_text, 100), CHR(10), CHR(32)), CHR(9), CHR(32))) AS sql_text
    INTO l_sql_text
    FROM dba_hist_sqltext
   WHERE sql_id = p_sql_id
     AND dbid = &&cs_dbid.
     AND ROWNUM = 1;
  --
  RETURN REPLACE(REPLACE(l_sql_text, ':'), '''');
END get_sql_text;
/****************************************************************************************/
FUNCTION get_pdb_name (p_con_id IN VARCHAR2)
RETURN VARCHAR2
IS
  l_pdb_name VARCHAR2(4000);
BEGIN
  SELECT name
    INTO l_pdb_name
    FROM v$containers
   WHERE con_id = TO_NUMBER(p_con_id);
  --
  RETURN l_pdb_name;
END get_pdb_name;
/****************************************************************************************/
FUNCTION application_category (
  p_sql_text     IN VARCHAR2, 
  p_command_name IN VARCHAR2 DEFAULT NULL
)
RETURN VARCHAR2
IS
  k_appl_handle_prefix CONSTANT VARCHAR2(30) := '/*'||CHR(37);
  k_appl_handle_suffix CONSTANT VARCHAR2(30) := CHR(37)||'*/'||CHR(37);
BEGIN
  IF    p_sql_text LIKE k_appl_handle_prefix||'Transaction Processing'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'addTransactionRow'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'checkEndRowValid'||k_appl_handle_suffix
    OR  p_sql_text LIKE k_appl_handle_prefix||'checkStartRowValid'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'deleteValue'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'exists'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch commit by idempotency token'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch latest transactions for cache'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Find lower commit id for transaction cache warm up'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'findMatchingRow'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getMaxTransactionCommitID'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getNewTransactionID'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getTransactionProgress'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'lockForCommit'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'lockKievTransactor'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'putBucket'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'readTransactionsSince'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'recordTransactionState'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'setValue'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'SPM:CP'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'updateIdentityValue'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'updateNextKievTransID'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'updateTransactorState'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'upsert_transactor_state'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'writeTransactionKeys'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'QueryTransactorHosts'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'WriteBucketValues'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'batch commit'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'batch mutation log'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'fetchAllIdentities'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'fetch_epoch'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'readFromTxorStateBeginTxn'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'readOnlyBeginTxn'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'validateTransactorState'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getDataStoreMaxTransaction'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'legacyGetDataStoreMaxTransaction'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'isPartitionDropDisabled'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getWithVersionOffsetSql'||k_appl_handle_suffix 
    OR  LOWER(p_sql_text) LIKE CHR(37)||'lock table kievtransactions'||CHR(37) 
    --
    OR  p_sql_text LIKE k_appl_handle_prefix||'Set ddl lock timeout for session'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'delete.leases'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'delete.workflow_instances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'delete.step_instances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'delete.historical_assignments'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'delete.workflow_definitions'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'delete.step_definitions'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'delete.leases_types'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getForUpdate.dataplane_alias'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'insert.leases_types'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'insert.leases'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'insert.workflow_instances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'insert.step_instances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'insert.historical_assignments'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'insert.workflow_definitions'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'insert.step_definitions'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'update.dataplane_alias'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'update.leases'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'update.workflow_instances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'update.step_instances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'update.historical_assignments'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'update.workflow_definitions'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Drop partition'||k_appl_handle_suffix 
  THEN RETURN 'TP'; /* Transaction Processing */
  --
  ELSIF p_sql_text LIKE k_appl_handle_prefix||'Read Only'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'bucketIndexSelect'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'bucketKeySelect'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'bucketValueSelect'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'countTransactions'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch snapshots'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Get system time'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getAutoSequences'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getNextIdentityValue'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getValues'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Lock row Bucket_Snapshot'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'longFromDual'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'performContinuedScanValues'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'performFirstRowsScanQuery'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'performScanQuery'||k_appl_handle_suffix
    OR  p_sql_text LIKE k_appl_handle_prefix||'performSnapshotScanQuery'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'performStartScanValues'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'selectBuckets'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch latest revisions'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch max sequence for'||k_appl_handle_suffix -- streaming
    OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch partition interval for'||k_appl_handle_suffix -- streaming
    OR  p_sql_text LIKE k_appl_handle_prefix||'Find High value for'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Find partitions for'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Init lock name for snapshot'||k_appl_handle_suffix -- snapshot
    OR  p_sql_text LIKE k_appl_handle_prefix||'List snapshot tables.'||k_appl_handle_suffix -- snapshot
    OR  p_sql_text LIKE k_appl_handle_prefix||'Tail read bucket'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'performSegmentedScanQuery'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'listArchiveStatusByIndexName'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'listAssignmentsByIndexName'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'listHosts'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'updateHost'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'updateArchiveStatus'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'updateOperationLock'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get KIEVWORKFLOWS table indexes'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'GetOldestLsn'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'GetStreamRecords'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Check if another workflow is running'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Delete old workflows from'||k_appl_handle_suffix 
    --
    OR  p_sql_text LIKE k_appl_handle_prefix||'getFutureWorkflowDefinition'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getPriorWorkflowDefinition'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'enumerateLeases'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'enumerateLeaseTypes'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getHistoricalAssignments'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getAllWorkflowDefinitions'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getVersionHistory'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getInstances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Find interval partitions for schema'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getStepInstances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getOldestGcWorkflowInstance'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getNextRecordID'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get.dataplane_alias'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getLeaseNonce'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get.leases_types'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get.leases'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get.workflow_instances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getByKey.workflow_instances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getRecordId.workflow_instances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getLast.historical_assignments'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get.historical_assignments'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'isPartitionDropDisabled'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Check if there are active rows for partition'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getRunningInstancesCount'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get.workflow_definitions'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getLatestWorkflowDefinition'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getLast.step_instances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get.workflow_instances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get.step_instances'||k_appl_handle_suffix 
  THEN RETURN 'RO'; /* Read Only */
  --
  ELSIF p_sql_text LIKE k_appl_handle_prefix||'Background'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Bootstrap snapshot table Kiev_S'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'bucketIdentitySelect'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'checkMissingTables'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'countAllBuckets'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'countAllRows'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'countKievTransactionRows'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'countKtkRows'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Delete garbage'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Delete rows from'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'deleteBucketGarbage'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'enumerateSequences'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch config'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'fetch_leader_heartbeat'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'gcEventMaxId'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'gcEventTryInsert'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Get txn at time'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get_leader'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getCurEndTime'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getDBSchemaVersion'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getEndTimeOlderThan'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getGCLogEntries'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getMaxTransactionOlderThan'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getSchemaMetadata'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getSupportedLibVersions'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'hashBucket'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'hashSnapshot'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Populate workspace'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'populateBucketGCWorkspace'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'primeTxCache'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'readOnlyRoleExists'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Row count between transactions'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'secondsSinceLastGcEvent'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'sync_leadership'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Test if table Kiev_S'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Update snapshot metadata'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'update_heartbeat'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'validateIfWorkspaceEmpty'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'verify_is_leader'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Checking existence of Mutation Log Table'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Checks if KIEVTRANSACTIONKEYS table is empty'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Checks if KIEVTRANSACTIONS table is empty'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch partition interval for KT'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch partition interval for KTK'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Insert dynamic config'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'createProxyUser'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'createSequence'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'deregister_host'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'dropAutoSequenceMetadata'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'dropBucketFromMetadata'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'dropSequenceMetadata'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get KievTransactionKeys table indexes'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get KievTransactions table indexes'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get session count'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'initializeMetadata'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'isKtPartitioned'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'isPartitioned'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'log'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'register_host'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'updateSchemaVersionInDB'||k_appl_handle_suffix 
    --
    OR  p_sql_text LIKE k_appl_handle_prefix||'getUnownedLeases'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getFutureWorks'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getMinorVersionsAtAndAfter'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getLeaseDecorators'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getUnownedLeasesByFiFo'||k_appl_handle_suffix 
  THEN RETURN 'BG'; /* Background */
  --
  ELSIF p_sql_text LIKE k_appl_handle_prefix||'Ignore'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'enumerateKievPdbs'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getJDBCSuffix'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'MV_REFRESH'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'null'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'selectColumnsForTable'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'selectDatastoreMd'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'SQL Analyze('||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'validateDataStoreId'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'countMetadata'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'countSequenceInstances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'iod-telemetry'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'insert snapshot metadata'||k_appl_handle_suffix 
    OR  p_sql_text LIKE CHR(37)||k_appl_handle_prefix||'OPT_DYN_SAMP'||k_appl_handle_suffix 
  THEN RETURN 'IG'; /* Ignore */
  --
  ELSIF p_command_name IN ('INSERT', 'UPDATE')
  THEN RETURN 'TP'; /* Transaction Processing */
  --
  ELSIF p_command_name = 'DELETE'
  THEN RETURN 'BG'; /* Background */
  --
  ELSIF p_command_name = 'SELECT'
  THEN RETURN 'RO'; /* Read Only */
  --
  ELSE RETURN 'UN'; /* Unknown */
  END IF;
END application_category;
/****************************************************************************************/
sample AS (
SELECT ceil_timestamp(TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') + ((LEVEL - 1) * &&cs2_plus_days.)) AS time FROM DUAL CONNECT BY LEVEL <= TO_NUMBER('&&cs2_samples.')
),
wait_classes AS (
      SELECT  1 AS rn, 'ON CPU'         AS dimension_group FROM DUAL
UNION SELECT  2 AS rn, 'User I/O'       AS dimension_group FROM DUAL
UNION SELECT  3 AS rn, 'System I/O'     AS dimension_group FROM DUAL
UNION SELECT  4 AS rn, 'Cluster'        AS dimension_group FROM DUAL
UNION SELECT  5 AS rn, 'Commit'         AS dimension_group FROM DUAL
UNION SELECT  6 AS rn, 'Concurrency'    AS dimension_group FROM DUAL
UNION SELECT  7 AS rn, 'Application'    AS dimension_group FROM DUAL
UNION SELECT  8 AS rn, 'Administrative' AS dimension_group FROM DUAL
UNION SELECT  9 AS rn, 'Configuration'  AS dimension_group FROM DUAL
UNION SELECT 10 AS rn, 'Network'        AS dimension_group FROM DUAL
UNION SELECT 11 AS rn, 'Queueing'       AS dimension_group FROM DUAL
UNION SELECT 12 AS rn, 'Scheduler'      AS dimension_group FROM DUAL
UNION SELECT 13 AS rn, 'Other'          AS dimension_group FROM DUAL
),
sql_txt AS (
  SELECT /*+ MATERIALIZE NO_MERGE */ sql_id, MAX(sql_text) AS sql_text
  FROM (
          SELECT /*+ MATERIALIZE NO_MERGE */ sql_id, REPLACE(REPLACE(SUBSTR(sql_text, 1, 100), CHR(10), CHR(32)), CHR(9), CHR(32)) AS sql_text
            FROM v$sql
          WHERE '&&cs2_sql_text_piece.' IS NOT NULL
            AND UPPER(sql_text) LIKE CHR(37)||UPPER('&&cs2_sql_text_piece.')||CHR(37)
            AND ROWNUM >= 1
          UNION ALL
          SELECT /*+ MATERIALIZE NO_MERGE */ sql_id, REPLACE(REPLACE(DBMS_LOB.substr(sql_text, 100), CHR(10), CHR(32)), CHR(9), CHR(32)) AS sql_text
            FROM dba_hist_sqltext
          WHERE '&&cs2_sql_text_piece.' IS NOT NULL
            AND UPPER(DBMS_LOB.substr(sql_text, 1000)) LIKE CHR(37)||UPPER('&&cs2_sql_text_piece.')||CHR(37)
            AND dbid = &&cs_dbid.
            AND ROWNUM >= 1
  )
  GROUP BY sql_id
),
ash_awr AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.sample_time,
       CASE 
         WHEN TRIM(&&cs2_group.) IS NULL THEN '"null"'
         WHEN '&&cs2_dimension.' IN ('sql_id', 'top_level_sql_id', 'pdb_name') THEN
           CASE
             WHEN &&cs2_group. = SUBSTR(q'[&&series_01.]', 1, INSTR(q'[&&series_01.]', ' ') - 1) THEN q'[&&series_01.]'
             WHEN &&cs2_group. = SUBSTR(q'[&&series_02.]', 1, INSTR(q'[&&series_02.]', ' ') - 1) THEN q'[&&series_02.]'
             WHEN &&cs2_group. = SUBSTR(q'[&&series_03.]', 1, INSTR(q'[&&series_03.]', ' ') - 1) THEN q'[&&series_03.]'
             WHEN &&cs2_group. = SUBSTR(q'[&&series_04.]', 1, INSTR(q'[&&series_04.]', ' ') - 1) THEN q'[&&series_04.]'
             WHEN &&cs2_group. = SUBSTR(q'[&&series_05.]', 1, INSTR(q'[&&series_05.]', ' ') - 1) THEN q'[&&series_05.]'
             WHEN &&cs2_group. = SUBSTR(q'[&&series_06.]', 1, INSTR(q'[&&series_06.]', ' ') - 1) THEN q'[&&series_06.]'
             WHEN &&cs2_group. = SUBSTR(q'[&&series_07.]', 1, INSTR(q'[&&series_07.]', ' ') - 1) THEN q'[&&series_07.]'
             WHEN &&cs2_group. = SUBSTR(q'[&&series_08.]', 1, INSTR(q'[&&series_08.]', ' ') - 1) THEN q'[&&series_08.]'
             WHEN &&cs2_group. = SUBSTR(q'[&&series_09.]', 1, INSTR(q'[&&series_09.]', ' ') - 1) THEN q'[&&series_09.]'
             WHEN &&cs2_group. = SUBSTR(q'[&&series_10.]', 1, INSTR(q'[&&series_10.]', ' ') - 1) THEN q'[&&series_10.]'
             WHEN &&cs2_group. = SUBSTR(q'[&&series_11.]', 1, INSTR(q'[&&series_11.]', ' ') - 1) THEN q'[&&series_11.]'
             WHEN &&cs2_group. = SUBSTR(q'[&&series_12.]', 1, INSTR(q'[&&series_12.]', ' ') - 1) THEN q'[&&series_12.]'
             WHEN &&cs2_group. = SUBSTR(q'[&&series_13.]', 1, INSTR(q'[&&series_13.]', ' ') - 1) THEN q'[&&series_13.]'
           ELSE '"all others"' END
         WHEN '&&cs2_dimension.' IN ('wait_class', 'event', 'machine', 'plan_hash_value', 'sid', 'blocking_session', 'current_obj#', 'module', 'program', 'sql_opname', 'appl_cat', 'p1', 'p2', 'p3') THEN
           CASE
             WHEN &&cs2_group. = q'[&&series_01.]' THEN q'[&&series_01.]'
             WHEN &&cs2_group. = q'[&&series_02.]' THEN q'[&&series_02.]'
             WHEN &&cs2_group. = q'[&&series_03.]' THEN q'[&&series_03.]'
             WHEN &&cs2_group. = q'[&&series_04.]' THEN q'[&&series_04.]'
             WHEN &&cs2_group. = q'[&&series_05.]' THEN q'[&&series_05.]'
             WHEN &&cs2_group. = q'[&&series_06.]' THEN q'[&&series_06.]'
             WHEN &&cs2_group. = q'[&&series_07.]' THEN q'[&&series_07.]'
             WHEN &&cs2_group. = q'[&&series_08.]' THEN q'[&&series_08.]'
             WHEN &&cs2_group. = q'[&&series_09.]' THEN q'[&&series_09.]'
             WHEN &&cs2_group. = q'[&&series_10.]' THEN q'[&&series_10.]'
             WHEN &&cs2_group. = q'[&&series_11.]' THEN q'[&&series_11.]'
             WHEN &&cs2_group. = q'[&&series_12.]' THEN q'[&&series_12.]'
             WHEN &&cs2_group. = q'[&&series_13.]' THEN q'[&&series_13.]'
           ELSE '"all others"' END
       ELSE '"all others"' END AS dimension_group
  FROM dba_hist_active_sess_history h,
       sql_txt t
 WHERE h.sample_time <= TO_TIMESTAMP('&&cs_ash_cut_off_date.', 'YYYY-MM-DD"T"HH24:MI')
   AND h.sample_time >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND h.sample_time < TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND h.dbid = TO_NUMBER('&&cs_dbid.')
   AND h.instance_number = TO_NUMBER('&&cs_instance_number.')
   AND h.snap_id BETWEEN TO_NUMBER('&&cs_snap_id_from.') AND TO_NUMBER('&&cs_snap_id_to.') + 1
   AND ('&&cs2_session_state.' IS NULL OR h.session_state = '&&cs2_session_state.')
   AND ('&&cs2_wait_class.' IS NULL OR h.wait_class = '&&cs2_wait_class.')
   AND ('&&cs2_event.' IS NULL OR h.event LIKE CHR(37)||'&&cs2_event.'||CHR(37))
   AND ('&&cs2_machine.' IS NULL OR h.machine LIKE CHR(37)||'&&cs2_machine.'||CHR(37))
   AND ('&&cs2_sql_text_piece.' IS NULL OR h.sql_id IN (SELECT /*+ NO_MERGE */ t.sql_id FROM sql_txt t))
   AND ('&&cs2_sql_id.' IS NULL OR h.sql_id = '&&cs2_sql_id.')
   AND t.sql_id(+) = h.sql_id
   AND ROWNUM >= 1 /* MATERIALIZE */
),
ash_mem AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.sample_time,
       CASE 
         WHEN TRIM(&&cs2_group.) IS NULL THEN '"null"'
         WHEN '&&cs2_dimension.' IN ('sql_id', 'top_level_sql_id', 'pdb_name') THEN
           CASE
             WHEN &&cs2_group. = SUBSTR(q'[&&series_01.]', 1, INSTR(q'[&&series_01.]', ' ') - 1) THEN q'[&&series_01.]'
             WHEN &&cs2_group. = SUBSTR(q'[&&series_02.]', 1, INSTR(q'[&&series_02.]', ' ') - 1) THEN q'[&&series_02.]'
             WHEN &&cs2_group. = SUBSTR(q'[&&series_03.]', 1, INSTR(q'[&&series_03.]', ' ') - 1) THEN q'[&&series_03.]'
             WHEN &&cs2_group. = SUBSTR(q'[&&series_04.]', 1, INSTR(q'[&&series_04.]', ' ') - 1) THEN q'[&&series_04.]'
             WHEN &&cs2_group. = SUBSTR(q'[&&series_05.]', 1, INSTR(q'[&&series_05.]', ' ') - 1) THEN q'[&&series_05.]'
             WHEN &&cs2_group. = SUBSTR(q'[&&series_06.]', 1, INSTR(q'[&&series_06.]', ' ') - 1) THEN q'[&&series_06.]'
             WHEN &&cs2_group. = SUBSTR(q'[&&series_07.]', 1, INSTR(q'[&&series_07.]', ' ') - 1) THEN q'[&&series_07.]'
             WHEN &&cs2_group. = SUBSTR(q'[&&series_08.]', 1, INSTR(q'[&&series_08.]', ' ') - 1) THEN q'[&&series_08.]'
             WHEN &&cs2_group. = SUBSTR(q'[&&series_09.]', 1, INSTR(q'[&&series_09.]', ' ') - 1) THEN q'[&&series_09.]'
             WHEN &&cs2_group. = SUBSTR(q'[&&series_10.]', 1, INSTR(q'[&&series_10.]', ' ') - 1) THEN q'[&&series_10.]'
             WHEN &&cs2_group. = SUBSTR(q'[&&series_11.]', 1, INSTR(q'[&&series_11.]', ' ') - 1) THEN q'[&&series_11.]'
             WHEN &&cs2_group. = SUBSTR(q'[&&series_12.]', 1, INSTR(q'[&&series_12.]', ' ') - 1) THEN q'[&&series_12.]'
             WHEN &&cs2_group. = SUBSTR(q'[&&series_13.]', 1, INSTR(q'[&&series_13.]', ' ') - 1) THEN q'[&&series_13.]'
           ELSE '"all others"' END
         WHEN '&&cs2_dimension.' IN ('wait_class', 'event', 'machine', 'plan_hash_value', 'sid', 'blocking_session', 'current_obj#', 'module', 'program', 'sql_opname', 'appl_cat', 'p1', 'p2', 'p3') THEN
           CASE
             WHEN &&cs2_group. = q'[&&series_01.]' THEN q'[&&series_01.]'
             WHEN &&cs2_group. = q'[&&series_02.]' THEN q'[&&series_02.]'
             WHEN &&cs2_group. = q'[&&series_03.]' THEN q'[&&series_03.]'
             WHEN &&cs2_group. = q'[&&series_04.]' THEN q'[&&series_04.]'
             WHEN &&cs2_group. = q'[&&series_05.]' THEN q'[&&series_05.]'
             WHEN &&cs2_group. = q'[&&series_06.]' THEN q'[&&series_06.]'
             WHEN &&cs2_group. = q'[&&series_07.]' THEN q'[&&series_07.]'
             WHEN &&cs2_group. = q'[&&series_08.]' THEN q'[&&series_08.]'
             WHEN &&cs2_group. = q'[&&series_09.]' THEN q'[&&series_09.]'
             WHEN &&cs2_group. = q'[&&series_10.]' THEN q'[&&series_10.]'
             WHEN &&cs2_group. = q'[&&series_11.]' THEN q'[&&series_11.]'
             WHEN &&cs2_group. = q'[&&series_12.]' THEN q'[&&series_12.]'
             WHEN &&cs2_group. = q'[&&series_13.]' THEN q'[&&series_13.]'
           ELSE '"all others"' END
       ELSE '"all others"' END AS dimension_group
  FROM v$active_session_history h,
       sql_txt t
 WHERE h.sample_time > TO_TIMESTAMP('&&cs_ash_cut_off_date.', 'YYYY-MM-DD"T"HH24:MI')
   AND h.sample_time >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND h.sample_time < TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND ('&&cs2_session_state.' IS NULL OR h.session_state = '&&cs2_session_state.')
   AND ('&&cs2_wait_class.' IS NULL OR h.wait_class = '&&cs2_wait_class.')
   AND ('&&cs2_event.' IS NULL OR h.event LIKE CHR(37)||'&&cs2_event.'||CHR(37))
   AND ('&&cs2_machine.' IS NULL OR h.machine LIKE CHR(37)||'&&cs2_machine.'||CHR(37))
   AND ('&&cs2_sql_text_piece.' IS NULL OR h.sql_id IN (SELECT /*+ NO_MERGE */ t.sql_id FROM sql_txt t))
   AND ('&&cs2_sql_id.' IS NULL OR h.sql_id = '&&cs2_sql_id.')
   AND t.sql_id(+) = h.sql_id
   AND ROWNUM >= 1 /* MATERIALIZE */
), 
ash_awr_denorm AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       ceil_timestamp(h.sample_time) AS time,
       --ROUND(24 * 3600 * (MAX(CAST(h.sample_time AS DATE)) - MIN(CAST(h.sample_time AS DATE))) + 10) AS interval_secs,
       SUM(CASE WHEN h.dimension_group = q'[&&series_01.]' THEN 10 ELSE 0 END) AS db_secs_01,
       SUM(CASE WHEN h.dimension_group = q'[&&series_02.]' THEN 10 ELSE 0 END) AS db_secs_02,
       SUM(CASE WHEN h.dimension_group = q'[&&series_03.]' THEN 10 ELSE 0 END) AS db_secs_03,
       SUM(CASE WHEN h.dimension_group = q'[&&series_04.]' THEN 10 ELSE 0 END) AS db_secs_04,
       SUM(CASE WHEN h.dimension_group = q'[&&series_05.]' THEN 10 ELSE 0 END) AS db_secs_05,
       SUM(CASE WHEN h.dimension_group = q'[&&series_06.]' THEN 10 ELSE 0 END) AS db_secs_06,
       SUM(CASE WHEN h.dimension_group = q'[&&series_07.]' THEN 10 ELSE 0 END) AS db_secs_07,
       SUM(CASE WHEN h.dimension_group = q'[&&series_08.]' THEN 10 ELSE 0 END) AS db_secs_08,
       SUM(CASE WHEN h.dimension_group = q'[&&series_09.]' THEN 10 ELSE 0 END) AS db_secs_09,
       SUM(CASE WHEN h.dimension_group = q'[&&series_10.]' THEN 10 ELSE 0 END) AS db_secs_10,
       SUM(CASE WHEN h.dimension_group = q'[&&series_11.]' THEN 10 ELSE 0 END) AS db_secs_11,
       SUM(CASE WHEN h.dimension_group = q'[&&series_12.]' THEN 10 ELSE 0 END) AS db_secs_12,
       SUM(CASE WHEN h.dimension_group = q'[&&series_13.]' THEN 10 ELSE 0 END) AS db_secs_13
  FROM ash_awr h
 GROUP BY
       ceil_timestamp(h.sample_time)
),
ash_mem_denorm AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       ceil_timestamp(h.sample_time) AS time,
       --ROUND(24 * 3600 * (MAX(CAST(h.sample_time AS DATE)) - MIN(CAST(h.sample_time AS DATE))) + 1) AS interval_secs,
       SUM(CASE WHEN h.dimension_group = q'[&&series_01.]' THEN 01 ELSE 0 END) AS db_secs_01,
       SUM(CASE WHEN h.dimension_group = q'[&&series_02.]' THEN 01 ELSE 0 END) AS db_secs_02,
       SUM(CASE WHEN h.dimension_group = q'[&&series_03.]' THEN 01 ELSE 0 END) AS db_secs_03,
       SUM(CASE WHEN h.dimension_group = q'[&&series_04.]' THEN 01 ELSE 0 END) AS db_secs_04,
       SUM(CASE WHEN h.dimension_group = q'[&&series_05.]' THEN 01 ELSE 0 END) AS db_secs_05,
       SUM(CASE WHEN h.dimension_group = q'[&&series_06.]' THEN 01 ELSE 0 END) AS db_secs_06,
       SUM(CASE WHEN h.dimension_group = q'[&&series_07.]' THEN 01 ELSE 0 END) AS db_secs_07,
       SUM(CASE WHEN h.dimension_group = q'[&&series_08.]' THEN 01 ELSE 0 END) AS db_secs_08,
       SUM(CASE WHEN h.dimension_group = q'[&&series_09.]' THEN 01 ELSE 0 END) AS db_secs_09,
       SUM(CASE WHEN h.dimension_group = q'[&&series_10.]' THEN 01 ELSE 0 END) AS db_secs_10,
       SUM(CASE WHEN h.dimension_group = q'[&&series_11.]' THEN 01 ELSE 0 END) AS db_secs_11,
       SUM(CASE WHEN h.dimension_group = q'[&&series_12.]' THEN 01 ELSE 0 END) AS db_secs_12,
       SUM(CASE WHEN h.dimension_group = q'[&&series_13.]' THEN 01 ELSE 0 END) AS db_secs_13
  FROM ash_mem h
 GROUP BY
       ceil_timestamp(h.sample_time)
), 
ash_denorm AS (
SELECT time, (time - LAG(time, 1, time) OVER (ORDER BY time)) * 24 * 3600 AS interval_secs, db_secs_01, db_secs_02, db_secs_03, db_secs_04, db_secs_05, db_secs_06, db_secs_07, db_secs_08, db_secs_09, db_secs_10, db_secs_11, db_secs_12, db_secs_13 FROM ash_awr_denorm
 UNION ALL
SELECT time, (time - LAG(time, 1, time) OVER (ORDER BY time)) * 24 * 3600 AS interval_secs, db_secs_01, db_secs_02, db_secs_03, db_secs_04, db_secs_05, db_secs_06, db_secs_07, db_secs_08, db_secs_09, db_secs_10, db_secs_11, db_secs_12, db_secs_13 FROM ash_mem_denorm
),
/****************************************************************************************/
my_query AS (
SELECT s.time, a.interval_secs, a.db_secs_01, a.db_secs_02, a.db_secs_03, a.db_secs_04, a.db_secs_05, a.db_secs_06, a.db_secs_07, a.db_secs_08, a.db_secs_09, a.db_secs_10, a.db_secs_11, a.db_secs_12, a.db_secs_13,
       ROW_NUMBER() OVER (ORDER BY s.time ASC  NULLS LAST) AS rn_asc,
       ROW_NUMBER() OVER (ORDER BY s.time DESC NULLS LAST) AS rn_desc
  FROM ash_denorm a,
       sample s
 WHERE a.interval_secs > 0
   AND a.time(+) = s.time
)
SELECT ', [new Date('||
       TO_CHAR(q.time, 'YYYY')|| /* year */
       ','||(TO_NUMBER(TO_CHAR(q.time, 'MM')) - 1)|| /* month - 1 */
       ','||TO_CHAR(q.time, 'DD')|| /* day */
       ','||TO_CHAR(q.time, 'HH24')|| /* hour */
       ','||TO_CHAR(q.time, 'MI')|| /* minute */
       ','||TO_CHAR(q.time, 'SS')|| /* second */
       ')'||
       ','||num_format(q.db_secs_01 / q.interval_secs, 3)|| 
       ','||num_format(q.db_secs_02 / q.interval_secs, 3)|| 
       ','||num_format(q.db_secs_03 / q.interval_secs, 3)|| 
       ','||num_format(q.db_secs_04 / q.interval_secs, 3)|| 
       ','||num_format(q.db_secs_05 / q.interval_secs, 3)|| 
       ','||num_format(q.db_secs_06 / q.interval_secs, 3)|| 
       ','||num_format(q.db_secs_07 / q.interval_secs, 3)|| 
       ','||num_format(q.db_secs_08 / q.interval_secs, 3)|| 
       ','||num_format(q.db_secs_09 / q.interval_secs, 3)|| 
       ','||num_format(q.db_secs_10 / q.interval_secs, 3)|| 
       ','||num_format(q.db_secs_11 / q.interval_secs, 3)|| 
       ','||num_format(q.db_secs_12 / q.interval_secs, 3)|| 
       ','||num_format(q.db_secs_13 / q.interval_secs, 3)|| 
       ']'
  FROM my_query q
 WHERE 1 = 1
   --AND q.rn_asc > 1 AND q.rn_desc > 1
   AND q.db_secs_01 + q.db_secs_02 + q.db_secs_03 + q.db_secs_04 + q.db_secs_05 + q.db_secs_06 + q.db_secs_07 + q.db_secs_08 + q.db_secs_09 + q.db_secs_10 + q.db_secs_11 + q.db_secs_12 + q.db_secs_13 > 0
 ORDER BY
       q.time
/
/****************************************************************************************/
SET HEA ON PAGES 100;
--
-- [Line|Area|SteppedArea|Scatter]
DEF cs_chart_type = 'SteppedArea';
-- disable explorer with "//" when using Pie
DEF cs_chart_option_explorer = '';
-- enable pie options with "" when using Pie
DEF cs_chart_option_pie = '//';
-- use oem colors
DEF cs_oem_colors_series = '&&use_oem_colors_series.';
DEF cs_oem_colors_slices = '//';
-- for line charts
DEF cs_curve_type = '//';
--
@@cs_internal/cs_spool_id_chart.sql
@@cs_internal/cs_spool_tail_chart.sql
PRO
PRO &&report_foot_note.
--
--@@cs_internal/&&cs_set_container_to_curr_pdb.
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--