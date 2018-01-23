SET echo OFF heading OFF feedback OFF
SET VERIFY OFF
SET linesize 150
SET pages 0

SELECT username || '|' || object_type user_types
  FROM (  SELECT DISTINCT usr.username, dbo.object_type
            FROM sys.dba_users usr, sys.dba_objects dbo
           WHERE     usr.default_tablespace NOT IN ('SYSTEM', 'SYSAUX')
                 AND usr.username NOT IN ('ANONYMOUS',
                                          'AUDSYS',
                                          'CTXSYS',
                                          'DBSNMP',
                                          'LBACSYS',
                                          'MDSYS',
                                          'OLAPSYS',
                                          'ORDDATA',
                                          'ORDPLUGINS',
                                          'ORDSYS',
                                          'SI_INFORMTN_SCHEMA',
                                          'SYS',
                                          'SYSBACKUP',
                                          'SYSDG',
                                          'SYSKM',
                                          'SYSTEM',
                                          'WMSYS',
                                          'XDB',
                                          'DIP',
                                          'MDDATA',
                                          'ORACLE_OCM',
                                          'SPATIAL_CSW_ADMIN_USR',
                                          'SPATIAL_WFS_ADMIN_USR',
                                          'XS$NULL',
                                          'HR',
                                          'OE',
                                          'PM',
                                          'IX',
                                          'SH')
                 AND usr.username = dbo.owner
                 AND dbo.object_type NOT IN ('INDEX PARTITION',
                                             'TABLE PARTITION',
                                             'DATABASE LINK',
                                             'TABLE SUBPARTITION',
                                             'INDEX SUBPARTITION',
                                             'LOB PARTITION',
                                             'LOB',
                                             'PACKAGE BODY')
        ORDER BY usr.username, dbo.object_type);

EXIT
/