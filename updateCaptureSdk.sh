#!/bin/sh -eul
rm -fdr src/ios/sdk-copy
mv src/ios/sdk src/ios/sdk-copy
git clone git@github.com:SocketMobile/cocoapods-capturesdk.git src/ios/sdk
rm -fdr src/ios/sdk/.git
rm src/ios/sdk/lib/.gitkeep
