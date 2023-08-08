#!/bin/bash

set -x

if [ "$#" -lt 1 ]; then
  echo "Secrets Store Json input file not given"
  exit 1
fi

jsonFileName=$1
echo "Input Json file $jsonFileName"

ts=$(date +"%y_%d_%m_%H_%M_%S")

modJsonFile=/tmp/ub_modJson_"$ts"
tr -d '\n' < "$jsonFileName" > "$modJsonFile"

outCmFilename=/tmp/ub_secrets_store_cm_"$ts".yaml
echo "cm file $outCmFilename"

cat > "$outCmFilename" << 'CMEOF'
kind: ConfigMap
apiVersion: v1
metadata:
  name: secrets-stores-config
data:
  SECRETS_STORES_ACCESS_INFO_JSON: |
CMEOF

cat "$modJsonFile" >> "$outCmFilename"

kubectl apply -f $outCmFilename
rm "$modJsonFile"
rm "outCmFilename"

echo "DONE"
