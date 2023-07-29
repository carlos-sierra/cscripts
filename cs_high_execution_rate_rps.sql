----------------------------------------------------------------------------------------
--
-- File name:   cs_high_execution_rate_rps.sql
--
-- Purpose:     List executions by time for a given SQL_ID with high RPS 
--
-- Author:      Carlos Sierra
--
-- Version:     2023/04/27
--
-- Usage:       Execute connected to PDB.
--
--              Enter SQL_ID when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_high_execution_rate_rps.sql
--
-- Notes:       Developed and tested on 19c
--             
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_high_execution_rate_rps';
--
PRO 1. SQL_ID: 
DEF cs_sql_id = '&1.';
UNDEF 1;
--
PRO
PRO 2. Seconds: [{1}|1-60]
DEF cs_seconds = '&2.';
UNDEF 2;
COL cs_seconds NEW_V cs_seconds NOPRI;
SELECT CASE WHEN TO_NUMBER('&&cs_seconds.') BETWEEN 1 AND 60 THEN '&&cs_seconds.' ELSE '1' END AS cs_seconds FROM DUAL
/
--
@@cs_internal/cs_last_snap.sql
--
SELECT '&&cs_file_prefix._&&cs_script_name._&&cs_sql_id.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_signature.sql
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id." "&&cs_seconds."
@@cs_internal/cs_spool_id.sql
@@cs_internal/cs_spool_id_list_sql_id.sql
--
PRO SECONDS      : &&cs_seconds.
--
@@cs_internal/cs_print_sql_text.sql
PRO
PRO Samples (v$sqlstats)
PRO ~~~~~~~ 
SET SERVEROUT ON;
DECLARE
  l_begin_timestamp TIMESTAMP(6) := SYSTIMESTAMP;
  l_exit_timestamp TIMESTAMP(6) := l_begin_timestamp + INTERVAL '&&cs_seconds.' SECOND;
  l_timestamp TIMESTAMP(6);
  l_parse_calls NUMBER;
  l_executions NUMBER;
  l_rows_processed NUMBER;
  l_us_delta NUMBER;
  l_parse_calls_total NUMBER := 0;
  l_executons_total NUMBER := 0;
  l_rows_processed_total NUMBER := 0;
  l_us_total NUMBER := 0;
  l_parse_calls_delta NUMBER;
  l_executions_delta NUMBER;
  l_rows_processed_delta NUMBER;
  l_timestamp_prior TIMESTAMP(6) := l_begin_timestamp;
  l_parse_calls_prior NUMBER;
  l_executions_prior NUMBER;
  l_rows_processed_prior NUMBER;
  l_timestamp_zero_begin TIMESTAMP(6) := l_begin_timestamp;
  l_timestamp_zero_end TIMESTAMP(6);
  l_us_delta_zero NUMBER;
  l_samples_zero NUMBER := 0;
  l_samples_total NUMBER := 0;
