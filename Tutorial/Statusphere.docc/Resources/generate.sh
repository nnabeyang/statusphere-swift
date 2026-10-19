cd StatusphereKit
swift package --disable-experimental-prebuilts plugin \
  --allow-writing-to-package-directory \
  --allow-network-connections all:443 \
  swift-atproto
