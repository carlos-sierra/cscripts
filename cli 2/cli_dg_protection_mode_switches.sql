SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
--
COL begin_time FOR A19 HEA 'AWR SNAP|BEGIN TIME';
COL end_time FOR A19 HEA 'AWR SNAP|END TIME';
COL begin_host FOR A64 HEA 'AWR SNAP|BEGIN HOST';
COL end_host FOR A64 HEA 'AWR SNAP|END HOST';
COL min_date_time FOR A19 HEA 'LOGON STORM|BEGIN TIME';
COL max_date_time FOR A19 HEA 'LOGON STORM|END TIME';
COL max_aas FOR 99,999 HEA 'LOGON STORM|MAX AAS';
COL max_machines FOR 999,990 HEA 'LOGON STORM|MAX AAS';
COL seconds FOR 999,990 HEA 'LOGON STORM|SECONDS';
COL max_pdbs FOR 999,990 HEA 'LOGON STORM|MAX PDBS';
COL begin_mode FOR A15 HEA 'AWR SNAP|BEGIN MODE';
COL end_mode FOR A15 HEA 'AWR SNAP|END MODE';
--
WITH
parameter_hist AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.snap_id,
       h.dbid,
       h.instance_number,
       h.parameter_name,
       LAG(h.value) OVER (PARTITION BY h.dbid, h.instance_number, h.parameter_name, h.con_id ORDER BY h.snap_id) AS prior_value,
       h.value,
       h.con_id
  FROM dba_hist_parameter h
 WHERE parameter_name LIKE 'log_archive_dest%'
   AND parameter_name NOT LIKE 'log_archive_dest_state%'
),
parameter_changes AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.snap_id,
       h.dbid,
       h.instance_number,
       h.parameter_name,
       h.prior_value,
       h.value,
       REPLACE(REPLACE(REGEXP_SUBSTR(h.prior_value, '\(HOST=([[:alnum:]]|\.|-)+\)'), '(HOST='), ')') AS begin_host,
       REPLACE(REPLACE(REGEXP_SUBSTR(h.value, '\(HOST=([[:alnum:]]|\.|-)+\)'), '(HOST='), ')') AS end_host,
       CASE 
         WHEN h.prior_value LIKE '% SYNC AFFIRM %' THEN 'SYNC AFFIRM' 
         WHEN h.prior_value LIKE '% ASYNC AFFIRM %' THEN 'ASYNC AFFIRM' -- not expected
         WHEN h.prior_value LIKE '% SYNC NOAFFIRM %' THEN 'SYNC NOAFFIRM'  -- not expected
         WHEN h.prior_value LIKE '% ASYNC NOAFFIRM %' THEN 'ASYNC NOAFFIRM'
       END AS begin_mode, 
       CASE 
         WHEN h.value LIKE '% SYNC AFFIRM %' THEN 'SYNC AFFIRM' 
         WHEN h.value LIKE '% ASYNC AFFIRM %' THEN 'ASYNC AFFIRM' -- not expected
         WHEN h.value LIKE '% SYNC NOAFFIRM %' THEN 'SYNC NOAFFIRM'  -- not expected
         WHEN h.value LIKE '% ASYNC NOAFFIRM %' THEN 'ASYNC NOAFFIRM'
       END AS end_mode,
       h.con_id,
       s.begin_interval_time,
       s.end_interval_time
  FROM parameter_hist h,
       dba_hist_snapshot s
 WHERE NVL(h.value, '-666') <> NVL(h.prior_value, '-666')
   AND h.prior_value LIKE '%(HOST=%'
   AND h.value LIKE '%(HOST=%'
   AND s.snap_id = h.snap_id
   AND s.dbid = h.dbid
   AND s.instance_number = h.instance_number
),
dg_mode_switches AS (
SELECT CAST(p.begin_interval_time AS DATE) AS begin_time,
       CAST(p.end_interval_time AS DATE) AS end_time,
       p.begin_mode,
       p.end_mode,
       p.begin_host,
       p.end_host
  FROM parameter_changes p
),
over_height AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.sample_time,
       COUNT(*) AS aas,
       COUNT(DISTINCT machine) AS machines, 
       COUNT(DISTINCT con_id) AS pdbs,
       (CAST(h.sample_time AS DATE) - LAG(CAST(h.sample_time AS DATE)) OVER (ORDER BY h.sample_time)) * 24 * 3600 AS secs_from_prior
  FROM dba_hist_active_sess_history h
 GROUP BY
       h.sample_time
HAVING COUNT(*) > 1000 -- active sessions!
),
over_time AS (
SELECT CAST(h.sample_time AS DATE) AS sample_time,
       h.aas,
       h.machines,
       h.pdbs
  FROM over_height h
 WHERE secs_from_prior < 20 -- contiguous
),
logon_storms AS (
SELECT TRUNC(sample_time) AS date_time,
       MIN(sample_time - (20/24/3600)) AS min_date_time,
       MAX(sample_time) AS max_date_time,
       ((MAX(sample_time) - MIN(sample_time)) * 24 * 3600) + 20 AS seconds,
       MAX(aas) AS max_aas,
       MAX(machines) AS max_machines,
       MAX(pdbs) AS max_pdbs
  FROM over_time
 GROUP BY
       TRUNC(sample_time)
)
SELECT dg.begin_time,
       dg.end_time,
       dg.begin_mode,
       dg.end_mode,
       ls.min_date_time,
       ls.max_date_time,
       ls.seconds,
       ls.max_aas,
       ls.max_pdbs,
       dg.begin_host,
       dg.end_host
  FROM dg_mode_switches dg
       OUTER APPLY (
         SELECT s.min_date_time,
                s.max_date_time,
                s.seconds,
                s.max_aas,
                s.max_pdbs
           FROM logon_storms s
          WHERE (s.min_date_time BETWEEN dg.begin_time AND dg.end_time OR s.max_date_time BETWEEN dg.begin_time AND dg.end_time)
            AND ROWNUM >= 1 /* MATERIALIZE NO_MERGE */
          ORDER BY
                s.min_date_time ASC
          FETCH FIRST 1 ROW ONLY
       ) ls
 ORDER BY
       dg.begin_time
/