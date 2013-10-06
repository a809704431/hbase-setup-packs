#!/usr/bin/env bash
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#
# If this scripted is run out of /usr/bin or some other system bin directory
# it should be linked to and not copied. Things like java jar files are found
# relative to the canonical path of this script.
#
# Author:huanggang 
# Date  :2013/10/1
#

BASEDIR=`dirname $0`/..
BASEDIR=`(cd "$BASEDIR"; pwd)`
CONFDIR=$BASEDIR/conf
SRCDIR=$BASEDIR/src
BACKUPDIR=$BASEDIR/backup
CONF_BACKUP_FLAG="#SYS BACKUP DONE#"

auto_ssh() {
    expect -c "set timeout -1;
                spawn ssh -o StrictHostKeyChecking=no $2 ${@:3};
                expect {
                    *assword:* {send -- $1\r;
                                 expect {
                                    *denied* {exit 2;}
                                    eof
                                 }
                    }
                    eof         {exit 1;}
                }
                "
    return $?
}


auto_scp() {
    expect -c "set timeout -1;
                spawn scp -o StrictHostKeyChecking=no ${@:2};
                expect {
                    *assword:* {send -- $1\r;
                                 expect {
                                    *denied* {exit 1;}
                                    eof
                                 }
                    }
                    eof         {exit 1;}
                }
                "
    return $?
}


read_configs() {
    echo "Read setup config files from $CONFDIR"
    source /etc/profile
    source $CONFDIR/core.cfg
    echo "Read setup config files successfully" 
}


create_user() {
    echo "Create a user to install HBase cluster"
    if cat /etc/passwd | awk -F : '{print $1}' | grep $install_usr >/dev/null 2>&1 
    then
       /usr/sbin/userdel -r $install_usr
    fi
    /usr/sbin/groupadd $install_usr > /dev/null 2>&1
    /usr/sbin/useradd -g $install_usr $install_usr
    echo $install_pwd|/usr/bin/passwd --stdin $install_usr
    echo "User $install_usr have been added, done."  
}


copy_setup_packs() {
    cd $BASEDIR/..
    basename=`basename $BASEDIR`
    echo "Tar setup resoures, start."
    tar -czpf hbase-packs.tar.gz $basename
    mv hbase-packs.tar.gz /usr/local
    echo "Tar setup resoures, done."
    IPLIST=`sed -e "s/#.*//g" $CONFDIR/hosts | awk '{if (length !=0) print $1}'`
    for ip in $IPLIST; do
       auto_scp $root_pwd "$BASEDIR/bin/remote_guide.sh" "root@$ip:/usr/local"
       if [ $ip == $master_host ];then
          continue
       fi
       auto_scp $root_pwd "/usr/local/hbase-packs.tar.gz" "root@$ip:/usr/local"
    done
    cd $BASEDIR
}


backup_files() {
   if [ `cat /etc/profile|grep "$CONF_BACKUP_FLAG"|wc -l` -eq 1 ]; then
       echo "Sys config files backuped, skip it."
       return
   fi
   cp /etc/security/limits.conf $BACKUPDIR/
   cp /etc/hosts                $BACKUPDIR/
   cp /etc/profile              $BACKUPDIR/
   cp /etc/sysconfig/network    $BACKUPDIR/
   echo $CONF_BACKUP_FLAG >> /etc/profile
   echo $CONF_BACKUP_FLAG >> /etc/hosts
   echo $CONF_BACKUP_FLAG >> /etc/security/limits.conf
   echo "Backup some sys files to $BACKUPDIR, done."
}


init_conf_node_params() {
   sed -i '/^'"$CONF_BACKUP_FLAG"'/,$d' /etc/security/limits.conf
   sed -i '/^'"$CONF_BACKUP_FLAG"'/,$d' /etc/hosts
   sed -i '/^'"$CONF_BACKUP_FLAG"'/,$d' /etc/profile
   echo $CONF_BACKUP_FLAG >> /etc/profile
   echo $CONF_BACKUP_FLAG >> /etc/hosts
   echo $CONF_BACKUP_FLAG >> /etc/security/limits.conf
   service iptables stop
   chkconfig iptables off
   cat $CONFDIR/hosts >> /etc/hosts
   echo "$install_usr soft nofile $ulimit_n"  >> /etc/security/limits.conf
   echo "$install_usr hard nofile $ulimit_n"  >> /etc/security/limits.conf
   echo "$install_usr soft nproc  $ulimit_u"  >> /etc/security/limits.conf
   echo "$install_usr hard nproc  $ulimit_u"  >> /etc/security/limits.conf
   ulimit -u
   ulimit -n
   cp /etc/security/limits.conf $SRCDIR/
   cp /etc/hosts                $SRCDIR/
   cp /etc/profile              $SRCDIR/
}


init_node_params() {
   service iptables stop
   chkconfig iptables off
   cp $SRCDIR/limits.conf     /etc/security/
   cp $SRCDIR/hosts           /etc/
   cp $SRCDIR/profile         /etc/
   sed -i '/^HOSTNAME=/cHOSTNAME='"$1"'' /etc/sysconfig/network
   hostname $1
   install_jdk $1 
   source /etc/profile
}


install_jdk() {
   echo "Install JDK with with the version $jdk_version for $1, please waiting..."
   cp $SRCDIR/$jdk_tar_name $jdk_path
   cd $jdk_path
   tar xf $jdk_path/$jdk_tar_name        
   echo "export JAVA_HOME=$jdk_path/$jdk_version" >> /etc/profile
   echo 'export PATH=$JAVA_HOME/bin:$PATH' >> /etc/profile
   echo 'export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar' >> /etc/profile
   source /etc/profile
}              


