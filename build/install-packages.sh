set -e -x

source /etc/lsb-release

function apt_get() {
  apt-get -y --force-yes --no-install-recommends "$@"
}

function install_mysql_so_files() {
    mysqlpath="/usr/lib/x86_64-linux-gnu"
    if [ "`uname -m`" == "ppc64le" ]; then
        mysqlpath="/usr/lib/powerpc64le-linux-gnu"
    fi
    if [ "`uname -m`" == "armv7l" ]; then
        mysqlpath="/usr/lib/arm-linux-gnueabihf"
    fi
    apt_get install libmysqlclient-dev
    tmp=`mktemp -d`
    mv $mysqlpath/libmysqlclient* $tmp
    apt_get remove libmysqlclient-dev libmysqlclient18
    mv $tmp/* $mysqlpath/
}

arch="amd64"
if [ "`uname -m`" == "armv7l" ]; then
    arch="armhf"
fi

packages="
apt-transport-https
aptitude
autoconf
bison
build-essential
bzr
ca-certificates
cmake
curl
dconf-gsettings-backend
debianutils
dnsutils
fakeroot
flex
fuse-emulator-utils
gdb
git-core
gnupg-curl
gsfonts
imagemagick
iputils-arping
krb5-user
laptop-detect
ldap-utils
libaio1
libatm1
libavcodec54
libboost-iostreams1.54.0:"$arch"
libcurl4-openssl-dev
libcwidget3
libdirectfb-1.2-9
libdrm-intel1
libdrm-nouveau2
libdrm-radeon1
libept1.4.12:"$arch"
libfuse-dev
libgd2-noxpm-dev
libgmp-dev
libgpm2
libgtk-3-0
libicu-dev
liblapack-dev
libmagickwand-dev
libmariadbclient-dev
libncurses5-dev
libopenblas-dev
libpango1.0-0
libparse-debianchangelog-perl
libpq-dev
libreadline6-dev
libsasl2-dev
libsasl2-modules
libselinux1-dev
libsigc++-2.0-0c2a:"$arch"
libsqlite0-dev
libsqlite3-dev
libsysfs2
libxapian22
libxcb-render-util0
libxslt1-dev
libyaml-dev
lsof
lzma
manpages-dev
mercurial
mysql-client
mysql-common
ocaml-base-nox
openssh-server
perl
perl-base
perl-modules
pip
postgresql-client
psmisc
python-pip
python-dev
quota
redis-tools
rsync
sensible-utils
sshfs
sshpass
strace
subversion
sysstat
tasksel
tasksel-data
tcpdump
traceroute
ttf-dejavu-core
unzip
uuid-dev
virtualenv
wget
zip
"

if [ "`uname -m`" == "ppc64le" ] || [ "`uname -m`" == "armv7l" ]; then
packages=$(sed '/\b\(libopenblas-dev\|libdrm-intel1\|dmidecode\)\b/d' <<< "${packages}")
ubuntu_url="http://ports.ubuntu.com/ubuntu-ports"
else
ubuntu_url="http://archive.ubuntu.com/ubuntu"
fi

cat > /etc/apt/sources.list <<EOS
deb $ubuntu_url $DISTRIB_CODENAME main universe multiverse
deb $ubuntu_url $DISTRIB_CODENAME-updates main universe multiverse
deb $ubuntu_url $DISTRIB_CODENAME-security main universe multiverse
EOS

apt_get update
apt_get dist-upgrade
# TODO: deprecate libmysqlclient
install_mysql_so_files
apt_get install $packages ubuntu-minimal
apt-get clean

######
#
wget -q -O - https://packages.cloudfoundry.org/debian/cli.cloudfoundry.org.key | apt-key add -
echo "deb https://packages.cloudfoundry.org/debian stable main" | tee /etc/apt/sources.list.d/cloudfoundry-cli.list
apt_get update
apt_get install cf-cli

apt-get clean

wget --no-check-certificate -q -O /usr/bin/mc https://dl.minio.io/client/mc/release/linux-amd64/mc
chmod 755 /usr/bin/mc

VER=`curl -k -s https://s3.amazonaws.com/bosh-cli-artifacts/cli-current-version`
curl -k -s -Lo /usr/bin/bosh https://s3.amazonaws.com/bosh-cli-artifacts/bosh-cli-${VER}-linux-amd64
chmod 755 /usr/bin/bosh

VER=`curl -L -k -s https://github.com/vmware/govmomi/releases/latest | grep "<title>Release" | awk '{ print $2 }'`
curl -k -s -Lo /usr/bin/govc.gz https://github.com/vmware/govmomi/releases/download/${VER}/govc_linux_amd64.gz
gzip -d /usr/bin/govc.gz
chmod 755 /usr/bin/govc

VER=`curl -L -k -s https://github.com/pivotal-cf/om/releases/latest | grep "<title>Release" | awk '{ print $2 }'`
curl -k -s -Lo /usr/bin/om-linux https://github.com/pivotal-cf/om/releases/download/${VER}/om-linux
chmod 755 /usr/bin/om-linux

curl -k -s -Lo /usr/bin/jq https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64
chmod 755 /usr/bin/jq

#curl -k -s -Lo awscli-bundle.zip https://s3.amazonaws.com/aws-cli/awscli-bundle.zip
#unzip awscli-bundle.zip
#./awscli-bundle/install -i /usr/local/aws -b /usr/bin/aws
#rm -r -f awscli-bundle
 
#
######

rm -rf /usr/share/doc/* /usr/share/man/* /usr/share/groff/* /usr/share/info/* /usr/share/lintian/* /usr/share/linda/*

