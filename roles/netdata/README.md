# To build netdata for Ubuntu

```
apt-get -yqq install zlib1g-dev uuid-dev libmnl-dev gcc make git autoconf autoconf-archive autogen automake pkg-config curl debhelper dh-autoreconf dh-systemd
git clone https://github.com/firehol/netdata.git
cd netdata
./autogen.sh
./configure
make -C contrib debian/changelog
ln -s contrib/debian
dpkg-buildpackage -us -uc -rfakeroot
```
