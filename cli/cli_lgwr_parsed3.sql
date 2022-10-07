SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
SET TIMI ON;
-- ALTER SESSION SET NLS_TIMESTAMP_TZ_FORMAT='YYYY-MM-DD"T"HH24:MI:SS.FF3';
ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS.FF3';
COL timestamp FOR A23;
COL write_duration_display FOR A15;
COL payload_size_display FOR A15;
COL write_duration_ms FOR 999,999,999,990;
COL payload_size_kb FOR 999,999,999,990;
COL kbps FOR 999,990.000;
--
SELECT TO_CHAR(v4.timestamp, 'YYYY-MM-DD"T"HH24:MI:SS.FF3') AS timestamp,
    --    v4.payload_size AS payload_size_display,
    --    v4.write_duration AS write_duration_display,
       TO_NUMBER(REGEXP_REPLACE(v4.payload_size, '[^0-9]', '')) AS payload_size_kb,
       TO_NUMBER(REGEXP_REPLACE(v4.write_duration, '[^0-9]', '')) AS write_duration_ms,
       ROUND((TO_NUMBER(REGEXP_REPLACE(v4.payload_size, '[^0-9]', ''))) / NULLIF(TO_NUMBER(REGEXP_REPLACE(v4.write_duration, '[^0-9]', '')) / POWER(10,3), 0), 3) AS kbps
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
                                 WHEN payload LIKE CHR(10)||'*** '||TO_CHAR(SYSDATE, 'YYYY')||'%' THEN 'DATE' 
                                 WHEN payload LIKE 'Warning: log write elapsed time %'            THEN 'WRITE'
                               END AS line_type,
                               CASE 
                                 WHEN payload LIKE CHR(10)||'*** '||TO_CHAR(SYSDATE, 'YYYY')||'%' THEN SUBSTR(SUBSTR(payload, 1, INSTR(payload, '(') - 2), INSTR(payload, TO_CHAR(SYSDATE, 'YYYY'))) 
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
      ) v4
 WHERE v4.rn = 1
   AND v4.timestamp > SYSTIMESTAMP - INTERVAL '1' MINUTE
ORDER BY v4.line_number
/