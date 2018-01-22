#!/bin/bash

#************************************************************************************************#
#                                   ddl2git.sh                                                   #
#                     written by Denis Ryazanov aka CWN                                          #
#                                     2011-2018                                                  #
#                                                                                                #
#************************************************************************************************#

SCRIPT_NAME=`basename $0`
SCRIPT_DIR=$(dirname "$(realpath -s "$0")")
SOURCES=$SCRIPT_DIR/sources

ARGS_COUNT=1
# error codes
E_ERROR=10
E_WRONG_ARGS=11
E_CONNECTION_ERROR=12
E_CANT_GET_USERS=13

if [ $# -ne "$ARGS_COUNT" ]; then
    echo -e "Usage: $SCRIPT_NAME oracle_connect_string"
    echo -e "\nExample: $SCRIPT_NAME user/password@tns_db_name"
    exit $E_WRONG_ARGS
fi
ORACLE_CONNECT_STRING=$1

source "$SCRIPT_DIR/oracle_env.sh"

function checkExitCode(){
    local exitCode=$1
    local errorCode=${2:-$E_ERROR}
    local errorMsg=${3:-"Error occurred"}

    if [ "$exitCode" -ne 0 ]
    then
      echo -e "SqlPlus error:\n${errorMsg}"
      exit $errorCode
    fi
}


# test DB connection
CONNECTION_TEST=$(sqlplus -silent /nolog <<SQL
@$SCRIPT_DIR/src/login.sql ${ORACLE_CONNECT_STRING}
SELECT * FROM DUAL;
exit
SQL
)

# exitCode=$?
# echo ${exitcode}

checkExitCode $? $E_CONNECTION_ERROR "$CONNECTION_TEST"

USER_LIST=$(sqlplus -silent /nolog <<SQL
@$SCRIPT_DIR/src/login.sql ${ORACLE_CONNECT_STRING}
@$SCRIPT_DIR/src/get_users.sql
exit
SQL
)

checkExitCode $? $E_CANT_GET_USERS "$USER_LIST"

echo $USER_LIST
