# Building a Network Services Orchestrator (NSO) container

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
Note the optional NSO version (default 5.4.2), server port (default 48888), and Dockerfile (default Dockerfile.script)
arguments.

If you don't want to use the script, use the ```install-files``` directory as the Docker build context
and do the build from there:
```commandline
cd ./install-files
docker build --build-arg build_date=$(date -u +'%Y-%m-%dT%H:%M:%SZ') --build-arg nso_ver=<NSOver> -t nso-test .
```

Note the container is set up to accept a git username and token for authentication if needed
(to access private package repos for example). Just pass ```GIT_USERNAME``` and ```OAUTH_TOKEN```
environment variables when launching.

For example, to run it interactively with a username+token:
```commandline
docker run -it --rm -e GIT_USERNAME=<username> -e OAUTH_TOKEN=<token> nso-test
```

Once launched, you can proceed with the initial NSO setup. Note ```ncs-run``` is a common naming convention
for where NSO will store its operational data (you could call it whatever you want):
```commandline
ncs-setup --dest ncs-run
```

Or you could clone a git-based project into the container and update it to run a series of tests.
For example:
```commandline
git clone https://$OAUTH_TOKEN:x-oauth-basic@https://github.com/ciscops/NSO-sample-project ncs-run
```

You may need to pull any submodules if the local project packages are set up that way:
```commandline
git clone --recurse-submodules https://$OAUTH_TOKEN:x-oauth-basic@https://github.com/ciscops/NSO-sample-project ncs-run
```

