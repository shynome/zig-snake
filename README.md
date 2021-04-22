# 简介

测试 zig 和 wasm 的集成

# 预览

```sh
# 生成 wasm 文件
make wasm
caddy file-server -listen 127.0.0.1:8081 -root docs/
```

打开本地: <http://127.0.0.1:8081/>
