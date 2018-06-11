PRO 1. Enter KIEV Transaction: [{CBSGU}|C|B|S|G|U|CB|SG] (C=CommitTx B=BeginTx S=Scan G=GC U=Unknown)
DEF kiev_tx = '&1.';
PRO 2. SQL_ID: (default null)
DEF sql_id = '&2.';
PRO 3. Plan Hash Value: (default null)
DEF phv = '&3.';

@@dba_hist_sqlstat_perf_chart.sql "&&kiev_tx." "&&sql_id." "&&phv."
@@dba_hist_sqlstat_dbtime_chart.sql "&&kiev_tx." "&&sql_id." "&&phv."
@@dba_hist_sqlstat_execs_chart.sql "&&kiev_tx." "&&sql_id." "&&phv."
@@dba_hist_sqlstat_bg_chart.sql "&&kiev_tx." "&&sql_id." "&&phv."
@@dba_hist_sqlstat_rows_chart.sql "&&kiev_tx." "&&sql_id." "&&phv."

HOS zip -m dba_hist_sqlstat_*_Tx&&kiev_tx._S&&sql_id._P&&phv..zip dba_hist_sqlstat_*_Tx&&kiev_tx._S&&sql_id._P&&phv._*.html

PRO
PRO dba_hist_sqlstat_*_Tx&&kiev_tx._S&&sql_id._P&&phv..zip