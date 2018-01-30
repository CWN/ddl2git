# ddl2git

**ddl2git** is a bash script for export oracle DDL to local filesystem and create commit in 

## Dependencies
- Oracle Client 10.x or higher
- sqlplus (if using Oracle Instant Client)
- git

## Installation

1. Check out a clone of this repo to a location of your choice, such as
    ```bash
    $ git clone --depth=1 https://github.com/CWN/ddl2git.git ~/ddl2git
    ```

2. Copy **oracle_env.sh.dist** to **oracle_env.sh** and modify it for you local oracle environment
    ```bash
    $ cp oracle_env.sh.dist oracle_env.sh
    $ vi oracle_env.sh
    ``` 
3. Create or use existing oracle user with granted role **SELECT_CATALOG_ROLE**
4. Set global (system wide) git user and email if it not yet configured
```bash
git config --global user.email "superuser@test.host"
git config --global user.name "superuser"
```

## Usage
Export entire DB, except oracle [predefined users](https://docs.oracle.com/database/121/TDPSG/GUID-3EC7A894-D620-4497-AFB1-64EB8C33D854.htm#TDPSG20030)

```bash
$ ./ddl2git.sh user/password@exampledb
```

Export only one user (include someone from predefined user)
```bash
$ ./ddl2git.sh user/password@exampledb example_schema_name
```

**NOTE:** For hide login/password pair - store it in file with db name (*exampledb*) in keys/ folder and run script:
```bash
$  ls <SCRIPT_DIR>/keys/
exampledb

$ ./ddl2git.sh exampledb
```


Script create or use existing folder **exampledb/** inside **sources/** in script dir and dump DDLs to it.
Destination export structure would be like this: 
```
<ORACLE_DB_NAME>/<ORACLE_USER>/<OBJECT_TYPE>/<OBJECT_NAME>
```

For example:

```bash
$ tree ./exampledb/
./exampledb/
└── OJVMSYS
    ├── INDEX
    │   ├── OJDS_DOLLARSIGN_NODE_INDEX.sql
    │   ├── OJDS_DOLLARSIGN_PERM_INDEX.sql
    │   ├── OJDS_DOLLARSIGN_REFADDR_INDEX.sql
    │   ├── OJDS_DOLLARSIGN_SHARED_DOLLARSIGN_OBJ_INDEX.sql
    │   ├── SYS_C005161.sql
    │   ├── SYS_C005162.sql
    │   └── SYS_IL0000073471C00003_DOLLARSIGN__DOLLARSIGN_.sql
    ├── SEQUENCE
    │   ├── OJDS_DOLLARSIGN_NODE_NUMBER_DOLLARSIGN_.sql
    │   └── OJDS_DOLLARSIGN_SHARED_DOLLARSIGN_OBJ_DOLLARSIGN_SEQ_DOLLARSIGN_.sql
    └── TABLE
        ├── OJDS_DOLLARSIGN_ATTRIBUTES_DOLLARSIGN_.sql
        ├── OJDS_DOLLARSIGN_BINDINGS_DOLLARSIGN_.sql
        ├── OJDS_DOLLARSIGN_INODE_DOLLARSIGN_.sql
        ├── OJDS_DOLLARSIGN_PERMISSIONS_DOLLARSIGN_.sql
        ├── OJDS_DOLLARSIGN_REFADDR_DOLLARSIGN_.sql
        └── OJDS_DOLLARSIGN_SHARED_DOLLARSIGN_OBJ_DOLLARSIGN_.sql

```

**NOTE** Object name converted before saving on disk:

symbol | replace by | comment
-------|---------|---------
$ | _DOLLARSIGN_ | It's a special character in BASH
/ | _SLASHSIGN_ | Used by path part separator
' ' (space) | _ (underline) | bug in some version of sqlplus when spool not working for filename with spaces 


On first run, when git not initialized - script init it by next commands:
```bash
$ git init
$ git config user.email "$GIT_AUTHOR_EMAIL"
$ git config user.name  "$GIT_AUTHOR_NAME"
``` 
GIT_AUTHOR_EMAIL and GIT_AUTHOR_NAME predefined inside script **ddl2git.sh**, you may change it, if needed. 

After that script add all files and create commit
```bash
$ git add *
$ git commit
```

### Remote repositories
Script push changes to all remotes master branch, if it exists.
You must add new remotes if needed. 

```bash
# list existing remotes
$ git remote -v

# add new remote
$ git remote add <remote_git_repo_url> <remote_git_repo_name>

# delete existing remote
$ git remote remove <remote_git_repo_name>
 
``` 
**NOTE**: For non-interactive usage use ssh url and key based authentication

### Cron
For periodical usage in cron task use **ddl2git_logger.sh**
```bash
$ crontab -e

45 16 * * * /home/oraexp/ddl2git/ddl2git_logger.sh user/password@exampledb
```

**ddl2git_logger.sh** will log script output to **logs/** folder inside script directory

If you want - you may mailing result log to email. See commented block inside **ddl2git_logger.sh**

## License
[MIT](LICENSE)