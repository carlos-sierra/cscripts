----------------------------------------------------------------------------------------
--
-- File name:   sql_patch_tombstones.sql
--
-- Purpose:     SQL Patch first_rows hint into queries on tombstones table(s).
--
-- Author:      Carlos Sierra
--
-- Version:     2017/12/08
--
-- Usage:       Execute connected into the DB of interest.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @sql_patch_tombstones.sql
--
-- Notes:       Executes on COMPUTE PDB (see ALTER SESSION), but on R2 it has to execute
--              in 3 PDBs: COMPUTE_PHX_4X, BLOCKSTORAGE_FE and BLOCKSTORAGE_BE
--
--              Compatible with SQL Plan Baselines.
--
--              Only acts on SQL decorated with search string below, executed over
--              100 times, with no prior SPB, Profile or Patch, and with performance
--              worse than 100ms per execution.
--
--              Use fs.sql script passing same search string to validate sql performance
--              before and after.
--             
-- Databases:
--              REGION	DATABASE	DOMAIN	MEMBER	HOST
--              ~~~~~~	~~~~~~~~	~~~~~~	~~~~~~	~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--              R1	KIEV02		AD1	A	iod-db-kiev-01302.node.ad1.r1
--              R1	KIEV03A2	AD2	B	iod-db-kiev-02009.node.ad2.r1
--              R2	KIEV1AD1	AD1	C	iod-db-kiev-01013.node.ad1.r2
--              R2	KIEV1AD2	AD2	C	iod-db-kiev-02014.node.ad2.r2
--              R2	KIEV1AD3	AD3	C	iod-db-kiev-03005.node.ad3.r2
--              R3	KIEV01A1	AD1	B	iod-db-kiev-01002.node.ad1.us-ashburn-1
--              R3	KIEV02A2	AD2	A	iod-db-kiev-02005.node.ad2.us-ashburn-1
--              R3	KIEV02A3	AD3	B	iod-db-kiev-03008.node.ad3.us-ashburn-1
--              R4	KIEV01A1	AD1	A	iod-db-kiev-01001.node.ad1.eu-frankfurt-1
--              R4	KIEV01A2	AD2	A	iod-db-kiev-02001.node.ad2.eu-frankfurt-1
--              R4	KIEV01A3	AD3	A	iod-db-kiev-03001.node.ad3.eu-frankfurt-1
--
--              PDBs: 
--              ~~~~
--              R4 and R3: COMPUTE 
--              R2: COMPUTE_PHX_4X, BLOCKSTORAGE_FE and BLOCKSTORAGE_BE
--              R1 AD1: COMPUTE_SEA, BLOCKSTORAGE_FE and BLOCKSTORAGE_BE
--              R1 AD2: COMPUTE_STABLE, BLOCKSTORAGE_FE and BLOCKSTORAGE_BE
--
---------------------------------------------------------------------------------------
--
DEF search_string = 'tombstones,HashRange';
DEF cbo_hints = 'FIRST_ROWS(1)';
--
WHENEVER SQLERROR EXIT FAILURE;
ALTER SESSION SET CONTAINER = &pdb_name.;
--
COL current_time NEW_V current_time FOR A15;
SELECT 'current_time: ' x, TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') current_time FROM DUAL;
COL x_host_name NEW_V x_host_name;
SELECT host_name x_host_name FROM v$instance;
COL x_db_name NEW_V x_db_name;
SELECT name x_db_name FROM v$database;
COL x_container NEW_V x_container;
SELECT 'NONE' x_container FROM DUAL;
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') x_container FROM DUAL;
--
SPO sql_patch_tombstones_&&current_time..txt;
PRO HOST: &&x_host_name.
PRO DATABASE: &&x_db_name.
PRO CONTAINER: &&x_container.
PRO SEARCH_STRING: &&search_string.
PRO CBO_HINTS: &&cbo_hints.
--
SET LIN 300 SERVEROUT ON;
DECLARE
  l_sql_fulltext CLOB;
BEGIN
  FOR i IN (SELECT sql_id
              FROM v$sql
             WHERE UPPER(sql_text) LIKE UPPER('%&&search_string.%')
               AND executions > 0 -- avoid division by zero error on HAVING
             GROUP BY
                   sql_id
            HAVING MAX(sql_plan_baseline) IS NULL -- sql has no baseline
               AND MAX(sql_profile) IS NULL -- sql has no sql profile
               AND MAX(sql_patch) IS NULL -- sql has no patch
               AND SUM(elapsed_time)/SUM(executions)/1e3 > 100 -- sql elapsed time per execution is > 100ms
               AND SUM(executions) > 50 -- sql has over 100 executions
             ORDER BY
                   SUM(executions) DESC)
  LOOP
    SELECT sql_fulltext INTO l_sql_fulltext FROM v$sql WHERE sql_id = i.sql_id AND ROWNUM = 1;
    DBMS_OUTPUT.PUT_LINE('creating sql patch "sql_patch_'||i.sql_id||'" with hint(s) /*+ &&cbo_hints. */ on '||TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS'));
    SYS.DBMS_SQLDIAG_INTERNAL.I_CREATE_PATCH (
      sql_text    => l_sql_fulltext,
      hint_text   => q'[&&cbo_hints.]',
      name        => 'sql_patch_'||i.sql_id,
      description => q'[/*+ &&cbo_hints. */ &&search_string.]',
      category    => 'DEFAULT',
      validate    => TRUE
    );  
    DBMS_OUTPUT.PUT_LINE('to drop: EXEC DBMS_SQLDIAG.DROP_SQL_PATCH(name => ''sql_patch_'||i.sql_id||''', ignore => TRUE);');
    --EXIT; this is to do 1st one and stop
  END LOOP;
END;
/
--
SPO OFF;
--
UNDEF pdb_name
