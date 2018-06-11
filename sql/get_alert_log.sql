SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
COL trace_dir NEW_V trace_dir FOR A100;
COL alert_log NEW_V alert_log FOR A20;
SELECT d.value trace_dir, 'alert_'||t.instance||'.log' alert_log FROM v$diag_info d, v$thread t WHERE d.name = 'Diag Trace';
HOS cp &&trace_dir./&&alert_log. .
HOS chmod 777 &&alert_log.
PRO
PRO Current and prior alert logs
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
HOS ls -lat &&trace_dir./*alert*log*
PRO
PRO Copy of current alert log
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~
HOS pwd
HOS ls -lat &&alert_log.
