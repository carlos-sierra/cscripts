----------------------------------------------------------------------------------------
--
-- File name:   aas.sql | cs_average_active_sessions.sql 
--
-- Purpose:     Average Active Sessions (ASH Analytics on dbc_active_session)
--
-- Author:      Carlos Sierra
--
-- Version:     2021/07/22
--
-- Usage:       Execute connected to CDB or PDB
--
--              Enter range of dates and filters when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_average_active_sessions.sql
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
DEF cs_script_name = 'cs_average_active_sessions';
DEF cs_script_acronym = 'aas.sql | ';
--
DEF cs_hours_range_default = '336';
--
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
COL cs2_granularity_list NEW_V cs2_granularity_list NOPRI;
COL cs2_default_granularity NEW_V cs2_default_granularity NOPRI;
SELECT CASE 
         WHEN TO_NUMBER('&&cs_from_to_seconds.') / 3600 <= 12  THEN '[{1m}|5m|15m|1h|1d|m|h|d]'  -- < 12h (up to 720 samples)
         WHEN TO_NUMBER('&&cs_from_to_seconds.') / 3600 <= 60  THEN '[{5m}|1m|15m|1h|1d|m|h|d]'  -- < 60h (2.5d) (up to 720 samples)
         WHEN TO_NUMBER('&&cs_from_to_seconds.') / 3600 <= 180 THEN '[{15m}|1m|5m|1h|1d|m|h|d]' -- < 180h (7.5d) (up to 720 samples)
         WHEN TO_NUMBER('&&cs_from_to_seconds.') / 3600 <= 720 THEN '[{1h}|1m|5m|15m|1d|m|h|d]'  -- < 720h (30d) (up to 720 samples)
         ELSE '[{1d}|1m|5m|15m|1h|1d|m|h|d]'
       END AS cs2_granularity_list,
       CASE 
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
         WHEN '&&cs2_granularity.' = 'm' THEN '1m'
         WHEN '&&cs2_granularity.' = 'h' THEN '1h'
         WHEN '&&cs2_granularity.' = 'd' THEN '1d'
         WHEN '&&cs2_granularity.' IN ('1m', '5m', '15m', '1h', '1d') THEN '&&cs2_granularity.' 
         ELSE '&&cs2_default_granularity.' 
       END cs2_granularity 
  FROM DUAL
/
--
COL cs2_fmt NEW_V cs2_fmt NOPRI;
SELECT CASE '&&cs2_granularity.' 
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
COL aas FOR 999,990.000 HEA 'Average Active|Sessions (AAS)';
COL db_seconds FOR 999,999,990 HEA 'DB Seconds';
COL session_state FOR A13 HEA 'Session|State';
BREAK ON REPORT;
COMPUTE SUM OF aas db_seconds ON REPORT;
--
ALTER SESSION SET container = CDB$ROOT;
WITH
ash_dbc AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.session_state,
       10 * SUM(h.sum_samples) AS db_seconds
  FROM &&cs_tools_schema..dbc_active_session h
 WHERE h.end_time >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND h.end_time < TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND h.db_domain = LOWER(SYS_CONTEXT('USERENV', 'DB_DOMAIN'))
   AND h.db_name = UPPER(SYS_CONTEXT('USERENV', 'DB_NAME'))
   AND '&&cs_con_name.' IN (h.pdb_name, 'CDB$ROOT')
 GROUP BY
       h.session_state
)
SELECT ROUND(SUM(db_seconds) / TO_NUMBER('&&cs_from_to_seconds.'), 3) AS aas,
       SUM(db_seconds) AS db_seconds,
       session_state
  FROM ash_dbc
 GROUP BY
       session_state
 ORDER BY
       1 DESC
