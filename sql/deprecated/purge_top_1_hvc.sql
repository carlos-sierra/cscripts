----------------------------------------------------------------------------------------
--
-- File name:   purge_top_1_hvc.sql
--
-- Purpose:     Finds top#1 HVC SQL and purges it if version count per PDB > 100 (on AVG) 
--
-- Author:      Carlos Sierra
--
-- Version:     2018/04/27
--
-- Usage:       Execute connected into CDB as SYS (or from OEM)
--              IOD_REPEATING_PURGE_TOP1_HVC_SQL on HOST_CLASS_IOD-DB
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @purge_top_1_hvc.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
--              To workaround bug 22994542 affecting SQL below
--
--              9p03bkzbspwp2 SELECT /*+ OPT_PARAM(‘_fix_control’ ‘9088510:0’) 
--                            NO_XML_QUERY_REWRITE cursor_sharing_exact* / count(*)  
--                            FROM SYS.DUAL WHERE sys_context(‘userenv’, ‘os_user’) 
--                            not in (‘root’,‘oracle’,‘?’)
--
---------------------------------------------------------------------------------------
--
-- exit graciously if executed on standby
WHENEVER SQLERROR EXIT SUCCESS;
DECLARE
  l_open_mode VARCHAR2(20);
BEGIN
  SELECT open_mode INTO l_open_mode FROM v$database;
  IF l_open_mode <> 'READ WRITE' THEN
    raise_application_error(-20000, 'Must execute on PRIMARY');
  END IF;
END;
/
WHENEVER SQLERROR CONTINUE;
--
PRO
SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
PRO
DEF sql_id = '';
COL sql_id NEW_V sql_id;
PRO
PRO Finding top#1 SQL as per HVC
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SELECT /* finds the top#1 HVC sql */
       sql_id, cursors, pdbs,  ROUND(cursors / pdbs) cursors_per_pdb, sharable_mem_mb, sql_text
 FROM (
SELECT sql_id,
       COUNT(*) cursors,
       COUNT(DISTINCT con_id) pdbs,
       ROUND(SUM(sharable_mem)/POWER(2,20)) sharable_mem_mb,
       ROW_NUMBER () OVER (ORDER BY COUNT(*) DESC) row_number, -- by HVC
       sql_text
  FROM v$sql
 GROUP BY
       sql_id,
       sql_text
 ORDER BY 1 DESC
) 
WHERE row_number = 1
  AND cursors / pdbs > 100 -- over 100 child cursors per PDB (on avg)
/
PRO
-- exit graciously if there is no such SQL
WHENEVER SQLERROR EXIT SUCCESS;
PRO
PRO *** Ignore potential "ORA-01476: divisor is equal to zero". It just means there is no such top#1 SQL ***
--COL ignore_me NEW_V ignore_me NOPRI;
SELECT CASE WHEN '&&sql_id.' IS NOT NULL THEN 'Life is Good!' ELSE TO_CHAR(1/0)||'SQLERROR then exit!' END ignore_me FROM v$database;
WHENEVER SQLERROR CONTINUE;
--
PRO
COL zip_file_name NEW_V zip_file_name;
COL output_file_name NEW_V output_file_name;
SELECT '/tmp/purge_top_1_hvc_'||LOWER(name)||'_'||LOWER(REPLACE(SUBSTR(host_name, 1 + INSTR(host_name, '.', 1, 2), 30), '.', '_')) zip_file_name FROM v$database, v$instance;
SELECT '&&zip_file_name._&&sql_id._'||TO_CHAR(SYSDATE, 'dd"T"hh24') output_file_name FROM DUAL;
PRO
SPO &&output_file_name..txt;
PRO
PRO SQL Text for &&sql_id.
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~
SELECT sql_text FROM v$sql WHERE sql_id = '&&sql_id.' AND ROWNUM = 1
/
PRO
PRO Version count per PDB (before purge)
PRO ~~~~~~~~~~~~~~~~~~~~~
SELECT COUNT(*), con_id FROM v$sql WHERE sql_id = '&&sql_id.' GROUP BY con_id ORDER BY 1 DESC
/
PRO
PRO Purging &&sql_id.
PRO ~~~~~~~~~~~~~~~~~~~~~
DECLARE
  l_name     VARCHAR2(64);
  l_sql_fulltext CLOB;
  l_sql_text VARCHAR2(1000);
  l_hint     VARCHAR2(64);
BEGIN
  IF '&&sql_id.' IS NOT NULL THEN
    -- get address, hash_value and sql text
    SELECT address||','||hash_value, sql_text, sql_fulltext 
      INTO l_name, l_sql_text, l_sql_fulltext 
      FROM v$sqlarea 
     WHERE sql_id = '&&sql_id.'
       AND ROWNUM = 1; -- there are cases where it comes back with > 1 row!!!
    -- not always does the job
    SYS.DBMS_SHARED_POOL.PURGE (
      name  => l_name,
      flag  => 'C',
      heaps => 1
    );
    -- hint
    IF LOWER(l_sql_text) LIKE '%_fix_control%' THEN
      l_hint := 'IGNORE_OPTIM_EMBEDDED_HINTS';
    ELSE
      l_hint := 'NULL';
    END IF;   
    --
    SYS.DBMS_SQLDIAG.DROP_SQL_PATCH (
      name   => 'purge_&&sql_id.', 
      ignore => TRUE
    );
    -- create sql patch
    SYS.DBMS_SQLDIAG_INTERNAL.I_CREATE_PATCH (
      sql_text    => l_sql_fulltext,
      hint_text   => l_hint, 
      name        => 'purge_&&sql_id.',
      description => 'PURGE CURSOR /*+ '||l_hint||' */',
      category    => 'DEFAULT',
      validate    => TRUE
    );
    --
    IF l_hint = 'NULL' THEN
      -- drop fake sql patch
      SYS.DBMS_SQLDIAG.DROP_SQL_PATCH (
        name   => 'purge_&&sql_id.', 
        ignore => TRUE
      );
    END IF;
  END IF;
END;
/
PRO
PRO Version count per PDB (after purge)
PRO ~~~~~~~~~~~~~~~~~~~~~
SELECT COUNT(*), con_id FROM v$sql WHERE sql_id = '&&sql_id.' GROUP BY con_id ORDER BY 1 DESC
/
PRO
SPO OFF;
PRO
HOS zip -mj &&zip_file_name..zip &&output_file_name..txt
HOS unzip -l &&zip_file_name..zip
PRO
