-- pdb_attributes_setup.sql - Create pdb_attributes Table and merge_pdb_attributes Procedure for IOD PDBs Fleet Inventory
DEF 1 = 'C##IOD';
DECLARE
  l_exists NUMBER;
  l_sql_statement VARCHAR2(32767) := q'[
CREATE TABLE &&1..pdb_attributes (
  -- /* key: version, db_domain, db_name, pdb_name */
  version                         DATE          NOT NULL
, db_domain                       VARCHAR2(64)  NOT NULL
, db_name                         VARCHAR2(9)   NOT NULL
, pdb_name                        VARCHAR2(30)  NOT NULL
  -- oci domains
, host_name                       VARCHAR2(64)  NOT NULL
, realm_type                      VARCHAR2(1)   NOT NULL
, realm_type_order_by             NUMBER        NOT NULL
, realm                           VARCHAR2(4)   NOT NULL
, realm_order_by                  NUMBER        NOT NULL
, region                          VARCHAR2(64)  NOT NULL
, region_acronym                  VARCHAR2(4)   NOT NULL
, region_order_by                 NUMBER        NOT NULL
, locale                          VARCHAR2(4)   NOT NULL
, locale_order_by                 NUMBER        NOT NULL
, kiev_or_wf                      VARCHAR2(1)       NULL
  -- data attributes
, ez_connect_string               VARCHAR2(256) NOT NULL
, total_size_bytes                NUMBER        NOT NULL
, sessions                        NUMBER        NOT NULL
, avg_running_sessions            NUMBER            NULL
, created                         DATE              NULL
, open_time                       DATE              NULL
, timestamp                       DATE          NOT NULL
)
PARTITION BY RANGE (version)
INTERVAL (NUMTOYMINTERVAL(1, 'MONTH'))
(
PARTITION before_2016_01_01 VALUES LESS THAN (TO_DATE('2016-01-01', 'YYYY-MM-DD'))
)
ROW STORE COMPRESS ADVANCED
TABLESPACE IOD
]';
  l_sql_statement2 VARCHAR2(32767) := q'[
CREATE UNIQUE INDEX &&1..pdb_attributes_pk 
ON &&1..pdb_attributes 
(version, db_domain, db_name, pdb_name) 
LOCAL
COMPRESS ADVANCED LOW
TABLESPACE IOD
]';
  l_sql_statement3 VARCHAR2(32767) := q'[
ALTER TABLE &&1..pdb_attributes ADD PRIMARY KEY 
(version, db_domain, db_name, pdb_name) 
USING INDEX &&1..pdb_attributes_pk
]';
BEGIN
  SELECT COUNT(*) INTO l_exists FROM dba_tables WHERE owner = UPPER(TRIM('&&1.')) AND table_name = UPPER('pdb_attributes');
  IF l_exists = 0 THEN
    EXECUTE IMMEDIATE l_sql_statement;
  END IF;
  SELECT COUNT(*) INTO l_exists FROM dba_indexes WHERE owner = UPPER(TRIM('&&1.')) AND index_name = UPPER('pdb_attributes_pk');
  IF l_exists = 0 THEN
    EXECUTE IMMEDIATE l_sql_statement2;
    EXECUTE IMMEDIATE l_sql_statement3;
  END IF;
END;
/    

CREATE OR REPLACE 
PROCEDURE c##iod.merge_pdb_attributes (
  p_version              IN VARCHAR2
, p_timestamp            IN VARCHAR2
, p_db_domain            IN VARCHAR2
, p_db_name              IN VARCHAR2
, p_pdb_name             IN VARCHAR2
, p_host_name            IN VARCHAR2
, p_realm_type           IN VARCHAR2
, p_realm_type_order_by  IN VARCHAR2
, p_realm                IN VARCHAR2
, p_realm_order_by       IN VARCHAR2
, p_region               IN VARCHAR2
, p_region_acronym       IN VARCHAR2
, p_region_order_by      IN VARCHAR2
, p_locale               IN VARCHAR2
, p_locale_order_by      IN VARCHAR2
, p_kiev_or_wf           IN VARCHAR2
, p_ez_connect_string    IN VARCHAR2
, p_total_size_bytes     IN VARCHAR2
, p_sessions             IN VARCHAR2
, p_avg_running_sessions IN VARCHAR2
, p_created              IN VARCHAR2
, p_open_time            IN VARCHAR2
)
IS
  r c##iod.pdb_attributes%ROWTYPE;
BEGIN
  EXECUTE IMMEDIATE q'[ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS']';
  --
  r.version := p_version;
  r.db_domain := p_db_domain;
  r.db_name := p_db_name;
  r.pdb_name := p_pdb_name;
  r.host_name := p_host_name;
  r.realm_type := p_realm_type;
  r.realm_type_order_by := p_realm_type_order_by;
  r.realm := p_realm;
  r.realm_order_by := p_realm_order_by;
  r.region := p_region;
  r.region_acronym := p_region_acronym;
  r.region_order_by := p_region_order_by;
  r.locale := p_locale;
  r.locale_order_by := p_locale_order_by;
  r.kiev_or_wf := p_kiev_or_wf;
  r.ez_connect_string := p_ez_connect_string;
  r.total_size_bytes := p_total_size_bytes;
  r.sessions := p_sessions;
  r.avg_running_sessions := p_avg_running_sessions;
  r.created := p_created;
  r.open_time := p_open_time;
  r.timestamp := p_timestamp;
  --
  DELETE c##iod.pdb_attributes WHERE version = r.version AND host_name = r.host_name AND db_domain = r.db_domain AND db_name = r.db_name AND pdb_name = r.pdb_name;
  INSERT INTO c##iod.pdb_attributes VALUES r;
  COMMIT;
END merge_pdb_attributes;
/
SHOW ERRORS;
