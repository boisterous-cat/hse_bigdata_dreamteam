# Инструкция по настройке Hive

## Step 1: Настройка и конфигурирование PostgreSQL

1. **Connect to the Name Node**
   ```bash
   ssh team-27-n
   ```
   Вводим пароль.

2. **Устанавливаем PostgreSQL**
   ```bash
   sudo apt install postgresql
   ```
   Вводим пароль и поддтверждаем введя `Y`.

3. **Переключаемся на пользователя PostgreSQL**
   ```bash
   sudo -i -u postgres
   ```

4. **Подключимся к консоли PostgreSQL**
   ```bash
   psql
   ```

5. **Создадим БД**
   ```sql
   CREATE DATABASE metastore;
   ```

6. **Создаем пользователя для БД**
   ```sql
   CREATE USER hive WITH PASSWORD '<postgre password>';
   ```

7. **Предоставляем права**
   ```sql
   GRANT ALL PRIVILEGES ON DATABASE "metastore" TO hive;
   ```

8. **Делаем нашего пользователя владельцем БД**
   ```sql
   ALTER DATABASE metastore OWNER TO hive;
   ```

9. **Выйдем из консоли PostgreSQL**
   ```sql
   \q
   ```

10. **Выйдем из пользователя PostgreSQL на Name Node**
    ```bash
    exit
    ```

11. **Поправим конфигурационные файлы PostgreSQL**
    - Откроем файл `postgresql.conf`:
      ```bash
      sudo vim /etc/postgresql/16/main/postgresql.conf
      ```
      В секции "CONNECTIONS AND AUTHENTICATION" в разделе Connection settings добавляем адрес Name Node:
      ```plaintext
      listen_addresses = 'team-27-nn'
      ```
    
    - Откроем файл `pg_hba.conf`:
      ```bash
      sudo vim /etc/postgresql/16/main/pg_hba.conf
      ```
      В секции "IPv4 local connections" в начале добавить:
      ```plaintext
      host    metastore       hive            <jumpnode-ip>/32         password
      ```
      Также требуется в той же секции удалить строку:
      ```plaintext
      host    all             all             127.0.0.1/32            scram-sha-256
      ```

12. **Перезапускаем PostgreSQL**
    ```bash
    sudo systemctl restart postgresql
    ```

13. **Проверяем статус PostgreSQL**
    ```bash
    sudo systemctl status postgresql
    ```

14. **Вернемся на Jump Node**
    ```bash
    exit
    ```

15. **Установим PostgreSQL Client нашей версии**
    ```bash
    sudo apt install postgresql-client-16
    ```

