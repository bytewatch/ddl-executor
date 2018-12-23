#!/bin/bash


if [ $# -lt 5 ]; then
    echo "Usage: $0 ddl_cases server_charset mysql_host mysql_port mysql_user [mysql_passwd]"
    exit 1
fi

ddl_cases=$1
server_charset=$2


mysql_conn_str="-h $3 -P $4 -u $5"
if [ -n "$6" ]; then
    mysql_conn_str="$mysql_conn_str -p $6"
fi

cat $ddl_cases | ./compatibility_test -type mysql $mysql_conn_str >mysql_exec.output
if [ $? -ne 0 ]; then
    exit 1
fi
cat $ddl_cases | ./compatibility_test -type lib -charset $server_charset  >lib_exec.output
if [ $? -ne 0 ]; then
    exit 1
fi
diff mysql_exec.output lib_exec.output 
