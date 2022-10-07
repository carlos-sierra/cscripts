--SET HEA OFF PAGES 0 SERVEROUT ON;
SET HEA OFF PAGES 0;
DECLARE
  l_line INTEGER := 0;
  l_b1 VARCHAR2(300) := '|                         |   Active || Top #1 SQL |                                                                  || Top #1 Event |                                                    || Top #1 PDB |                                     |'; -- begin line 1
  l_b2 VARCHAR2(300) := '| Sample Time             | Sessions ||   Sessions | Top #1 SQL                                                       ||     Sessions | Top #1 Timed Event                                 ||   Sessions | Top #1 PDB                          |'; -- begin line 2
  l_s1 VARCHAR2(300) := '+-------------------------+----------++------------+------------------------------------------------------------------++--------------+----------------------------------------------------++------------+-------------------------------------+'; -- spacer
  l_l1 VARCHAR2(300); -- line
  l_begin_peak DATE;
  l_seconds NUMBER;
  l_sessions_peak NUMBER;
  l_sql_id_peak VARCHAR2(13);
  l_con_id_peak NUMBER;
  l_sql_text_peak VARCHAR2(1000);
  l_session_state_peak VARCHAR2(30);
  l_wait_class_peak VARCHAR2(255);
  l_event_peak VARCHAR2(255);
  l_pdb_name_peak VARCHAR2(128);
BEGIN
DELETE plan_table;
IF &&times_cpu_cores. = 0 THEN
  DBMS_OUTPUT.put_line(l_s1);
  DBMS_OUTPUT.put_line(l_b1);
  DBMS_OUTPUT.put_line(l_b2);
  DBMS_OUTPUT.put_line(l_s1);
