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


echo "Read config from $CONFDIR"
source /etc/profile
source $CONFDIR/core.cfg
echo "Read config successfully" 

IPLIST=`sed -e "s/#.*//g" $CONFDIR/hosts | awk '{if (length !=0) print $1}'`
for ip in $IPLIST; do
   if [ $ip == $master_host ];then
      continue
   fi
   echo "Sending command to $ip..., sync hadoop conf"
   rsync -vaz $CONFDIR/hadoop/conf $ip:/home/$install_usr/$hadoop_version/
   echo "Sending command to $ip..., sync hbase conf"
   rsync -vaz $CONFDIR/hbase/conf $ip:/home/$install_usr/$hbase_version/
done

for host in $zookeeper_quorums; do
   echo "Sending command to $ip..., sync zookeeper conf"
   rsync -vaz $CONFDIR/zookeeper/conf $host:/home/$install_usr/$zookeeper_version/
done

echo "done."
