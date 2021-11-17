----------------------------------------------------------------------------------------
--
-- File name:   cs_tbs_resize.sql
--
-- Purpose:     Tablespace Resize
--
-- Author:      Rodrigo Righetti
--
-- Version:     2020/12/09
--
-- Usage:       Execute connected to CDB or PDB.
--
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_tbs_resize.sql TBSNAME 10
--
--              This execution would increase the maxsize for Tablespace TBSNAME in 10%.
--
-- Notes:       Developed and tested on 12.1.0.2 and 19c.
--
---------------------------------------------------------------------------------------
--
--
DEF permanent = 'Y';
DEF undo = 'Y';
DEF temporary = 'Y';
-- order_by: [{pdb_name, tablespace_name}|max_size_gb DESC|allocated_gb DESC|used_gb DESC|free_gb DESC]
DEF order_by = 'pdb_name, tablespace_name';
DEF rows = '999';
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_tbs_resize';
--
COL tablespace_name FOR A30;
SELECT tablespace_name 
FROM   dba_tablespaces;
PRO
--
PRO 1. Tablespace to resize: 
DEF tbs_name = '&1.';
UNDEF 1;

--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&tbs_name."
@@cs_internal/cs_spool_id.sql
--
--
CLEAR BREAK COMPUTE;
BREAK ON REPORT;
COMPUTE SUM LABEL 'TOTAL' OF allocated_gb used_gb free_gb max_size_gb ON REPORT; 
--
COL pdb_name FOR A30;
COL tablespace_name FOR A30;
COL allocated_gb FOR 999,990.000 HEA 'ALLOCATED|SPACE (GB)';
COL used_gb FOR 999,990.000 HEA 'USED|SPACE (GB)';
COL used_percent FOR 990.0 HEA 'USED|PERC';
COL free_gb FOR 999,990.000 HEA 'FREE|SPACE (GB)';
COL free_percent FOR 990.0 HEA 'FREE|PERC';
COL max_size_gb FOR 999,990.000 HEA 'MAX|SIZE (GB)';
COL met_used_space_GB FOR 999,990.000 HEA 'METRICS|USED|SPACE (GB)';
COL met_used_percent FOR 990.0 HEA 'METRICS|USED|PERC';
--
WITH
t AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       con_id,
       tablespace_name,
       SUM(NVL(bytes, 0)) bytes
  FROM cdb_data_files
  WHERE con_id=&&cs_con_id.
 GROUP BY 
       con_id,
       tablespace_name
 UNION ALL
SELECT /*+ MATERIALIZE NO_MERGE */
       con_id,
       tablespace_name,
       SUM(NVL(bytes, 0)) bytes
  FROM cdb_temp_files
    WHERE con_id=&&cs_con_id.
 GROUP BY 
       con_id,
       tablespace_name
),
u AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       con_id,
       tablespace_name,
       SUM(bytes) bytes
  FROM cdb_free_space
    WHERE con_id=&&cs_con_id.
 GROUP BY 
        con_id,
        tablespace_name
 UNION ALL
