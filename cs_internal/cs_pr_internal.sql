----------------------------------------------------------------------------------------
--
-- File name:   cs_pr_internal.sql
--
-- Purpose:     Print Table (vertical display of result columns for last query)
--
-- Author:      Carlos Sierra
--
-- Version:     2020/03/10
--
-- Usage:       Execute connected to PDB or CDB. 
--
--              Parameter options:
--
--              1. directory_path/script_name.sql (with one query)
--
--              2. one query
--
--              3. null (assumes then last sql executed)
--
-- Examples:    1. SQL> @cs_pr_internal.sql "/tmp/carlos.sql"
--
--              2. SQL> @cs_pr_internal.sql "SELECT * FROM v$database;"
--
--              3. SQL> @cs_pr_internal.sql ""
--
-- Notes:       When passing a query which contains single quotes then double them
--              e.g. SQL> @cs_pr_internal.sql "SELECT sid||'',''||serial# AS sid_serial FROM v$session"
--
--              Modified version of Tanel Poder pr.sql script, which is a mofified version
--              of Tom Kyte printtbl code.
--             
---------------------------------------------------------------------------------------
--
-- https://github.com/tanelpoder/tpt-oracle/blob/master/pr.sql
-- Notes:   This script is based on Tom Kyte's original printtbl code ( http://asktom.oracle.com )
--          For coding simplicity (read: lazyness) I'm using custom quotation marks ( q'\ ) so 
--          this script works only from Oracle 10gR2 onwards
-- prompt Pivoting output using Tom Kyte's printtab....
--
SET TERM OFF;
SPO &&cs_file_name..txt APP;
SPO OFF;
SAVE "/tmp/sql_pr_tmpfile.sql" REPLACE;
STORE SET "/tmp/set_pr_tmpfile.sql" REPLACE;
SET TERM ON HEA OFF TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON SERVEROUT ON SIZE UNL TRIM ON LIN 4050;
--
--PRO
--PRO 1. Enter [directory_path/script_name.sql|"query"|null]: 
DEF cs_parameter = '&1.';
UNDEF 1;
SET TERM OFF;
--
COL cs_option NEW_V cs_option NOPRI;
COL cs_parameter NEW_V cs_parameter NOPRI;
SELECT CASE 
         WHEN LOWER(SUBSTR(TRIM(q'[&&cs_parameter.]'), -4, 4)) = '.sql' THEN '1'
         WHEN TRIM(q'[&&cs_parameter.]') IS NULL THEN '3'
         ELSE '2'
       END AS cs_option,
       CASE 
         WHEN LOWER(SUBSTR(TRIM(q'[&&cs_parameter.]'), -4, 4)) = '.sql' THEN TRIM(q'[&&cs_parameter.]')
         WHEN TRIM(q'[&&cs_parameter.]') IS NULL THEN '/tmp/sql_pr_tmpfile.sql'
         ELSE TRIM(';' FROM TRIM('"' FROM TRIM(q'[&&cs_parameter.]')))
       END AS cs_parameter
  FROM DUAL
/
--
SPOOL "/tmp/sql2_pr_tmpfile.sql";
PRO &&cs_parameter.
SPOOL OFF;
--
COL script_name NEW_V script_name NOPRI;
SELECT CASE '&&cs_option.'
       WHEN '1' THEN q'[&&cs_parameter.]'
       WHEN '2' THEN '/tmp/sql2_pr_tmpfile.sql'
       WHEN '3' THEN '/tmp/sql_pr_tmpfile.sql'
       END AS script_name
  FROM DUAL
/
--
GET "&&script_name." NOLIST;
SAVE "/tmp/sql_pr_tmpfile.sql" REPLACE;
--
0 c clob := q'\
0 declare
--
666666      \';;
666666      l_theCursor     integer default dbms_sql.open_cursor;;
666666      l_columnValue   varchar2(4000);;
666666      l_status        integer;;
666666      l_descTbl       dbms_sql.desc_tab;;
666666      l_colCnt        number;;
666666      l_amount        number;;
666666  begin
666666      IF DBMS_LOB.instr(c, ';') = 0 THEN 
666666        l_amount := DBMS_LOB.getlength(c);;
666666      ELSE 
666666        l_amount := DBMS_LOB.instr(c, ';') - 1;;
666666      END IF;;
666666      c := DBMS_LOB.substr(c, l_amount);;
666666      dbms_sql.parse(  l_theCursor, c, dbms_sql.native );;
666666      dbms_sql.describe_columns( l_theCursor, l_colCnt, l_descTbl );;
666666      for i in 1 .. l_colCnt loop
666666          dbms_sql.define_column( l_theCursor, i,
666666                                  l_columnValue, 4000 );;
666666      end loop;;
666666      l_status := dbms_sql.execute(l_theCursor);;
666666      while ( dbms_sql.fetch_rows(l_theCursor) > 0 ) loop
666666          dbms_output.put_line( '+--------------------------------+' );;
666666          for i in 1 .. l_colCnt loop
666666                  dbms_sql.column_value( l_theCursor, i,
666666                                         l_columnValue );;
666666                  dbms_output.put_line
666666                      ( '|'||lpad( lower(l_descTbl(i).col_name),
666666                        31 ) || ' : ' || l_columnValue );;
666666          end loop;;
666666      end loop;;
666666      dbms_output.put_line( '+--------------------------------+' );;
666666  exception
666666      when others then
666666          dbms_output.put_line(dbms_utility.format_error_backtrace);;
666666          raise;;
666666 end;;
SET TERM ON;
SPO &&cs_file_name..txt APP;
/
--
@"/tmp/set_pr_tmpfile.sql";
GET "&&script_name." NOLIST;
HOST rm "/tmp/set_pr_tmpfile.sql" "/tmp/sql_pr_tmpfile.sql" "/tmp/sql2_pr_tmpfile.sql";
SET TERM ON;
--
