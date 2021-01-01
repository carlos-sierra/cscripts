-- iod_setup.sql - Complile IOD PL/SQL Packages (new versions of code)
@../iod/pdb_config/setup.sql C##IOD
@../iod/iod_admin/setup.sql C##IOD
@../iod/iod_amw/setup.sql C##IOD
@../iod/iod_rsrc_mgr/setup.sql C##IOD
@../iod/iod_sess/setup.sql C##IOD
@../iod/iod_sess_mgr/setup.sql C##IOD
@../iod/iod_space/setup.sql C##IOD
@../iod/iod_spm/setup.sql C##IOD
@../iod/iod_sqlstats/setup.sql C##IOD
@../iod/iod_metadata/setup.sql C##IOD
@../iod/iod_meta_aux/setup.sql C##IOD

prompt ========================================
prompt Compile invalid objects
prompt ========================================
BEGIN
  FOR cur_rec IN (SELECT owner,
                         object_name,
                         object_type,
                         DECODE(object_type, 'PACKAGE', 1,
                                             'PACKAGE BODY', 2, 2) AS recompile_order
                  FROM   dba_objects
                  WHERE  object_type IN ('PACKAGE', 'PACKAGE BODY')
                  AND    owner = UPPER(TRIM('C##IOD'))
                  AND    status != 'VALID'
                  ORDER BY 4)
  LOOP
    BEGIN
      IF cur_rec.object_type = 'PACKAGE' THEN
        EXECUTE IMMEDIATE 'ALTER ' || cur_rec.object_type || 
            ' "' || cur_rec.owner || '"."' || cur_rec.object_name || '" COMPILE';
      ElSE
        EXECUTE IMMEDIATE 'ALTER PACKAGE "' || cur_rec.owner || 
            '"."' || cur_rec.object_name || '" COMPILE BODY';
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.put_line(cur_rec.object_type || ' : ' || cur_rec.owner || 
                             ' : ' || cur_rec.object_name);
    END;
  END LOOP;
END;
/

SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
COL name FOR A15 TRUNC;
COL type FOR A13 TRUNC;
COL text FOR A100 TRUNC;
SELECT name, type, text 
  FROM dba_source 
 WHERE owner = 'C##IOD' 
   AND line <= 3 
   AND type LIKE 'PACKAGE%' 
   AND text LIKE '%Header%'
 ORDER BY
       name, type
/

