#!/bin/bash
nohup jupyter lab \
  --ip=0.0.0.0 \
  --port=8888 \
  --no-browser \
  --allow-root \
  --NotebookApp.token='' \
  --NotebookApp.password='' \
  --ServerApp.token='' \
  --ServerApp.password='' \
  --ServerApp.base_url=/ \
  --ServerApp.trust_xheaders=True \
  --ServerApp.use_redirect_file=False \
  --ServerApp.allow_origin='*' \
  --ServerApp.allow_origin_pat='.*proxy\.runpod\.net' \
  --ServerApp.disable_check_xsrf=True \
  --ServerApp.root_dir=/workspace >/tmp/jupyter.log 2>&1 &
