#Install and start Apache httpd
yum -y install httpd

# remove welcome page
rm -f /etc/httpd/conf.d/welcome.conf

# Configure httpd. Replace server name to your own environment.
vi /etc/httpd/conf/httpd.conf

# line 86: change to admin's email address
ServerAdmin root@localhost 

# line 95: change to your server's name
# ServerName www.srv.world:80

# line 151: change
AllowOverride All

# line 164: add file name that it can access only with directory's name
DirectoryIndex index.html index.cgi index.php

# add follows to the end
# server's response header
ServerTokens Prod

systemctl start httpd
systemctl enable httpd

#If Firewalld is running, allow HTTP service. HTTP uses 80/TCP.
firewall-cmd --add-service=http --permanent
firewall-cmd --reload

#Create a HTML test page and access to it from client PC with web browser. It's OK if following page is shown.
vi /var/www/html/index.html
<html>
<body>
<div style="width: 100%; font-size: 40px; font-weight: bold; text-align: center;">
Test Page
</div>
</body>
</html>

#Install PHP
yum -y install php php-mbstring php-pear

vi /etc/php.ini
# line 878: uncomment and add your timezone
date.timezone = "Africa/Luanda"

systemctl restart httpd

# Create a PHP test page and access to it from client PC with web browser
vi /var/www/html/index.php

<html>
<body>
<div style="width: 100%; font-size: 40px; font-weight: bold; text-align: center;">
<?php
   print Date("Y/m/d");
?>
</div>
</body>
</html>

# Install MariaDB 5.5.
yum -y install mariadb-server
vi /etc/my.cnf

# add follows within [mysqld] section
[mysqld]
character-set-server=utf8

systemctl start mariadb
systemctl enable mariadb

# Initial Settings for MariaDB.

mysql_secure_installation

NOTE: RUNNING ALL PARTS OF THIS SCRIPT IS RECOMMENDED FOR ALL MariaDB
      SERVERS IN PRODUCTION USE!  PLEASE READ EACH STEP CAREFULLY!

In order to log into MariaDB to secure it, we'll need the current
password for the root user.  If you've just installed MariaDB, and
you haven't set the root password yet, the password will be blank,
so you should just press enter here.

Enter current password for root (enter for none):
OK, successfully used password, moving on...

Setting the root password ensures that nobody can log into the MariaDB
root user without the proper authorisation.

# set root password
Set root password? [Y/n] y
New password:
Re-enter new password:
Password updated successfully!
Reloading privilege tables..
 ... Success!

By default, a MariaDB installation has an anonymous user, allowing anyone
to log into MariaDB without having to have a user account created for
them.  This is intended only for testing, and to make the installation
go a bit smoother.  You should remove them before moving into a
production environment.
# remove anonymous users
Remove anonymous users? [Y/n] y
 ... Success!

Normally, root should only be allowed to connect from 'localhost'.  This
ensures that someone cannot guess at the root password from the network.

# disallow root login remotely
Disallow root login remotely? [Y/n] y
 ... Success!

By default, MariaDB comes with a database named 'test' that anyone can
access.  This is also intended only for testing, and should be removed
before moving into a production environment.

# remove test database
Remove test database and access to it? [Y/n] y
 - Dropping test database...
 ... Success!
 - Removing privileges on test database...
 ... Success!

Reloading the privilege tables will ensure that all changes made so far
will take effect immediately.

# reload privilege tables
Reload privilege tables now? [Y/n] y
 ... Success!

Cleaning up...

All done!  If you've completed all of the above steps, your MariaDB
installation should now be secure.

Thanks for using MariaDB!

# connect to MariaDB with root
[root@www ~]# mysql -u root -p
Enter password:     # MariaDB root password you set
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 3
Server version: 5.5.37-MariaDB MariaDB Server

Copyright (c) 2000, 2014, Oracle, Monty Program Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

# show user list
MariaDB [(none)]> select user,host,password from mysql.user;
+------+-----------+-------------------------------------------+
| user | host      | password                                  |
+------+-----------+-------------------------------------------+
| root | localhost | *xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx |
| root | 127.0.0.1 | *xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx |
| root | ::1       | *xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx |
+------+-----------+-------------------------------------------+
3 rows in set (0.00 sec)

# show database list
MariaDB [(none)]> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
+--------------------+
3 rows in set (0.00 sec)

MariaDB [(none)]> exit
Bye


# If Firewalld is running and also MariaDB is used from remote Hosts, allow service like follows. MariaDB uses 3306/TCP.
firewall-cmd --add-service=mysql --permanent
firewall-cmd --reload

# Install Cacti, SNMP.
yum --enablerepo=epel -y install cacti net-snmp net-snmp-utils php-mysql php-snmp rrdtool
sudo yum install php-mysqlnd
sudo yum install cacti-doc

# Configure SNMP (Simple Network Management Protocol).
vi /etc/snmp/snmpd.conf

# line 41: comment out
#com2sec notConfigUser   default       public

# line 74,75: uncomment and change
# change "mynetwork" to your own network
# change comunity name to anyone except public, private (for security reason)
com2sec local     localhost     Serverworld
com2sec mynetwork     192.168.232.0/24     Serverworld

# line 78,79: uncomment and change
group MyRWGroup     v2c     local
group MyROGroup     v2c     mynetwork

# line 85: uncomment
view all    included  .1                               80

# line 93,94: uncomment and change
access MyROGroup ""     v2c   noauth   exact   all   none   none
access MyRWGroup ""     v2c   noauth   exact   all   all      all

systemctl start snmpd
systemctl enable snmpd

snmpwalk -v2c -c 192.168.232.198 localhost system

#  Create a Database for Cacti and import tables.
mysql -u root -p

# create a "Cacti" database ( set any password for 'password' section )
MariaDB [(none)]> create database cacti;
Query OK, 1 row affected (0.00 sec)

MariaDB [(none)]> grant all privileges on cacti.* to cacti@'localhost' identified by 'password';
Query OK, 0 rows affected (0.00 sec)

MariaDB [(none)]> flush privileges;
Query OK, 0 rows affected (0.00 sec)

MariaDB [(none)]> exit
Bye

mysql -u cacti -p cacti < /usr/share/doc/cacti-*/cacti.sql
Enter password:     # cacti user's password

# Configure Cacti.
vi /etc/cron.d/cacti

# uncomment
*/5 * * * * cacti /usr/bin/php /usr/share/cacti/poller.php > /dev/null 2>&1

vi /usr/share/cacti/include/config.php

# line 29: change to the connection info to MariaDB
$database_type = "mysql";
$database_default = "cacti";
$database_hostname = "localhost";
$database_username = "cacti";
$database_password = "password";
$database_port = "3306";
$database_ssl = false;

vi /etc/httpd/conf.d/cacti.conf
# line 17: add access permission if need
Require host localhost
Require ip 192.168.232.0/24

systemctl restart httpd