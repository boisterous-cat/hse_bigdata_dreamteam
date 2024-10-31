# Project Setup Guide

This document outlines the necessary steps to set up a PostgreSQL database and configure Hadoop and Hive on a Jump Node.

## Prerequisites

- Access to the Jump Node
- SSH credentials for the node
- Necessary software packages (PostgreSQL, Hadoop, Apache Hive)

## Step 1: Install and Configure PostgreSQL

1. **Connect to the Jump Node**
   ```bash
   ssh team-27-nn
   ```
   Enter the password for the team when prompted.

2. **Install PostgreSQL**
   ```bash
   sudo apt install postgresql
   ```
   Enter the team password and confirm with `Y`.

3. **Switch to the PostgreSQL User**
   ```bash
   sudo -i -u postgres
   ```

4. **Access PostgreSQL Console**
   ```bash
   psql
   ```

5. **Create the Database**
   ```sql
   CREATE DATABASE metastore;
   ```

6. **Create a User for the Database**
   ```sql
   CREATE USER hive WITH PASSWORD 'hivePass!team27';
   ```

7. **Grant Privileges**
   ```sql
   GRANT ALL PRIVILEGES ON DATABASE "metastore" TO hive;
   ```

8. **Change Owner of the Database**
   ```sql
   ALTER DATABASE metastore OWNER TO hive;
   ```

9. **Exit the PostgreSQL Console**
   ```sql
   \q
   ```

10. **Exit from PostgreSQL User**
    ```bash
    exit
    ```

11. **Edit PostgreSQL Configuration Files**
    - Open the main configuration file:
      ```bash
      sudo vim /etc/postgresql/16/main/postgresql.conf
      ```
      Add the following line in the "CONNECTIONS AND AUTHENTICATION" section:
      ```plaintext
      listen_addresses = 'team-27-nn'
      ```
    
    - Open the `pg_hba.conf` file:
      ```bash
      sudo vim /etc/postgresql/16/main/pg_hba.conf
      ```
      Add the following line at the beginning of the "IPv4 local connections" section (replace `<jumpnode-ip>` with the actual IP of JumpNode):
      ```plaintext
      host    metastore       hive            192.168.1.110/32         password
      ```
      Remove this line:
      ```plaintext
      host    all             all             127.0.0.1/32            scram-sha-256
      ```

12. **Restart PostgreSQL**
    ```bash
    sudo systemctl restart postgresql
    ```

13. **Check PostgreSQL Status**
    ```bash
    sudo systemctl status postgresql
    ```

14. **Install PostgreSQL Client**
    ```bash
    sudo apt install postgresql-client-16
    ```

15. **Test Connection to the Database**
    ```bash
    psql -h team-27-nn -p 5432 -U hive -W -d metastore
    ```

## Step 2: Set Up Hadoop

1. **Extract Hadoop Distribution**
   ```bash
   tar -xvzf hadoop-3.4.0.tar.gz
   ```

2. **Configure Environment Variables**
   ```bash
   vim ~/.profile
   ```
   Add the following lines:
   ```plaintext
   export HADOOP_HOME=/home/hadoop/hadoop-3.4.0
   export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
   export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
   ```

3. **Apply Changes to Current Session**
   ```bash
   source ~/.profile
   ```

4. **Verify Hadoop Installation**
   ```bash
   hadoop version
   ```

5. **Navigate to Hadoop Configuration Directory**
   ```bash
   cd hadoop-3.4.0/etc/hadoop
   ```

6. **Configure core-site.xml**
   ```bash
   vim core-site.xml
   ```
   Add the following lines:
   ```xml
   <configuration>
       <property>
           <name>fs.defaultFS</name>
           <value>hdfs://team-27-nn:9000</value>
       </property>
   </configuration>
   ```

7. **Configure hdfs-site.xml**
   ```bash
   vim hdfs-site.xml
   ```
   Add the following lines:
   ```xml
   <configuration>
       <property>
           <name>dfs.replication</name>
           <value>3</value>
       </property>
   </configuration>
   ```

