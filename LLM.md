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

## 💻 LM-Studio

[LM-Studio](https://lmstudio.ai/) should be configured to start a server on port `5001`.

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
> Generate Ollama Modelfiles for the LLMs with the following format to use multiple GPU threads:
>
> ```
> FROM deepseek-coder-v2:16b-lite-instruct-q3_K_M
> PARAMETER num_gpu 99
> ```

- [Template Modelfile for Qwen2.5](./llm/Modelfile)
- [Functions Export](./llm/functions.json)
- [Tools Export](./llm/tools.json)

### `Documents` Settings for embeddings

- Select embedding model. Current model is `sentence-transformers/all-MiniLM-L6-v2`.
- `Top K` is set to `10`, `Chunk Size` is set to `2000`, `Chunk Overlap` is set to `500`.

Prompt:

```text
**Generate Response to User Query**
**Step 1: Parse Context Information**
Extract and utilize relevant knowledge from the provided context within `<context></context>` XML tags.
**Step 2: Analyze User Query**
Carefully read and comprehend the user's query, pinpointing the key concepts, entities, and intent behind the question.
**Step 3: Determine Response**
If the answer to the user's query can be directly inferred from the context information, provide a concise and accurate response in the same language as the user's query.
**Step 4: Handle Uncertainty**
If the answer is not clear, ask the user for clarification to ensure an accurate response.
**Step 5: Avoid Context Attribution**
When formulating your response, do not indicate that the information was derived from the context.
**Step 6: Respond in User's Language**
Maintain consistency by ensuring the response is in the same language as the user's query.
**Step 7: Provide Response**
Generate a clear, concise, and informative response to the user's query, adhering to the guidelines outlined above.
User Query: [query]
<context>
[context]
</context>
```
