SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;

SELECT tablespace_name FROM dba_tablespaces ORDER BY 1;

PRO
PRO 1. Enter TABLESPACE_NAME (required)
DEF tablespace_name = '&1.';
PRO

COL size_gb FOR 999,990.000 HEA 'SIZE (GBs)';
COL percent FOR 990.0;
COL segment_type HEA 'TYPE';
COL owner FOR A30;
COL segment_name FOR A30;

BRE ON segment_type SKIP 1 ON owner;
COMP SUM LAB 'TOTAL' OF size_gb percent ON segment_type;

COL current_time NEW_V current_time FOR A15;
SELECT 'current_time: ' x, TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') current_time FROM DUAL;
COL x_host_name NEW_V x_host_name;
SELECT host_name x_host_name FROM v$instance;
COL x_db_name NEW_V x_db_name;
SELECT name x_db_name FROM v$database;
COL x_container NEW_V x_container;
SELECT 'NONE' x_container FROM DUAL;
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') x_container FROM DUAL;

SPO segments_&&tablespace_name._&&current_time..txt;
PRO TABLESPACE: &&tablespace_name.
PRO HOST: &&x_host_name.
PRO DATABASE: &&x_db_name.
PRO CONTAINER: &&x_container.

SELECT v.segment_type,
       v.owner,
       v.segment_name,
       v.size_gb,
       v.percent
  FROM
(
SELECT SUBSTR(s.segment_type, 1, 5) segment_type,
       s.owner,
       s.segment_name,
       SUM(s.bytes) / POWER(2, 30) size_gb,
       RANK() OVER (ORDER BY SUM(s.bytes) DESC) rank,
       ROUND(100 * SUM(s.bytes) / SUM(SUM(s.bytes)) OVER (), 1) percent
  FROM dba_segments s
 WHERE s.tablespace_name = UPPER(TRIM('&&tablespace_name.'))
   AND SUBSTR(s.segment_type, 1, 5) IN ('TABLE', 'INDEX')
 GROUP BY
       SUBSTR(s.segment_type, 1, 5),
       s.owner,
       s.segment_name
) v
 WHERE v.rank <= 5 OR v.percent >= 5
 ORDER BY
       v.rank
/

SPO OFF;
CL BRE COMP;
