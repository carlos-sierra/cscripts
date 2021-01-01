----------------------------------------------------------------------------------------
--
-- File name:   cs_LGWR_trc.sql
--
-- Purpose:     Get log writer LGWR trace
--
-- Author:      Carlos Sierra
--
-- Version:     2020/12/06
--
-- Usage:       Execute connected to CDB or PDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_LGWR_trc.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
--
COL trace_dir NEW_V trace_dir FOR A100 NOPRI;
COL lgwr_trc NEW_V lgwr_trc FOR A30 NOPRI;
SELECT d.value AS trace_dir, LOWER('&&cs_db_name._')||LOWER(p.pname)||'_'||p.spid||'.trc' AS lgwr_trc FROM v$diag_info d, v$process p WHERE d.name = 'Diag Trace' AND p.pname = 'LGWR';
HOS cp &&trace_dir./&&lgwr_trc. /tmp/
HOS chmod 644 /tmp/&&lgwr_trc.
PRO
PRO Preserved LGWR trace on /tmp
PRO ~~~~~~~~~~~~~~~~~~~~~~~
HOS ls -oX /tmp/&&lgwr_trc.
PRO
PRO If you want to copy LGWR trace file, execute scp command below, from a TERM session running on your Mac/PC:
PRO
PRO scp &&cs_host_name.:/tmp/&&lgwr_trc. &&cs_local_dir.
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--
