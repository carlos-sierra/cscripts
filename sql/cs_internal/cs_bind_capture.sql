COL last_captured FOR A19 HEA 'Last Captured';
COL child_number FOR 999999 HEA 'Child|Number';
COL position FOR 99999999 HEA 'Position';
COL bind_name FOR A30 HEA 'Bind Name';
COL datatype_string FOR A15 HEA 'Data Type';
COL bind_value FOR A200 HEA 'Bind Value';
--
BRE ON last_captured SKIP PAGE ON con_id ON child_number;
--
PRO
PRO CAPTURED BINDS (v$sql_bind_capture)
PRO ~~~~~~~~~~~~~~
SELECT TO_CHAR(last_captured, '&&cs_datetime_full_format.') last_captured,
       con_id,
       child_number,
       position, 
       name bind_name,
       datatype_string,
       value_string bind_value
  FROM v$sql_bind_capture 
 WHERE sql_id = '&&cs_sql_id.'
 ORDER BY
       last_captured,
       con_id,
       child_number,
       position
/
--
CL BRE;
--