/
ALTER SESSION SET CONTAINER = &&cs_con_name.;
--
PRO
PRO 4. Session State (opt):
DEF cs2_session_state = '&4.';
UNDEF 4;
DEF cs2_instruct_to_skip = '(opt)';
COL cs2_instruct_to_skip NEW_V cs2_instruct_to_skip NOPRI;
SELECT '(hit "Return" to skip this patameter since Session State is "ON CPU")' AS cs2_instruct_to_skip FROM DUAL WHERE '&&cs2_session_state.' = 'ON CPU'
/
--
COL wait_class HEA 'Wait Class';
--
ALTER SESSION SET container = CDB$ROOT;
WITH
ash_dbc AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.session_state,
       h.wait_class,
       10 * SUM(h.sum_samples) AS db_seconds
  FROM &&cs_tools_schema..dbc_active_session h
 WHERE h.end_time >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND h.end_time < TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND h.db_domain = LOWER(SYS_CONTEXT('USERENV', 'DB_DOMAIN'))
   AND h.db_name = UPPER(SYS_CONTEXT('USERENV', 'DB_NAME'))
   AND '&&cs_con_name.' IN (h.pdb_name, 'CDB$ROOT')
   AND ('&&cs2_session_state.' IS NULL OR h.session_state = '&&cs2_session_state.')
   AND NVL('&&cs2_session_state.', 'X') <> 'ON CPU'
 GROUP BY
       h.session_state,
       h.wait_class
)
SELECT ROUND(SUM(db_seconds) / TO_NUMBER('&&cs_from_to_seconds.'), 3) AS aas,
       SUM(db_seconds) AS db_seconds,
       wait_class,
       session_state
  FROM ash_dbc
 GROUP BY
       wait_class,
       session_state
 ORDER BY
       1 DESC
/
ALTER SESSION SET CONTAINER = &&cs_con_name.;
--
PRO
PRO 5. Wait Class &&cs2_instruct_to_skip.:
DEF cs2_wait_class = '&5.';
UNDEF 5;
--
COL event HEA 'Event';
--
ALTER SESSION SET container = CDB$ROOT;
WITH
ash_dbc AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.event,
       h.wait_class,
       h.session_state,
       10 * SUM(h.sum_samples) AS db_seconds
  FROM &&cs_tools_schema..dbc_active_session h
 WHERE h.end_time >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND h.end_time < TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND h.db_domain = LOWER(SYS_CONTEXT('USERENV', 'DB_DOMAIN'))
   AND h.db_name = UPPER(SYS_CONTEXT('USERENV', 'DB_NAME'))
   AND '&&cs_con_name.' IN (h.pdb_name, 'CDB$ROOT')
   AND ('&&cs2_session_state.' IS NULL OR h.session_state = '&&cs2_session_state.')
   AND NVL('&&cs2_session_state.', 'X') <> 'ON CPU'
   AND ('&&cs2_wait_class.' IS NULL OR h.wait_class = '&&cs2_wait_class.')
 GROUP BY
       h.event,
       h.wait_class,
       h.session_state
)
SELECT ROUND(SUM(db_seconds) / TO_NUMBER('&&cs_from_to_seconds.'), 3) AS aas,
       SUM(db_seconds) AS db_seconds,
       event,
       wait_class,
       session_state
  FROM ash_dbc
 GROUP BY
       event,
       wait_class,
       session_state
 ORDER BY
       1 DESC
 FETCH FIRST 30 ROWS ONLY
