-- exit graciously if executed on standby
WHENEVER SQLERROR EXIT SUCCESS;
DECLARE
  l_open_mode VARCHAR2(20);
BEGIN
  SELECT open_mode INTO l_open_mode FROM v$database;
  IF l_open_mode <> 'READ WRITE' THEN
    raise_application_error(-20000, 'Must execute on PRIMARY');
  END IF;
END;
/
WHENEVER SQLERROR CONTINUE;
--
-- exit graciously if executed from CDB$ROOT
WHENEVER SQLERROR EXIT SUCCESS;
BEGIN
  IF SYS_CONTEXT('USERENV', 'CON_NAME') = 'CDB$ROOT' THEN
    raise_application_error(-20000, 'Must execute from a PDB');
  END IF;
END;
/
WHENEVER SQLERROR CONTINUE;

SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;

COL owner FOR A30;
SELECT owner
  FROM dba_tables
 WHERE table_name = 'KIEVTRANSACTIONS'
 ORDER BY 1
/
PRO
PRO 1. Enter Owner
DEF owner = '&1.';

BREAK ON REPORT;
COMPUTE SUM LABEL 'TOTAL' OF transactions in_flight committed aborted failed KievLive_Y KievLive_N ON REPORT;

SPO kiev_transactions_age_&&owner..txt;
PRO
PRO kiev_transactions_age_&&owner..txt;
PRO
PRO SQL> @kiev_transactions_age.sql "&&owner." 
PRO
PRO OWNER: &&owner.
PRO

PRO
PRO KievTransactions (KT) by DAY
PRO ~~~~~~~~~~~~~
SELECT TO_CHAR(TRUNC(k.BEGINTIME), 'YYYY-MM-DD') DAY,
       COUNT(*) transactions,
       SUM(CASE k.status WHEN 'IN_FLIGHT' THEN 1 ELSE 0 END) in_flight,
       SUM(CASE k.status WHEN 'COMMITTED' THEN 1 ELSE 0 END) committed,
       SUM(CASE k.status WHEN 'ABORTED' THEN 1 ELSE 0 END) aborted,
       SUM(CASE k.status WHEN 'FAILED' THEN 1 ELSE 0 END) failed
  FROM &&owner..kievtransactions k
 GROUP BY
       TRUNC(k.BEGINTIME)
ORDER BY 1
/

PRO
PRO KievTransactions (KT) by MONTH
PRO ~~~~~~~~~~~~~
SELECT TO_CHAR(TRUNC(k.BEGINTIME, 'MM'), 'YYYY-MM') MONTH,
       COUNT(*) transactions,
       SUM(CASE k.status WHEN 'IN_FLIGHT' THEN 1 ELSE 0 END) in_flight,
       SUM(CASE k.status WHEN 'COMMITTED' THEN 1 ELSE 0 END) committed,
       SUM(CASE k.status WHEN 'ABORTED' THEN 1 ELSE 0 END) aborted,
       SUM(CASE k.status WHEN 'FAILED' THEN 1 ELSE 0 END) failed
  FROM &&owner..kievtransactions k
 GROUP BY
       TRUNC(k.BEGINTIME, 'MM')
ORDER BY 1
/

PRO
PRO KievTransactionKeys (KTK) by DAY
PRO ~~~~~~~~~~~~~
SELECT TO_CHAR(TRUNC(t.BEGINTIME), 'YYYY-MM-DD') DAY,
       COUNT(*) transactions,
       SUM(CASE t.status WHEN 'IN_FLIGHT' THEN 1 ELSE 0 END) in_flight,
       SUM(CASE t.status WHEN 'COMMITTED' THEN 1 ELSE 0 END) committed,
       SUM(CASE t.status WHEN 'ABORTED' THEN 1 ELSE 0 END) aborted,
       SUM(CASE t.status WHEN 'FAILED' THEN 1 ELSE 0 END) failed
  FROM &&owner..kievtransactions t,
       &&owner..kievtransactionkeys k
 WHERE k.TRANSACTIONID = t.TRANSACTIONID
   AND k.COMMITTRANSACTIONID = t.COMMITTRANSACTIONID
 GROUP BY
       TRUNC(t.BEGINTIME)
ORDER BY 1
/

PRO
PRO KievTransactionKeys (KTK) by MONTH
PRO ~~~~~~~~~~~~~
SELECT TO_CHAR(TRUNC(t.BEGINTIME, 'MM'), 'YYYY-MM') MONTH,
       COUNT(*) transactions,
       SUM(CASE t.status WHEN 'IN_FLIGHT' THEN 1 ELSE 0 END) in_flight,
       SUM(CASE t.status WHEN 'COMMITTED' THEN 1 ELSE 0 END) committed,
       SUM(CASE t.status WHEN 'ABORTED' THEN 1 ELSE 0 END) aborted,
       SUM(CASE t.status WHEN 'FAILED' THEN 1 ELSE 0 END) failed
  FROM &&owner..kievtransactions t,
       &&owner..kievtransactionkeys k
 WHERE k.TRANSACTIONID = t.TRANSACTIONID
   AND k.COMMITTRANSACTIONID = t.COMMITTRANSACTIONID
 GROUP BY
       TRUNC(t.BEGINTIME, 'MM')
ORDER BY 1
/

PRO
PRO kiev_transactions_age_&&owner..txt;
PRO
SPO OFF;

UNDEF 1 2
CLEAR COLUMNS BREAK COMPUTE
