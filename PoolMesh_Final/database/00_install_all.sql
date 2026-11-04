-- PoolMesh DB - Install everything (run from this folder in SQL*Plus / SQLcl)
-- Manoj Kumar S (24BDE0052), Manoj K (24BDE0147), S M Nithin (24BDE0033)
-- VIT Vellore | BCSE302P Database Systems | Oracle 12c+
SET SERVEROUTPUT ON
SET DEFINE OFF

-- Usage:  sqlplus user/password@//localhost:1521/XEPDB1 @00_install_all.sql
@01_schema.sql
@02_data.sql
@03_functions.sql
@04_triggers.sql
@05_procedures.sql
PROMPT PoolMesh DB installed: 8 tables, 126 rows, 3 functions, 3 triggers, 3 procedures.
