COL spfile_value FOR A12;
COL spfile_sid FOR A10;
WITH
system_parameter AS (
SELECT inst_id,
       name,
       value
  FROM gv$system_parameter2
 WHERE name IN
( 'memory_max_target'
, 'memory_target'
, 'pga_aggregate_target'
, 'sga_max_size'
, 'sga_target'
, 'db_cache_size'
, 'shared_pool_size'
, 'shared_pool_reserved_size'
, 'large_pool_size'
, 'java_pool_size'
, 'streams_pool_size'
, 'result_cache_max_size'
, 'db_keep_cache_size	'
, 'db_recycle_cache_size'
, 'db_32k_cache_size'
, 'db_16k_cache_size'
, 'db_8k_cache_size'
, 'db_4k_cache_size'
, 'db_2k_cache_size'
)),
spparameter_inst AS (
SELECT i.inst_id,
       p.name,
       p.display_value
  FROM v$spparameter p,
       gv$instance i
 WHERE p.isspecified = 'TRUE'
   AND p.sid <> '*'
   AND i.instance_name = p.sid
),
spparameter_all AS (
SELECT p.name,
       p.display_value
  FROM v$spparameter p
 WHERE p.isspecified = 'TRUE'
   AND p.sid = '*'
)
SELECT s.name,
       s.inst_id,
       CASE WHEN i.name IS NOT NULL THEN TO_CHAR(i.inst_id) ELSE (CASE WHEN a.name IS NOT NULL THEN '*' END) END spfile_sid,
       NVL(i.display_value, a.display_value) spfile_value,
       CASE s.value WHEN '0' THEN '0' ELSE TRIM(TO_CHAR(ROUND(TO_NUMBER(s.value)/POWER(2,30),3),'9990.000'))||'G' END current_gb 
  FROM system_parameter s,
       spparameter_inst i,
       spparameter_all  a
 WHERE i.inst_id(+) = s.inst_id
   AND i.name(+)    = s.name
   AND a.name(+)    = s.name
 ORDER BY
       CASE s.name
       WHEN 'memory_max_target'         THEN  1
       WHEN 'memory_target'             THEN  2
       WHEN 'pga_aggregate_target'      THEN  3
       WHEN 'sga_max_size'              THEN  4
       WHEN 'sga_target'                THEN  5
       WHEN 'db_cache_size'             THEN  6
       WHEN 'shared_pool_size'          THEN  7
       WHEN 'shared_pool_reserved_size' THEN  8
       WHEN 'large_pool_size'           THEN  9
       WHEN 'java_pool_size'            THEN 10
       WHEN 'streams_pool_size'         THEN 11
       WHEN 'result_cache_max_size'     THEN 12
       WHEN 'db_keep_cache_size	'       THEN 13
       WHEN 'db_recycle_cache_size'     THEN 14
       WHEN 'db_32k_cache_size'         THEN 15
       WHEN 'db_16k_cache_size'         THEN 16
       WHEN 'db_8k_cache_size'          THEN 17
       WHEN 'db_4k_cache_size'          THEN 18
       WHEN 'db_2k_cache_size'          THEN 19
       END,
       s.inst_id
/
