----------------------------------------------------------------------------------------
--
-- File name:   cs_LGWR_trc.sql
--
-- Purpose:     Get log writer LGWR trace
--
-- Author:      Carlos Sierra
--
-- Version:     2023/01/03
--
-- Usage:       Execute connected to CDB or PDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_LGWR_trc.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
--
COL trace_dir NEW_V trace_dir FOR A100 NOPRI;
COL lgwr_trc NEW_V lgwr_trc FOR A30 NOPRI;
SELECT d.value AS trace_dir, LOWER('&&cs_db_name._')||LOWER(p.pname)||'_'||p.spid||'.trc' AS lgwr_trc FROM v$diag_info d, v$process p WHERE d.name = 'Diag Trace' AND p.pname = 'LGWR';
--
HOS cat &&trace_dir./&&lgwr_trc.
PRO
PRO LONG WRITES
PRO ~~~~~~~~~~~
COL timestamp FOR A23;
COL write_duration_display FOR A15;
COL payload_size_display FOR A15;
COL write_duration_ms FOR 999,999,999,990;
COL payload_size_kb FOR 999,999,999,990;
COL kbps FOR 999,990.000;
WITH 
trace AS (
SELECT d.value AS trace_dir, LOWER(b.name)||'_'||LOWER(p.pname)||'_'||p.spid||'.trc' AS lgwr_trc FROM v$diag_info d, v$process p, v$database b WHERE d.name = 'Diag Trace' AND p.pname = 'LGWR'
),
relevant_lines AS (
SELECT line_number, 
       CASE 
        --  WHEN payload LIKE CHR(10)||'*** '||TO_CHAR(SYSDATE, 'YYYY')||'%' THEN 'DATE' -- failed after 2023-01-01
         WHEN payload LIKE CHR(10)||'*** ____-__-__T__:__:__%' THEN 'DATE' 
         WHEN payload LIKE 'Warning: log write elapsed time %'            THEN 'WRITE'
       END AS line_type,
       CASE 
        --  WHEN payload LIKE CHR(10)||'*** '||TO_CHAR(SYSDATE, 'YYYY')||'%' THEN SUBSTR(SUBSTR(payload, 1, INSTR(payload, '(') - 2), INSTR(payload, TO_CHAR(SYSDATE, 'YYYY'))) -- failed after 2023-01-01
         WHEN payload LIKE CHR(10)||'*** ____-__-__T__:__:__%' THEN SUBSTR(SUBSTR(payload, 1, INSTR(payload, '(') - 2), INSTR(payload, '20')) 
         WHEN payload LIKE 'Warning: log write elapsed time %'            THEN REPLACE(payload, 'Warning: log write elapsed time ')
       END AS line_text
  FROM v$diag_trace_file_contents
 WHERE trace_filename = (SELECT lgwr_trc FROM trace)
),
parsed_lines AS (
SELECT line_number,
       CASE line_type WHEN 'DATE'  THEN CAST(TO_TIMESTAMP_TZ(line_text, 'YYYY-MM-DD"T"HH24:MI:SS.FF6TZH:TZM') AS TIMESTAMP) END AS timestamp,
       CASE line_type WHEN 'WRITE' THEN SUBSTR(line_text, 1, INSTR(line_text, ', size ') - 1) END AS write_duration,
       CASE line_type WHEN 'WRITE' THEN SUBSTR(line_text, INSTR(line_text, ', size ') + 7) END AS payload_size
  FROM relevant_lines
 WHERE line_type IN ('DATE', 'WRITE')
   AND line_text IS NOT NULL
),
normalized_lines AS (
SELECT line_number,
       LAST_VALUE(timestamp) IGNORE NULLS OVER (ORDER BY line_number ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS timestamp,
       write_duration,
       payload_size
  FROM parsed_lines
),
filtered_lines AS (
SELECT line_number,
       timestamp,
       write_duration,
       payload_size,
        ROW_NUMBER() OVER (PARTITION BY timestamp ORDER BY payload_size DESC) AS rn
  FROM normalized_lines
 WHERE write_duration||payload_size IS NOT NULL
   AND timestamp IS NOT NULL
)
SELECT timestamp,
    --    payload_size AS payload_size_display,
    --    write_duration AS write_duration_display,
       TO_NUMBER(REGEXP_REPLACE(payload_size, '[^0-9]', '')) AS payload_size_kb,
       TO_NUMBER(REGEXP_REPLACE(write_duration, '[^0-9]', '')) AS write_duration_ms,
       (TO_NUMBER(REGEXP_REPLACE(payload_size, '[^0-9]', ''))) / NULLIF(TO_NUMBER(REGEXP_REPLACE(write_duration, '[^0-9]', '')) / POWER(10,3), 0) AS kbps
  FROM filtered_lines
   WHERE rn = 1
 ORDER BY line_number
/
PRO 
PRO &&trace_dir./&&lgwr_trc.
PRO
HOS cp &&trace_dir./&&lgwr_trc. /tmp/
HOS chmod 644 /tmp/&&lgwr_trc.
PRO
PRO Preserved LGWR trace on /tmp
PRO ~~~~~~~~~~~~~~~~~~~~~~~
HOS ls -oX /tmp/&&lgwr_trc.
PRO
PRO If you want to copy LGWR trace file, execute scp command below, from a TERM session running on your Mac/PC:
PRO
PRO scp &&cs_host_name.:/tmp/&&lgwr_trc. &&cs_local_dir.
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--
