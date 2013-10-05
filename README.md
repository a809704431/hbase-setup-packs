hbase-setup-packs
=================

一键式部署HBase集群，最大限度减少人为枯燥、繁琐的操作，只需简单几步配置，一切就交由脚本自动执行
方案亮点
1、只需准备好搭建所必须的JDK，Hadoop，HBase，Zookeeper包，并简单修改两个配置文件；
2、利用expect实现交互性操作的自动化，去除安装过程中人为值守协助操作过程；
3、对Hadoop，HBase，Zookeeper相关配置文件统一管理，修改主节点配置，同步一下完成

部署包整体结构
hbase-setup-packs
                                  |————src
                                  |                     |————zookeeper.tar.gz, hbase.tar.gz, hadoop.tar.gz
                                  |                     |_______expect.tar.gz,tcl.tar.gz
                                  |_______conf
                                  |                      |______core.cfg, hosts
                                  |                      |______zookeeper,hbase,hadoop/conf
                                  |_______bin
                                  |                      |______setup.sh
                                  |                      |______remote_guide.sh, rsync_conf.sh, gen_ssh.sh
                                  |                      |______mgr_cluster.sh
                                  |_______backup
                                                         |______hosts,profile,limits.conf,network

使用指南
       假设我们需要用192.168.70.128,192.168.70.129,10.28.192.70.130三台机器作为节点搭建集群，规划如下：
192.168.70.128     #nn,zk,hmaster
192.168.70.129     #dn,zk,rs
192.168.70.130     #dn,zk,rs

1、首先从【资源列表】中下载hbase-setup-packs.tar.gz，将其上传至拟搭建集群中准备作为HMaster的机器上，如192.168.70.128的/usr/local/目录，然后执行
[html] view plaincopy
[root@virt128 ~]# cd /usr/local/src  
[root@virt128 ~]# tar xvf hbase-setup-packs.tar.gz  
[root@virt128 ~]# cd hbase-setup-packs/conf  
 2、修改配置文件core.cfg和hosts
[html] view plaincopy
#!/usr/bin/env bash  
root_pwd=cdyanfa            #root账户密码  
install_usr=hdfs            #拟安装hbase集群的账户名称  
install_pwd=hdfs            #拟安装hbase集群的账户密码  
master_host=192.168.70.128  #作为hbase master的节点IP地址  
  
jdk_version=jdk1.6.0_25          #jdk版本名，一般以解压出来的名称为准  
jdk_tar_name=jdk1.6.0_25.tar.gz  #jdk安装包名称  
jdk_path=/usr/local              #jdk安装路径  
  
hadoop_version=hadoop-0.20.2-cdh3u3           #hadoop版本名，以解压出来的名称为准  
hadoop_tar_name=hadoop-0.20.2-cdh3u3.tar.gz   #hadoop安装包名称  
hadoop_namenode_dir=/export/hadoop/nn         #hadoop namenode数据存放路径  
hadoop_datanode_dir=/export/hadoop/dn         #hadoop datanode数据存放路径  
hadoop_log_dir=/export/hadoop/logs            #hadoop日志存放路径  
  
zookeeper_version=zookeeper-3.4.3             #zk版本名，以解压出来的名称为准  
zookeeper_quorums="node128 node129 node130"   #哪些主机需要安装zk，需要以主机名，逗号分隔，并以引号括起来  
zookeeper_tar_name=zookeeper-3.4.3.tar.gz     #zk安装包名称  
zookeeper_data_dir=/export/zookeeper/data     #zk数据存放路径  
zookeeper_log_dir=/export/zookeeper/logs      #zk日志存放路径  
   
hbase_version=hbase-0.94.5-security           #hbase版本名，以解压出来的名称为准  
hbase_tar_name=hbase-0.94.5-security.tar.gz   #hbase安装包名称  
hbase_log_dir=/export/hbase/logs              #hbase日志存放路径  
  
ulimit_n=65535   #hbase账户最大打开文件数  
ulimit_u=65535   #hbase账户最大进程数  
注：core.cfg

[html] view plaincopy
192.168.70.128 node128  #集群中IP及其主机名称列表，一行一个节点  
192.168.70.129 node129  
192.168.70.130 node130  
注：hosts

3、进入bin目录后，以root账户运行setup.sh脚本，如果以其他账户执行将会出现如下提示。且注意的是，安装开始阶段有些重要的系统配置信息文件将会被备份至/usr/local/hbase-setup-packs/backup/目录中，方便必要时恢复相关配置。


4、修改/usr/local/hbase-setup-packs/conf/hadoop/conf,/usr/local/hbase-setup-packs/conf/zookeeper/conf,/usr/local/hbase-setup-packs/conf/zookeeper/conf目录下对应hbase集群各个组件的配置信息，然后执行bin/rsync_conf.sh将配置信息同步到相关节点中。现在便已经完成整个安装配置过程。该版本暂时还没有写完bin/mgr_cluster.sh脚本，所以需要到指定节点上将hadoop,zookeepr,hbase启动，不久就只需通过bin/mgr_cluster.sh脚本去控制hbase集群启动和停止过程，敬请期待。