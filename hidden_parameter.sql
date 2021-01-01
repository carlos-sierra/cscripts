----------------------------------------------------------------------------------------
--
-- File name:   hidden_parameter.sql
--
-- Purpose:     Get value of one hidden parameter
--
-- Author:      Carlos Sierra
--
-- Version:     2020/12/16
--
-- Usage:       Execute connected to CDB or PDB
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @hidden_parameter.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
--
COL name FOR A50 TRUNC;
COL value FOR A50 TRUNC;
COL pdbs FOR 9999;
COL min_con_id FOR 999999 HEA 'MIN|CON_ID';
COL max_con_id FOR 999999 HEA 'MAX|CON_ID';
--
SELECT p.ksppinm name,
       v.ksppstvl value,
       COUNT(*) pdbs,
       MIN(v.con_id) min_con_id,
       MAX(v.con_id) max_con_id
  FROM x$ksppi p, 
       x$ksppsv v 
 WHERE p.ksppinm LIKE '%&parameter_name.%'
   AND v.indx = p.indx
   AND v.inst_id = USERENV('INSTANCE')
   AND p.inst_id = USERENV('INSTANCE')
   AND p.ksppinm LIKE '\_%' ESCAPE '\'
 GROUP BY
       p.ksppinm,
       v.ksppstvl
 ORDER BY
       p.ksppinm,
       v.ksppstvl
/