config_ssh() {   
   ip=`cat $CONFDIR/hosts| grep $1| awk '{print $1}'`
   auto_ssh $install_usr $install_usr@$ip "/usr/local/remote_guide.sh sss"
}

create_dirs() {
   rm -rf $hadoop_namenode_dir
   rm -rf $hadoop_datanode_dir
   rm -rf $hadoop_log_dir
   rm -rf $hadoop_tmp_dir
   rm -rf $zookeeper_data_dir
   rm -rf $zookeeper_log_dir
   rm -rf $hbase_log_dir
     
   mkdir -p $hadoop_namenode_dir
   mkdir -p $hadoop_datanode_dir
   mkdir -p $hadoop_log_dir
   mkdir -p $hadoop_tmp_dir
   mkdir -p $zookeeper_data_dir
   mkdir -p $zookeeper_log_dir
   mkdir -p $hbase_log_dir 

   chown -R $install_usr:$install_usr $hadoop_namenode_dir
   chown -R $install_usr:$install_usr $hadoop_datanode_dir
   chown -R $install_usr:$install_usr $hadoop_log_dir
   chown -R $install_usr:$install_usr $hadoop_tmp_dir
   chown -R $install_usr:$install_usr $zookeeper_data_dir
   chown -R $install_usr:$install_usr $zookeeper_log_dir
   chown -R $install_usr:$install_usr $hbase_log_dir
   echo "Have made needed dirs for you, please check it."
}


move_resources() {
   cd $SRCDIR
   echo "Move Hadoop&HBase&Zookeeper sources to home dir location."
   tar xf $hadoop_tar_name -C /home/$install_usr/
   tar xf $hbase_tar_name  -C /home/$install_usr/

   i=1
   for host in $zookeeper_quorums; do
      if [ $host = $1 ]; then
         tar xf $zookeeper_tar_name -C /home/$install_usr/
         touch $zookeeper_data_dir/myid
         echo $i > $zookeeper_data_dir/myid
      fi
      i=$(($i+1))
   done
   chown -R $install_usr:$install_usr /home/$install_usr/
}


install_expect() {
    echo "Install tcl and expect dependencies, start."
    cd $SRCDIR
    tar zxf tcl8.4.11-src.tar.gz
    cd tcl8.4.11/unix
    ./configure && make && make install
    cp tclUnixPort.h  ../generic/
    cd $SRCDIR
    tar zxf expect-5.43.0.tar.gz
    cd expect-5.43/
    ./configure --with-tcl=/usr/local/lib/ --with-tclinclude=$SRCDIR/tcl8.4.11/generic/  --with-x=no
    make && make install
    echo "Install tcl and expect dependencies successfuly"
}


login_nodes_first() {
    IPLIST=`sed -e "s/#.*//g" $CONFDIR/hosts | awk '{if (length !=0) print $1}'`
    for ip in $IPLIST; do
       vhost=`cat $CONFDIR/hosts| grep $ip| awk '{print $2}'`
       auto_ssh $root_pwd root@$ip "/usr/local/remote_guide.sh $vhost"
    done
}


login_nodes_second() {
    mv /home/$install_usr/.ssh/id_rsa.pub /usr/local/tmp.pub
    IPLIST=`sed -e "s/#.*//g" $CONFDIR/hosts | awk '{if (length !=0) print $1}'`
    for ip in $IPLIST; do
      if [ $master_host = $ip ]; then
          continue
       else
          auto_scp $root_pwd "/usr/local/tmp.pub" "root@$ip:/usr/local"
       fi
    done    
    for ip in $IPLIST; do
       auto_ssh $root_pwd root@$ip "/usr/local/remote_guide.sh second $ip"
    done
  
}

read_configs

if [ -f "/usr/local/bin/expect" ];  then
    echo "/usr/local/bin/expect exists, we now ignore to install it."
else
    install_expect
fi

if [ "$1" = "init" ]; then
   backup_files
   init_node_params $2
   create_user
   create_dirs
   move_resources $2
   config_ssh $2
elif [ "$1" = "second" ]; then
    IPLIST=`sed -e "s/#.*//g" $CONFDIR/hosts | awk '{if (length !=0) print $1}'`
    for ip in $IPLIST; do
       if [ $master_host = $ip ]; then
          continue 
       elif [ $ip = $2 ]; then
          cat /usr/local/tmp.pub >> /home/$install_usr/.ssh/authorized_keys
       fi   
    done
    echo -e "\e[1;42m Congratulations, we have setup HBase Cluster successfully,"\
            " please enjoy the NoSQL world. now we must reboot first, wait a minute.\e[0m"
    sleep 1
    reboot 
else
   echo  "====================================================================="
   echo "|               Welcome to use the HBase Setup Guide 1.0             |"
   echo "|                                                                    |"
   echo "|  Author:huanggang                                                  |"
   echo "|  Date  :2013-10-1                                                  |"
   echo  "====================================================================="     
   echo  -e "\n"  
   
   WHO=`whoami`
   if [ $WHO != "root" ]; then
       echo -e "\e[1;31m Sorry, only root account can you execute the setup operation.\e[0m"
       exit 1;
   fi
  
   IP_ADDR=`/sbin/ifconfig|awk '{if ( $1 == "inet" && $3 ~ /^Bcast/) print $2}'|cut -f2 -d ":"`
   if [ $IP_ADDR != $master_host ]; then
       echo -e "\e[1;31m Sorry, only on master ip $master_host host can you execute the setup scripts,"\
            " please notice that you are on $IP_ADDR host.\e[0m"
       exit 1;
   fi   

   chmod a+x $BASEDIR/bin/*   
   backup_files
   init_conf_node_params 
   copy_setup_packs
   login_nodes_first
   login_nodes_second
fi