/
ALTER SESSION SET CONTAINER = &&cs_con_name.;
--
PRO
PRO 6. Event &&cs2_instruct_to_skip.:
DEF cs2_event = '&6.';
UNDEF 6;
--
COL machine HEA 'Machine';
--
ALTER SESSION SET container = CDB$ROOT;
WITH
ash_dbc AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.machine,
       10 * SUM(h.sum_samples) AS db_seconds
  FROM &&cs_tools_schema..dbc_active_session h
 WHERE h.end_time >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND h.end_time < TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND h.db_domain = LOWER(SYS_CONTEXT('USERENV', 'DB_DOMAIN'))
   AND h.db_name = UPPER(SYS_CONTEXT('USERENV', 'DB_NAME'))
   AND '&&cs_con_name.' IN (h.pdb_name, 'CDB$ROOT')
   AND ('&&cs2_session_state.' IS NULL OR h.session_state = '&&cs2_session_state.')
   AND ('&&cs2_wait_class.' IS NULL OR h.wait_class = '&&cs2_wait_class.')
   AND ('&&cs2_event.' IS NULL OR h.event LIKE CHR(37)||'&&cs2_event.'||CHR(37))
 GROUP BY
       h.machine
)
SELECT ROUND(SUM(db_seconds) / TO_NUMBER('&&cs_from_to_seconds.'), 3) AS aas,
       SUM(db_seconds) AS db_seconds,
       machine
  FROM ash_dbc
 GROUP BY
       machine
 ORDER BY
       1 DESC
 FETCH FIRST 30 ROWS ONLY
/
ALTER SESSION SET CONTAINER = &&cs_con_name.;
--
PRO
PRO 7. Machine (opt):
DEF cs2_machine = '&7.';
UNDEF 7;
--
PRO
PRO 8. SQL Text piece (e.g.: ScanQuery, getValues, TableName, IndexName):
DEF cs2_sql_text_piece = '&8.';
UNDEF 8;
--
COL sql_text FOR A60 TRUNC;
--
ALTER SESSION SET container = CDB$ROOT;
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
            AND UPPER(DBMS_LOB.substr(sql_text, 100)) LIKE CHR(37)||UPPER('&&cs2_sql_text_piece.')||CHR(37)
            AND dbid = &&cs_dbid.
            AND ROWNUM >= 1
  )
  GROUP BY sql_id
),
ash_dbc AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.sql_id,
       10 * SUM(h.sum_samples) AS db_seconds
  FROM &&cs_tools_schema..dbc_active_session h
 WHERE h.end_time >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND h.end_time < TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND h.db_domain = LOWER(SYS_CONTEXT('USERENV', 'DB_DOMAIN'))
   AND h.db_name = UPPER(SYS_CONTEXT('USERENV', 'DB_NAME'))
   AND '&&cs_con_name.' IN (h.pdb_name, 'CDB$ROOT')
   AND ('&&cs2_session_state.' IS NULL OR h.session_state = '&&cs2_session_state.')
   AND ('&&cs2_wait_class.' IS NULL OR h.wait_class = '&&cs2_wait_class.')
   AND ('&&cs2_event.' IS NULL OR h.event LIKE CHR(37)||'&&cs2_event.'||CHR(37))
   AND ('&&cs2_machine.' IS NULL OR h.machine LIKE CHR(37)||'&&cs2_machine.'||CHR(37))
   AND ('&&cs2_sql_text_piece.' IS NULL OR h.sql_id IN (SELECT /*+ NO_MERGE */ t.sql_id FROM sql_txt t))
 GROUP BY
       h.sql_id
)
SELECT ROUND(SUM(db_seconds) / TO_NUMBER('&&cs_from_to_seconds.'), 3) AS aas,
       SUM(db_seconds) AS db_seconds,
       sql_id,
       (SELECT s.sql_text FROM sql_txt s WHERE s.sql_id = a.sql_id AND ROWNUM = 1) AS sql_text
  FROM ash_dbc a
 GROUP BY
       sql_id
 ORDER BY
       1 DESC
 FETCH FIRST 30 ROWS ONLY
