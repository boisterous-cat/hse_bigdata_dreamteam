# Инструкция по развертыванию Hadoop кластера

## Содержание

1. [Настройка конфигурационных файлов](#настройка-конфигурационных-файлов)
2. [Копирование конфигурационных файлов на Data Nodes](#копирование-конфигурационных-файлов-на-data-nodes)
3. [Запуск сервисов](#запуск-сервисов)
4. [Настройка Nginx](#настройка-nginx)
8. [Доступ к компонентам Hadoop](#доступ-к-компонентам-hadoop)

## Настройка конфигурационных файлов

#### 1.1 Подключаемся по ssh к Jump Node и подключаемся к пользователю hadoop: 

```bash
ssh team-27-jn
sudo -i -u hadoop
```
#### 1.2 Переходим на Name Node и зайдем в папку дистрибутива:

```bash
ssh team-27-nn
cd hadoop-3.4.0/etc/hadoop
```

#### 1.3 Редактируем конфигурационный файл _mapred-site.xml_:

```bash
vim mapred-site.xml
```

Добавляем несколько строк в файл и сохраняем его:

```xml
<configuration>
    <property>
        <name>mapreduce.framework.name</name>
        <value>yarn</value>
    </property>
    <property>
        <name>mapreduce.application.classpath</name>
        <value>$HADOOP_HOME/share/hadoop/mapreduce/*:$HADOOP_HOME/share/hadoop/mapreduce/lib/*</value>
    </property>
</configuration>
```
#### 1.4 Редактируем конфигурационный файл _yarn-site.xml_:

```bash
vim yarn-site.xml
```

Добавляем несколько строк в файл и сохраняем его:

```xml
<configuration>
    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
    </property>
    <property>
        <name>yarn.nodemanager.env-whitelist</name>
        <value>JAVA_HOME,HADOOP_COMMON_HOME,HADOOP_HDFS_HOME,HADOOP_CONF_DIR,CLASSPATH_PREPEND_DISTCACHE,HADOOP_YARN_HOME,HADOOP_HOME,PATH,LANG,TZ,HADOOP_MAPRED_HOME</value>
    </property>
</configuration>
```

## Копирование конфигурационных файлов на Data Nodes

#### 2.1 Копируем файл `mapred-site.xml`:

```bash
scp mapred-site.xml team-27-dn-00:/home/hadoop/hadoop-3.4.0/etc/hadoop
scp mapred-site.xml team-27-dn-01:/home/hadoop/hadoop-3.4.0/etc/hadoop
```

#### 2.2 Копируем файл `yarn-site.xml`:

```bash
scp yarn-site.xml team-27-dn-00:/home/hadoop/hadoop-3.4.0/etc/hadoop
scp yarn-site.xml team-27-dn-01:/home/hadoop/hadoop-3.4.0/etc/hadoop
```

Теперь все необходимые конфигурационные файлы скопированы на Data Nodes

## Запуск сервисов

#### 3.1 Запустим YARN:

```bash
cd ../../
sbin/start-yarn.sh
```

#### 3.2 Запустим History Server:

```bash
mapred --daemon start historyserver
```

## Настройка Nginx

Сделаем конфиги для веб-интерфейсов

#### 4.1 Возврат на Jump Node

```bash
exit #возврат на джаммп ноду
exit #выход из под юзера
```
#### 4.2 Создаем копию конфигурации

```bash
sudo cp /etc/nginx/sites-available/nn /etc/nginx/sites-available/ya
sudo cp /etc/nginx/sites-available/nn /etc/nginx/sites-available/dh
```

#### 4.3 Редактируем файл конфигурации:

```bash
sudo vim /etc/nginx/sites-available/ya
```

#### 4.4 Вставляем следующую конфигурацию:

Меняем порт 9870 на 8088.

Итог примерно такой:

```nginx
server {
   listen 8088 default_server;
   # try_files $uri/=404;
   proxy_pass http://team-27-nn:8088;
}
```

#### 4.5 Редактируем файл конфигурации:

```bash
sudo vim /etc/nginx/sites-available/dh
```

#### 4.6 Вставляем следующую конфигурацию:

Меняем порт 9870 на 19888.

Итог примерно такой:

```nginx
server {
   listen 19888 default_server;
   # try_files $uri/=404;
   proxy_pass http://team-27-nn:19888;
}
```
#### 4.7 Создаем символическую ссылку для активации конфигурации:

```bash
sudo ln -s /etc/nginx/sites-available/ya /etc/nginx/sites-enabled/ya
sudo ln -s /etc/nginx/sites-available/dh /etc/nginx/sites-enabled/dh
```

#### 4.8 Перезапуск Nginx

Теперь, когда все конфигурации настроены, необходимо перезапустить Nginx, чтобы применить изменения:

```bash
sudo systemctl reload nginx
```

## Доступ к компонентам Hadoop

Теперь Nginx настроен на проксирование запросов как к NameNode.

- **YARN:** `http://<IP-адрес-Jump-Node>:8088`
- **History Server:** `http://<IP-адрес-Jump-Node>:19888`

После обращения по данному адресу убедимся, что все запущено верно:

![8088](https://github.com/user-attachments/assets/d5714700-2a93-44d3-9d31-882edc508c92)

![hadoop 19888](https://github.com/user-attachments/assets/3f1e4869-1bb5-4ad1-81a4-fa02913c4a56)
