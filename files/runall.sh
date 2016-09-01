#!/usr/bin/with-contenv sh
if [ -z ${KARAF_CONFIG} ]; then
   echo "==> Configuring Karaf ..."
   echo "start karaf client; install wrapper ..."
   /opt/karaf/bin/client -f /root/karaf_service.script
   
   echo "wrapper installed..."
   export KARAF_CONFIG=1
   printf "%s" "${KARAF_CONFIG}" > /var/run/s6/container_environment/KARAF_CONFIG
fi

#/opt/karaf/bin/stop
#ln -s /opt/karaf/bin/karaf-service /etc/init.d/
#update-rc.d karaf-service defaults 
#sed -i "s|#org.ops4j.pax.url.mvn.localRepository=|org.ops4j.pax.url.mvn.localRepository=~/.m2/repository|" /opt/karaf/etc/org.ops4j.pax.url.mvn.cfg
#/opt/karaf/bin/start
#sleep 60
/root/fedora_camel_toolbox.sh
cd $CATALINA_HOME
catalina.sh run
