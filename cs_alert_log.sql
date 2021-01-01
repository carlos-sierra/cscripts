----------------------------------------------------------------------------------------
--
-- File name:   cs_alert_log.sql
--
-- Purpose:     Get alert log
--
-- Author:      Carlos Sierra
--
-- Version:     2020/12/05
--
-- Usage:       Execute connected to CDB or PDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_alert_log.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
--
COL trace_dir NEW_V trace_dir FOR A100 NOPRI;
COL alert_log NEW_V alert_log FOR A30 NOPRI;
SELECT d.value trace_dir, 'alert_'||t.instance||'.log' alert_log FROM v$diag_info d, v$thread t WHERE d.name = 'Diag Trace';
HOS cp &&trace_dir./&&alert_log.* /tmp/
HOS chmod 644 /tmp/&&alert_log.*
PRO
PRO Current and prior alert logs on &&trace_dir.
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
HOS ls -oX &&trace_dir./&&alert_log.*
PRO
PRO Preserved alert logs on /tmp
PRO ~~~~~~~~~~~~~~~~~~~~~~~
HOS ls -oX /tmp/alert*.log*
PRO
PRO If you want to copy alert log file(s), execute one scp command below, from a TERM session running on your Mac/PC:
PRO
PRO scp &&cs_host_name.:/tmp/&&alert_log. &&cs_local_dir.
PRO scp &&cs_host_name.:/tmp/&&alert_log.* &&cs_local_dir.
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--
