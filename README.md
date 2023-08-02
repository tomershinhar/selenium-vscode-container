# selenium-vscode-container
this repo contains the needed files to build an run a container-image that has both selenium web driver and vs-code web server

to build the image, clone the repo and run:
```bash
docker build -t {name} -f Dockerfile .
```

then to run it:
```bash
docker run -it --shm-size=2g -p 4444:4444 -p 5999:5999 {name}
```

alternatively, a pre built image can be pulled from quay:

```bash
docker run -it --shm-size=2g -p 4444:4444 -p 5999:5999 quay.io/tshinhar/selenium-vscode
```

when the container starts, it will automatically start all the needed services.

you can connect to the container using a vnc client on port 5999 and see what happens in the container
the vs-code server runs on port 8080 and selenium runs on port 4444
