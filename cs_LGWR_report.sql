----------------------------------------------------------------------------------------
--
-- File name:   cs_LGWR_report.sql
--
-- Purpose:     Log Writer LGWR Slow Writes Duration Report - from current LGWR trace
--
-- Author:      Carlos Sierra
--
-- Version:     2023/01/03
--
-- Usage:       Execute connected to PDB or CDB
--
--              Enter range of dates when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_LGWR_report.sql
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
DEF cs_script_name = 'cs_LGWR_report';
DEF cs_hours_range_default = '24';
--
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
-- @@cs_internal/&&cs_set_container_to_cdb_root.
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." 
@@cs_internal/cs_spool_id.sql
--
@@cs_internal/cs_spool_id_sample_time.sql
--
PRO 
PRO Log Writer LGWR Slow Writes Duration
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
COL timestamp FOR A23 HEA 'Log Write|End|Timestamp' TRUNC;
COL write_duration_ms FOR 999,990 HEA 'Write|Duration|(ms)';
COL payload_size_kb FOR 999,999,990 HEA 'Payload|Size|KBs';
COL kbps FOR 999,999,990 HEA 'KBs|per|Sec';
--
SELECT v4.timestamp,
    --    TO_CHAR(v4.timestamp, 'YYYY-MM-DD"T"HH24:MI:SS.FF3') AS timestamp,
    --    v4.payload_size AS payload_size_display,
    --    v4.write_duration AS write_duration_display,
    TO_NUMBER(REGEXP_REPLACE(v4.write_duration, '[^0-9]', '')) AS write_duration_ms,
    TO_NUMBER(REGEXP_REPLACE(v4.payload_size, '[^0-9]', '')) AS payload_size_kb,
    ROUND((TO_NUMBER(REGEXP_REPLACE(v4.payload_size, '[^0-9]', ''))) / NULLIF(TO_NUMBER(REGEXP_REPLACE(v4.write_duration, '[^0-9]', '')) / POWER(10,3), 0)) AS kbps
FROM 
    (
    SELECT v3.line_number,
            v3.timestamp,
            v3.write_duration,
            v3.payload_size,
            ROW_NUMBER() OVER (PARTITION BY v3.timestamp ORDER BY v3.payload_size DESC) AS rn
        FROM
            (
            SELECT v2.line_number,
                LAST_VALUE(v2.timestamp) IGNORE NULLS OVER (ORDER BY v2.line_number ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS timestamp,
                v2.write_duration,
                v2.payload_size
            FROM
                (
                SELECT v1.line_number,
                        CASE v1.line_type WHEN 'DATE'  THEN CAST(TO_TIMESTAMP_TZ(v1.line_text, 'YYYY-MM-DD"T"HH24:MI:SS.FF6TZH:TZM') AS TIMESTAMP) END AS timestamp,
                        CASE v1.line_type WHEN 'WRITE' THEN SUBSTR(v1.line_text, 1, INSTR(v1.line_text, ', size ') - 1) END AS write_duration,
                        CASE v1.line_type WHEN 'WRITE' THEN SUBSTR(v1.line_text, INSTR(v1.line_text, ', size ') + 7) END AS payload_size
                    FROM 
                        (
                        SELECT line_number, 
                            CASE 
                                -- WHEN payload LIKE CHR(10)||'*** '||TO_CHAR(SYSDATE, 'YYYY')||'%' THEN 'DATE' -- failed after 2023-01-01
                                WHEN payload LIKE CHR(10)||'*** ____-__-__T__:__:__%' THEN 'DATE' 
                                WHEN payload LIKE 'Warning: log write elapsed time %'            THEN 'WRITE'
                            END AS line_type,
                            CASE 
                                -- WHEN payload LIKE CHR(10)||'*** '||TO_CHAR(SYSDATE, 'YYYY')||'%' THEN SUBSTR(SUBSTR(payload, 1, INSTR(payload, '(') - 2), INSTR(payload, TO_CHAR(SYSDATE, 'YYYY'))) -- failed after 2023-01-01
                                WHEN payload LIKE CHR(10)||'*** ____-__-__T__:__:__%' THEN SUBSTR(SUBSTR(payload, 1, INSTR(payload, '(') - 2), INSTR(payload, '20')) 
                                WHEN payload LIKE 'Warning: log write elapsed time %'            THEN REPLACE(payload, 'Warning: log write elapsed time ')
                            END AS line_text
                        FROM v$diag_trace_file_contents
                        WHERE trace_filename = (SELECT LOWER(b.name)||'_'||LOWER(p.pname)||'_'||p.spid||'.trc' AS lgwr_trc FROM v$diag_info d, v$process p, v$database b WHERE d.name = 'Diag Trace' AND p.pname = 'LGWR')
                        ) v1
                WHERE v1.line_type IN ('DATE', 'WRITE')
                    AND v1.line_text IS NOT NULL
                ) v2
            ) v3
    WHERE v3.write_duration||payload_size IS NOT NULL
      AND timestamp IS NOT NULL
    ) v4
WHERE v4.rn = 1
AND v4.timestamp >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.')
AND v4.timestamp <= TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
ORDER BY v4.timestamp
/
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." 
--
@@cs_internal/cs_spool_tail.sql
--
-- @@cs_internal/&&cs_set_container_to_curr_pdb.
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--