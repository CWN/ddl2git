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

# set git author environment - used by git commit
export GIT_AUTHOR_NAME="ddl2git v1.2.3"
export GIT_AUTHOR_EMAIL="dd2git@localhost"

# error codes
E_ERROR=10
E_WRONG_ARGS=11
E_CONNECTION_ERROR=12
E_CANT_GET_USERS=13
E_USERS_NOT_FOUND=14
E_DESTINATION_DIR=15
E_CANT_GET_TYPES=16
E_CANT_GENERATE_EXPORT_SCRIPT=17
E_CANT_EXPORT_DDL=18


# check arguments
ARGS_COUNT=1
if [ $# -lt "$ARGS_COUNT" ]; then
    echo -e "Usage: $SCRIPT_NAME oracle_connect_string"
    echo -e "\nExample: $SCRIPT_NAME user/password@tns_db_name"
    echo -e "\nor for single schema: $SCRIPT_NAME user/password@tns_db_name schema_name"
    exit $E_WRONG_ARGS
fi

ORACLE_CONNECT_STRING=$1
ORACLE_USER=$2

# get oracle instance from connection string
ORACLE_INSTANCE=${ORACLE_CONNECT_STRING##*@}

# check that authentication part present
if [[ $ORACLE_CONNECT_STRING = *"@"* ]]; then
    ORACLE_SECURE=${ORACLE_CONNECT_STRING%%@*}
else
    ORACLE_SECURE=
fi

# if authentication empty - search login pair in files inside keys/ directory
if [ -z "${ORACLE_SECURE}" ]
then
    KEY_FILE="$SCRIPT_DIR/keys/$ORACLE_INSTANCE"
    if [ -e "$KEY_FILE" ]
    then
        ORACLE_SECURE=`cat "$KEY_FILE"`
        ORACLE_CONNECT_STRING="$ORACLE_SECURE@$ORACLE_INSTANCE"
    else
        ORACLE_CONNECT_STRING="/@$ORACLE_INSTANCE"
        echo "Authentication parameters not found"
    fi
fi

ORACLE_INSTANCE_DIR="$SOURCES/$ORACLE_INSTANCE"

# global variables
ORACLE_SQL_EXECUTE_RESULT=""


# functions
function checkExitCode(){
    local exitCode=$1
    local errorCode=${2:-$E_ERROR}
    local errorMsg=${3:-"Error occurred"}
    local emsg=`echo "${errorMsg}" | tail -n 15`

    if [ "$exitCode" -ne 0 ]
    then
        echo -e "Error:\n${emsg}"
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

# export start time
START_TSTMP=`LANG=c date "+%F %T"`

# =====================================================
# Create destination project structure for export
# =====================================================

echo "=== Export sources ==="
echo "Started at $START_TSTMP"

checkAndCreateDestination "$ORACLE_INSTANCE_DIR"

# get users with types of their objects
if [ -z ${ORACLE_USER} ]
then
    execSQL "@$SCRIPT_DIR/src/get_users_with_types.sql;"
else
    execSQL "@$SCRIPT_DIR/src/types_for_schema.sql $ORACLE_USER"
fi

checkExitCode $? $E_CANT_GET_USERS "$ORACLE_SQL_EXECUTE_RESULT"

USER_TYPES_LIST=$ORACLE_SQL_EXECUTE_RESULT

if [ -z "${USER_TYPES_LIST}" ]
then
    echo "Nothing to export from users schema!"
    exit $E_USERS_NOT_FOUND
fi

echo "${USER_TYPES_LIST}" | while read line
do
    user=${line%%|*}
    type=${line##*|}

    USER_DIR=$ORACLE_INSTANCE_DIR/$user
    TYPE_DIR=$USER_DIR/$type

    checkAndCreateDestination "$USER_DIR"
    checkAndCreateDestination "$TYPE_DIR"
done

# =====================================================
# Export DDL to project folders
# =====================================================

TEMP_EXPORT_SCRIPT="$SOURCES/temp_export_${ORACLE_INSTANCE}.sql"
EXPORT_SCRIPT="$SOURCES/export_${ORACLE_INSTANCE}.sql"

if [ -z ${ORACLE_USER} ]
then
    execSQL "@$SCRIPT_DIR/src/generate_export_script.sql $TEMP_EXPORT_SCRIPT"
else
    execSQL "@$SCRIPT_DIR/src/generate_export_script_for_schema.sql $TEMP_EXPORT_SCRIPT $ORACLE_USER"
fi
checkExitCode $? $E_CANT_GENERATE_EXPORT_SCRIPT "$ORACLE_SQL_EXECUTE_RESULT"

cat $SCRIPT_DIR/src/header.sql > $EXPORT_SCRIPT
cat $TEMP_EXPORT_SCRIPT >> $EXPORT_SCRIPT
echo "EXIT" >> $EXPORT_SCRIPT
echo "/" >> $EXPORT_SCRIPT

cd $ORACLE_INSTANCE_DIR
execSQL "@$EXPORT_SCRIPT;"
checkExitCode $? $E_CANT_EXPORT_DDL "$ORACLE_SQL_EXECUTE_RESULT"

# export stop time
END_TSTMP=`LANG=c date "+%F %T"`
echo "Finished at $END_TSTMP"

# =======================================================
# Commit to git
# =======================================================

echo "=== Commit changes in .git repo ==="

git_check=$(git rev-parse)
if [ $? -ne 0 ]
then
    git init 2>&1
    git config user.email "$GIT_AUTHOR_EMAIL" 2>&1
    git config user.name "$GIT_AUTHOR_NAME" 2>&1
    git add * 2>&1
    git commit -m "Initial commit on $START_TSTMP, export ended at $END_TSTMP" 2>&1
else
    git add * 2>&1
    git commit -m "Store changes on $START_TSTMP, export ended at $END_TSTMP" 2>&1

    echo "===  Commit details ==="
    git --no-pager log -1 --name-status 2>&1
fi

echo "=== Update remote repository ==="
# push to remote repo from remote list
GIT_REMOTE_LIST=$(git remote)
for git_remote in $GIT_REMOTE_LIST
do
    echo "On $git_remote :"
    git push ${git_remote} master 2>&1
done