SET echo OFF heading OFF feedback OFF
SET VERIFY OFF
SET linesize 150
SET pages 0

SELECT DISTINCT object_type
FROM sys.dba_objects dbo
WHERE owner = '&&1'
      AND object_type NOT IN
          ('INDEX PARTITION'
            , 'TABLE PARTITION'
            , 'DATABASE LINK'
            , 'TABLE SUBPARTITION'
            , 'INDEX SUBPARTITION'
            , 'LOB PARTITION'
            , 'LOB'
            , 'PACKAGE BODY'
            , 'MATERIALIZED VIEW'
            , 'JOB')
ORDER BY object_type;

EXIT
/