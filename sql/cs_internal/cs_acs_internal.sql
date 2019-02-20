COL last_active_time FOR A19 HEA 'Last Active Time';
COL child_number FOR 999999 HEA 'Child|Number';
COL plan_hash_value FOR 9999999999 HEA 'Plan|Hash Value';
COL object_status FOR A14 HEA 'Object|Status';
COL is_obsolete FOR A8 HEA 'Is|Obsolete';
COL is_shareable FOR A9 HEA 'Is|Shareable';
COL is_bind_aware FOR A9 HEA 'Is Bind|Aware';
COL is_bind_sensitive FOR A9 HEA 'Is Bind|Sensitive';
COL bucket_id FOR 999999 HEA 'Bucket|ID';
COL count FOR 999999 HEA 'Count';
COL predicate FOR A9 HEA 'Predicate';
COL range_id FOR 99999 HEA 'Range|ID';
COL low HEA 'Low';
COL high HEA 'High';
COL high_low_avg HEA 'AVG' FOR A10;
--
PRO
PRO ACS HISTOGRAM (v$sql_cs_histogram)
PRO ~~~~~~~~~~~~~
SELECT TO_CHAR(s.last_active_time, '&&cs_datetime_full_format.') last_active_time,
       h.child_number,
       h.bucket_id,
       h.count,
       s.object_status, 
       s.is_obsolete,
       s.is_shareable,
       s.is_bind_aware,
       s.is_bind_sensitive,
       s.plan_hash_value
  FROM v$sql_cs_histogram h, 
       v$sql s
 WHERE h.sql_id = '&&cs_sql_id.'
   AND s.sql_id = h.sql_id
   AND s.child_number = h.child_number
   AND s.con_id = h.con_id
 ORDER BY
       s.last_active_time,
       h.child_number,
       h.bucket_id
/
--
/* v$sql_cs_statistics not populated on 12c as per bug 24441377 */
--
PRO
PRO ACS SELECTIVITY PROFILE (v$sql_cs_selectivity)
PRO ~~~~~~~~~~~~~~~~~~~~~~~
SELECT TO_CHAR(s.last_active_time, '&&cs_datetime_full_format.') last_active_time,
       l.child_number,
       l.predicate,
       l.range_id,
       l.low,
       TRIM(TO_CHAR(ROUND((TO_NUMBER(l.high) + TO_NUMBER(l.low)) / 2, 6), '0.000000')) high_low_avg,
       l.high,
       s.object_status, 
       s.is_obsolete,
       s.is_shareable,
       s.is_bind_aware,
       s.is_bind_sensitive,
       s.plan_hash_value
  FROM v$sql_cs_selectivity l, 
       v$sql s
 WHERE l.sql_id = '&&cs_sql_id.'
   AND s.sql_id = l.sql_id
   AND s.child_number = l.child_number
   AND s.con_id = l.con_id
 ORDER BY
       s.last_active_time,
       l.child_number,
       l.predicate,
       l.range_id,
       l.low,
       l.high
/
--
