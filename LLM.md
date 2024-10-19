# 📝LLM

## 🦙 Ollama

**Chat**

- Current chat LLM: [Replete-LLM-V2.5-Qwen-14b-q4_K_M](https://huggingface.co/bartowski/Replete-LLM-V2.5-Qwen-14b-GGUF)
- Current coding LLM: [Qwen2.5-coder:7b-Instruct-q6_K](https://huggingface.co/bartowski/Qwen2.5-Coder-7B-Instruct-GGUF)

**Image Generation**

- Current LLM: [Dreamshaper XL 2.1 Turbo](https://civitai.com/models/112902/dreamshaper-xl)
- LORAs: [Detailed Style XL](https://civitai.com/models/421162/detailed-style-xl-hand-focus-all-in-one-detailed-perfection-style-extension?modelVersionId=469308) and [Detailed Perfection Style XL](https://civitai.com/models/411088/detailed-perfection-style-xl-hands-feet-face-body-all-in-one?modelVersionId=458257)
- Negative embeddings: [BadDream + UnrealisticDream](https://civitai.com/models/72437?modelVersionId=77173) and [FastNegativeV2](https://civitai.com/models/71961/fast-negative-embedding)
- Upscaler: RealESRGAN x2

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

## 🖼️Comfy UI

Install [ComfyUI](https://github.com/comfyanonymous/ComfyUI) and [ComfyUI-Manager](https://github.com/ltdrdata/ComfyUI-Manager) according to the instructions. Copy [./llm/pyproject.toml] to the `ComfyUI` directory and run `uv sync`. Enable `Dev Mode`.

[Custom plist](./llm/com.joncrangle.llm.plist) can be moved to `~/Library/LaunchAgents` to automatically start on login listening on `0.0.0.0` for local network access.

- Current workflow: [Dreamshaper](./llm/dreamshaper-workflow-api.json)
- Custom nodes (use ComfyUI-Manager to install):
 - ComfyUI Impact Pack
 - WAS Node Suite
 - rgthree's ComfyUI Nodes
 - ComfyUI-Custom-Scripts
 - ComfyUI MLX Nodes

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
