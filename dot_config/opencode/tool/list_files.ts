import { tool } from "@opencode-ai/plugin";

export default tool({
  description:
    "List files and directories. Uses 'eza' (modern ls) if available, falling back to 'ls' or Windows 'dir'.",
  args: {
    path: tool.schema
      .string()
      .optional()
      .describe("The directory to list (default: current directory)."),
    style: tool.schema
      .enum(["simple", "long", "all", "tree"])
      .optional()
      .describe(
        "Output style: 'simple' (names only), 'long' (permissions/size), 'all' (includes hidden files), 'tree' (hierarchical view). Default: 'simple'.",
      ),
  },
  async execute({ path = ".", style = "simple" }) {
    try {
      // 1. Try Eza
      if (Bun.which("eza")) {
        const flags: string[] = [];

        switch (style) {
          case "simple":
            break;
          case "long":
            flags.push("-l", "--git");
          case "all":
            flags.push("-l", "-a", "--git");
          case "tree":
            flags.push("-T", "--level=2");
        }

        return await Bun.$`eza ${flags} --color=never --group-directories-first ${path}`
          .nothrow()
          .text();
      }

      // 2. Try Standard 'ls' (Linux/Mac/GitBash)
      else if (Bun.which("ls")) {
        const flags: string[] = [];

        switch (style) {
          case "simple":
            break;
          case "long":
            flags.push("-lh");
            break;
          case "all":
            flags.push("-lah");
            break;
          case "tree":
            // Fallback: Check if native 'tree' command exists
            if (Bun.which("tree")) {
              return await Bun.$`tree -L 2 ${path}`.nothrow().text();
            }
            // If no tree, force a recursive ls limited to depth?
            // Better to just return a standard recursive listing or warn.
            return await Bun.$`ls -R ${path}`.nothrow().text();
        }

        return await Bun.$`ls ${flags} ${path}`.nothrow().text();
      }

      // 3. Try Windows 'dir' (CMD/PowerShell)
      else {
        const flags: string[] = [];

        switch (style) {
          case "simple":
            flags.push("/B");
            break;
          case "long":
            break;
          case "all":
            flags.push("/A");
            break;
          case "tree":
            return await Bun.$`tree /F /A ${path}`.nothrow().text();
        }

        // Note: Windows path separator handling is automatic in Bun.$
        return await Bun.$`dir ${flags} ${path}`.nothrow().text();
      }
    } catch (e: any) {
      return `List Error: ${e.stderr ? e.stderr.toString() : e.message}`;
    }
  },
});
