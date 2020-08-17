COL con_id FOR 999 HEA 'Con|ID';
COL pdb_name FOR A30 HEA 'PDB Name' FOR A30 TRUNC;
COL machine FOR A64 HEA 'Machine (Application Server)';
COL samples FOR 999,999 HEA 'Samples';
COL min_sample_time FOR A19 HEA 'Min Sample Time';
COL max_sample_time FOR A19 HEA 'Max Sample Time';
COL sid_serial# FOR A12 HEA 'Sid,Serial#';
--
BREAK ON con_id ON pdb_name ON machine SKIP 1;
--
PRO
PRO RECENT SESSIONS (v$active_session_history past 15 minutes)
PRO ~~~~~~~~~~~~~~~
SELECT h.con_id,
       c.name AS pdb_name,
       h.machine,
       COUNT(*) samples,
       TO_CHAR(MIN(h.sample_time), '&&cs_datetime_full_format.') AS min_sample_time,
       TO_CHAR(MAX(h.sample_time), '&&cs_datetime_full_format.') AS max_sample_time,
       h.session_id||','||h.session_serial# AS sid_serial#,
       h.sql_plan_hash_value AS plan_hash_value
  FROM v$active_session_history h,
       v$containers c
 WHERE h.sql_id = '&&cs_sql_id.'
   AND h.sample_time > SYSDATE - (15/24/60)
   AND c.con_id = h.con_id
 GROUP BY
       h.con_id,
       c.name,
       h.machine,
       h.session_id||','||h.session_serial#,
       h.sql_plan_hash_value
 ORDER BY
       1, 2, 3, 4 DESC, 5, 6
/
--
CLEAR BREAK;
