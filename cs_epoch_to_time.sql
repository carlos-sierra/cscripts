----------------------------------------------------------------------------------------
--
-- File name:   cs_epoch_to_time.sql
--
-- Purpose:     Convert Epoch to Time
--
-- Author:      Carlos Sierra
--
-- Version:     2020/12/06
--
-- Usage:       Execute connected to CDB or PDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_epoch_to_time.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
SET NUM 15;
DEF cs_datetime_full_format = 'YYYY-MM-DD"T"HH24:MI:SS';
PRO
PRO 1. Enter Epoch: 
DEF cs_epoch = '&1.';
UNDEF 1;
--
-- note: on 19c consider select dbms_stats.convert_raw_to_date(hextoraw('7877031203192A0C1988C0')) from dual;
--
WITH
days AS (
SELECT TO_NUMBER('&&cs_epoch.'||CASE WHEN LENGTH('&&cs_epoch.') <= 10 THEN '000' END) / 1000 / 3600 / 24 AS cnt,
       CASE WHEN LENGTH('&&cs_epoch.') > 10 THEN SUBSTR('&&cs_epoch.', 11, 3) END AS ms
  FROM DUAL
)
SELECT TO_CHAR(TO_DATE('1970-01-01T00:00:00', '&&cs_datetime_full_format.') + days.cnt, '&&cs_datetime_full_format.')||
       CASE WHEN days.ms IS NOT NULL THEN '.'||days.ms END
       AS time
  FROM days
/
