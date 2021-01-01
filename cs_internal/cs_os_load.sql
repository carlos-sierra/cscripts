COL stat_name FOR A13 HEA 'Stat Name';
COL stat_value FOR 990.0 HEA 'Value';
--
PRO
PRO OS LOAD (v$osstat)
PRO ~~~~~~~
SELECT stat_name,
       ROUND(value, 1) stat_value
  FROM v$osstat
 WHERE stat_name IN ('LOAD', 'NUM_CPU_CORES')
 ORDER BY
       stat_name
/
