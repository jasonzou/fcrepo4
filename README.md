# FCREPO 4.6.0
FCREPO 4.6.0 on Alpine linux.
You need to change the first line of the DockerFile (find an openjdk alpine docker image for yourself).
## Build
``` console
docker build -t fcrepo4 .
```
## Run
``` console
docker run --rm -p 28080:8080 -t fcrepo4 
```
## Notice
Read (stole) a lot from yinlinchen/fcrepo4-docker:https://github.com/yinlinchen/fcrepo4-docker
