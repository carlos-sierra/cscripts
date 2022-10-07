-- kiev_metadata_setup.sql - Create kiev_metadata Table and merge_kiev_metadata Procedure for IOD PDBs Fleet Inventory
DEF 1 = 'C##IOD';
DECLARE
  l_exists NUMBER;
  l_sql_statement VARCHAR2(32767) := q'[
CREATE TABLE &&1..kiev_metadata (
  -- /* key: version, db_domain, db_name, jdbcurl */
  version                         DATE          NOT NULL
, db_domain                       VARCHAR2(64)  NOT NULL
, db_name                         VARCHAR2(9)   NOT NULL
, jdbcurl                         VARCHAR2(256) NOT NULL
  -- oci domains
, host_name                       VARCHAR2(64)  NOT NULL
  -- data attributes
, schemaname                      VARCHAR2(64)
, storename                       VARCHAR2(128) 
, state                           VARCHAR2(64) 
, dns                             VARCHAR2(256)  
, compartmentid                   VARCHAR2(128)  
, tenancyid                       VARCHAR2(128)  
, phonebookentry                  VARCHAR2(256)  
, created                         DATE
, lastmodified                    DATE
)
PARTITION BY RANGE (version)
INTERVAL (NUMTOYMINTERVAL(1, 'MONTH'))
(
PARTITION before_2021_11_01 VALUES LESS THAN (TO_DATE('2021-11-01', 'YYYY-MM-DD'))
)
ROW STORE COMPRESS ADVANCED
TABLESPACE IOD
]';
  l_sql_statement2 VARCHAR2(32767) := q'[
CREATE UNIQUE INDEX &&1..kiev_metadata_pk 
ON &&1..kiev_metadata 
(version, db_domain, db_name, jdbcurl) 
LOCAL
COMPRESS ADVANCED LOW
TABLESPACE IOD
]';
  l_sql_statement3 VARCHAR2(32767) := q'[
ALTER TABLE &&1..kiev_metadata ADD PRIMARY KEY 
(version, db_domain, db_name, jdbcurl) 
USING INDEX &&1..kiev_metadata_pk
]';
BEGIN
  SELECT COUNT(*) INTO l_exists FROM dba_tables WHERE owner = UPPER(TRIM('&&1.')) AND table_name = UPPER('kiev_metadata');
  IF l_exists = 0 THEN
    EXECUTE IMMEDIATE l_sql_statement;
  END IF;
  SELECT COUNT(*) INTO l_exists FROM dba_indexes WHERE owner = UPPER(TRIM('&&1.')) AND index_name = UPPER('kiev_metadata_pk');
  IF l_exists = 0 THEN
    EXECUTE IMMEDIATE l_sql_statement2;
    EXECUTE IMMEDIATE l_sql_statement3;
  END IF;
END;
/    

CREATE OR REPLACE 
PROCEDURE c##iod.merge_kiev_metadata (
  p_version              IN VARCHAR2
, p_db_domain            IN VARCHAR2
, p_db_name              IN VARCHAR2
, p_host_name            IN VARCHAR2
, p_jdbcurl              IN VARCHAR2
, p_schemaname           IN VARCHAR2
, p_storename            IN VARCHAR2
, p_state                IN VARCHAR2
, p_dns                  IN VARCHAR2
, p_compartmentid        IN VARCHAR2
, p_tenancyid            IN VARCHAR2
, p_created              IN VARCHAR2
, p_lastmodified         IN VARCHAR2
, p_phonebookentry       IN VARCHAR2
)
IS
  r c##iod.kiev_metadata%ROWTYPE;
BEGIN
  EXECUTE IMMEDIATE q'[ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS']';
  --
  r.version        := p_version       ;
  r.db_domain      := p_db_domain     ;
  r.db_name        := p_db_name       ;
  r.jdbcurl        := p_jdbcurl       ;
  r.host_name      := p_host_name     ;
  r.schemaname     := p_schemaname    ;
  r.storename      := p_storename     ;
  r.state          := p_state         ;
  r.dns            := p_dns           ;
  r.compartmentid  := p_compartmentid ;
  r.tenancyid      := p_tenancyid     ;
  r.phonebookentry := p_phonebookentry;
  r.created        := p_created       ;
  r.lastmodified   := p_lastmodified  ;
  --
  DELETE c##iod.kiev_metadata WHERE version = r.version AND host_name = r.host_name AND db_domain = r.db_domain AND db_name = r.db_name AND jdbcurl = r.jdbcurl;
  INSERT INTO c##iod.kiev_metadata VALUES r;
  COMMIT;
END merge_kiev_metadata;
/
SHOW ERRORS;