16. **Пробуем подключиться**
    ```bash
    psql -h team-27-nn -p 5432 -U hive -W -d metastore
    ```
    ![Скриншот 29-10-2024 203759](https://github.com/user-attachments/assets/dc6e16eb-159e-4246-bddc-49d4a95b002d)


## Step 2: Настраиваем Hadoop на Jump Node

1. **Проверяем подключение**
   ```bash
   ssh hadoop@team-27-jn
   ```
2. **Разархивируем архив с Hadoop**
   ```bash
   tar -xvzf hadoop-3.4.0.tar.gz
   ```

3. **Добавим определение переменных окружения в файл**
   ```bash
   vim ~/.profile
   ```
   Добавляем в файла следующие строки для настройки окружения Hadoop:
   ```plaintext
   export HADOOP_HOME=/home/hadoop/hadoop-3.4.0
   export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
   export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
   ```

4. **После редактирования файла применяем изменения**
   ```bash
   source ~/.profile
   ```

5. **Проверка установки Hadoop**
   ```bash
   hadoop version
   ```

6. **Заходим в папку дистрибутива**
   ```bash
   cd hadoop-3.4.0/etc/hadoop
   ```

7. **Редактирование конфигурационного файла _core-site.xml_**
   ```bash
   vim core-site.xml
   ```
   Добавляем несколько строк в файл:
   ```xml
   <configuration>
       <property>
           <name>fs.defaultFS</name>
           <value>hdfs://team-27-nn:9000</value>
       </property>
   </configuration>
   ```

8. **Редактирование конфигурационного файла _hdfs-site.xml_**
   ```bash
   vim hdfs-site.xml
   ```
   Добавляем несколько строк в файл:
   ```xml
   <configuration>
       <property>
           <name>dfs.replication</name>
           <value>3</value>
       </property>
   </configuration>
   ```

9. **Выход из пользователя Hadoop**
   ```bash
   exit
   ```

## Step 3: Настройка и конфигурирование Apache Hive

1. **Скачаем дистриибутив Apache Hive**
   ```bash
   wget https://dlcdn.apache.org/hive/hive-4.0.1/apache-hive-4.0.1-bin.tar.gz
   ```

2. **Разархивируем архив Hive**
   ```bash
   tar -xvzf apache-hive-4.0.1-bin.tar.gz
   ```

3. **Переходим в папку дистрибутива**
   ```bash
   cd apache-hive-4.0.1-bin/
   ```

4. **Проверяем что в папке с библиотеками нет нужного драйвера**
   ```bash
   cd lib
   ls -l | grep postgres
   ```

5. **Скачаем jdbc драйвер с официального сайта**
   ```bash
   wget https://jdbc.postgresql.org/download/postgresql-42.7.4.jar
   ```

   ![driver appers](https://github.com/user-attachments/assets/c9b5e851-7205-43d5-9c45-888bed3aba01)


6. **Вернемся, чтобы поправить конфигурационные файлы Hive**
   - Выйдем  директории:
     ```bash
     cd ../conf/
     ```
   - Создадим новый файл `hive-site.xml`:
     ```bash
     vim hive-site.xml
     ```
     Вставляем:
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
             <value><postgre password></value>
         </property>
     </configuration>
     ```

7. **Редактируем .profile для Hive**
   ```bash
   vim ~/.profile
   ```
   Добавляем пути:
   ```plaintext
   export HIVE_HOME=/home/hadoop/apache-hive-4.0.1-bin
   export HIVE_CONF_DIR=$HIVE_HOME/conf
   export HIVE_AUX_JARS_PATH=$HIVE_HOME/lib/*
   export PATH=$PATH:$HIVE_HOME/bin
   ```

8. **Активируем наше окружение**
   ```bash
   source ~/.profile
   ```

9. **Проверяем версии Hive и Hadoop**
   ```bash
   hive --version
   hadoop version
   ```

10. **Создаем директории HDFS (через webUI проверяем что таких папок нет)**
    ```bash
    hdfs dfs -mkdir -p /user/hive/warehouse
    hdfs dfs -chmod g+w /tmp
    hdfs dfs -chmod g+w /user/hive/warehouse
    ```
    ![photo_2024-10-31_21-43-43](https://github.com/user-attachments/assets/7e291ab9-852a-45e7-a91c-c45ea09b6a5e)

11. **Инициализация схемы Hive**
    ```bash
    cd ../
    bin/schematool -dbType postgres -initSchema
    ```

12. **Запуск Hive Server**
    ```bash
    hive --hiveconf hive.server2.enable.doAs=false --hiveconf hive.security.authorization.enabled=false --service hiveserver2 1>> /tmp/hs2.log 2>> /tmp/hs2.log &
    ```

13. **Прверяем**
    ```bash
    jps
    ```
    ![photo_2024-10-31_21-44-16](https://github.com/user-attachments/assets/69635dad-43b8-4c22-a2fa-0950b528e64d)


## Step 4: Подключаемся к Hive через Билайн

1. **Активируем наше окружение**
   ```bash
   source ~/.profile
   ```

2. **Подключаемся к Hive**
   ```bash
   beeline -u jdbc:hive2://team-27-jn:5433
   ```

3. **Создаем тестовую БД**
   ```plaintext
   SHOW DATABASES;
   CREATE DATABASE test;
   SHOW DATABASES;
   DESCRIBE DATABASE test;
   ```

4. **Выход из Beeline**
   Press `Ctrl+C` to exit.

   ![photo_2024-10-31_21-44-45](https://github.com/user-attachments/assets/dfd6a1fe-44b2-42d1-aae3-6c5af88542e8)

## Step 5: Загрузка данных в Hive

1. **Загрузим датасет на jump-node (за основу был взят доступный housing.csv)**
   ```bash
   ssh team-27-jn
   sudo -i -u hadoop
   wget https://raw.githubusercontent.com/ageron/handson-ml/refs/heads/master/datasets/housing/housing.csv
   ```

2. **Выполним**
   ```bash
   cd ~
   source ~/.profile
   hdfs dfs -mkdir /input
   hdfs dfs -chmod g+w /input
   hdfs dfs -put housing.csv /input
   ```

3. **Проверим, что с файлом все хорошо**
   ```bash
   hdfs fsck /input/dataset.csv
   ```

4. **TO DO**
   
