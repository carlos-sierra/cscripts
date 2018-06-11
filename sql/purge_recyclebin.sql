SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
SET SERVEROUT ON SIZE UNLIMITED;

-- same as iod_space.purge_recyclebin
  DECLARE 
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    /* non identity tables (and their indexes) */
    FOR i IN (SELECT DISTINCT rb.type, rb.owner, rb.original_name, rb.object_name
                FROM dba_recyclebin rb,
                     sys.obj$ o1
               WHERE TO_DATE(rb.droptime, 'YYYY-MM-DD:HH24:MI:SS') < SYSDATE - 8
                 AND rb.type = 'TABLE'
                 AND o1.name = rb.object_name
                 /* exclude identity */
                 AND NOT EXISTS (SELECT NULL FROM sys.idnseq$ id WHERE id.obj# = o1.obj#))
     LOOP
      DBMS_OUTPUT.PUT_LINE(i.type||' '||i.owner||'.'||i.original_name||' '||i.object_name);
      EXECUTE IMMEDIATE 'PURGE '||i.type||' '||i.owner||'.'||i.original_name;
    END LOOP;
    /* non identity (stand-alone indexes) */
    FOR i IN (SELECT DISTINCT rb.type, rb.owner, rb.original_name, rb.object_name
                FROM dba_recyclebin rb,
                     sys.obj$ o1
               WHERE TO_DATE(rb.droptime, 'YYYY-MM-DD:HH24:MI:SS') < SYSDATE - 8
                 AND rb.type = 'INDEX'
                 AND o1.name = rb.object_name
                 /* exclude identity */
                 AND NOT EXISTS (SELECT NULL FROM sys.idnseq$ id WHERE id.obj# = o1.obj#))
     LOOP
      DBMS_OUTPUT.PUT_LINE(i.type||' '||i.owner||'.'||i.original_name||' '||i.object_name);
      DECLARE
        l_unique_or_primary EXCEPTION;
        PRAGMA EXCEPTION_INIT(l_unique_or_primary, -02429); /* ORA-02429: cannot drop index used for enforcement of unique/primary key */
      BEGIN
        EXECUTE IMMEDIATE 'PURGE '||i.type||' '||i.owner||'.'||i.original_name;
      EXCEPTION
        WHEN l_unique_or_primary THEN
          DBMS_OUTPUT.PUT_LINE(SQLERRM);
      END;
    END LOOP;
    /* identity tables (and their indexes) */
    FOR i IN (SELECT DISTINCT rb.type, rb.owner, rb.original_name, rb.object_name
                FROM dba_recyclebin rb,
                     sys.obj$ o1, 
                     sys.idnseq$ id,
                     sys.obj$ o2
               WHERE TO_DATE(rb.droptime, 'YYYY-MM-DD:HH24:MI:SS') < SYSDATE - 8
                 AND rb.type = 'TABLE'
                 AND o1.name = rb.object_name
                 AND id.obj# = o1.obj#
                 AND o2.obj# = id.seqobj#) /* ORA-00600: internal error code, arguments: [12811], [91945] -- bug 19949998 */
    LOOP
      DBMS_OUTPUT.PUT_LINE(i.type||' '||i.owner||'.'||i.original_name||' '||i.object_name);
      EXECUTE IMMEDIATE 'PURGE '||i.type||' '||i.owner||'.'||i.original_name;
    END LOOP;
    /* identity tables (and their indexes) ORA-00600 */
    FOR i IN (SELECT DISTINCT rb.type, rb.owner, rb.original_name, rb.object_name
                FROM dba_recyclebin rb,
                     sys.obj$ o1, 
                     sys.idnseq$ id,
                     sys.obj$ o2
               WHERE TO_DATE(rb.droptime, 'YYYY-MM-DD:HH24:MI:SS') < SYSDATE - 8
                 AND rb.type = 'TABLE'
                 AND o1.name = rb.object_name
                 AND id.obj# = o1.obj#
                 AND o2.obj#(+) = id.seqobj#) /* ORA-00600: internal error code, arguments: [12811], [91945] -- bug 19949998 */
    LOOP
      DBMS_OUTPUT.PUT_LINE(i.type||' '||i.owner||'.'||i.original_name||' '||i.object_name);
      DBMS_OUTPUT.PUT_LINE('ORA-00600: internal error code, arguments: [12811], [91945] -- bug 19949998');
      /*EXECUTE IMMEDIATE 'PURGE '||i.type||' '||i.owner||'.'||i.original_name;*/
    END LOOP;
    COMMIT;
  END;
/
