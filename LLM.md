# 📝LLM

## 🦙 Ollama

> [!NOTE]
To expose on local network, edit: `~/Library/LaunchAgents/homebrew.mxcl.ollama.plist` by adding the following:
```xml
<key>EnvironmentVariables</key>
<dict>
<key>OLLAMA_HOST</key>
<string>0.0.0.0</string>
</dict>
```

[Ollama](https://github.com/ollama/ollama) can be started as a service by running `brew services start ollama`.

## 💻 MLX-Textgen

[MLX-Textgen](https://github.com/nath1295/MLX-Textgen) is started automatically by [Custom plist](./llm/com.joncrangle.llm.plist) to expose a server on the local network using port `5001`.

[model_configs.yaml](./llm/model_configs.yaml) is used to configure the model to use MLX models. This file should be moved into the `MLX-Textgen` directory before starting the server.

## 🖼️Comfy UI

**Image Generation**

- Current LLM: [argmaxinc/mlx-FLUX.1-schnell-4bit-quantized](https://huggingface.co/argmaxinc/mlx-FLUX.1-schnell-4bit-quantized)
- Othr: [Dreamshaper XL 2.1 Turbo](https://civitai.com/models/112902/dreamshaper-xl)
  - LORAs: [Detailed Style XL](https://civitai.com/models/421162/detailed-style-xl-hand-focus-all-in-one-detailed-perfection-style-extension?modelVersionId=469308) and [Detailed Perfection Style XL](https://civitai.com/models/411088/detailed-perfection-style-xl-hands-feet-face-body-all-in-one?modelVersionId=458257)
  - Negative embeddings: [BadDream + UnrealisticDream](https://civitai.com/models/72437?modelVersionId=77173) and [FastNegativeV2](https://civitai.com/models/71961/fast-negative-embedding)
  - Upscaler: RealESRGAN x2

Install [ComfyUI](https://github.com/comfyanonymous/ComfyUI) and [ComfyUI-Manager](https://github.com/ltdrdata/ComfyUI-Manager) according to the instructions. Copy [./llm/pyproject.toml] to the `ComfyUI` directory and run `uv sync`. Enable `Dev Mode`.

[Custom plist](./llm/com.joncrangle.llm.plist) can be moved to `~/Library/LaunchAgents` to automatically start on login listening on `0.0.0.0` for local network access.

- Current workflow: [Flux.1 Schnell](./llm/flux-workflow-api.json)
- Custom nodes (use ComfyUI-Manager to install):
 - ComfyUI Impact Pack
 - WAS Node Suite
 - rgthree's ComfyUI Nodes
 - ComfyUI-Custom-Scripts
 - ComfyUI MLX Nodes
 - ComfyUI Easy Use

## 💬 OpenWebUI

[OpenWebUI](https://openwebui.com/) can be hosted as a docker container:

```dockerfile
  open-webui:
    image: ghcr.io/open-webui/open-webui:main
    container_name: open-webui
    volumes:
      - open-webui:/app/backend/data
    ports:
      - 11434:8080
    environment:
      - OLLAMA_BASE_URL=${OLLAMA_BASE_URL} # http://IP:11434
      - ENABLE_IMAGE_GENERATION=True
      - IMAGE_GENERATION_ENGINE=comfyui
      - COMFYUI_BASE_URL=${COMFYUI_BASE_URL} # http://IP:8188/
      - IMAGE_SIZE=1024x768
    restart: always
    labels:
      - traefik.enable=true
      - traefik.http.routers.open-webui.rule=Host(`open-webui.${HOST_NAME}`)
      - traefik.http.routers.open-webui.tls=true
      - traefik.http.routers.open-webui.tls.certresolver=myresolver
      - traefik.http.services.open-webui.loadbalancer.server.port=8080
      - homepage.group=Utilities
      - homepage.name=Open WebUI
      - homepage.icon=open-webui.png
      - homepage.href=https://open-webui.${HOST_NAME}
      - homepage.description=Open WebUI
      - homepage.weight=1
```

> [!TIP]
> Generate Modelfiles for the LLMs with the following format to use multiple GPU threads:
> ```
> FROM deepseek-coder-v2:16b-lite-instruct-q3_K_M
> PARAMETER num_gpu 99
> ```

- [Template Modelfile for Qwen2.5](./llm/Modelfile)
- [Functions Export](./llm/functions.json)
- [Tools Export](./llm/tools.json)
