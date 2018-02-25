WITH
all_parameters AS (
SELECT /*+  MATERIALIZE NO_MERGE   DYNAMIC_SAMPLING(4)  */ /* 1a.30 */
       snap_id,
       dbid,
       con_id,
       instance_number,
       parameter_name,
       value,
       isdefault,
       ismodified,
       lag(value) OVER (PARTITION BY dbid,
       con_id,
       instance_number, parameter_hash ORDER BY snap_id) prior_value
  FROM dba_hist_parameter
)
SELECT /*+  NO_MERGE  */ /* 1a.30 */
       TO_CHAR(s.begin_interval_time, 'YYYY-MM-DD HH24:MI:SS') begin_time,
       TO_CHAR(s.end_interval_time, 'YYYY-MM-DD HH24:MI:SS') end_time,
       p.snap_id,
       p.con_id,
       --p.dbid,
       p.instance_number,
       p.parameter_name,
       p.value,
       p.isdefault,
       p.ismodified,
       p.prior_value
  FROM all_parameters p,
       dba_hist_snapshot s
 WHERE p.value != p.prior_value
   AND s.snap_id = p.snap_id
   AND s.dbid = p.dbid
   AND s.instance_number = p.instance_number
 ORDER BY
       s.begin_interval_time DESC,
       --p.dbid,
       p.instance_number,
       p.parameter_name;