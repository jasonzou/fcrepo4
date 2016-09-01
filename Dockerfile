FROM localhost:5000/openjdk8

MAINTAINER Jason Zou <jason.zou@gmail.com>

# Install essential packages
ENV MVN_VERSION 3.3.9
ENV M2_HOME=/opt/mvn

RUN set -x && \
    mkdir -p /tmp && \
    mkdir -p "$M2_HOME" && \
    cd /tmp && \
    wget http://apache.mirror.rafal.ca/maven/maven-3/$MVN_VERSION/binaries/apache-maven-$MVN_VERSION-bin.tar.gz -O /tmp/apache-maven.tar.gz && \
    tar -xvf /tmp/apache-maven.tar.gz && \
    rm apache-maven.tar.gz  && \
    mv apache-maven-$MVN_VERSION $M2_HOME && \
    mv $M2_HOME/apache-maven-$MVN_VERSION/* $M2_HOME && \
    rm -f -R  $M2_HOME/apache-maven-$MVN_VERSION

ENV JAVA_HOME=/usr/lib/jvm/java-1.8-openjdk
ENV JAVA=$JAVA_HOME/bin/java
ENV M2=$M2_HOME/bin
ENV PATH $PATH:$JAVA_HOME:$JAVA:$M2_HOME:$M2

ENV CATALINA_HOME /opt/tomcat7
ENV PATH $CATALINA_HOME/bin:$PATH
ENV TOMCAT_MAJOR 7
ENV TOMCAT_VERSION 7.0.70
ENV TOMCAT_TGZ_URL http://archive.apache.org/dist/tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz

RUN mkdir -p "$CATALINA_HOME" \
  && cd $CATALINA_HOME \
  && set -x \
  && curl -fSL "$TOMCAT_TGZ_URL" -o $CATALINA_HOME/tomcat.tar.gz \
  && tar -xvf $CATALINA_HOME/tomcat.tar.gz \
  && rm tomcat.tar.gz* \
  && mv apache-tomcat-$TOMCAT_VERSION $CATALINA_HOME \
  && mv $CATALINA_HOME/apache-tomcat-$TOMCAT_VERSION/* $CATALINA_HOME \
  && rm -f -R  $CATALINA_HOME/apache-tomcat-$TOMCAT_VERSION

COPY rootfs/logging.properties ${CATALINA_HOME}/conf/logging.properties
COPY rootfs/server.xml ${CATALINA_HOME}/conf/server.xml

# Make the ingest directory
RUN mkdir /mnt/ingest 
VOLUME /mnt/ingest

# Install Fedora4
ENV FEDORA_VERSION 4.6.0
ENV FEDORA_TAG 4.6.0

RUN mkdir -p /opt/tomcat7/fcrepo4-data \
  && chmod g-w /opt/tomcat7/fcrepo4-data \
  && cd /tmp \
  && curl -fSL https://github.com/fcrepo4-exts/fcrepo-webapp-plus/releases/download/fcrepo-webapp-plus-$FEDORA_TAG/fcrepo-webapp-plus-$FEDORA_VERSION.war -o fcrepo.war \
  && cp fcrepo.war /opt/tomcat7/webapps/fcrepo.war 

# Install Solr
ENV SOLR_VERSION 4.10.3
ENV SOLR_HOME /opt/tomcat7/solr

RUN cd /tmp \
  && curl -fSL http://archive.apache.org/dist/lucene/solr/$SOLR_VERSION/solr-$SOLR_VERSION.tgz -o solr-$SOLR_VERSION.tgz \
  && curl -fSL http://repo1.maven.org/maven2/commons-logging/commons-logging/1.1.2/commons-logging-1.1.2.jar -o commons-logging-1.1.2.jar \
  && mkdir -p "$SOLR_HOME" \
  && tar -xzf solr-"$SOLR_VERSION".tgz \
  && cp -v /tmp/solr-"$SOLR_VERSION"/dist/solr-"$SOLR_VERSION".war /opt/tomcat7/webapps/solr.war \
  && cp "commons-logging-1.1.2.jar" /opt/tomcat7/lib \
  && cp /tmp/solr-"$SOLR_VERSION"/example/lib/ext/slf4j* /opt/tomcat7/lib \
  && cp /tmp/solr-"$SOLR_VERSION"/example/lib/ext/log4j* /opt/tomcat7/lib \
  && cp -Rv /tmp/solr-"$SOLR_VERSION"/example/solr/* $SOLR_HOME \
  && touch /opt/tomcat7/velocity.log 

# Install Fuseki 2.3.1 (2.4.0 does not work)
ENV FUSEKI_VERSION 2.3.1
ENV FUSEKI_BASE /opt/fuseki
ENV FUSEKI_DEPLOY /opt/tomcat7/webapps

RUN mkdir -p "$FUSEKI_BASE" && \
    mkdir -p "$FUSEKI_BASE"/configuration && \
    cd /tmp && \
    curl -fSL http://archive.apache.org/dist/jena/binaries/apache-jena-fuseki-$FUSEKI_VERSION.tar.gz -o apache-jena-fuseki-$FUSEKI_VERSION.tar.gz && \
    tar -xzvf apache-jena-fuseki-$FUSEKI_VERSION.tar.gz && \
    mv apache-jena-fuseki-"$FUSEKI_VERSION" jena-fuseki1-"$FUSEKI_VERSION" && \
    cp -R jena-fuseki1-$FUSEKI_VERSION/* $FUSEKI_BASE && \
    cd jena-fuseki1-"$FUSEKI_VERSION" && \
    mv -v fuseki.war $FUSEKI_DEPLOY 

COPY files/shiro.ini  ${FUSEKI_BASE}
COPY files/test.ttl  ${FUSEKI_BASE}/configuration/.

# Install Apache Karaf
ENV KARAF_VERSION 4.0.5

COPY files/karaf_service.script /root/

RUN cd /tmp && \
    wget -q -O "apache-karaf-$KARAF_VERSION.tar.gz" "http://archive.apache.org/dist/karaf/"$KARAF_VERSION"/apache-karaf-"$KARAF_VERSION".tar.gz" && \
    tar -zxvf apache-karaf-$KARAF_VERSION.tar.gz && \
    mv /tmp/apache-karaf-$KARAF_VERSION /opt/karaf  

# JAVA_OPTS Tomcat7
COPY files/setenv.sh ${CATALINA_HOME}/bin/setenv.sh
COPY files/tomcat-users.xml ${CATALINA_HOME}/conf/.
RUN chmod a+x ${CATALINA_HOME}/bin/setenv.sh

# Fedora Camel Toolbox
COPY files/fedora_camel_toolbox.script /root/
COPY files/fedora_camel_toolbox.sh /root/

COPY files/runall.sh /root/
RUN chmod a+x /root/*sh

ADD rootfs /

WORKDIR $CATALINA_HOME
EXPOSE 8080

# Init Karaf and Launch Tomcat on startup
CMD bash /root/runall.sh
#${CATALINA_HOME}/bin/catalina.sh run
