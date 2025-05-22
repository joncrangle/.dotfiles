# 📝LLM

## 🪛 MLX Omni Server

[MLX Omni Server](https://github.com/madroidmaq/mlx-omni-server)

```sh
# install
uv tool install --python=python3.12 mlx-omni-server@latest
# upgrade
uv tool upgrade --all
# start on default port 10240
mlx-omni-server
```

Current models:
- Text - mlx-community/Qwen3-4B-4bit, mlx-community/Qwen3-8B-4bit-DWQ, mlx-community/gemme-3-4b-it-4bit-DWQ, mlx-community/gemma-3-12b-it-4bit-DWQ
- TTS - mlx-community/Dia-1.6B-4bit
- STT - mlx-community/whisper-large-v3-turbo
- Image - dhairyashil/FLUX.1-schnell-mflux-4bit
- Embeddings - mlx-community/all-MiniLM-L6-v2-4bit

## 💬 Open WebUI

[Open WebUI](https://openwebui.com/) and [MCPO](https://github.com/open-webui/mcpo) can be hosted as docker containers.

> [!TIP]
> Each tool needs to be added individually at a different route.

`servers.json`

```json
{
	"mcpServers": {
		"time": {
			"args": ["mcp-server-time", "--local-timezone=America/New_York"],
			"command": "uvx"
		},
		"context7": {
			"args": ["-y", "@upstash/context7-mcp@latest"],
			"command": "npx"
		},
		"memory": {
			"args": ["-y", "@modelcontextprotocol/server-memory"],
			"command": "npx"
		},
		"fetch": {
			"args": ["mcp-server-fetch"],
			"command": "uvx"
		},
		"sequentialthinking": {
			"args": ["-y", "@modelcontextprotocol/server-sequential-thinking"],
			"command": "npx"
		}
	}
}
```

## ⌨️ Copilot Models

```http
@COPILOT_API_KEY = api_key

###

# Get available models
GET https://api.githubcopilot.com/models HTTP/1.1
Authorization: Bearer {{COPILOT_API_KEY}}
Copilot-Integration-Id: vscode-chat
Content-Type: application/json
```

## 📁 Archive

### 💻 LM-Studio

[LM-Studio](https://lmstudio.ai/) can be configured to start a server as a service.

## 🖼️Comfy UI

**Image Generation**

- Current LLM: [argmaxinc/mlx-FLUX.1-schnell-4bit-quantized](https://huggingface.co/argmaxinc/mlx-FLUX.1-schnell-4bit-quantized)
- Other: [Dreamshaper XL 2.1 Turbo](https://civitai.com/models/112902/dreamshaper-xl)
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

### 🦙 Ollama

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
