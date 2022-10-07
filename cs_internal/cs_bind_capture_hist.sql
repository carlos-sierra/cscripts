--
/****************************************************************************************/
--
@@&&cs_set_container_to_cdb_root.
--
COL con_id FOR 999 HEA 'Con|ID';
COL pdb_name FOR A30 HEA 'PDB Name' FOR A30 TRUNC;
COL last_captured FOR A19 HEA 'Last Captured';
COL position FOR 990 HEA 'Pos';
COL bind_name FOR A30 HEA 'Bind Name';
COL datatype_string FOR A15 HEA 'Data Type';
COL bind_value FOR A150 HEA 'Bind Value';
COL precision FOR 999999999 HEA 'Precision';
COL scale FOR 99999 HEA 'Scale';
COL max_length FOR 999999 HEA 'Max|Length';
COL was_captured FOR A8 HEA 'Was|Captured';
--
BRE ON last_captured SKIP 1 ON con_id ON pdb_name;
--
PRO
PRO CAPTURED BINDS (dba_hist_sqlbind) last &&cs_binds_days. day(s)
PRO ~~~~~~~~~~~~~~
SELECT  DISTINCT -- view contains duplicates!
        TO_CHAR(h.last_captured, '&&cs_datetime_full_format.') AS last_captured,
        h.con_id,
        c.name AS pdb_name,
        h.position, 
        h.name AS bind_name,
        h.datatype_string,
        --h.precision,
        --h.scale,
        h.max_length,
        h.value_string AS bind_value,
        h.was_captured  
  FROM  dba_hist_sqlbind h, 
        dba_hist_snapshot s,
        v$containers c
 WHERE  h.sql_id = '&&cs_sql_id.'
   AND  h.dbid = '&&cs_dbid.'
   AND  h.instance_number = '&&cs_instance_number.'
   AND  &&cs_con_id. IN (1, h.con_id)
   AND  s.snap_id = h.snap_id
   AND  s.dbid = h.dbid
   AND  s.instance_number = h.instance_number
   AND  s.end_interval_time BETWEEN SYSDATE - &&cs_binds_days. AND SYSDATE -- filter out bogus future dates such as 2106-02-07T06:13:16
   AND  c.con_id = h.con_id
 ORDER BY
       1, 2, 4
/
--
CL BRE;
--
@@&&cs_set_container_to_curr_pdb.
--
/****************************************************************************************/
--
