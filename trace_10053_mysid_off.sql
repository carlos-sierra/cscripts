-- trace_10053_mysid_off.sql - Turn OFF CBO EVENT 10053 on own Session
ALTER SESSION SET EVENTS '10053 TRACE NAME CONTEXT OFF';
--
HOS cp &&trace_file. /tmp/
HOS chmod 644 /tmp/&&filename.
--
PRO scp &&host_name.:/tmp/&&filename.* .
