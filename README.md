# Network Services Orchestrator (NSO) container

## Building
First you need the Linux installer for the target NSO release from [Cisco](https://software.cisco.com/download/home).
Then you have two options for building the container, either use the ```dockerbuild.sh``` script or call
```docker build``` directly. Using the script will result in a slightly smaller container image as it pulls
the install files from a local temporary HTTP server instead of including those files in the Docker context
and doing additional COPY operations in the Dockerfile.

First, put the non-signed NSO installer in the ```install-files``` directory. If you need to unpack it first
from a signed installer, do:
```commandline
sh ./<signed installer> --skip-verification
```

If you want to use the script, run:
```commandline
./dockerbuild.sh <local server IP> [--nsoVer <NSOver>] [--serverPort <FileServerPort>] [--dockerfile <Dockerfile>]
```
Note the optional NSO version (default 5.4.4.3), server port (default 48888), and Dockerfile (default Dockerfile.script)
arguments. There are some additional optional arguments if you look at the script.

If you don't want to use the script, use the ```install-files``` directory as the Docker build context
and do the build from there:
```commandline
cd ./install-files
NSOver=<NSOver> docker build --build-arg build_date=$(date -u +'%Y-%m-%dT%H:%M:%SZ') --build-arg nso_ver=$NSOver -t $USER/nso:$NSOver .
```
You can override any of the other ```ARG``` defaults in the Dockerfile with additional ```--build-arg```.

## Running the container
It's strongly recommended you launch the container non-interactively so logging and child process exits are
handled properly. For example (with randomly-assigned ports):
```commandline
docker run -d --rm -P --name nso-test <image>
```

Once launched, you can ```exec``` into the running container as the "ncsadmin" user:
```commandline
docker exec -it -u ncsadmin nso-test /bin/bash
```

To stop/shutdown the container:
```commandline
docker container stop nso-test
```

## NSO setup
Once you're in the running container, you can proceed with the initial NSO setup for an NSO local install. Note
```ncs-run``` is a common naming convention for the directory where a local install of NSO will store its operational
data, but you could call it whatever you want:
```commandline
ncs-setup --dest ./ncs-run
cd ./ncs-run
ncs
ncs_cli -Cu admin
```

## Build and run for an NSO system install
This is still a bit experimental. The alternate ```Dockerfile.script.system``` can support both local and system
installs. For system:
```commandline
./dockerbuild.sh <local server IP> [--nsoVer <NSOver>] --dockerfile Dockerfile.script.system --nsoInstallType system
```
To run the container:
```commandline
docker run -d --rm -P --name nso-system-test <image>
```
NSO should start automatically when the container is launched. Then exec in as before:
```commandline
docker exec -it -u ncsadmin nso-test /bin/bash
```
When stopping/shutting down the container, make sure you give NSO time to exit cleanly and close its database,
especially if you plan on restarting the container (or another instance) with the same data. The default Docker
stop timeout  should be fine:
```commandline
docker container stop nso-test
```
