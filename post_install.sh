PRODUCT='NAKIVO Backup & Replication (Beta)'

#URL="http://10.10.18.60:208/11.3.0.107585.sh"
#SHA256="5eb580350f0ac03173a78c33a9c6c7f12d2c5769464de7a9f724ad98e9f8a97c"
#URL="http://10.10.18.60:208/11.2.1.105491.sh"
#SHA256="c834ba8c06b4845e6e87ea298c8c38ed281d7827371d10104f069bc3df0d55d4"

#URL="http://10.10.18.60:208/11.2.2.108114.sh"
#SHA256="737fb2b318773eea5c4b9f22fa7b396f6417f4c459412227ae19677505997554"

URL="http://10.10.18.60:208/11.3.0.108127.sh"
SHA256="999b5b754c4e81b9ea7fa507cce7bd99deb255c7f1ebef0f24519caa62a1a666"


PRODUCT_ROOT="/usr/local/nakivo"
INSTALL="inst.sh"

fetch --no-verify-peer -o $INSTALL "$URL"
if [ $? -ne 0 -o ! -e $INSTALL ]; then
    echo "ERROR: Failed to get $PRODUCT installer"
    rm $INSTALL >/dev/null 2>&1
    exit 1
fi

CHECKSUM=`sha256 -q $INSTALL`
if [ "$SHA256" != "$CHECKSUM" ]; then
    echo "ERROR: Incorrect $PRODUCT installer checksum"
    rm $INSTALL >/dev/null 2>&1
    exit 2
fi

sh ./$INSTALL -f -y -i "$PRODUCT_ROOT" --eula-accept --extract 2>&1
if [ $? -ne 0 ]; then
    echo "ERROR: $PRODUCT install failed"
    rm $INSTALL >/dev/null 2>&1
    exit 3
fi
rm $INSTALL >/dev/null 2>&1

#disable default HTTP ports redirect
SVC_PATH="$PRODUCT_ROOT/director"
awk 'BEGIN{A=0} /port="80/{A=1} {if (A==0) print $0} />/{A=0}' $SVC_PATH/tomcat/conf/server-linux.xml >$SVC_PATH/tomcat/conf/server-linux.xml_ 2>/dev/null
mv $SVC_PATH/tomcat/conf/server-linux.xml_ $SVC_PATH/tomcat/conf/server-linux.xml >/dev/null 2>&1

#enforce EULA
PROFILE=`ls "$SVC_PATH/userdata/"*.profile 2>/dev/null | head -1`
if [ "x$PROFILE" != "x" ]; then
    sed -e 's@"system.licensing.eula.must.agree": false@"system.licensing.eula.must.agree": true@' "$PROFILE" >"${PROFILE}_" 2>/dev/null
    mv "${PROFILE}_" "$PROFILE" >/dev/null 2>&1
fi

service nkv_dirsvc start >/dev/null 2>&1
