-- trace_10046_off.sql - Turn OFF SQL Trace on own Session
ALTER SESSION SET SQL_TRACE = FALSE;
ALTER SESSION SET STATISTICS_LEVEL = 'TYPICAL';
--
HOS cp &&trace_file. /tmp/
HOS chmod 644 /tmp/&&filename.
--
HOS tkprof &&trace_file. /tmp/&&filename._tkprof_nosort.txt
HOS tkprof &&trace_file. /tmp/&&filename._tkprof_sort.txt sort=prsela exeela fchela 
HOS chmod 644 /tmp/&&filename._tkprof_*sort.txt
--
PRO scp &&host_name.:/tmp/&&filename.* .
PRO scp &&host_name.:/tmp/&&filename._tkprof*.txt .