8. **Exit the Hadoop User**
   ```bash
   exit
   ```

## Step 3: Install and Configure Apache Hive

1. **Download Apache Hive**
   ```bash
   wget https://dlcdn.apache.org/hive/hive-4.0.1/apache-hive-4.0.1-bin.tar.gz
   ```

2. **Extract Hive Distribution**
   ```bash
   tar -xvzf apache-hive-4.0.1-bin.tar.gz
   ```

3. **Change to Hive Directory**
   ```bash
   cd apache-hive-4.0.1-bin/
   ```

4. **Check for PostgreSQL Driver**
   ```bash
   cd lib
   ls -l | grep postgres
   ```

5. **Download JDBC Driver**
   ```bash
   wget https://jdbc.postgresql.org/download/postgresql-42.7.4.jar
   ```

6. **Edit Hive Configuration Files**
   - Change to configuration directory:
     ```bash
     cd ../conf/
     ```
   - Create `hive-site.xml`:
     ```bash
     vim hive-site.xml
     ```
     Add the following lines:
     ```xml
     <configuration>
         <property>
             <name>hive.server2.authentication</name>
             <value>NONE</value>
         </property>
         <property>
             <name>hive.metastore.warehouse.dir</name>
             <value>/user/hive/warehouse</value>
         </property>
         <property>
             <name>hive.server2.thrift.port</name>
             <value>5433</value>
         </property>
         <property>
             <name>javax.jdo.option.ConnectionURL</name>
             <value>jdbc:postgresql://team-27-nn:5432/metastore</value>
         </property>
         <property>
             <name>javax.jdo.option.ConnectionDriverName</name>
             <value>org.postgresql.Driver</value>
         </property>
         <property>
             <name>javax.jdo.option.ConnectionUserName</name>
             <value>hive</value>
         </property>
         <property>
             <name>javax.jdo.option.ConnectionPassword</name>
             <value>hivePass!team27</value>
         </property>
     </configuration>
     ```

7. **Update .profile for Hive**
   ```bash
   vim ~/.profile
   ```
   Add:
   ```plaintext
   export HIVE_HOME=/home/hadoop/apache-hive-4.0.1-bin
   export HIVE_CONF_DIR=$HIVE_HOME/conf
   export HIVE_AUX_JARS_PATH=$HIVE_HOME/lib/*
   export PATH=$PATH:$HIVE_HOME/bin
   ```

8. **Activate Hadoop and Hive Environment**
   ```bash
   source ~/.profile
   ```

9. **Check Hive and Hadoop Versions**
   ```bash
   hive --version
   hadoop version
   ```

10. **Create Necessary HDFS Directories**
    ```bash
    hdfs dfs -mkdir -p /user/hive/warehouse
    hdfs dfs -chmod g+w /tmp
    hdfs dfs -chmod g+w /user/hive/warehouse
    ```

11. **Initialize the Hive Schema**
    ```bash
    bin/schematool -dbType postgres -initSchema
    ```

12. **Start Hive Server**
    ```bash
    hive --hiveconf hive.server2.enable.doAs=false --hiveconf hive.security.authorization.enabled=false --service hiveserver2 1>> /tmp/hs2.log 2>> /tmp/hs2.log &
    ```

13. **Check Hive and Hadoop Processes**
    ```bash
    jps
    ```

## Step 4: Connect to Hive Using Beeline

1. **Load Environment Profile**
   ```bash
   source ~/.profile
   ```

2. **Connect to Hive**
   ```bash
   beeline -u jdbc:hive2://team-27-jn:5433
   ```

3. **Execute Hive Commands**
   ```plaintext
   SHOW DATABASES;
   CREATE DATABASE test;
   SHOW DATABASES;
   DESCRIBE DATABASE test;
   ```

4. **Exit Beeline**
   Press `Ctrl+C` to exit.

## Conclusion

Following these steps, you have successfully set up PostgreSQL, Hadoop, and Hive on your Jump Node. Make sure to verify the installation and configurations according to your project's requirements. Happy coding!