COL con_id FOR 999 HEA 'Con|ID';
COL pdb_name FOR A30 HEA 'PDB Name' FOR A30 TRUNC;
COL last_captured FOR A19 HEA 'Last Captured';
COL child_number FOR 999999 HEA 'Child|Number';
COL position FOR 990 HEA 'Pos';
COL bind_name FOR A30 HEA 'Bind Name';
COL datatype_string FOR A15 HEA 'Data Type';
COL bind_value FOR A150 HEA 'Bind Value';
COL plan_hash_value FOR 9999999999 HEA 'Plan|Hash Value';
COL precision FOR 999999999 HEA 'Precision';
COL scale FOR 99999 HEA 'Scale';
COL max_length FOR 999999 HEA 'Max|Length';
COL was_captured FOR A8 HEA 'Was|Captured';
--
BRE ON last_captured SKIP 1 ON con_id ON pdb_name ON plan_hash_value ON child_number;
--
PRO
PRO CAPTURED BINDS (v$sql_bind_capture)
PRO ~~~~~~~~~~~~~~
SELECT  TO_CHAR(c.last_captured, '&&cs_datetime_full_format.') AS last_captured,
        c.con_id,
        x.name AS pdb_name,
        s.plan_hash_value,
        c.child_number,
        c.position, 
        c.name AS bind_name,
        c.datatype_string,
        --c.precision,
        --c.scale,
        c.max_length,
        c.value_string AS bind_value,
        c.was_captured  
  FROM v$sql_bind_capture c,
       v$sql s,
       v$containers x
 WHERE c.sql_id = '&&cs_sql_id.'
   AND s.address(+) = c.address
   AND s.hash_value(+) = c.hash_value
   AND s.sql_id(+) = c.sql_id
   AND s.child_address(+) = c.child_address
   AND s.child_number(+) = c.child_number
   AND s.con_id(+) = c.con_id
   AND x.con_id = c.con_id
 ORDER BY
       c.last_captured,
       c.con_id,
       c.child_number,
       c.position
/
--
CL BRE;
--