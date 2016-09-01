#!/bin/bash
JAVA_OPTS="$JAVA_OPTS -Dfcrepo.modeshape.configuration=classpath:config/minimal-default/repository.json -Dfcrepo.home=/mnt/ingest"
export JAVA_OPTS
echo $JAVA_OPTS
