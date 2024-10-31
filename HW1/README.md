# Инструкция по развертыванию Hadoop кластера

## Содержание

1. [Настройка подключения к нодам](#настройка-подключения-к-нодам)
2. [Настройка безпарольного доступа к нодам](#настройка-безпарольного-доступа-к-нодам)
3. [Установка необходимых файлов](#установка-необходимых-файлов)
4. [Настройка переменных окружения для Hadoop и Java](#настройка-переменных-окружения-для-hadoop-и-java)
5. [Настройка конфигурационных файлов](#настройка-конфигурационных-файлов)
6. [Копирование конфигурационных файлов на Data Nodes](#копирование-конфигурационных-файлов-на-data-nodes)
7. [Форматирование NameNode и запуск сервисов Hadoop](#форматирование-namenode-и-запуск-сервисов-hadoop)
8. [Настройка Nginx для NameNode](#настройка-nginx-для-namenode)
9. [Доступ к компонентам Hadoop](#доступ-к-компонентам-hadoop)

## Настройка подключения к нодам

#### 1.1 Подключаемся по ssh к jump Node: 

```bash
ssh team@ip
```
#### 1.2 Создаем пользователя hadoop без root прав и с ОСОЗНАННЫМ паролем:

```bash
sudo adduser hadoop
```
Для sudo прав заполняем пароль команды. Full Name нового пользователя - hadoop. Остальные поля заполняются опционально.

#### 1.3 Редактируем файл с хостами, чтобы хосты знали друг друга по именам:

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
<jumpnode-ip>   team-27-jn
<namenode-ip>   team-27-nn
<datanode1-ip>   team-27-dn-00
<datanode2-ip>   team-27-dn-01
```

Проверяем, что мы всё сделали правильно:
```bash
ping team-27-dn-00
```

#### 1.4 Повторяем все действия пункта с **1.1 по 1.3** на NameNode, DataNode-00, DataNode-01.
Для входа используем названия хостов, указанные в пункет 1.3, например для подключения на DataNode-00:

```bash
ssh team-27-dn-00
```

## Настройка безпарольного доступа к нодам

#### 2.1 Переключаемся на пользователя hadoop и генерируем ssh ключ:
Повторяем все действия пункта на каждой ноде.

```bash
sudo -i -u hadoop
ssh-keygen
```

После генерации SSH ключа копируем публичный ключ и вставляем в любой текстовый файл:

```bash
cat .ssh/id_ed25519.pub
```

#### 2.2 Возвращаемся на Jump Node, переключаемся на пользователя hadoop и редактируем файл `authorized_keys`:

```bash
sudo -i -u hadoop
vim .ssh/authorized_keys
```

Добавляем в этот файл все предварительно сохраненные ключи (от Jump Node, Name Node, Data Node-00, Data Node-01). Пример:

```bash
ssh-ed25519 AAAAC3***C1lZDI1NTE5****IDqoPBUVpmQHwv***TBRrbtWyaW***5Avj8AfAx9b56m
```

#### 2.3 Распространим файл `authorized_keys` на все ноды через `scp` (необходимо ввести пароль от пользоватлей hadoop на каждой ноде):

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

#### 3.1 Скачивание дистрибутива hadoop
Переходим на Jump node, переключаемся на пользователя hadoop и скачиваем архив Hadoop с официального сайта.

```bash
ssh team-27-jn
sudo -i -u hadoop
```

```bash
wget https://dlcdn.apache.org/hadoop/common/hadoop-3.4.0/hadoop-3.4.0.tar.gz
```

#### 3.2 Распространим скачанный дистрибутив hadoop на все ноды через `scp`:

```bash
scp hadoop-3.4.0.tar.gz team-27-nn:/home/hadoop
scp hadoop-3.4.0.tar.gz team-27-dn-00:/home/hadoop/
scp hadoop-3.4.0.tar.gz team-27-dn-01:/home/hadoop/
```

#### 3.3 Распаковка архива
**Далее итеративно для каждой ноды (Name Node, Data Node-00, Data Node-01)**:

Разархивируем его:

```bash
tar -xvzf hadoop-3.4.0.tar.gz
```

## Настройка переменных окружения для Hadoop и Java

#### 4.1 Переходим на Name Node и переключаемся на пользователя hadoop: 

```bash
ssh team-27-nn
sudo -i -u hadoop
```

#### 4.2 Проверяем версию java (должна быть 11)

```bash
java -version
```
#### 4.3 Смотрим где установлена java и сохраняем путь

```bash
which java
```
/usr/bin/java

Определяем фактический путь к Java

```bash
readlink -f /usr/bin/java
```
/usr/lib/jvm/java-11-openjdk-amd64/bin/java

#### 4.4 Добавим определение переменных окружения в файл:

```bash
vim ~/.profile
```

Добавляем в файл следующие строки для настройки окружения Hadoop:

```bash
export HADOOP_HOME=/home/hadoop/hadoop-3.4.0
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
```

#### 4.5 После редактирования файла проверяем:

```bash
source ~/.profile
hadoop version
```

#### 4.6 Откроем файл конфигурации Hadoop для указания пути к Java. Заходим в папку дистрибутива и откроем файл:

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

#### 5.1 Редактирование конфигурационного файла _core-site.xml_

Далее мы редактируем конфигурационный файл _core-site.xml_, чтобы указать URL для NameNode:

```bash
vim core-site.xml
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

#### 5.2 Редактирование конфигурационного файла _hdfs-site.xml_

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

#### 5.3 Редактирование файла _workers_

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

#### 6.1 Копируем файл `.profile`:

```bash
scp ~/.profile team-27-dn-00:/home/hadoop
scp ~/.profile team-27-dn-01:/home/hadoop
```

#### 6.2 Копируем файл `hadoop-env.sh`:

```bash
scp hadoop-env.sh team-27-dn-00:/home/hadoop/hadoop-3.4.0/etc/hadoop
scp hadoop-env.sh team-27-dn-01:/home/hadoop/hadoop-3.4.0/etc/hadoop
```

#### 6.3 Копируем файл `core-site.xml`:

```bash
scp core-site.xml team-27-dn-00:/home/hadoop/hadoop-3.4.0/etc/hadoop
scp core-site.xml team-27-dn-01:/home/hadoop/hadoop-3.4.0/etc/hadoop
```

#### 6.4 Копируем файл `hdfs-site.xml`:

```bash
scp hdfs-site.xml team-27-dn-00:/home/hadoop/hadoop-3.4.0/etc/hadoop
scp hdfs-site.xml team-27-dn-01:/home/hadoop/hadoop-3.4.0/etc/hadoop
```

#### 6.5 Копируем файл `workers`:

```bash
scp workers team-27-dn-00:/home/hadoop/hadoop-3.4.0/etc/hadoop
scp workers team-27-dn-01:/home/hadoop/hadoop-3.4.0/etc/hadoop
```

Теперь все необходимые конфигурационные файлы скопированы на Data Nodes

## Форматирование NameNode и запуск сервисов Hadoop

#### 7.1 Форматирование NameNode:

   Для начала выйдем из директории: hadoop-3.4.0/etc/hadoop и отформатируем файловую систему:

```bash
cd ../../
bin/hdfs namenode -format
```

#### 7.2 Запуск HDFS:

```bash
sbin/start-dfs.sh
```
   ![image-1](https://github.com/user-attachments/assets/be0e1f0a-bd91-4497-9e9f-5a3897c341fe)


#### 7.3 Проверка состояния:

```bash
jps
```
 ![image](https://github.com/user-attachments/assets/b7465d91-1f55-4580-888e-a3dfd9cf39d2)


Таким образом, мы подготовили и запустили необходимые компоненты кластера Hadoop.

## Настройка Nginx для NameNode

Настроим Nginx на Jump Node.

Переходим на Jump Node под обычным пользователем.

```bash
ssh team-27-jn
```

#### 8.1 Настройка Nginx для NameNode

1. **Копируем конфиг для nginx**
```bash
sudo cp /etc/nginx/sites-available/default /etc/nginx/sites-available/nn
```

2. **Редактируем файл конфигурации для NameNode:**

```bash
sudo vim /etc/nginx/sites-available/nn
```

3. **Вставляем следующую конфигурацию:**

Комментируем строку: listen [::]:80 default_server;
Меняем строку: listen 80 НА: listen 9870 default_server;
Перенаправим трафик в нужное нам место - комментируем строку: try_files $uri/=404;
Добавляем в это же место строку: proxy_pass http://team-27-nn:9870;

Итог такой:

```nginx
server {
        listen 9870 default_server;
        #listen [::]:80 default_server;

        # SSL configuration
        #
        # listen 443 ssl default_server;
        # listen [::]:443 ssl default_server;
        #
        # Note: You should disable gzip for SSL traffic.
        # See: https://bugs.debian.org/773332
        #
        # Read up on ssl_ciphers to ensure a secure configuration.
        # See: https://bugs.debian.org/765782
        #
        # Self signed certs generated by the ssl-cert package
        # Don't use them in a production server!
        #
        # include snippets/snakeoil.conf;

        root /var/www/html;

        # Add index.php to the list if you are using PHP
        index index.html index.htm index.nginx-debian.html;

        server_name _;

        location / {
                # First attempt to serve request as file, then
                # as directory, then fall back to displaying a 404.
                # try_files $uri $uri/ =404;
                proxy_pass http://team-27-nn:9870;
        }

        # pass PHP scripts to FastCGI server
        #
        #location ~ \.php$ {
        #       include snippets/fastcgi-php.conf;
        #
        #       # With php-fpm (or other unix sockets):
        #       fastcgi_pass unix:/run/php/php7.4-fpm.sock;
        #       # With php-cgi (or other tcp sockets):
        #       fastcgi_pass 127.0.0.1:9000;
        #}

        # deny access to .htaccess files, if Apache's document root
        # concurs with nginx's one
        #
        #location ~ /\.ht {
        #       deny all;
        #}
}
```

4. **Создаем символическую ссылку для активации конфигурации:**

```bash
sudo ln -s /etc/nginx/sites-available/nn /etc/nginx/sites-enabled/nn
```

#### 8.2 Перезапуск Nginx

Теперь, когда все конфигурации настроены, необходимо перезапустить Nginx, чтобы применить изменения:

```bash
sudo systemctl reload nginx
```

## Доступ к компонентам Hadoop

Теперь Nginx настроен на проксирование запросов как к NameNode.

- **NameNode:** `http://<IP-адрес-Jump-Node>:9870`

После обращения по данному адресу убедимся, что все запущено верно:
![image-2](https://github.com/user-attachments/assets/82a7120e-be4a-4895-8b07-5ae9390e25d6)


![image-3](https://github.com/user-attachments/assets/d5cc3032-3065-478d-b47e-dfe836ee6335)


