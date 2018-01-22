SET echo off HEADING OFF FEEDBACK OFF
SET linesize 150
SET pages 0

-- exclude predefined accounts
-- https://docs.oracle.com/database/121/TDPSG/GUID-3EC7A894-D620-4497-AFB1-64EB8C33D854.htm#TDPSG20030

SELECT username
FROM sys.dba_users
WHERE default_tablespace NOT IN ('SYSTEM', 'SYSAUX')
      AND username NOT IN (
              'ANONYMOUS',
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
              'SH'
      )
ORDER BY 1;

EXIT
/