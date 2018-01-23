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


# error codes
E_ERROR=10
E_WRONG_ARGS=11
E_CONNECTION_ERROR=12
E_CANT_GET_USERS=13
E_USERS_NOT_FOUND=14
E_DESTINATION_DIR=15
E_CANT_GET_TYPES=16


# check arguments
ARGS_COUNT=1
if [ $# -ne "$ARGS_COUNT" ]; then
    echo -e "Usage: $SCRIPT_NAME oracle_connect_string"
    echo -e "\nExample: $SCRIPT_NAME user/password@tns_db_name"
    exit $E_WRONG_ARGS
fi

ORACLE_CONNECT_STRING=$1

# global variables
ORACLE_SQL_EXECUTE_RESULT=""


# functions
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

function execSQL(){
    local SQL=$1
    if [ -z "${SQL}" ]
    then
        return E_ERROR
    fi

    ORACLE_SQL_EXECUTE_RESULT=$(sqlplus -silent /nolog <<SQL
        @$SCRIPT_DIR/src/login.sql ${ORACLE_CONNECT_STRING}
        $SQL
        EXIT
        /
SQL
)
    return $?
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
        mkdir "$dest"
    fi
}

# load oracle environment variables
source "$SCRIPT_DIR/oracle_env.sh"

# test DB connection
execSQL "SELECT * FROM DUAL;"
checkExitCode $? $E_CONNECTION_ERROR "$ORACLE_SQL_EXECUTE_RESULT"

# =====================================================
# Create destination project structure for export
# =====================================================

# get oracle instance from connection string
ORACLE_INSTANCE=${ORACLE_CONNECT_STRING##*@}
ORACLE_INSTANCE_DIR=$SOURCES/$ORACLE_INSTANCE
checkAndCreateDestination "$ORACLE_INSTANCE_DIR"

# get users with types of their objects
execSQL "@$SCRIPT_DIR/src/get_users_with_types.sql;"
checkExitCode $? $E_CANT_GET_USERS "$ORACLE_SQL_EXECUTE_RESULT"

USER_TYPES_LIST=$ORACLE_SQL_EXECUTE_RESULT

if [ -z "${USER_TYPES_LIST}" ]
then
    echo "Users not found!"
    exit $E_USERS_NOT_FOUND
fi

echo "${USER_TYPES_LIST}" | while read line
do
    echo $line
    user=${line%%|*}
    type=${line##*|}

    USER_DIR=$ORACLE_INSTANCE_DIR/$user
    TYPE_DIR=$USER_DIR/$type

    checkAndCreateDestination "$USER_DIR"
    echo ${TYPE_DIR}
    checkAndCreateDestination "$TYPE_DIR"
done
