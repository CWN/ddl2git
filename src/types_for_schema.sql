-- single user version
SET echo OFF heading OFF feedback OFF
SET VERIFY OFF
SET linesize 150
SET pages 0

SELECT username || '|' || translate(object_type,' ','_') user_types
  FROM (  SELECT DISTINCT usr.username, dbo.object_type
            FROM sys.dba_users usr, sys.dba_objects dbo
           WHERE     usr.default_tablespace NOT IN ('SYSTEM', 'SYSAUX')
                 AND usr.username = UPPER('&&1')
                 AND usr.username = dbo.owner
                 AND dbo.object_type NOT IN ('INDEX PARTITION',
                                             'TABLE PARTITION',
                                             'DATABASE LINK',
                                             'TABLE SUBPARTITION',
                                             'INDEX SUBPARTITION',
                                             'LOB PARTITION',
                                             'LOB',
                                             'PACKAGE BODY',
                                             'JOB',
                                             'JAVA DATA')
        ORDER BY usr.username, dbo.object_type);

EXIT
/