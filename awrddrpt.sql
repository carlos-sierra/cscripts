-- AWR Difference Report
@$ORACLE_HOME/rdbms/admin/awrddrpt.sql
--
HOS cp awrdiff_*.* /tmp
HOS chmod 644 /tmp/awrdiff_*.*
PRO
PRO If you want to preserve script output, execute corresponding scp command below, from a TERM session running on your Mac/PC:
HOS echo "scp $HOSTNAME:/tmp/awrdiff_*.* ."