# Инструкция по развертыванию Hadoop кластера

## Содержание

1. [Настройка подключения к нодам](#настройка-подключения-к-нодам)
2. [Установка необходимых файлов](#установка-необходимых-файлов)
3. [Настройка переменных окружения для Hadoop и Java](#настройка-переменных-окружения-для-hadoop-и-java)
4. [Настройка конфигурационных файлов](#настройка-конфигурационных-файлов)
5. [Копирование конфигурационных файлов на Data Nodes](#копирование-конфигурационных-файлов-на-data-nodes)
6. [Форматирование NameNode и запуск сервисов Hadoop](#форматирование-namenode-и-запуск-сервисов-hadoop)
7. [Настройка Nginx для NameNode](#настройка-nginx-для-namenode-yarn)
8. [Доступ к компонентам Hadoop](#доступ-к-компонентам-hadoop)

## 1. Настройка подключения к нодам

Подключаемся по ssh к * Node (начинаем с jump node): 
Создаем пользователя hadoop без root прав и с ОСОЗНАННЫМ паролем:

```bash
sudo adduser hadoop
```

Редактируем файл с хостами:

```bash
sudo vim /etc/hosts
```

Комментируем все строки и прописываем ip адреса и названия хостов, итоговый вид должен получиться такой:

```bash
# The following lines are desirable for IPv6 capable hosts
#::1     ip6-localhost ip6-loopback
#fe00::0 ip6-localnet
#ff00::0 ip6-mcastprefix
#ff02::1 ip6-allnodes
#ff02::2 ip6-allrouters
192.168.1.110   team-27-jn
192.168.1.111   team-27-nn
192.168.1.112   team-27-dn-00
192.168.1.113   team-27-dn-01
```

Проверяем, что мы всё сделали правильно:
```bash
ping team-27-dn-00
```

Повторяем все действия пункта 1 на NameNode, DataNode-00, DataNode-01.


### Настройка SSH ключей для безпарольного доступа к нодам

На каждой ноде переключаемся на пользователя hadoop и генерируем ssh ключ:

```bash
sudo -i -u hadoop
ssh-keygen
```

После генерации SSH ключа копируем публичный ключ и вставляем в любой текстовый файл:

```bash
cat .ssh/id_ed25519.pub
```

Возвращаемся на Jump Node, переключаемся на пользователя hadoop и редактируем файл с авторизионными ключами:

```bash
sudo -i -u hadoop
vim .ssh/authorized_keys
```

Добавляем в этот файл все предварительно сохраненные ключи (от Jump Node, Name Node, Data Node-00, Data Node-01). Пример:

```bash
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDqoPBUVpmQHwv10pTBRrbtWyaWyuz5Avj8AfAx9b44m
```

Распространим файл `authorized_keys` на все ноды через `scp` (необходимо ввести парроль от пользоватлей hadoop на кааждой ноде):

```bash
scp .ssh/authorized_keys team-27-nn:/home/hadoop/.ssh/
scp .ssh/authorized_keys team-27-dn-00:/home/hadoop/.ssh/
scp .ssh/authorized_keys team-27-dn-01:/home/hadoop/.ssh/
```

Проверяем, что мы всё сделали правильно и можно подключаться без пароля:

```bash
ssh team-27-nn
ssh team-27-dn-00
ssh team-27-dn-01
```

## Установка необходимых файлов

Переходим на Jump node и скачиваем архив с Hadoop с официального сайта. Это готовый для использования архив, содержащий все необходимые файлы и библиотеки для запуска Hadoop, включая HDFS, YARN, и MapReduce.

```bash
ssh hadoop@team-27-jn
```

```bash
wget https://dlcdn.apache.org/hadoop/common/hadoop-3.4.0/hadoop-3.4.0.tar.gz
```

Распространим файл на все ноды через `scp`:

```bash
scp hadoop-3.4.0.tar.gz team-27-nn:/home/hadoop
scp hadoop-3.4.0.tar.gz team-27-dn-00:/home/hadoop/
scp hadoop-3.4.0.tar.gz team-27-dn-01:/home/hadoop/
```

**Далее итеративно для каждой ноды (Name Node, Data Node-00, Data Node-01)**:

Разархивируем его:

```bash
tar -xvzf hadoop-3.4.0.tar.gz
```

## Настройка переменных окружения для Hadoop и Java

Переходим снова на Name Node и переключаемся на пользователя hadoop: 

```bash
ssh team-27-nn
sudo -i -u hadoop
```

Проверка пути к Java

```bash
which java
```
/usr/bin/java

Определяем фактический путь к Java

```bash
readlink -f /usr/bin/java
```
/usr/lib/jvm/java-11-openjdk-amd64/bin/java

Добавим определение переменных окружения в файл:

```bash
vim ~/.profile
```

Добавляем в файла следующие строки для настройки окружения Hadoop:

```bash
export HADOOP_HOME=/home/hadoop/hadoop-3.4.0
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
```

После редактирования файла применяем изменения:

```bash
source ~/.profile
```

Откроем файл конфигурации Hadoop для указания пути к Java. Заходим в папку дистрибутива и откроем файл:

```bash
cd hadoop-3.4.0/etc/hadoop
vim hadoop-env.sh
```

Добавим переменные окружения для Java после закомментированной строки JAVA_HOME (положение в файле важно!):

```bash
JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
```

Убедимся, что все настроено правильно, проверив какие переменные отобразятся

```bash
export
```

## Настройка конфигурационных файлов

### Редактирование конфигурационного файла _core-site.xml_

Далее мы редактируем конфигурационный файл _core-site.xml_, чтобы указать URL для NameNode:

```bash
sudo vim core-site.xml
```

Затем добавляем несколько строк в файл и сохраняем его:

```xml
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://team-27-nn:9000</value>
    </property>
</configuration>
```

### Редактирование конфигурационного файла _hdfs-site.xml_

Далее мы также редактируем конфигурационный файл _hdfs-site.xml_, чтобы определить коэффициент репликации

```bash
vim hdfs-site.xml
```

Затем добавляем несколько строк в файл и сохраняем его:

```xml
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>3</value>
    </property>
</configuration>
```

### Редактирование файла _workers_

Редактируем файл _workers_ для указания имен нод:

```bash
vim workers
```

Удаляем из файла строку _localhost_

Добавляем в файл следующие строки:

```bash
team-27-nn
team-27-dn-00
team-27-dn-01
```

Теперь все необходимые конфигурации выполнены

## Копирование конфигурационных файлов на Data Nodes

1. **Копируем файл `.profile`:**

   ```bash
   scp ~/profile team-27-dn-00:/home/hadoop
   scp ~/profile team-27-dn-01:/home/hadoop
   ```

2. **Копируем файл `hadoop-env.sh`:**

   ```bash
   scp hadoop-env.sh team-27-dn-00:/home/hadoop/hadoop-3.4.0/etc/hadoop
   scp hadoop-env.sh team-27-dn-01:/home/hadoop/hadoop-3.4.0/etc/hadoop
   ```

3. **Копируем файл `core-site.xml`:**

   ```bash
   scp core-site.xml team-27-dn-00:/home/hadoop/hadoop-3.4.0/etc/hadoop
   scp core-site.xml team-27-dn-01:/home/hadoop/hadoop-3.4.0/etc/hadoop
   ```

4. **Копируем файл `hdfs-site.xml`:**

   ```bash
   scp hdfs-site.xml team-27-dn-00:/home/hadoop/hadoop-3.4.0/etc/hadoop
   scp hdfs-site.xml team-27-dn-01:/home/hadoop/hadoop-3.4.0/etc/hadoop
   ```

5. **Копируем файл `workers`:**

   ```bash
   scp workers team-27-dn-00:/home/hadoop/hadoop-3.4.0/etc/hadoop
   scp workers team-27-dn-01:/home/hadoop/hadoop-3.4.0/etc/hadoop
   ```

Теперь все необходимые конфигурационные файлы скопированы на Data Nodes

## Форматирование NameNode и запуск сервисов Hadoop

1. **Форматирование NameNode:**

   Для начала выйдем из директории: hadoop-3.4.0/etc/hadoop и отформатируем файловую систему:

   ```bash
   cd ../../
   bin/hdfs namenode -format
   ```

2. **Запуск HDFS:**

   ```bash
   sbin/start-dfs.sh
   ```
   ![alt text](image-1.png)

3. **Проверка состояния процессов:**

   ```bash
   jps
   ```
   ![alt text](image.png)

Таким образом, мы подготовили и запустили необходимые компоненты кластера Hadoop.

## Настройка Nginx для NameNode

Настроим Nginx на Jump Node.

Переходим на Jump Node

   ```bash
   ssh hadoop@team-27-jn
   ```

### 1. Настройка Nginx для NameNode

1. **Редактируем файл конфигурации для NameNode:**

   ```bash
   sudo vim /etc/nginx/sites-available/nn
   ```

2. **Вставляем следующую конфигурацию:**

   Комментируем строку: listen [::]:80 default_server;
   Меняем строку: listen 80 НА: listen 9870 default_server;
   Переаправим трафик в нужное нам место - комментируем строку: try_files $uri/=404;
   Добавляем в это же место строку: proxy_pass http://team-27-nn:9870;

   Итог примерно такой:

   ```nginx
   server {
       listen 9870 default_server;
       # try_files $uri/=404;
       proxy_pass http://team-27-nn:9807;
   }
   ```

3. **Создаем символическую ссылку для активации конфигурации:**

   ```bash
   sudo ln -s /etc/nginx/sites-available/nn /etc/nginx/sites-enabled/nn
   ```

#### 2. Перезапуск Nginx

Теперь, когда все конфигурации настроены, необходимо перезапустить Nginx, чтобы применить изменения:

```bash
sudo systemctl reload nginx
```

## Доступ к компонентам Hadoop

Теперь Nginx настроен на проксирование запросов как к NameNode.

- **NameNode:** `http://<IP-адрес-Jump-Node>:9870`

После обращения по данному адресу убедимся, что все запущено верно:
![alt text](image-2.png)

![alt text](image-3.png)

