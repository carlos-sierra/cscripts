----------------------------------------------------------------------------------------
--
-- File name:   cs_extents_map.sql
--
-- Purpose:     Tablespace Block Map
--
-- Author:      Carlos Sierra
--
-- Version:     2020/12/06
--
-- Usage:       Execute connected to PDB.
--
-- Parameters:  1. Tablespace Name
--
--              2. Grouping 
--
--                 [{SEGMENT}|S|PARTITION|P]
--
--              3. Coalesce (on Map) Contiguos Extents of same Grouping 
--
--                 [{Y}|N]
--
--              4. Smallest BLOCK_ID on Top (of Map) or at the Bottom 
--
--                 [{BOTTOM}|B|TOP|T]
--
-- Example(s):  $ sqlplus / as sysdba
--              SQL> @cs_extents_map.sql "KIEV" "PARTITION" "Y" "BOTTOM"
--              SQL> @cs_extents_map.sql "KIEV" "P" "Y" "B"
--              SQL> @cs_extents_map.sql KIEV S N T
--
-- Notes:       Source: https://oraboard.wordpress.com/2016/04/22/tablespace-block-map/
--
--              Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_extents_map';
--
--ALTER SESSION SET container = CDB$ROOT;
--
SELECT tablespace_name 
  FROM dba_tablespaces
 WHERE contents = 'PERMANENT'
 ORDER BY 1
/
PRO
PRO 1. Tablespace Name:
DEF cs_tablespace_name = '&1.';
UNDEF 1;
PRO
PRO 2. Grouping: [{SEGMENT}|S|PARTITION|P]
DEF cs_grouping = '&2.';
UNDEF 2;
COL cs_grouping NEW_V cs_grouping NOPRI;
SELECT CASE WHEN UPPER(NVL('&&cs_grouping.', 'SEGMENT')) LIKE '%P%' THEN 'PARTITION' ELSE 'SEGMENT' END AS cs_grouping FROM DUAL
/
PRO
PRO 3. Coalesce (on Map) Contiguos Extents of same Grouping (&&cs_grouping.): [{Y}|N]
DEF cs_coalesce_contiguous_extents = '&3.';
UNDEF 3;
COL cs_coalesce_contiguous_extents NEW_V cs_coalesce_contiguous_extents NOPRI;
SELECT CASE SUBSTR(UPPER(TRIM(NVL('&&cs_coalesce_contiguous_extents.', 'Y'))), 1, 1) WHEN 'N' THEN 'N' ELSE 'Y' END AS cs_coalesce_contiguous_extents FROM DUAL
/
PRO
PRO 4. Smallest BLOCK_ID on Top (of Map) or at the Bottom: [{BOTTOM}|B|TOP|T]
DEF cs_top_or_bottom = '&4.';
UNDEF 4;
COL cs_top_or_bottom NEW_V cs_top_or_bottom NOPRI;
SELECT CASE SUBSTR(UPPER(TRIM(NVL('&&cs_top_or_bottom.', 'BOTTOM'))), 1, 1) WHEN 'T' THEN 'TOP' ELSE 'BOTTOM' END AS cs_top_or_bottom FROM DUAL
/
--
SELECT '&&cs_file_prefix._&&cs_script_name._&&cs_tablespace_name.' cs_file_name FROM DUAL;
--
DEF report_foot_note = 'SQL> @&&cs_script_name..sql "&&cs_tablespace_name." "&&cs_grouping." "&&cs_coalesce_contiguous_extents." "&&cs_top_or_bottom."';
--
SPO &&cs_file_name..html
SET HEA OFF PAGES 0 SERVEROUT ON;
DECLARE
  l_rowcount NUMBER := 0;
  l_group_count NUMBER := 0;
  l_cellcolor VARCHAR2(10);
  l_cellwidth NUMBER(3);
  l_file_id NUMBER := -1;
  l_datafile  VARCHAR2(1024);
  l_segment VARCHAR2(512);
  l_prior_segment VARCHAR2(512);
  l_blocks NUMBER := 0;
  l_extents NUMBER := 0;
  l_tot_extents NUMBER := 0;
  l_block_id_from NUMBER;
  l_block_id_to NUMBER;
  l_group VARCHAR2(512);
  l_prior_group VARCHAR2(512);
  l_busy_blocks NUMBER := 0;
  l_free_blocks NUMBER := 0;
  l_block_size NUMBER;
  l_map_row NUMBER := 0;
  l_prior_file_id NUMBER;
  --
  PROCEDURE print_line (p_line IN VARCHAR2)
  IS
  BEGIN
    DBMS_OUTPUT.put_line(p_line);
  END print_line;
  --
  PROCEDURE put_line (l_prior_file_id IN NUMBER, p_map_row IN NUMBER, p_group_count IN NUMBER, p_line IN VARCHAR2)
  IS
  BEGIN
    INSERT INTO plan_table (statement_id, plan_id, parent_id, id, remarks) VALUES ('&&cs_file_date_time.', l_prior_file_id, p_map_row, p_group_count, p_line);
    --print_line(p_line);
  END put_line;
