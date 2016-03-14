REM $Header: 215187.1 1_mon_repository.sql 11.4.5.8 2013/05/10 carlos.sierra $

DROP TABLE v_sql_monitor;

CREATE TABLE v_sql_monitor (
  sql_id             VARCHAR2(13),
  key                NUMBER,
  sql_exec_start     DATE,
  sql_exec_id        NUMBER,
  status             VARCHAR2(19),
  first_refresh_time DATE,
  last_refresh_time  DATE,
  username           VARCHAR2(30),
  capture_date       DATE,
  report_date        DATE,
  sql_text           VARCHAR2(2000),
  mon_report         CLOB,
PRIMARY KEY (sql_id, key));
