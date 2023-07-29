----------------------------------------------------------------------------------------
--
-- File name:   cs_listener_log.sql
--
-- Purpose:     Get listener log
--
-- Author:      Carlos Sierra
--
-- Version:     2021/07/02
--
-- Usage:       Execute connected to CDB or PDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_listener_log.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
--
COL listener_log_dir NEW_V listener_log_dir FOR A100 NOPRI;
SELECT d.value||'/diag/tnslsnr/'||SUBSTR(i.host_name, 1, INSTR(i.host_name, '.') - 1)||'/listener/trace' AS listener_log_dir FROM v$diag_info d, v$instance i WHERE d.name = 'ADR Base';
PRO copy listener.log into /tmp
HOS cp &&listener_log_dir./listener.log* /tmp/
PRO compute logons per second
HOS cat /tmp/listener.log | grep "CONNECT_DATA" | grep "[0-9][0-9]\-[A-Z][A-Z][A-Z]\-[0-9][0-9][0-9][0-9] " | cut -b 1-20 | uniq -c > /tmp/listener.log_logons_per_sec.txt
PRO compute logons per minute
HOS cat /tmp/listener.log | grep "CONNECT_DATA" | grep "[0-9][0-9]\-[A-Z][A-Z][A-Z]\-[0-9][0-9][0-9][0-9] " | cut -b 1-17 | uniq -c > /tmp/listener.log_logons_per_min.txt
PRO compute logons per hour
HOS cat /tmp/listener.log | grep "CONNECT_DATA" | grep "[0-9][0-9]\-[A-Z][A-Z][A-Z]\-[0-9][0-9][0-9][0-9] " | cut -b 1-14 | uniq -c > /tmp/listener.log_logons_per_hour.txt
PRO compute logons per day
HOS cat /tmp/listener.log | grep "CONNECT_DATA" | grep "[0-9][0-9]\-[A-Z][A-Z][A-Z]\-[0-9][0-9][0-9][0-9] " | cut -b 1-11 | uniq -c > /tmp/listener.log_logons_per_day.txt
HOS chmod 644 /tmp/listener.log*
PRO
PRO Current and prior listener logs on &&listener_log_dir.
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
HOS ls -oX &&listener_log_dir./listener.log*
PRO
PRO Preserved listener logs on /tmp
PRO ~~~~~~~~~~~~~~~~~~~~~~~
HOS ls -oX /tmp/listener.log*
PRO
PRO If you want to copy listener log file(s), execute one scp command below, from a TERM session running on your Mac/PC:
PRO
PRO scp &&cs_host_name.:/tmp/listener.log &&cs_local_dir.
PRO scp &&cs_host_name.:/tmp/listener.log_logons_per_*.txt &&cs_local_dir.
PRO scp &&cs_host_name.:/tmp/listener.log* &&cs_local_dir.
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--