/
ALTER SESSION SET CONTAINER = &&cs_con_name.;
--
PRO
PRO 9. SQL_ID (opt):
DEF cs2_sql_id = '&9.';
UNDEF 9;
--
PRO
PRO 10. Reporting Dimension: [{event}|wait_class|machine|sql_id|plan_hash_value|module|pdb_name|host_name]
DEF cs2_dimension = '&10.';
UNDEF 10;
COL cs2_dimension NEW_V cs2_dimension NOPRI;
SELECT NVL(LOWER(TRIM('&&cs2_dimension.')), 'event') cs2_dimension FROM DUAL;
SELECT CASE WHEN '&&cs2_dimension.' IN ('event', 'wait_class', 'machine', 'sql_id', 'plan_hash_value', 'module', 'pdb_name', 'host_name') THEN '&&cs2_dimension.' ELSE 'event' END cs2_dimension FROM DUAL;
--
COL use_oem_colors_series NEW_V use_oem_colors_series NOPRI;
SELECT CASE '&&cs2_dimension.' WHEN 'wait_class' THEN NULL ELSE '//' END AS use_oem_colors_series FROM DUAL;
--
COL cs2_group NEW_V cs2_group NOPRI;
SELECT CASE '&&cs2_dimension.'
         WHEN 'wait_class' THEN q'[CASE h.session_state WHEN 'ON CPU' THEN h.session_state ELSE h.wait_class END]'
         WHEN 'event' THEN CASE WHEN '&&cs2_wait_class.' IS NULL THEN q'[CASE h.session_state WHEN 'ON CPU' THEN h.session_state ELSE h.wait_class||' - '||h.event END]' ELSE q'[h.event]' END
         WHEN 'machine' THEN q'[h.machine]' 
         WHEN 'sql_id' THEN q'[h.sql_id]' 
         WHEN 'plan_hash_value' THEN q'[TO_CHAR(h.sql_plan_hash_value)]' 
         WHEN 'module' THEN q'[h.module]' 
         WHEN 'pdb_name' THEN q'[h.pdb_name]'
         WHEN 'host_name' THEN q'[h.host_name]'
       END AS cs2_group
  FROM DUAL