BEGIN
    WHILE SYSTIMESTAMP < l_exit_timestamp 
    LOOP
        SELECT parse_calls, executions, rows_processed INTO l_parse_calls, l_executions, l_rows_processed FROM v$sqlstats WHERE sql_id = '&&cs_sql_id.';
        l_timestamp := SYSTIMESTAMP;
        l_us_delta := ((86400 * EXTRACT(DAY FROM (l_timestamp - l_timestamp_prior)) + (3600 * EXTRACT(HOUR FROM (l_timestamp - l_timestamp_prior))) + (60 * EXTRACT(MINUTE FROM (l_timestamp - l_timestamp_prior))) + EXTRACT(SECOND FROM (l_timestamp - l_timestamp_prior)))) * 1e6;
        l_parse_calls_delta := l_parse_calls - l_parse_calls_prior;
        l_executions_delta := l_executions - l_executions_prior;
        l_rows_processed_delta := l_rows_processed - l_rows_processed_prior;
        l_samples_total := l_samples_total + 1;
        IF l_us_delta > 0 THEN
            l_us_total := l_us_total + l_us_delta;
            l_parse_calls_total := NVL(l_parse_calls_total, 0) + l_parse_calls_delta;
            l_executons_total := NVL(l_executons_total, 0) + l_executions_delta;
            l_rows_processed_total := NVL(l_rows_processed_total, 0) + l_rows_processed_delta;
        END IF;
        --
        IF l_parse_calls_delta > 0 OR l_executions_delta > 0 OR l_rows_processed_delta > 0 THEN
            IF l_timestamp_zero_begin IS NOT NULL AND l_timestamp_zero_end IS NOT NULL THEN
                l_us_delta_zero := ((86400 * EXTRACT(DAY FROM (l_timestamp_zero_end - l_timestamp_zero_begin)) + (3600 * EXTRACT(HOUR FROM (l_timestamp_zero_end - l_timestamp_zero_begin))) + (60 * EXTRACT(MINUTE FROM (l_timestamp_zero_end - l_timestamp_zero_begin))) + EXTRACT(SECOND FROM (l_timestamp_zero_end - l_timestamp_zero_begin)))) * 1e6;
                DBMS_OUTPUT.put_line (
                    RPAD(TO_CHAR(l_timestamp_zero_begin, 'YYYY-MM-DD"T"HH24:MI:SS.FF6'), 26, ' ')||' - '||
                    RPAD(TO_CHAR(l_timestamp_zero_end, 'YYYY-MM-DD"T"HH24:MI:SS.FF6'), 26, ' ')||
                    LPAD(TO_CHAR(l_us_delta_zero, '999,999,990'), 12, ' ')||' us'||
                    LPAD(TO_CHAR(0, '999,990'), 8, ' ')||' parses'||
                    LPAD(TO_CHAR(0, '999,990'), 8, ' ')||' executions'||
                    LPAD(TO_CHAR(0, '999,999,990'), 12, ' ')||' rows'||
                    LPAD(TO_CHAR(l_samples_zero, '9,999,990'), 10, ' ')||' samples'
                );
            END IF;
            --
            IF l_timestamp_prior IS NOT NULL AND l_timestamp IS NOT NULL THEN
                DBMS_OUTPUT.put_line (
                    RPAD(TO_CHAR(l_timestamp_prior, 'YYYY-MM-DD"T"HH24:MI:SS.FF6'), 26, ' ')||' - '||
                    RPAD(TO_CHAR(l_timestamp, 'YYYY-MM-DD"T"HH24:MI:SS.FF6'), 26, ' ')||
                    LPAD(TO_CHAR(l_us_delta, '999,999,990'), 12, ' ')||' us'||
                    LPAD(TO_CHAR(l_parse_calls_delta, '999,990'), 8, ' ')||' parses'||
                    LPAD(TO_CHAR(l_executions_delta, '999,990'), 8, ' ')||' executions'||
                    LPAD(TO_CHAR(l_rows_processed_delta, '999,999,990'), 12, ' ')||' rows'
                );
            END IF;
            l_timestamp_zero_begin := l_timestamp;
            l_timestamp_zero_end := NULL;
            l_samples_zero := 0;
        ELSE
            l_timestamp_zero_end := l_timestamp;
            l_samples_zero := NVL(l_samples_zero, 0) + 1;
        END IF;
        --
        l_timestamp_prior := l_timestamp;
        l_parse_calls_prior := l_parse_calls;
        l_executions_prior := l_executions;
        l_rows_processed_prior := l_rows_processed;
    END LOOP;
    --
    DBMS_OUTPUT.put_line('---');
    DBMS_OUTPUT.put_line (
        RPAD(TO_CHAR(l_begin_timestamp, 'YYYY-MM-DD"T"HH24:MI:SS.FF6'), 26, ' ')||' - '||
        RPAD(TO_CHAR(l_timestamp, 'YYYY-MM-DD"T"HH24:MI:SS.FF6'), 26, ' ')||
        LPAD(TO_CHAR(l_us_total, '999,999,990'), 12, ' ')||' us'||
        LPAD(TO_CHAR(l_parse_calls_total, '999,990'), 8, ' ')||' parses'||
        LPAD(TO_CHAR(l_executons_total, '999,990'), 8, ' ')||' executions'||
        LPAD(TO_CHAR(l_rows_processed_total, '999,999,990'), 12, ' ')||' rows'||
        LPAD(TO_CHAR(l_samples_total, '9,999,990'), 10, ' ')||' samples'
    );
END;
/
SET SERVEROUT OFF;
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id." "&&cs_seconds."
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--