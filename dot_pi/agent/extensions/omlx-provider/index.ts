import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default async function (pi: ExtensionAPI) {
  try {
    const response = await fetch("http://localhost:8081/v1/models", {
      headers: { Authorization: "Bearer null" },
    });
    const payload = (await response.json()) as {
      data: Array<{
        id: string;
        name?: string;
        context_window?: number;
      }>;
    };

    pi.registerProvider("omlx", {
      baseUrl: "http://localhost:8081/v1",
      apiKey: "null",
      api: "openai-completions",
      models: payload.data.map((model) => ({
        id: model.id,
        name: model.name ?? model.id,
        reasoning: false,
        input: ["text"],
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
        contextWindow: model.context_window ?? 128000,
        maxTokens: 4096,
      })),
    });
  } catch {
    console.log("oMLX not available on port 8081");
  }
}

