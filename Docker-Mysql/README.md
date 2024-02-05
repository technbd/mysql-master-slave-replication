



### MySQL Configuration File for Master Node:

```
[mysqld]

server-id = 1
bind-address = 0.0.0.0
port = 3306

log-bin = /var/lib/mysql/master-bin.log
#binlog-do-db = your_database_name

default_authentication_plugin=mysql_native_password

max_connections = 1000
max_connect_errors = 10000
```


### MySQL Configuration File for Slave-1:

```
[mysqld]

server-id = 2
bind-address = 0.0.0.0
port = 3306

log-bin = /var/lib/mysql/slave1-bin.log
#binlog-do-db = your_database_name

default_authentication_plugin=mysql_native_password

max_connections = 1000
max_connect_errors = 10000
```


### MySQL Configuration File for Slave-2:

```
[mysqld]

server-id = 3
bind-address = 0.0.0.0
port = 3306

log-bin = /var/lib/mysql/slave2-bin.log
#binlog-do-db = your_database_name

default_authentication_plugin=mysql_native_password

max_connections = 1000
max_connect_errors = 10000
```



### Run the Docker Containers:

```
docker-compose up -d
```


```
docker ps

CONTAINER ID   IMAGE          COMMAND                  CREATED          STATUS          PORTS                               NAMES
b86470db8ef2   mysql:8.0.34   "docker-entrypoint.s…"   29 seconds ago   Up 26 seconds   33060/tcp, 0.0.0.0:3306->3306/tcp   mysql_master
b16f6942d0fb   mysql:8.0.34   "docker-entrypoint.s…"   29 seconds ago   Up 26 seconds   33060/tcp, 0.0.0.0:3307->3306/tcp   mysql_slave1
c1cd0fbac6d5   mysql:8.0.34   "docker-entrypoint.s…"   29 seconds ago   Up 26 seconds   33060/tcp, 0.0.0.0:3308->3306/tcp   mysql_slave2
```


### Login to MySQL containers:

**On Master:**

```
mysql -h 192.168.0.6 -P 3306 -u root -p

or,

docker exec -it <container_name> bash

mysql -u root -p
```


```
show variables like 'server_id';

+---------------+-------+
| Variable_name | Value |
+---------------+-------+
| server_id     | 1     |
+---------------+-------+
```


**On Slave-1:**

```
mysql -h 192.168.0.6 -P 3307 -u root -p

or,

docker exec -it <container_name> bash

mysql -u root -p
```


```
show variables like 'server_id';
+---------------+-------+
| Variable_name | Value |
+---------------+-------+
| server_id     | 2     |
+---------------+-------+
```



**On Slave-2:**

```
mysql -h 192.168.0.6 -P 3308 -u root -p

or,

docker exec -it <container_name> bash

mysql -u root -p
```


```
show variables like 'server_id';
+---------------+-------+
| Variable_name | Value |
+---------------+-------+
| server_id     | 3     |
+---------------+-------+
```



### Create Replication User:
Create a dedicated MySQL user for replication with the necessary privileges.


**On Master:**

```
create user 'replicator'@'%' identified with mysql_native_password by 'secret';

grant replication slave on *.* to 'replicator'@'%';

FLUSH PRIVILEGES;
```

```
SHOW GRANTS FOR 'replicator'@'%';
```

```
use mysql;
select user,host,plugin from user;
```



### Get the Log File and Position:

**On Master:**

```
show variables like 'log_bin%';
```


```
show binary logs;
```


```
show master status;

+-------------------+----------+--------------+------------------+-------------------+
| File              | Position | Binlog_Do_DB | Binlog_Ignore_DB | Executed_Gtid_Set |
+-------------------+----------+--------------+------------------+-------------------+
| master-bin.000003 |      831 |              |                  |                   |
+-------------------+----------+--------------+------------------+-------------------+
```




---
---



### Set up Replication On Slave-1 and Slave-2:
After start replica ensure that "Slave_IO_Running" and "Slave_SQL_Running" are both "Yes" on both mysql instances.


**On Slave-1**

```
stop replica;
```


```
CHANGE REPLICATION SOURCE TO
SOURCE_HOST='master_ip',
SOURCE_PORT = 3306,
SOURCE_USER='replicator',
SOURCE_PASSWORD='secret',
SOURCE_LOG_FILE='master-bin.000003',
SOURCE_LOG_POS=831;
```


```
start replica;
```


**On Slave-2**

```
stop replica;
```


```
CHANGE REPLICATION SOURCE TO
SOURCE_HOST='master_ip',
SOURCE_PORT = 3306,
SOURCE_USER='replicator',
SOURCE_PASSWORD='admin',
SOURCE_LOG_FILE='master-bin.000003',
SOURCE_LOG_POS=831;
```


```
start replica;
```



### Verify Replication:

Look for the "Slave_IO_Running" and "Slave_SQL_Running" fields. Both should be "Yes" if replication is working correctly.

Check the replication status on slave nodes:

__On Slave-1:__

```
SHOW SLAVE STATUS\G;
```

__On Slave-2:__

```
SHOW SLAVE STATUS\G;
```

**On Master:**
```
SHOW REPLICAS;

+-----------+------+------+-----------+------------------------------+
| Server_Id | Host | Port | Source_Id | Replica_UUID                 |
+-----------+------+------+-----------+------------------------------+
|         2 |      | 3306 |         1 | fbb4e0c9-c3af-11ee-b189-xxxx |
|         3 |      | 3306 |         1 | fbae0729-c3af-11ee-b160-xxxx |
+-----------+------+------+-----------+------------------------------+
```


**On Master**
```
create database db1;
```


```
show databases;

+--------------------+
| Database           |
+--------------------+
| db1                |
| information_schema |
| mysql              |
| performance_schema |
| sys                |
+--------------------+
```


__On Slave-1:__

```
show databases;

+--------------------+
| Database           |
+--------------------+
| db1                |
| information_schema |
| mysql              |
| performance_schema |
| sys                |
+--------------------+
```


__On Slave-2:__

```
show databases;

+--------------------+
| Database           |
+--------------------+
| db1                |
| information_schema |
| mysql              |
| performance_schema |
| sys                |
+--------------------+
```


**Set the database read only:**

__On Slave-1 and On Slave-2:__

```
alter database db1 read only = 1;
```




