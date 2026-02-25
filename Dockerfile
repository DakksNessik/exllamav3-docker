# Build and run Exllamav3 from Docker to Convert Models to exl3 format.
# Update: 2026/01/20
# CREATOR: jsims@crazygnome.com
# docker build -f ./Dockerfile -t exllamav3:latest ./build
# docker run -d  -e USER_UID=1000 -e INPUT=/content/model -e OUTPUT=/content/output -e BITS=8 -e HEAD_BITS=8 -e HF_USERNAME=anonymous -e HF_TOKEN=HF-TOKEN-HERE -v ./output:/content/output:rw --rm --name exllamav3 exllamav3:latest
FROM nvidia/cuda:12.8.1-cudnn-devel-ubuntu24.04
ARG USER_UID=1000 USER_GID=$USER_UID MODE755=755 VIRTUAL_ENV=/opt/python-venv VIRTUAL_ENV_BIN=$VIRTUAL_ENV/bin PATH=$VIRTUAL_ENV_BIN:$PATH MAX_JOBS=1
ENV DEBIAN_FRONTEND=noninteractive USER_UID=${USER_UID:-1000} USER_GID=${USER_GID:-1000} VIRTUAL_ENV=${VIRTUAL_ENV:-/opt/python-venv} VIRTUAL_ENV_BIN=$VIRTUAL_ENV/bin PATH=$VIRTUAL_ENV_BIN:$PATH MAX_JOBS=${MAX_JOBS:-1}
COPY --chown=$USER_UID:$USER_GID --chmod=$MODE755 entrypoint.sh /usr/local/bin/entrypoint.sh
RUN apt-get update && apt-get install --no-install-recommends -y \
    git \
    python3.12 \
    python3.12-dev \
    python3-pip \
    python3-venv \
    python-is-python3 \
    && rm -rf /var/log/apt/* /etc/apt/sources.list.d/* \
    && apt-get purge -y \
    && apt-get autoremove -y \
    && apt-get autoclean -y \
    && rm -rf /var/lib/apt/lists/* \
    && python -m venv $VIRTUAL_ENV \
    && chmod +x /usr/local/bin/entrypoint.sh \
    && mkdir /content \
    && chown -fR $USER_UID:$USER_GID /content $VIRTUAL_ENV \
    && pip -v install -U pip setuptools wheel ninja packaging psutil \
    && pip -v install -U huggingface_hub
RUN pip -v install -U torch torchvision --index-url https://download.pytorch.org/whl/cu128
RUN pip -v install -U https://github.com/Dao-AILab/flash-attention/releases/download/v2.8.3/flash_attn-2.8.3+cu12torch2.9cxx11abiTRUE-cp312-cp312-linux_x86_64.whl
RUN pip -v install -U https://github.com/turboderp-org/exllamav3/releases/download/v0.0.22/exllamav3-0.0.22+cu128.torch2.9.0-cp312-cp312-linux_x86_64.whl
RUN python -v -m pip cache purge
# Endpoint
USER $USER_UID:$USER_GID
VOLUME ["/content/output","/content/input"]
WORKDIR ${VIRTUAL_ENV}/lib/python3.12/site-packages/exllamav3
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
