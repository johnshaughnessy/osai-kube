#!/bin/bash

SCRIPT_DIR="$(dirname "$0")"
MANIFEST_DIR="$SCRIPT_DIR/../kubernetes-manifests"

config_encoded=$(base64 -w 0 $MANIFEST_DIR/secrets/gatekeeper-doodle-config.yaml)

cat <<EOF >$MANIFEST_DIR/secrets/gatekeeper-doodle-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: gatekeeper-doodle-secret
type: Opaque
data:
  config.yaml: $config_encoded
EOF

# echo "Secret manifest created: $MANIFEST_DIR/secrets/gatekeeper-doodle-secret.yaml"