SELECT /*+ MATERIALIZE NO_MERGE */
       con_id,
       tablespace_name,
       NVL(SUM(bytes_used), 0) bytes
  FROM gv$temp_extent_pool
    WHERE con_id=&&cs_con_id.
 GROUP BY 
       con_id,
       tablespace_name
),
un AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       ts.con_id,
       ts.tablespace_name,
       NVL(um.used_space * ts.block_size, 0) bytes
  FROM cdb_tablespaces              ts,
       cdb_tablespace_usage_metrics um
 WHERE ts.contents           = 'UNDO'
   AND um.tablespace_name(+) = ts.tablespace_name
   AND um.con_id(+)          = ts.con_id
),
oem AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       ts.con_id,
       pdb.name pdb_name,
       ts.tablespace_name,
       ts.contents,
       ts.bigfile,
       ts.block_size,
       NVL(t.bytes, 0) allocated_space_bytes,
       NVL(
       CASE ts.contents
       WHEN 'UNDO'         THEN un.bytes
       WHEN 'PERMANENT'    THEN t.bytes - NVL(u.bytes, 0)
       WHEN 'TEMPORARY'    THEN
         CASE ts.extent_management
         WHEN 'LOCAL'      THEN u.bytes
         WHEN 'DICTIONARY' THEN t.bytes - NVL(u.bytes, 0)
         END
       END 
       , 0) used_space_bytes
  FROM cdb_tablespaces ts,
       v$containers    pdb,
       t,
       u,
       un
 WHERE 1 = 1
   AND t.tablespace_name = upper('&&tbs_name.')
   AND pdb.con_id            = ts.con_id
   AND t.tablespace_name(+)  = ts.tablespace_name
   AND t.con_id(+)           = ts.con_id
   AND u.tablespace_name(+)  = ts.tablespace_name
   AND u.con_id(+)           = ts.con_id
   AND un.tablespace_name(+) = ts.tablespace_name
   AND un.con_id(+)          = ts.con_id
),
tablespaces AS (
SELECT o.pdb_name,
       o.tablespace_name,
       o.contents,
       o.bigfile,
       ROUND(m.maxbytes / POWER(10, 9), 3) AS max_size_gb,
       ROUND(o.allocated_space_bytes / POWER(10, 9), 3) AS allocated_gb,
       ROUND(o.used_space_bytes / POWER(10, 9), 3) AS used_gb,
       ROUND((o.allocated_space_bytes - o.used_space_bytes) / POWER(10, 9), 3) AS free_gb,
       ROUND(100 * o.used_space_bytes / o.allocated_space_bytes, 3) AS used_percent, -- as per allocated space
       ROUND(100 * (o.allocated_space_bytes - o.used_space_bytes) / o.allocated_space_bytes, 3) AS free_percent -- as per allocated space
  FROM oem                          o,
       (SELECT con_id, tablespace_name, sum(maxbytes) maxbytes
       FROM cdb_data_files
       WHERE con_id = &&cs_con_id.
       GROUP BY con_id, tablespace_name
       UNION
       SELECT con_id, tablespace_name, sum(maxbytes) maxbytes
       FROM cdb_temp_files
       WHERE con_id = &&cs_con_id.
       GROUP BY con_id, tablespace_name
       ) m
 WHERE m.tablespace_name(+) = o.tablespace_name
   AND m.con_id(+)          = o.con_id
)
SELECT pdb_name,
       tablespace_name,
       contents,
       bigfile,
       '|' AS "|",
       max_size_gb,
       allocated_gb,
       used_gb,
       free_gb,
       used_percent,
       free_percent 
  FROM tablespaces
 ORDER BY
       &&order_by.
FETCH FIRST &&rows. ROWS ONLY
/
--
--
ALTER SESSION SET container = CDB$ROOT;
--
COL p_u02 NEW_V p_u02 FOR 99999999;
--
PRO
PRO OS SPACE AVAILABLE - FREE GB U02
 -- OS space available
