PRO
PRO Producing list of cs scripts as per: HOST ls $ORATK_HOME/sql/cscripts/<file_mask> | xargs -n1 basename | sort
PRO 
PRO 1. Enter optional file_mask, e.g.: [{*}|cs|spbl|sprf|spch|ash|chart|awr|kiev|session|kill|sqlmon|osstat|...]
HOST ls $ORATK_HOME/sql/cscripts/*&1.* | xargs -n1 basename | sort
UNDEF 1