/
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
ALTER SESSION SET container = CDB$ROOT;
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
          SELECT sql_id, REPLACE(REPLACE(SUBSTR(sql_text, 1, 100), CHR(10), CHR(32)), CHR(9), CHR(32)) AS sql_text
            FROM v$sql
          WHERE '&&cs2_sql_text_piece.' IS NOT NULL
            AND UPPER(sql_text) LIKE CHR(37)||UPPER('&&cs2_sql_text_piece.')||CHR(37)
            AND ROWNUM >= 1
          UNION ALL
          SELECT sql_id, REPLACE(REPLACE(DBMS_LOB.substr(sql_text, 100), CHR(10), CHR(32)), CHR(9), CHR(32)) AS sql_text
            FROM dba_hist_sqltext
          WHERE '&&cs2_sql_text_piece.' IS NOT NULL
            AND UPPER(DBMS_LOB.substr(sql_text, 100)) LIKE CHR(37)||UPPER('&&cs2_sql_text_piece.')||CHR(37)
            AND dbid = &&cs_dbid.
            AND ROWNUM >= 1
  )
  GROUP BY sql_id
),
ash_dbc AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       &&cs2_group. AS dimension_group,
       10 * SUM(h.sum_samples) AS db_seconds
  FROM &&cs_tools_schema..dbc_active_session h
 WHERE h.end_time >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND h.end_time < TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND h.db_domain = LOWER(SYS_CONTEXT('USERENV', 'DB_DOMAIN'))
   AND h.db_name = UPPER(SYS_CONTEXT('USERENV', 'DB_NAME'))
   AND '&&cs_con_name.' IN (h.pdb_name, 'CDB$ROOT')
   AND ('&&cs2_session_state.' IS NULL OR h.session_state = '&&cs2_session_state.')
   AND ('&&cs2_wait_class.' IS NULL OR h.wait_class = '&&cs2_wait_class.')
   AND ('&&cs2_event.' IS NULL OR h.event LIKE CHR(37)||'&&cs2_event.'||CHR(37))
   AND ('&&cs2_machine.' IS NULL OR h.machine LIKE CHR(37)||'&&cs2_machine.'||CHR(37))
   AND ('&&cs2_sql_text_piece.' IS NULL OR h.sql_id IN (SELECT /*+ NO_MERGE */ t.sql_id FROM sql_txt t))
   AND ('&&cs2_sql_id.' IS NULL OR h.sql_id = '&&cs2_sql_id.')
 GROUP BY
       &&cs2_group.
),
ash_by_dim AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       ROUND(SUM(db_seconds) / TO_NUMBER('&&cs_from_to_seconds.'), 3) AS aas,
       SUM(db_seconds) AS db_seconds,
       dimension_group,
       ROW_NUMBER() OVER(ORDER BY SUM(db_seconds) DESC) AS rn
  FROM ash_dbc a
 GROUP BY
       dimension_group
),
top AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       rn, -- up to 12
       aas,
       db_seconds,
       SUBSTR(CASE
         WHEN TRIM(dimension_group) IS NULL THEN '"null"'
         WHEN '&&cs2_dimension.' = 'sql_id' THEN dimension_group||' '||get_sql_text(dimension_group)
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
ALTER SESSION SET CONTAINER = &&cs_con_name.;
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
DEF report_title = 'Average Active Sessions by &&cs2_dimension. between &&cs_sample_time_from. and &&cs_sample_time_to. UTC';
DEF chart_title = '&&report_title.';
DEF vaxis_title = 'Average Active Sessions (AAS)';
DEF xaxis_title = '';
--
COL xaxis_title NEW_V xaxis_title NOPRI;
SELECT
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
DEF report_foot_note = 'SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&cs2_granularity." "&&cs2_session_state." "&&cs2_wait_class." "&&cs2_event." "&&cs2_machine." "&&cs2_sql_text_piece." "&&cs2_sql_id." "&&cs2_dimension."';
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
ALTER SESSION SET container = CDB$ROOT;
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
  IF '&&cs2_granularity.' = '5m' THEN
    RETURN TRUNC(CAST(p_timestamp AS DATE), 'HH') + FLOOR(TO_NUMBER(TO_CHAR(CAST(p_timestamp AS DATE), '&&cs2_fmt.')) / 5) * 5 / (24 * 60) + &&cs2_plus_days.;
  ELSIF '&&cs2_granularity.' = '15m' THEN
    RETURN TRUNC(CAST(p_timestamp AS DATE), 'HH') + FLOOR(TO_NUMBER(TO_CHAR(CAST(p_timestamp AS DATE), '&&cs2_fmt.')) / 15) * 15 / (24 * 60) + &&cs2_plus_days.;
  ELSE -- 1m, 1h, 1d
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
          SELECT sql_id, REPLACE(REPLACE(SUBSTR(sql_text, 1, 100), CHR(10), CHR(32)), CHR(9), CHR(32)) AS sql_text
            FROM v$sql
          WHERE '&&cs2_sql_text_piece.' IS NOT NULL
            AND UPPER(sql_text) LIKE CHR(37)||UPPER('&&cs2_sql_text_piece.')||CHR(37)
            AND ROWNUM >= 1
          UNION ALL
          SELECT sql_id, REPLACE(REPLACE(DBMS_LOB.substr(sql_text, 100), CHR(10), CHR(32)), CHR(9), CHR(32)) AS sql_text
            FROM dba_hist_sqltext
          WHERE '&&cs2_sql_text_piece.' IS NOT NULL
            AND UPPER(DBMS_LOB.substr(sql_text, 100)) LIKE CHR(37)||UPPER('&&cs2_sql_text_piece.')||CHR(37)
            AND dbid = &&cs_dbid.
            AND ROWNUM >= 1
  )
  GROUP BY sql_id
),
ash_dbc AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.end_time,
       h.sum_samples,
       h.max_samples,
       CASE 
         WHEN TRIM(&&cs2_group.) IS NULL THEN '"null"'
         WHEN '&&cs2_dimension.' = 'sql_id' THEN
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
         WHEN '&&cs2_dimension.' IN ('wait_class', 'event', 'machine', 'plan_hash_value', 'module', 'pdb_name', 'host_name') THEN
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
  FROM &&cs_tools_schema..dbc_active_session h
 WHERE h.end_time >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND h.end_time < TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND h.db_domain = LOWER(SYS_CONTEXT('USERENV', 'DB_DOMAIN'))
   AND h.db_name = UPPER(SYS_CONTEXT('USERENV', 'DB_NAME'))
   AND '&&cs_con_name.' IN (h.pdb_name, 'CDB$ROOT')
   AND ('&&cs2_session_state.' IS NULL OR h.session_state = '&&cs2_session_state.')
   AND ('&&cs2_wait_class.' IS NULL OR h.wait_class = '&&cs2_wait_class.')
   AND ('&&cs2_event.' IS NULL OR h.event LIKE CHR(37)||'&&cs2_event.'||CHR(37))
   AND ('&&cs2_machine.' IS NULL OR h.machine LIKE CHR(37)||'&&cs2_machine.'||CHR(37))
   AND ('&&cs2_sql_text_piece.' IS NULL OR h.sql_id IN (SELECT /*+ NO_MERGE */ t.sql_id FROM sql_txt t))
   AND ('&&cs2_sql_id.' IS NULL OR h.sql_id = '&&cs2_sql_id.')
),
ash_dbc_denorm AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       ceil_timestamp(h.end_time) AS time,
       SUM(CASE WHEN h.dimension_group = q'[&&series_01.]' THEN 10 * sum_samples ELSE 0 END) AS db_secs_01,
       SUM(CASE WHEN h.dimension_group = q'[&&series_02.]' THEN 10 * sum_samples ELSE 0 END) AS db_secs_02,
       SUM(CASE WHEN h.dimension_group = q'[&&series_03.]' THEN 10 * sum_samples ELSE 0 END) AS db_secs_03,
       SUM(CASE WHEN h.dimension_group = q'[&&series_04.]' THEN 10 * sum_samples ELSE 0 END) AS db_secs_04,
       SUM(CASE WHEN h.dimension_group = q'[&&series_05.]' THEN 10 * sum_samples ELSE 0 END) AS db_secs_05,
       SUM(CASE WHEN h.dimension_group = q'[&&series_06.]' THEN 10 * sum_samples ELSE 0 END) AS db_secs_06,
       SUM(CASE WHEN h.dimension_group = q'[&&series_07.]' THEN 10 * sum_samples ELSE 0 END) AS db_secs_07,
       SUM(CASE WHEN h.dimension_group = q'[&&series_08.]' THEN 10 * sum_samples ELSE 0 END) AS db_secs_08,
       SUM(CASE WHEN h.dimension_group = q'[&&series_09.]' THEN 10 * sum_samples ELSE 0 END) AS db_secs_09,
       SUM(CASE WHEN h.dimension_group = q'[&&series_10.]' THEN 10 * sum_samples ELSE 0 END) AS db_secs_10,
       SUM(CASE WHEN h.dimension_group = q'[&&series_11.]' THEN 10 * sum_samples ELSE 0 END) AS db_secs_11,
       SUM(CASE WHEN h.dimension_group = q'[&&series_12.]' THEN 10 * sum_samples ELSE 0 END) AS db_secs_12,
       SUM(CASE WHEN h.dimension_group = q'[&&series_13.]' THEN 10 * sum_samples ELSE 0 END) AS db_secs_13
  FROM ash_dbc h
 GROUP BY
       ceil_timestamp(h.end_time)
),
ash_denorm AS (
SELECT time, (time - LAG(time, 1, time) OVER (ORDER BY time)) * 24 * 3600 AS interval_secs, db_secs_01, db_secs_02, db_secs_03, db_secs_04, db_secs_05, db_secs_06, db_secs_07, db_secs_08, db_secs_09, db_secs_10, db_secs_11, db_secs_12, db_secs_13 FROM ash_dbc_denorm
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
  --  AND q.rn_asc > 1 AND q.rn_desc > 1
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
ALTER SESSION SET CONTAINER = &&cs_con_name.;
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--