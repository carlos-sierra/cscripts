/*
COL trace_directory NEW_V trace_directory;
SELECT value trace_directory FROM v$diag_info WHERE name = 'Diag Trace';
CREATE OR REPLACE DIRECTORY TRACE_DIR AS '&&trace_directory.';
GRANT READ ON DIRECTORY TRACE_DIR TO PUBLIC
/
*/

COL trace_directory NEW_V trace_directory;
SELECT value trace_directory 
FROM v$diag_info WHERE name = 'Diag Trace';

COL full_trace_name NEW_V full_trace_name;
COL trace_name NEW_V trace_name;
SELECT value full_trace_name,
REPLACE(REPLACE(value, '&&trace_directory.'), '/') trace_name 
FROM v$diag_info WHERE name = 'Default Trace File';

COL trace_directory_name NEW_V trace_directory_name;
SELECT directory_name trace_directory_name 
FROM all_directories WHERE directory_path = '&&trace_directory.';

VAR my_trace CLOB;
DECLARE
  l_file_in BFILE;
  l_blob BLOB;
  l_clob         CLOB;
  l_dest_offset  INTEGER := 1;
  l_src_offset   INTEGER := 1;
  l_lang_context INTEGER := DBMS_LOB.DEFAULT_LANG_CTX;
  l_warning      INTEGER;
BEGIN
  l_file_in := BFILENAME('&&trace_directory_name.', '&&trace_name.');
  DBMS_LOB.FILEOPEN(l_file_in); 
  DBMS_LOB.CREATETEMPORARY(l_blob, TRUE);
  DBMS_LOB.LOADFROMFILE (
    dest_lob => l_blob, 
    src_lob  => l_file_in,
    amount   => DBMS_LOB.GETLENGTH(l_file_in)
  );
  DBMS_LOB.FILECLOSE(l_file_in);
  DBMS_LOB.CREATETEMPORARY (
    lob_loc => l_clob,
    cache   => TRUE,
    dur     => DBMS_LOB.SESSION
  );
  DBMS_LOB.CONVERTTOCLOB (
    dest_lob     => l_clob,
    src_blob     => l_blob,
    amount       => DBMS_LOB.LOBMAXSIZE,
    dest_offset  => l_dest_offset,
    src_offset   => l_src_offset, 
    blob_csid    => DBMS_LOB.DEFAULT_CSID,
    lang_context => l_lang_context,
    warning      => l_warning
  );
  :my_trace := l_clob;
  DBMS_LOB.FREETEMPORARY(lob_loc => l_clob);
END;
/

SET PAGES 0 LINES 2000 HEA OFF LONGC 2000 LONG 2000000
SPO &&trace_name..txt
PRINT my_trace
SPO OFF