WHENEVER SQLERROR CONTINUE;
SET TERM OFF;
STORE SET "/tmp/cs_store_set.sql" REP;
SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS.FF3';
--ALTER SESSION SET NLS_TIMESTAMP_TZ_FORMAT='YYYY-MM-DD"T"HH24:MI:SS.FF3 TZR';
ALTER SESSION SET NLS_TIMESTAMP_TZ_FORMAT='YYYY-MM-DD"T"HH24:MI:SS.FF3';
ALTER SESSION SET STATISTICS_LEVEL = 'ALL';
ALTER SESSION SET "_px_cdb_view_enabled" = FALSE;
--
-- setting hidden parameter "_with_subquery" [{OPTIMIZER}|MATERIALIZE|INLINE]
-- workaround for bug: ORA-00600: internal error code, arguments: [qks3tGCL:1]: set to INLINE
-- ALTER SESSION SET "_with_subquery" = INLINE; 
-- workaround for ORA-32036: unsupported case for inlining of query name in WITH clause" on DBMS_SQLTUNE.report_sql_monitor: set to MATERIALIZE (or OPTIMIZER)
-- ALTER SESSION SET "_with_subquery" = MATERIALIZE;
ALTER SESSION SET "_with_subquery" = OPTIMIZER;
--