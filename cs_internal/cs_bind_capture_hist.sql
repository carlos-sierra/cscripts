--
/****************************************************************************************/
--
@@&&cs_set_container_to_cdb_root.
--
COL con_id FOR 999 HEA 'Con|ID';
COL pdb_name FOR A30 HEA 'PDB Name' FOR A30 TRUNC;
COL last_captured FOR A19 HEA 'Last Captured';
COL position FOR 990 HEA 'Pos';
COL datatype_string FOR A15 HEA 'Data Type';
COL name_and_value FOR A200 HEA 'Bind Name and Value';
COL max_length FOR 999999 HEA 'Max|Length';
--
BRE ON last_captured SKIP 1 ON con_id ON pdb_name;
--
PRO
PRO CAPTURED BINDS (dba_hist_sqlbind) - last &&cs_binds_days. day(s)
PRO ~~~~~~~~~~~~~~
SELECT  DISTINCT
        TO_CHAR(h.last_captured, '&&cs_datetime_full_format.') AS last_captured,
        h.position, 
        h.datatype_string,
        h.max_length,
        h.name||' = '||h.value_string AS name_and_value,
        c.name AS pdb_name,
        h.con_id
  FROM  dba_hist_sqlbind h,
        v$containers c
 WHERE  h.sql_id = '&&cs_sql_id.'
   AND  h.dbid = '&&cs_dbid.'
   AND  h.instance_number = '&&cs_instance_number.'
   AND  &&cs_con_id. IN (1, h.con_id)
   AND  h.last_captured BETWEEN SYSDATE - &&cs_binds_days. AND SYSDATE -- filter out bogus future dates such as 2106-02-07T06:13:16
   AND  c.con_id = h.con_id
 ORDER BY
       1, 2
/
--
CL BRE;
--
@@&&cs_set_container_to_curr_pdb.
--
/****************************************************************************************/
--