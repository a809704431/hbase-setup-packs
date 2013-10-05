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

if [ "$1" = "sss" ]; then
   login_usr=`whoami`
   cd /home/$login_usr
   rm -rf .ssh
   /usr/local/hbase-setup-packs/bin/gen_ssh.sh
   chmod 700 .ssh
   cd .ssh
   touch authorized_keys
   cat id_rsa.pub > authorized_keys
   chmod 600 authorized_keys
   cd ~  
elif [ "$1" = "second" ]; then 
   source /etc/profile
   cd /usr/local/hbase-setup-packs/bin
   ./setup.sh second $2
else
   source /etc/profile
   cd /usr/local
   tar zxvf /usr/local/hbase-packs.tar.gz
   cd /usr/local/hbase-setup-packs/bin
   ./setup.sh init $1
fi
