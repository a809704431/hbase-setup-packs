#!/usr/local/bin/expect
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


spawn ssh-keygen -t rsa

expect {
    "id_rsa):" {send "\r";exp_continue}
    "passphrase):" {send "\r";exp_continue}
    "again:" {send "\r";exp_continue}
}