BEGIN
  SELECT block_size INTO l_block_size FROM dba_tablespaces WHERE tablespace_name = '&&cs_tablespace_name.';
  -- initial html
  print_line('<HTML>');
  print_line('<!-- $Header: &&cs_file_name..html carlos.sierra $ -->');
  print_line('<style type="text/css">body {font:10pt Arial,Helvetica,Geneva,sans-serif; color:black; background:white;} pre {font:8pt monospace,Monaco,"Courier New",Courier;} font.n {font-size:8pt; font-style:italic; color:#336699;} font.f {font-size:8pt; color:#999999; border-top:1px solid #336699; margin-top:30pt;}</style>');
  print_line('<style>.datafile {clear:both; font: Arial; font-size:12pt;  font-weight:bold; color:#336699; margin-top:10pt; margin-bottom:10pt; padding:0px;} .blocks{ float:left; width:5px; height:5px; border:1px solid Silver; padding:5px; } </style>');
  print_line('<H1 style="clear:both; font:Arial; font-size:16pt; font-weight:bold; color:#336699; border-bottom:1px solid #336699; margin-top:0pt; margin-bottom:0pt; padding:0px 0px 0px 0px; ">&&cs_tablespace_name. Tablespace Block Map </H1>');
  print_line('<BODY>');
  print_line('<pre>');
  print_line('DATE_TIME    : &&cs_date_time.Z');
  print_line('REFERENCE    : &&cs_reference.');
  print_line('LOCALE       : &&cs_realm. &&cs_region. &&cs_locale.');
  print_line('DATABASE     : &&cs_db_name_u. (&&cs_db_version.) STARTUP:&&cs_startup_time.');
  print_line('CONTAINER    : &&cs_db_name..&&cs_con_name. (&&cs_con_id.) &&cs_pdb_open_mode.');
  print_line('CPU          : CORES:&&cs_num_cpu_cores. THREADS:&&cs_num_cpus. COUNT:&&cs_cpu_count. ALLOTTED:&&cs_allotted_cpu. PLAN:&&cs_resource_manager_plan.');
  print_line('HOST         : &&cs_host_name.');
  print_line('CONNECT_STRNG: &&cs_easy_connect_string.');
  print_line('SCRIPT       : &&cs_script_name..sql');
  print_line('KIEV_VERSION : &&cs_kiev_version. (&&cs_schema_name.)');
  print_line('</pre>');
  print_line('<div class="datafile">');
  -- open cursor
  FOR l_row IN (
SELECT file_id,
       block_id,
       block_id + blocks - 1 AS end_block,
       blocks,
       owner,
       segment_name,
       partition_name,
       segment_type
  FROM dba_extents
 WHERE tablespace_name = '&&cs_tablespace_name.'
 UNION ALL
SELECT file_id,
       block_id,
       block_id + blocks - 1 AS end_block,
       blocks,
       'free' AS owner,
       'free' AS segment_name,
       NULL AS partition_name,
       NULL AS segment_type
  FROM dba_free_space
 WHERE tablespace_name = '&&cs_tablespace_name.'
 ORDER BY 1, 2 
  )
  LOOP
    l_tot_extents := l_tot_extents + 1;
    IF l_row.segment_name = 'free' THEN l_free_blocks := l_free_blocks + l_row.blocks; ELSE l_busy_blocks := l_busy_blocks + l_row.blocks; END IF;
    IF '&&cs_grouping.' = 'PARTITION' THEN l_segment := TRIM('.' FROM l_row.segment_name||'.'||l_row.partition_name); ELSE l_segment := l_row.segment_name; END IF;
    IF '&&cs_coalesce_contiguous_extents.' = 'Y' THEN l_group := l_row.file_id||' '||l_segment; ELSE l_group := l_row.file_id||' '||l_segment||' '||l_row.block_id; END IF;
    --
    IF l_rowcount = 0 THEN
      l_prior_segment := l_segment;
      l_prior_group := l_group;
      l_prior_file_id := l_row.file_id;
      l_block_id_from := l_row.block_id;
    END IF;
    l_rowcount := l_rowcount + 1;
    --
    IF l_group = l_prior_group THEN
      l_block_id_to := l_row.end_block;
      l_blocks := l_blocks + l_row.blocks;
      l_extents := l_extents + 1;
    ELSE
      -- max of 50 cells per row
      IF mod(l_group_count,50) = 0 THEN
        l_map_row := l_map_row + 1;
        put_line(l_prior_file_id, l_map_row, l_group_count, '<div style="clear:both;"></div>');
        l_map_row := l_map_row + 1;
      END IF;
      l_group_count := l_group_count + 1;
      -- set cell color
      IF l_prior_segment = 'free' THEN l_cellcolor := 'Azure'; ELSE l_cellcolor := 'Gray'; END IF;
      -- display space cells
      put_line(l_prior_file_id, l_map_row, l_group_count, '<div name="'||l_prior_segment||'" title='||'"'||l_prior_segment||','||l_blocks||'('||l_block_id_from||'-'||l_block_id_to||'),'||l_extents||'" class="blocks" style="background-color:'|| l_cellcolor||';" onClick="SetSelectionColor('''||l_prior_segment ||''')";></div>');
      --
      l_prior_segment := l_segment;
      l_prior_group := l_group;
      l_prior_file_id := l_row.file_id;
      l_block_id_from := l_row.block_id;
      l_block_id_to := l_row.end_block;
      l_blocks := l_row.blocks;
      l_extents := 1;
    END IF;
  END LOOP;
  -- set cell color for last cell and display it
  IF l_prior_segment = 'free' THEN l_cellcolor := 'Azure'; ELSE l_cellcolor := 'Gray'; END IF;
  put_line(l_prior_file_id, l_map_row, l_group_count, '<div name="'||l_prior_segment||'" title='||'"'||l_prior_segment||','||l_blocks||'('||l_block_id_from||'-'||l_block_id_to||'),'||l_extents||'" class="blocks" style="background-color:'|| l_cellcolor||';" onClick="SetSelectionColor('''||l_prior_segment ||''')";></div>');
  l_map_row := l_map_row + 1;
  put_line(l_prior_file_id, l_map_row, l_group_count, '<div style="clear:both;"></div>');
  -- process put lines
  FOR i IN (SELECT plan_id AS file_id, parent_id AS map_row, id AS group_count, remarks AS line FROM plan_table WHERE statement_id = '&&cs_file_date_time.' ORDER BY plan_id, CASE '&&cs_top_or_bottom.' WHEN 'BOTTOM' THEN -1 ELSE 1 END * parent_id, id)
  LOOP
    -- check if a new datafile
    IF i.file_id <> l_file_id THEN
      l_file_id := i.file_id;
      SELECT name INTO l_datafile FROM v$datafile WHERE file#=l_file_id;
      print_line('<div style="clear:both; font:Arial; ">'||'File '||l_file_id||':' ||l_datafile||'</div>');
    END IF;
    --
    print_line(i.line);
  END LOOP;
  -- javascript to color selected  segments
  print_line('<script>');
  print_line('function SetSelectionColor(prm){');
  print_line('var elements = document.getElementsByName(prm);');
  print_line('for(var i=0; i<elements.length; i++) {');
  print_line('if (elements[i].title.search(/free/i) < 0) {');
  print_line('if (elements[i].style.backgroundColor == ''rgb(0, 0, 255)'') {');
  print_line('elements[i].style.background=''Gray'';}');
    print_line('else { ');
  print_line('elements[i].style.background=''#0000FF''; }}}}');
  print_line('</script>');
  -- closing html tags
  print_line('</div>');
  print_line('<font class="n"><br>Notes:</font>');
  print_line('<font class="n"><br>1. Total Extents on &&cs_tablespace_name. Tablespace:'||l_tot_extents||'. Total Blocks:'||(l_busy_blocks + l_free_blocks)||'('||ROUND((l_busy_blocks + l_free_blocks) * l_block_size / POWER(10,9), 1)||'GB). Busy Blocks:'||l_busy_blocks||'('||ROUND(l_busy_blocks * l_block_size / POWER(10,9), 1)||'GB). Free Blocks:'||l_free_blocks||'('||ROUND(l_free_blocks * l_block_size / POWER(10,9), 1)||'GB). Space utilization:'||ROUND(100 * l_busy_blocks / (l_busy_blocks + l_free_blocks), 1)||'%</font>');
  print_line('<font class="n"><br>2. The Azure squares are those free, the Gray ones are those busy, and the Blue ones are those selected by you (with a click on a Grey square).</font>');
  print_line('<font class="n"><br>3. If you click on a Gray square corresponding to a Group (&&cs_grouping.), it will Blue all other Extents in all datafiles belonging to that Group. Click again to reset.</font>');
  print_line('<font class="n"><br>4. A tooltip appears on hover with: Group (&&cs_grouping.), number of blocks, blocks range, and number of extents. E.g.: TABLE_NAME,blocks(block_id_from-block_id_to),extents.</font>');
  print_line('<font class="n"><br>5. The smallest BLOCK_ID is at the &&cs_top_or_bottom. of the Map (on the left-most square).</font>');
  IF '&&cs_coalesce_contiguous_extents.' = 'Y' THEN print_line('<font class="n"><br>6. Contiguous Extents belonging to the same Grouping (&&cs_grouping.) have been Coalesced on this Map.</font>'); END IF;
  print_line('<font class="f"><br><br>&&report_foot_note.</font>');
  print_line('</BODY>');
  print_line('</HTML>');
END;
/
SET HEA ON PAGES 100 SERVEROUT OFF;
PRO <pre>
L 59 80
PRO </pre>
--
@@cs_internal/cs_spool_tail_chart.sql
ROLLBACK;
PRO
PRO &&report_foot_note.
--
--ALTER SESSION SET CONTAINER = &&cs_con_name.;
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--
