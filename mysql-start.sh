#!/bin/bash
mysqld --defaults-file=/mysqldb/8.0.34/mysql-8.0.34/my.cnf --user=rcms
sleep 5
echo "MySQL Running..."
