-- ASH report
@$ORACLE_HOME/rdbms/admin/ashrpt.sql
--
HOS cp ashrpt_*.* /tmp
HOS chmod 644 /tmp/ashrpt_*.*
PRO
PRO If you want to preserve script output, execute corresponding scp command below, from a TERM session running on your Mac/PC:
HOS echo "scp $HOSTNAME:/tmp/ashrpt_*.* ."