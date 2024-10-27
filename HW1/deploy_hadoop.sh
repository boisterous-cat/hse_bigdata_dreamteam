#!/bin/bash

echo "Создаем пользователя hadoop"
sudo adduser hadoop

echo "Редактируем файл /etc/hosts"
sudo bash -c 'cat <<EOF > /etc/hosts
# IPv6 entries
#::1     ip6-localhost ip6-loopback
#fe00::0 ip6-localnet
#ff00::0 ip6-mcastprefix
#ff02::1 ip6-allnodes
#ff02::2 ip6-allrouters
192.168.1.110   team-27-jn
192.168.1.111   team-27-nn
192.168.1.112   team-27-dn-00
192.168.1.113   team-27-dn-01
EOF'

ping team-27-dn-00

# Настройка SSH ключей
echo "Генерация SSH ключей для пользователя hadoop"
sudo -i -u hadoop ssh-keygen -t ed25519 -f /home/hadoop/.ssh/id_ed25519 -N ""

echo "Копируем ключи на ноды"
sudo -i -u hadoop bash -c 'cat ~/.ssh/id_ed25519.pub >> ~/.ssh/authorized_keys'

# Установка Java и Hadoop
echo "Установка Java и скачивание Hadoop"
sudo apt update
sudo apt install -y openjdk-11-jdk
sudo -i -u hadoop bash -c '
wget https://dlcdn.apache.org/hadoop/common/hadoop-3.4.0/hadoop-3.4.0.tar.gz -P /home/hadoop
tar -xvzf /home/hadoop/hadoop-3.4.0.tar.gz -C /home/hadoop
'

# Настройка переменных окружения
echo "Настройка переменных окружения"
sudo -i -u hadoop bash -c '
echo "export HADOOP_HOME=/home/hadoop/hadoop-3.4.0" >> ~/.profile
echo "export JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:/bin/java::")" >> ~/.profile
echo "export PATH=\$PATH:\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin" >> ~/.profile
source ~/.profile
'

# Конфигурация Hadoop
echo "Настройка файлов Hadoop"
sudo -i -u hadoop bash -c '
cat <<EOT > $HADOOP_HOME/etc/hadoop/core-site.xml
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://team-27-nn:9000</value>
    </property>
</configuration>
EOT

cat <<EOT > $HADOOP_HOME/etc/hadoop/hdfs-site.xml
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>3</value>
    </property>
</configuration>
EOT

cat <<EOT > $HADOOP_HOME/etc/hadoop/workers
team-27-nn
team-27-dn-00
team-27-dn-01
EOT
'

# Форматирование NameNode (выполнять только на NameNode)
if [[ "$HOSTNAME" == "team-27-nn" ]]; then
    echo "Форматирование NameNode"
    sudo -i -u hadoop bash -c 'cd $HADOOP_HOME && bin/hdfs namenode -format'
fi

# Запуск HDFS
echo "Запуск HDFS сервисов"
sudo -i -u hadoop bash -c 'start-dfs.sh'

# Настройка и перезапуск Nginx (только на Jump Node)
if [[ "$HOSTNAME" == "team-27-jn" ]]; then
    echo "Настройка и перезапуск Nginx"
    sudo bash -c 'cat <<EOT > /etc/nginx/sites-available/nn
server {
    listen 9870 default_server;
    proxy_pass http://team-27-nn:9870;
}
EOT'
    sudo ln -s /etc/nginx/sites-available/nn /etc/nginx/sites-enabled/nn
    sudo systemctl reload nginx
fi

echo "Развертывание Hadoop завершено!"