END IF;
FOR i IN (
WITH
threshold AS (
  SELECT /*+ MATERIALIZE NO_MERGE */ &&times_cpu_cores. * value AS value FROM v$osstat WHERE stat_name = 'NUM_CPU_CORES' AND ROWNUM >= 1 /* MATERIALIZE */
),
active_sessions_time_series AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.sample_time,
       h.con_id,
       h.session_state,
       h.wait_class,
       h.event,
       COALESCE(h.sql_id, h.top_level_sql_id, '"null"') AS sql_id,
       COUNT(*) AS active_sessions
  FROM dba_hist_active_sess_history h
 WHERE 1 = 1
   AND '&&include_hist.' = 'Y'
   AND h.dbid = &&cs_dbid. AND h.instance_number = &&cs_instance_number. AND h.snap_id BETWEEN &&cs_snap_id_from. AND &&cs_snap_id_to. 
  --  AND TO_NUMBER('&&cs_con_id.') IN (1, h.con_id)
   AND (TO_NUMBER('&&cs_con_id.') IN (0, 1, h.con_id) OR h.con_id IN (0, 1)) -- now we include CDB$ROOT samples when executed from a PDB
   AND h.sample_time >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND h.sample_time < TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND ROWNUM >= 1 /* MATERIALIZE */
 GROUP BY
       h.sample_time,
       h.con_id,
       h.session_state,
       h.wait_class,
       h.event,
       COALESCE(h.sql_id, h.top_level_sql_id, '"null"')
UNION
SELECT /*+ MATERIALIZE NO_MERGE */
       h.sample_time,
       h.con_id,
       h.session_state,
       h.wait_class,
       h.event,
       COALESCE(h.sql_id, h.top_level_sql_id, '"null"') AS sql_id,
       COUNT(*) AS active_sessions
  FROM v$active_session_history h
 WHERE 1 = 1
   AND '&&include_mem.' = 'Y'
  --  AND TO_NUMBER('&&cs_con_id.') IN (1, h.con_id)
   AND (TO_NUMBER('&&cs_con_id.') IN (0, 1, h.con_id) OR h.con_id IN (0, 1)) -- now we include CDB$ROOT samples when executed from a PDB
   AND h.sample_time >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND h.sample_time < TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND ROWNUM >= 1 /* MATERIALIZE */
 GROUP BY
       h.sample_time,
       h.con_id,
       h.session_state,
       h.wait_class,
       h.event,
       COALESCE(h.sql_id, h.top_level_sql_id, '"null"')
),
time_dim AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sample_time,
       SUM(active_sessions) AS active_sessions,
       LAG(SUM(active_sessions)) OVER (ORDER BY sample_time) AS lag_active_sessions,
       LEAD(SUM(active_sessions)) OVER (ORDER BY sample_time) AS lead_active_sessions
  FROM active_sessions_time_series
 WHERE ROWNUM >= 1 /* MATERIALIZE */
 GROUP BY
       sample_time
),
t AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       t.sample_time,
       t.active_sessions,
       CASE WHEN t.active_sessions < threshold.value AND t.lead_active_sessions >= threshold.value THEN 'Y' END AS b,
       CASE WHEN t.active_sessions >= threshold.value THEN 'Y' END AS p,
       CASE WHEN t.active_sessions < threshold.value AND t.lag_active_sessions >= threshold.value THEN 'Y' END AS e
  FROM threshold,
       time_dim t
 WHERE (t.active_sessions >= threshold.value OR t.lag_active_sessions >= threshold.value OR t.lead_active_sessions >= threshold.value)
   AND ROWNUM >= 1 /* MATERIALIZE */
),
con_dim AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sample_time,
       con_id,
       SUM(active_sessions) AS active_sessions,
       ROW_NUMBER() OVER (PARTITION BY sample_time ORDER BY SUM(active_sessions) DESC) AS rn
  FROM active_sessions_time_series
 WHERE ROWNUM >= 1 /* MATERIALIZE */
 GROUP BY
       sample_time,
       con_id
),
c AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sample_time,
       con_id,
       active_sessions
  FROM con_dim
 WHERE rn = 1
   AND ROWNUM >= 1 /* MATERIALIZE */
),
eve_dim AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sample_time,
       session_state,
       wait_class,
       event,
       SUM(active_sessions) AS active_sessions,
       ROW_NUMBER() OVER (PARTITION BY sample_time ORDER BY SUM(active_sessions) DESC) AS rn
  FROM active_sessions_time_series
 WHERE ROWNUM >= 1 /* MATERIALIZE */
 GROUP BY
       sample_time,
       session_state,
       wait_class,
       event
),
e AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sample_time,
       session_state,
       wait_class,
       event,
       active_sessions
  FROM eve_dim
 WHERE rn = 1
   AND ROWNUM >= 1 /* MATERIALIZE */
),
sql_dim AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sample_time,
       sql_id,
       SUM(active_sessions) AS active_sessions,
       ROW_NUMBER() OVER (PARTITION BY sample_time ORDER BY SUM(active_sessions) DESC) AS rn
  FROM active_sessions_time_series
 WHERE ROWNUM >= 1 /* MATERIALIZE */
 GROUP BY
       sample_time,
       sql_id
),
s AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sample_time,
       sql_id,
       active_sessions
  FROM sql_dim
 WHERE rn = 1
   AND ROWNUM >= 1 /* MATERIALIZE */
)
SELECT t.sample_time,
       t.active_sessions,
       t.b,
       t.p,
       t.e,
       s.active_sessions AS s_active_sessions,
       s.sql_id,
       (SELECT /*+ NO_MERGE */ REPLACE(v.sql_text, CHR(39)) FROM v$sql v WHERE s.sql_id <> '"null"' AND v.sql_id = s.sql_id AND ROWNUM = 1 /* MATERIALIZE */) AS sql_text,
       e.active_sessions AS e_active_sessions,
       e.session_state,
       e.wait_class,
       e.event,
       c.active_sessions AS c_active_sessions,
       (SELECT /*+ NO_MERGE */ v.name FROM v$containers v WHERE v.con_id = c.con_id AND ROWNUM = 1 /* MATERIALIZE */) AS pdb_name,
       c.con_id
  FROM t, c, e, s
 WHERE c.sample_time = t.sample_time
   AND e.sample_time = t.sample_time
   AND s.sample_time = t.sample_time
 ORDER BY
       t.sample_time
)
LOOP
  l_line := l_line + 1;
  l_l1 := 
  '| '||TO_CHAR(i.sample_time, 'YYYY-MM-DD"T"HH24:MI:SS.FF3')||
  ' | '||TO_CHAR(i.active_sessions, '999,990')||
  ' ||   '||TO_CHAR(i.s_active_sessions, '999,990')||
  ' | '||RPAD(i.sql_id, 13)||
  ' '||RPAD(COALESCE(i.sql_text, ' '), 50)||
  ' ||     '||TO_CHAR(i.e_active_sessions, '999,990')||
  ' | '||RPAD(CASE i.session_state WHEN 'ON CPU' THEN i.session_state ELSE i.wait_class||' - '||i.event END, 50)||
  ' ||   '||TO_CHAR(i.c_active_sessions, '999,990')||
  ' | '||RPAD(i.pdb_name||'('||i.con_id||')', 35)||
  ' | ';
  IF i.e = 'Y' AND i.b = 'Y' THEN -- end of peak followed by begin of peak (same row is both)
    DBMS_OUTPUT.put_line(l_l1);
    l_seconds := ROUND((CAST(i.sample_time AS DATE) - l_begin_peak) * 24 * 3600); 
    -- DBMS_OUTPUT.put_line(TO_CHAR(l_begin_peak, 'YYYY-MM-DD"T"HH24:MI:SS')||' '||l_seconds||' '||l_sessions_peak);
    INSERT INTO plan_table (timestamp, cost, cardinality, statement_id, plan_id, remarks, operation, options, object_node, object_owner, object_type) 
    VALUES (l_begin_peak, l_seconds, l_sessions_peak, l_sql_id_peak, l_con_id_peak, l_sql_text_peak, l_session_state_peak, l_wait_class_peak, l_event_peak, l_pdb_name_peak, 'GLOBAL');
    DBMS_OUTPUT.put_line(l_s1);
  END IF;
  IF i.b = 'Y' THEN -- begin of peak
    DBMS_OUTPUT.put_line(l_s1);
    DBMS_OUTPUT.put_line(l_b1);
    DBMS_OUTPUT.put_line(l_b2);
    DBMS_OUTPUT.put_line(l_s1);
    l_begin_peak := NULL; l_sessions_peak := 0; l_sql_id_peak := NULL; l_con_id_peak := NULL; l_sql_text_peak := NULL; l_session_state_peak := NULL; l_wait_class_peak := NULL; l_event_peak := NULL; l_pdb_name_peak := NULL;
  END IF;
  DBMS_OUTPUT.put_line(l_l1); -- line
  IF i.active_sessions > l_sessions_peak THEN
    l_sessions_peak := i.active_sessions;
    l_sql_id_peak := i.sql_id;
    l_con_id_peak := i.con_id;
    l_sql_text_peak := i.sql_text;
    l_session_state_peak := i.session_state;
    l_wait_class_peak := i.wait_class;
    l_event_peak := i.event;
    l_pdb_name_peak := i.pdb_name;
  END IF;
  IF i.e IS NULL AND i.b IS NULL AND l_begin_peak IS NULL THEN -- first line after a begin-peak
    l_begin_peak := CAST(i.sample_time AS DATE);
  END IF;
  IF i.e = 'Y' AND i.b IS NULL THEN -- end of peak
    l_seconds := ROUND((CAST(i.sample_time AS DATE) - l_begin_peak) * 24 * 3600); 
    -- DBMS_OUTPUT.put_line(TO_CHAR(l_begin_peak, 'YYYY-MM-DD"T"HH24:MI:SS')||' '||l_seconds||' '||l_sessions_peak);
    INSERT INTO plan_table (timestamp, cost, cardinality, statement_id, plan_id, remarks, operation, options, object_node, object_owner, object_type) 
    VALUES (l_begin_peak, l_seconds, l_sessions_peak, l_sql_id_peak, l_con_id_peak, l_sql_text_peak, l_session_state_peak, l_wait_class_peak, l_event_peak, l_pdb_name_peak, 'GLOBAL');
    DBMS_OUTPUT.put_line(l_s1);
  END IF;
  IF &&times_cpu_cores. = 0 AND MOD(l_line, 100) = 0 THEN -- heading every 100 rows when executed requesting all sample times and not just peaks
    DBMS_OUTPUT.put_line(l_s1);
    DBMS_OUTPUT.put_line(l_b1);
    DBMS_OUTPUT.put_line(l_b2);
    DBMS_OUTPUT.put_line(l_s1);
  END IF;
