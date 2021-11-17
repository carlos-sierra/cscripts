----------------------------------------------------------------------------------------
--
-- File name:   cs_past_days_to_epoch.sql
--
-- Purpose:     Convert Past Days to Epoch
--
-- Author:      Carlos Sierra
--
-- Version:     2021/08/24
--
-- Usage:       Execute connected to CDB or PDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_past_days_to_epoch.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
SET NUM 15;
DEF cs_datetime_full_format = 'YYYY-MM-DD"T"HH24:MI:SS';
DEF cs_datetime_display_format = 'yyyy-mm-ddThh:mi:ss';
PRO
PRO 1. Enter Past Days: [ex: 60]
DEF cs_past_days = '&1.';
UNDEF 1;
--
-- note: on 19c consider select dbms_stats.convert_raw_to_date(hextoraw('7877031203192A0C1988C0')) from dual;
--
WITH
days AS (
SELECT TRUNC(SYSDATE) - &&cs_past_days. - TO_DATE('1970-01-01T00:00:00', '&&cs_datetime_full_format.') AS cnt FROM DUAL
)
SELECT TO_CHAR(TRUNC(SYSDATE) - &&cs_past_days., '&&cs_datetime_full_format.') AS time, days.cnt * 24 * 3600 AS epoch_seconds, days.cnt * 24 * 3600 * 1000 AS epoch_milliseconds
  FROM days
/
