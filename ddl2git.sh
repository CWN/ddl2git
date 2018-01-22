#!/bin/bash

#************************************************************************************************#
#                                                                                                #
#                                   ddl2git.sh                                                   #
#                      written by Denis Ryazanov aka CWN                                         #
#                                   2011-2018                                                    #
#                        https://github.com/CWN/ddl2git                                          #
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
E_USERS_NOT_FOUND=14
E_DESTINATION_DIR=15

# check arguments
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

function checkAndCreateDestination(){
    local dest=$1
    if [ -z "${dest}" ]
    then
        echo "Destination directory not provided"
        exit $E_DESTINATION_DIR
    fi

    if [ ! -e "$dest" ]
    then
        mkdir $dest
    fi
}

# test DB connection
CONNECTION_TEST=$(sqlplus -silent /nolog <<SQL
@$SCRIPT_DIR/src/login.sql ${ORACLE_CONNECT_STRING}
SELECT * FROM DUAL;
exit
SQL
)

checkExitCode $? $E_CONNECTION_ERROR "$CONNECTION_TEST"

# get oracle instance from connection string
ORACLE_INSTANCE=${ORACLE_CONNECT_STRING##*@}
ORACLE_INSTANCE_DIR=$SOURCES/$ORACLE_INSTANCE
checkAndCreateDestination "$ORACLE_INSTANCE_DIR"

# get users list for export schema scripts
USER_LIST=$(sqlplus -silent /nolog <<SQL
@$SCRIPT_DIR/src/login.sql ${ORACLE_CONNECT_STRING}
@$SCRIPT_DIR/src/get_users.sql
exit
SQL
)

checkExitCode $? $E_CANT_GET_USERS "$USER_LIST"

echo $USER_LIST

if [ -z "${USER_LIST}" ]
then
    echo "Users not found!"
    exit $E_USERS_NOT_FOUND
fi
