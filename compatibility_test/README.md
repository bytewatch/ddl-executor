# About
This is a cmd tool to test compatibility the ddl-executor library between MySQL.

# Usage
Type commad like this, will execute hundreds of DDL statements in file ddl_cases.sql using the ddl-executor library and MySQL, and print a diff output between this library and MySQL.

```
./test.sh ddl_cases.sql latin1 172.17.0.2 3306 root passwd123456
```

Of course, replace MySQL connect info by yourself, and replace 'latin1' with your MySQL's charset_server.
