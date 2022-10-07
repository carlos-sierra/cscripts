SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
-- ALTER SESSION SET NLS_TIMESTAMP_TZ_FORMAT='YYYY-MM-DD"T"HH24:MI:SS.FF3';
ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS.FF3';
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
         WHEN payload LIKE CHR(10)||'*** '||TO_CHAR(SYSDATE, 'YYYY')||'%' THEN 'DATE' 
         WHEN payload LIKE 'Warning: log write elapsed time %'            THEN 'WRITE'
       END AS line_type,
       CASE 
         WHEN payload LIKE CHR(10)||'*** '||TO_CHAR(SYSDATE, 'YYYY')||'%' THEN SUBSTR(SUBSTR(payload, 1, INSTR(payload, '(') - 2), INSTR(payload, TO_CHAR(SYSDATE, 'YYYY'))) 
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