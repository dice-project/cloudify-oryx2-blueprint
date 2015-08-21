#!/usr/bin/env bash

set -e

export ORYX_BIN=~/oryx
mkdir -p ${ORYX_BIN}
cd ${ORYX_BIN}

# for asset in $(wget -qO- https://api.github.com/repos/OryxProject/oryx/releases/latest | grep -Po 'browser_download_url": "\K[^"]+'); do
#     wget ${asset}
#     if [[ ${asset##*.} == "sh" ]]; then
#         chmod +x ${asset##*/}
#     fi
# done

# Hardcoded because I test too much and the API hates me
assets="https://github.com/OryxProject/oryx/releases/download/oryx-2.0.0-beta-1/compute-classpath.sh
https://github.com/OryxProject/oryx/releases/download/oryx-2.0.0-beta-1/oryx-batch-2.0.0-beta-1.jar
https://github.com/OryxProject/oryx/releases/download/oryx-2.0.0-beta-1/oryx-run.sh
https://github.com/OryxProject/oryx/releases/download/oryx-2.0.0-beta-1/oryx-serving-2.0.0-beta-1.jar
https://github.com/OryxProject/oryx/releases/download/oryx-2.0.0-beta-1/oryx-speed-2.0.0-beta-1.jar"
for asset in $(echo ${assets}); do
    wget ${asset}
    if [[ ${asset##*.} == "sh" ]]; then
        chmod +x ${asset##*/}
    fi
done
