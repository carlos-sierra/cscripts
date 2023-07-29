COL con_id FOR 999 HEA 'Con|ID';
COL pdb_name FOR A30 HEA 'PDB Name' FOR A30 TRUNC;
COL last_captured FOR A19 HEA 'Last Captured';
COL child_number FOR 999999 HEA 'Child|Number';
COL position FOR 990 HEA 'Pos';
COL datatype_string FOR A15 HEA 'Data Type';
COL name_and_value FOR A200 HEA 'Bind Name and Value';
COL plan_hash_value FOR 9999999999 HEA 'Plan|Hash Value';
COL max_length FOR 999999 HEA 'Max|Length';
--
BRE ON last_captured SKIP 1 ON con_id ON pdb_name ON plan_hash_value ON child_number;
--
PRO
PRO CAPTURED BINDS (v$sql_bind_capture)
PRO ~~~~~~~~~~~~~~
SELECT  DISTINCT
        TO_CHAR(c.last_captured, '&&cs_datetime_full_format.') AS last_captured,
        c.child_number,
        s.plan_hash_value,
        c.position, 
        c.datatype_string,
        c.max_length,
        c.name||' = '||c.value_string AS name_and_value,
        x.name AS pdb_name,
        c.con_id
  FROM v$sql_bind_capture c,
       v$sql s,
       v$containers x
 WHERE c.sql_id = '&&cs_sql_id.'
   AND c.last_captured < SYSDATE -- filter out bogus future dates such as 2106-02-07T06:13:16
   AND s.address(+) = c.address
   AND s.hash_value(+) = c.hash_value
   AND s.sql_id(+) = c.sql_id
   AND s.child_address(+) = c.child_address
   AND s.child_number(+) = c.child_number
   AND s.con_id(+) = c.con_id
   AND x.con_id = c.con_id
 ORDER BY
       1, 2, 4
/
--
CL BRE;
--
