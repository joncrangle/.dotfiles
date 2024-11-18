export type KeyBinding = {
	keybinding: string;
	description: string;
};

let keyBindings: KeyBinding[];

async function reload() {
	const data = Utils.readFile(
		App.configDir.slice(0, -"ags".length) + "/hypr/conf/keybindings.conf",
	);

	const lines = data.split("\n");
	let mainMod = "";
	let currentSubmap = "";

	keyBindings = lines
		.map((line) => {
			line = line.trim();
			if (line.startsWith("$mainMod")) {
				const parts = line.split("=");
				if (parts.length === 2) {
					mainMod = parts[1].trim();
				}
				return null;
			}

			if (line.startsWith("submap = reset")) {
				currentSubmap = "";
				return null;
			}

			if (line.startsWith("submap =")) {
				currentSubmap = line.split("=")[1].trim();
				return null;
			}

			if (line.startsWith("bind") && line.includes("#")) {
				const parts = line.split("#");
				if (parts.length !== 2) return null;

				const description = parts[1].trim();
				const bindingPart = parts[0]
					.split("=")[1]
					.trim()
					.split(",")
					.slice(0, 2)
					.map((part) => part.trim())
					.map((part) => part.split(" ").join(" + "))
					.filter((part) => part !== "")
					.reduce((acc, part, index) => {
						if (index === 0) {
							return part;
						}
						return acc + " + " + part;
					}, "");

				let keybinding = bindingPart.replace("$mainMod", mainMod);

				if (currentSubmap) {
					keybinding = `${currentSubmap} + ${keybinding}`;
				}
				return { keybinding, description };
			}

			return null;
		})
		.filter((item) => item !== null) as KeyBinding[];
}

async function get() {
	if (keyBindings.length === 0) {
		await reload();
	}
	return keyBindings;
}

async function query(filter: string) {
	return (await get())
		.filter((binding) =>
			binding.description.toLowerCase().includes(filter.toLowerCase()),
		)
		.slice(0, 44);
}

class Cheatsheet extends Service {
	static {
		Service.register(this);
	}

	constructor() {
		super();
		reload();
	}

	query = query;
}

export default new Cheatsheet();
