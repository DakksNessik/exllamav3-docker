#!/bin/bash
# Setting Enviroment Variables
VIRTUAL_ENV=${VIRTUAL_ENV:-/opt/python-venv}
VIRTUAL_ENV_BIN=$VIRTUAL_ENV/bin
PATH=$VIRTUAL_ENV_BIN:$PATH
INPUT="${INPUT:-/content/input}"
OUTPUT="${OUTPUT:-/content/output}"
TMP_DIR=$OUTPUT/.tmp
APP_DIR="${APP_DIR:-/opt/exllamav3}"
APP_TMP=$TMP_DIR/quant
SHARD_SIZE="${SHARD_SIZE-8192}"
BITS="${BITS:-8.0}"
HEAD_BITS="${HEAD_BITS:-6}"
EXL3_PM="${EXL3_PM:-false}"
EXL3_DL="${EXL3_DL:-0}"
exl3_args="-w $APP_TMP"
command=""
HF_USERNAME="${HF_USERNAME:-anonymous}"
HF_TOKEN=$HF_TOKEN
HF_MODEL=$HF_MODEL
HF_TMP=$INPUT/.hf
HF_WORKERS="${HF_WORKERS:-8}"
MODEL_AUTHOR=$(echo "$HF_MODEL" | cut -f1 -d '/')
MODEL_NAME=$(echo "$HF_MODEL" | cut -f2 -d '/')
FOLDER_NAME=$(echo "$MODEL_AUTHOR-$MODEL_NAME-exl3")
QUANT_NAME=$(echo "$MODEL_AUTHOR"-"$MODEL_NAME"_"$BITS"bpw_H"$HEAD_BITS"-exl3)
OUTPUT_MODEL=$(echo "$OUTPUT"/"$FOLDER_NAME")
OUTPUT_QUANT=$(echo "$OUTPUT_MODEL"/"$QUANT_NAME")
function set_options {
  [ ! -z "$INPUT" ] && exl3_args="${exl3_args} -i ${INPUT}"
  [ ! -z "$OUTPUT_QUANT" ] && exl3_args="${exl3_args} -o ${OUTPUT_QUANT}"
  [ ! -z "$SHARD_SIZE" ] && exl3_args="${exl3_args} -ss ${SHARD_SIZE}"
  [ ! -z "$BITS" ] && exl3_args="${exl3_args} -b ${BITS}"
  [ ! -z "$HEAD_BITS" ] && exl3_args="${exl3_args} -hb ${HEAD_BITS}"
  if [ "$EXL3_PM" = true ]; then
    exl3_args="${exl3_args} -pm -d ${EXL3_DL}"
  fi
}
function command_build {
  [ ! -z "$exl3_args" ] && command="python convert.py ${exl3_args}"
  [ -z "$command" ] && exit 1 || printf "Running the following exllamav3 convert command:\n%s\n" "$command"
}
function run_command {
  ${command}
}
function display_gpus {
   nvidia-smi -L
}
function hf_download {
  export HF_HUB_DOWNLOAD_TIMEOUT=60
  mkdir -p "$HF_TMP"
  hf download --max-workers "$HF_WORKERS" --token="$HF_TOKEN" --local-dir "$INPUT" --cache-dir "$HF_TMP" "$HF_MODEL"
}
function convert {
  mkdir -p "$APP_TMP"
  mkdir -p "$OUTPUT_QUANT"
  run_command
}
function clean_tmp {
  rm -rf "$TMP_DIR"
}
echo "Setting Global Environment Variables..."
export VIRTUAL_ENV=/opt/python-venv
export PATH="$VIRTUAL_ENV/bin:$PATH"
echo "Displaying a list of availible GPU(s)..."
display_gpus
echo "Starting Model Download from HuggingFace..."
hf_download
echo "Building exllamav3 convert command..."
set_options
command_build
echo "Starting the conversion of model..."
convert
#echo "Starting the cleanup of tmp Directory..."
clean_tmp
echo "Process has been completed. Please check for output."