SELECT round(U02_AVAILABLE/power(2,20)) p_u02
FROM C##IOD.dbc_system
WHERE TIMESTAMP= (select max(TIMESTAMP) from C##IOD.dbc_system);
--
PRO
--
ALTER SESSION SET CONTAINER = &&cs_con_name.;
--
SET SERVEROUTPUT ON
BEGIN
    DBMS_OUTPUT.put_line('-----------------------------------------------------------------------------------------');
    DBMS_OUTPUT.put_line('Max permissible increase must be between 1% and 20%, different values will default to 10%');
    DBMS_OUTPUT.put_line('-----------------------------------------------------------------------------------------');
    DBMS_OUTPUT.put_line('Increments are always rounded up "ceil", small files always added with 1G and maxsize 32G');
    DBMS_OUTPUT.put_line('-----------------------------------------------------------------------------------------');

END;
/
PRO
PRO 2. What percentange to increase the TBS maxsize  {[10]|1-20}?:
DEF perc_increase = '&2.';
UNDEF 2;
--
COL p_perc_increase NEW_V p_perc_increase NOPRI;
SELECT CASE WHEN &&perc_increase. BETWEEN 1 AND 20 THEN &&perc_increase. ELSE 10 END AS p_perc_increase FROM DUAL
/
--
SET SERVEROUTPUT ON
--
DECLARE

l_u02_avail NUMBER := &&p_u02.;
l_perc_increase NUMBER := (&&p_perc_increase./100)+1;
l_statement CLOB;
l_newmax    NUMBER;
l_bytes     NUMBER;
l_maxbytes  NUMBER;
l_nfiles    NUMBER;
l_smmaxfix  NUMBER;
l_addfilesc NUMBER;
l_counter   NUMBER := 1;
l_temp      VARCHAR2(10) := ' DATAFILE ';

BEGIN

    IF upper('&&tbs_name.') like 'TEMP%' THEN

        SELECT round(sum(bytes)/power(2,30)) bytes_gb , round(sum(maxbytes)/power(2,30)) maxbytes_gb, count(*) numfiles
        INTO   l_bytes, l_maxbytes, l_nfiles
        FROM  dba_temp_files
        WHERE tablespace_name = upper('&&tbs_name.');

        l_temp := ' TEMPFILE ';

    ELSE
        SELECT round(sum(bytes)/power(2,30)) bytes_gb , round(sum(maxbytes)/power(2,30)) maxbytes_gb, count(*) numfiles
        INTO   l_bytes, l_maxbytes, l_nfiles
        FROM  dba_data_files
        WHERE tablespace_name = upper('&&tbs_name.');

    END IF;



    FOR i IN (SELECT tablespace_name, bigfile
              FROM dba_tablespaces
              WHERE tablespace_name = upper('&&tbs_name.') ) LOOP

              IF i.bigfile = 'YES' THEN

                    FOR j IN (SELECT file_id, autoextensible, (bytes/power(2,30)) bytes_gb, (maxbytes/power(2,30)) maxbytes_gb
                          FROM dba_data_files
                          WHERE tablespace_name = upper('&&tbs_name.')
                            ) LOOP

                            IF j.maxbytes_gb <= j.bytes_gb THEN
                                l_newmax := ceil(j.bytes_gb * l_perc_increase);
                            ELSIF j.maxbytes_gb < (j.maxbytes_gb*l_perc_increase) THEN 
                                l_newmax := ceil(j.maxbytes_gb * l_perc_increase);
                            ELSIF j.maxbytes_gb >= (j.maxbytes_gb*l_perc_increase) THEN
                                DBMS_OUTPUT.put_line( 'Maxsize already has over '||l_perc_increase||'% increase requested.');
                                RETURN;
                            END IF;

                            IF l_newmax = 0 THEN
                                l_newmax := 1;
                                DBMS_OUTPUT.put_line('Tablespace too small, minimal adjustment is 1G:');
                            END IF;

                            IF (l_newmax - j.bytes_gb) >= (l_u02_avail*.7) THEN
                                DBMS_OUTPUT.put_line('Your new Maxsize request is over 70% of the available /u02 free space !!!');
                                RETURN;
                            END IF;

                            DBMS_OUTPUT.put_line('-------------------------------------------------------------------------------------');

                            l_statement := 'ALTER DATABASE DATAFILE '||j.file_id||' AUTOEXTEND ON NEXT 1G MAXSIZE '||l_newmax||'G';
                            DBMS_OUTPUT.put_line(l_statement);
                            execute immediate l_statement;
                            
                    END LOOP;
            ELSE
                    -- small file support
                    -- if all datafiles already at max 32 gb, then add datafile, else fix Maxsize and add datafile if needed
                    -- Small files always increamented in 32gb files maxsize

                    -- fix max size of current datafiles

                    IF l_maxbytes > l_bytes THEN
                        l_newmax := ceil((l_maxbytes*l_perc_increase)-l_maxbytes);
                    ELSE
                        l_newmax := ceil((l_bytes*l_perc_increase)-l_bytes);
                    END IF;

                    IF (l_newmax - l_bytes) >= (l_u02_avail*.7) THEN
                        DBMS_OUTPUT.put_line( 'Your new Maxsize request is over 70% of the available /u02 free space !!!');
                        RETURN;
                    END IF;

                    FOR j IN (SELECT file_id, autoextensible, (bytes/power(2,30)) bytes_gb, (maxbytes/power(2,30)) maxbytes_gb, (maxbytes/power(2,30))-(bytes/power(2,30)) free_gb
                          FROM dba_data_files
                          WHERE tablespace_name = upper('&&tbs_name.')
                          AND   round(maxbytes/power(2,30)) < 32
                          UNION 
                          SELECT file_id, autoextensible, (bytes/power(2,30)) bytes_gb, (maxbytes/power(2,30)) maxbytes_gb, (maxbytes/power(2,30))-(bytes/power(2,30)) free_gb
                          FROM dba_temp_files
                          WHERE tablespace_name = upper('&&tbs_name.')
                          AND   round(maxbytes/power(2,30)) < 32
                          ORDER by file_id) LOOP

                            l_statement := 'ALTER DATABASE '||l_temp||' '||j.file_id||' AUTOEXTEND ON NEXT 1G MAXSIZE UNLIMITED';
                            DBMS_OUTPUT.put_line(l_statement);
                            execute immediate l_statement;

                    END LOOP;

                     SELECT max(maxbytes_gb)
                     INTO   l_smmaxfix
                     FROM ( 
                         SELECT sum(maxbytes)/power(2,30) maxbytes_gb
                         FROM  dba_data_files
                         WHERE tablespace_name = upper('&&tbs_name.')
                         UNION 
                         SELECT sum(maxbytes)/power(2,30) maxbytes_gb
                         FROM  dba_temp_files
                         WHERE tablespace_name = upper('&&tbs_name.')
                     )
                     ;

                    DBMS_OUTPUT.put_line('-------------------------------------------------------------------------------------');

                    IF l_smmaxfix >= l_maxbytes+l_newmax THEN
                        DBMS_OUTPUT.PUT_LINE('SmallFile Tablespace maxsize increased to: '||round(l_smmaxfix,2)||'G, no need to add more datafiles');
                    ELSE
                        DBMS_OUTPUT.PUT_LINE( 'Smallfile tablespaces are added with 1G autoexted and Maxsize of 32G.');

                        l_newmax := ceil((l_smmaxfix*l_perc_increase)-l_smmaxfix);

                        IF (l_newmax - l_bytes) >= (l_u02_avail*.7) THEN
                           DBMS_OUTPUT.PUT_LINE( 'Your new Maxsize request is over 70% of the available /u02 free space !!!');
                           RETURN;
                        END IF;

                        l_addfilesc := ceil(l_newmax/32);

                        WHILE l_counter <= l_addfilesc
                        LOOP

                          l_statement := 'ALTER TABLESPACE '||i.tablespace_name||' ADD '||l_temp||' SIZE 1G AUTOEXTEND ON NEXT 1G MAXSIZE UNLIMITED';
                           DBMS_OUTPUT.put_line(l_statement);
                           execute immediate l_statement;
                          l_counter := l_counter + 1;
                        END LOOP;
 
                    END IF;
                        
            END IF;
    END LOOP;

END;
/

PRO -------------------
PRO
PRO New Tablespace Size
PRO -------------------

WITH
t AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       con_id,
       tablespace_name,
       SUM(NVL(bytes, 0)) bytes
  FROM cdb_data_files
  WHERE con_id=&&cs_con_id.
 GROUP BY 
       con_id,
       tablespace_name
 UNION ALL
SELECT /*+ MATERIALIZE NO_MERGE */
       con_id,
       tablespace_name,
       SUM(NVL(bytes, 0)) bytes
  FROM cdb_temp_files
    WHERE con_id=&&cs_con_id.
 GROUP BY 
       con_id,
       tablespace_name
),
u AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       con_id,
       tablespace_name,
       SUM(bytes) bytes
  FROM cdb_free_space
    WHERE con_id=&&cs_con_id.
 GROUP BY 
        con_id,
        tablespace_name
 UNION ALL
