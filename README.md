Container Image
```
docker.io/runpod/base:0.5.1-cpu
```

Container Start Command

```
bash -lc "[ -d /workspace/runpod_data_test/.git ] || git clone https://github.com/acceleratescience/runpod_data_test.git /workspace/runpod_data_test && cd /workspace/runpod_data_test && chmod +x start_jupyter.sh start_code_server.sh clone_repo.sh && bash clone_repo.sh && bash start_jupyter.sh && bash start_code_server.sh && tail -f /dev/null"
```
