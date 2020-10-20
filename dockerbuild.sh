#!/usr/bin/env bash
# Create container image for Cisco NSO
# Inspiration: https://opensource.com/article/20/5/optimize-container-builds
set -e

USAGE="Usage: $0 <FileServerIP> [--nsoVer <NSOver>] [--serverPort <FileServerPort>]"

nsoVer=${nsoVer:-5.4.1.1}
serverIP=${1:-0.0.0.0}
serverPort=${serverPort:-48888}
IMAGE_TAG=nso-test
NSO_URL=https://earth.tail-f.com:8443/ncs/

while [ $# -gt 0 ]; do
  if [[ $1 == *"--"* ]]; then
    param="${1/--/}"
    declare $param="$2"
  fi
  shift
done

if [ "$serverIP" = "0.0.0.0" -o "$serverIP" = "127.0.0.1" -o "$serverIP" = "localhost" ]; then \
  echo "You need to supply a local server IP, otherwise wget for resources in the Dockerfile will likely fail"
  echo $USAGE
  exit 1
fi

# Stop local HTTP server in case it was already running
(kill -9 `ps -ef | grep http.server | grep $serverPort | awk '{print $2}'`) || true

# Pull NSO installer
NSO_FILE=nso-$nsoVer.linux.x86_64.installer.bin
#curl -k -u user:pass --output ./install-files/$NSO_FILE $NSO_URL/$NSO_FILE

# Start a local HTTP server to serve files from the 'install-files' directory. Place
# the NSO installer there, along with anything else required
python3 -m http.server -d ./install-files $serverPort &

# The build date must be from RFC 3339, the date-time string
docker image build -f ./Dockerfile.script \
   --build-arg build_date=$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
   --build-arg nso_ver=$nsoVer \
   --build-arg file_server=$serverIP:$serverPort -t $IMAGE_TAG .

# Stop local HTTP server
kill -9 `ps -ef | grep http.server | grep $serverPort | awk '{print $2}'`