SELECT /*+ MATERIALIZE NO_MERGE */
       con_id,
       tablespace_name,
       NVL(SUM(bytes_used), 0) bytes
  FROM gv$temp_extent_pool
    WHERE con_id=&&cs_con_id.
 GROUP BY 
       con_id,
       tablespace_name
),
un AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       ts.con_id,
       ts.tablespace_name,
       NVL(um.used_space * ts.block_size, 0) bytes
  FROM cdb_tablespaces              ts,
       cdb_tablespace_usage_metrics um
 WHERE ts.contents           = 'UNDO'
   AND um.tablespace_name(+) = ts.tablespace_name
   AND um.con_id(+)          = ts.con_id
),
oem AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       ts.con_id,
       pdb.name pdb_name,
       ts.tablespace_name,
       ts.contents,
       ts.bigfile,
       ts.block_size,
       NVL(t.bytes, 0) allocated_space_bytes,
       NVL(
       CASE ts.contents
       WHEN 'UNDO'         THEN un.bytes
       WHEN 'PERMANENT'    THEN t.bytes - NVL(u.bytes, 0)
       WHEN 'TEMPORARY'    THEN
         CASE ts.extent_management
         WHEN 'LOCAL'      THEN u.bytes
         WHEN 'DICTIONARY' THEN t.bytes - NVL(u.bytes, 0)
         END
       END 
       , 0) used_space_bytes
  FROM cdb_tablespaces ts,
       v$containers    pdb,
       t,
       u,
       un
 WHERE 1 = 1
   AND t.tablespace_name = upper('&&tbs_name.')
   AND pdb.con_id            = ts.con_id
   AND t.tablespace_name(+)  = ts.tablespace_name
   AND t.con_id(+)           = ts.con_id
   AND u.tablespace_name(+)  = ts.tablespace_name
   AND u.con_id(+)           = ts.con_id
   AND un.tablespace_name(+) = ts.tablespace_name
   AND un.con_id(+)          = ts.con_id
),
tablespaces AS (
SELECT o.pdb_name,
       o.tablespace_name,
       o.contents,
       o.bigfile,
       ROUND(m.maxbytes / POWER(10, 9), 3) AS max_size_gb,
       ROUND(o.allocated_space_bytes / POWER(10, 9), 3) AS allocated_gb,
       ROUND(o.used_space_bytes / POWER(10, 9), 3) AS used_gb,
       ROUND((o.allocated_space_bytes - o.used_space_bytes) / POWER(10, 9), 3) AS free_gb,
       ROUND(100 * o.used_space_bytes / o.allocated_space_bytes, 3) AS used_percent, -- as per allocated space
       ROUND(100 * (o.allocated_space_bytes - o.used_space_bytes) / o.allocated_space_bytes, 3) AS free_percent -- as per allocated space
  FROM oem                          o,
       (SELECT con_id, tablespace_name, sum(maxbytes) maxbytes
       FROM cdb_data_files
       WHERE con_id = &&cs_con_id.
       GROUP BY con_id, tablespace_name
       UNION
       SELECT con_id, tablespace_name, sum(maxbytes) maxbytes
       FROM cdb_temp_files
       WHERE con_id = &&cs_con_id.
       GROUP BY con_id, tablespace_name
       ) m
 WHERE m.tablespace_name(+) = o.tablespace_name
   AND m.con_id(+)          = o.con_id
)
SELECT pdb_name,
       tablespace_name,
       contents,
       bigfile,
       '|' AS "|",
       max_size_gb,
       allocated_gb,
       used_gb,
       free_gb,
       used_percent,
       free_percent 
  FROM tablespaces
 ORDER BY
       &&order_by.
FETCH FIRST &&rows. ROWS ONLY
/

CLEAR BREAK COMPUTE;
--
PRO
PRO SQL> @&&cs_script_name..sql "&&tbs_name." "&&perc_increase."
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--