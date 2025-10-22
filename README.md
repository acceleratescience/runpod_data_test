### Container Start Command

```
bash -lc "[ -d /workspace/runpod_data_test/.git ] || git clone https://github.com/acceleratescience/runpod_data_test.git /workspace/runpod_data_test && cd /workspace/runpod_data_test && chmod +x start_jupyter.sh start_code_server.sh TODO.sh autocommit.sh && bash TODO.sh && bash start_jupyter.sh && bash start_code_server.sh && bash autocommit.sh && tail -f /dev/null"
```

Replace TODO with workshop-specific script

### GitHub token

https://github.com/settings/tokens/new