END LOOP;
IF &&times_cpu_cores. = 0 THEN
  DBMS_OUTPUT.put_line(l_s1); -- separator when executed requesting all sample times and not just peaks
END IF;
COMMIT;
END;
/
SET HEA ON PAGES 5000 SERVEROUT OFF;
PRO NOTE: Sum of Active Sessions per AWR sampled time, when greater than &&times_cpu_cores.x NUM_CPU_CORES(&&cs_num_cpu_cores.). Report includes for each sampled time Top #1: SQL, Timed Event and PDB; with corresponding Sum of Active Sessions for each of these 3 dimensions.

/*
 plan_table mapping

 Name                                      Null?    Type
 ----------------------------------------- -------- ----------------------------
 STATEMENT_ID                                       VARCHAR2(30)                sql_id
 PLAN_ID                                            NUMBER                      con_id
 TIMESTAMP                                          DATE                        begin_peak
 REMARKS                                            VARCHAR2(4000)              sql_text
 OPERATION                                          VARCHAR2(30)                session_state
 OPTIONS                                            VARCHAR2(255)               wait_class
 OBJECT_NODE                                        VARCHAR2(128)               event
 OBJECT_OWNER                                       VARCHAR2(128)               pdb_name
 OBJECT_NAME                                        VARCHAR2(128)
 OBJECT_ALIAS                                       VARCHAR2(261)
 OBJECT_INSTANCE                                    NUMBER(38)                  
 OBJECT_TYPE                                        VARCHAR2(30)                global
 OPTIMIZER                                          VARCHAR2(255)
 SEARCH_COLUMNS                                     NUMBER
 ID                                                 NUMBER(38)
 PARENT_ID                                          NUMBER(38)
 DEPTH                                              NUMBER(38)
 POSITION                                           NUMBER(38)
 COST                                               NUMBER(38)                  seconds
 CARDINALITY                                        NUMBER(38)                  sessions_peak
 BYTES                                              NUMBER(38)
 OTHER_TAG                                          VARCHAR2(255)
 PARTITION_START                                    VARCHAR2(255)
 PARTITION_STOP                                     VARCHAR2(255)
 PARTITION_ID                                       NUMBER(38)
 OTHER                                              LONG
 OTHER_XML                                          CLOB
 DISTRIBUTION                                       VARCHAR2(30)
 CPU_COST                                           NUMBER(38)
 IO_COST                                            NUMBER(38)
 TEMP_SPACE                                         NUMBER(38)
 ACCESS_PREDICATES                                  VARCHAR2(4000)
 FILTER_PREDICATES                                  VARCHAR2(4000)
 PROJECTION                                         VARCHAR2(4000)
 TIME                                               NUMBER(38)
 QBLOCK_NAME                                        VARCHAR2(128)

 SELECT TO_CHAR(timestamp, 'YYYY-MM-DD"T"HH24:MI:SS') AS begin_peak, 
        TO_CHAR(timestamp + (cost/3600/24), 'YYYY-MM-DD"T"HH24:MI:SS') AS end_peak, 
        cost AS seconds, 
        cardinality AS sessions_peak,
        -- statement_id AS sql_id,
        -- remarks AS sql_text,
        statement_id||' '||SUBSTR(remarks, 1, 50) AS sql_statement,
        -- operation AS session_state,
        -- options AS wait_class,
        -- object_node AS event,
        CASE operation WHEN 'ON CPU' THEN operation ELSE options||' - '||object_node END AS timed_event,
        -- object_owner AS pdb_name,
        -- plan_id AS con_id
        object_owner||'('||plan_id||')' AS pdb_name
   FROM plan_table 
  ORDER BY 1;
*/
