import GLib from "gi://GLib";
import { dependencies, sh, bash } from "lib/utils";

const hyprland = await Service.import("hyprland");

const now = () => GLib.DateTime.new_now_local().format("%Y-%m-%d_%H-%M-%S");

class Recorder extends Service {
	static {
		Service.register(
			this,
			{},
			{
				timer: ["int"],
				recording: ["boolean"],
			},
		);
	}

	#recordings = Utils.HOME + "/Videos/Screencasting";
	#screenshots = Utils.HOME + "/Pictures/Screenshots";
	#file = "";
	#interval = 0;

	recording = false;
	timer = 0;
	is_night = false;

	async start() {
		if (!dependencies("slurp", "wf-recorder")) return;

		if (this.recording) return;

		Utils.ensureDirectory(this.#recordings);
		this.#file = `${this.#recordings}/${now()}.mp4`;
		sh(
			`wf-recorder -g "${await sh("slurp")}" -f ${this.#file} --pixel-format yuv420p`,
		);

		this.recording = true;
		this.changed("recording");

		this.timer = 0;
		this.#interval = Utils.interval(1000, () => {
			this.changed("timer");
			this.timer++;
		});
	}

	async stop() {
		if (!this.recording) return;

		await bash("killall -INT wf-recorder");
		this.recording = false;
		this.changed("recording");
		GLib.source_remove(this.#interval);

		Utils.notify({
			iconName: "video-x-generic-symbolic",
			summary: "Screenrecord",
			body: this.#file,
			actions: {
				"Show in Files": () => sh(`xdg-open ${this.#recordings}`),
				View: () => sh(`xdg-open ${this.#file}`),
			},
		});
	}

	async screenshot(type: "full" | "region" | "window") {
		if (!dependencies("slurp", "grim")) return;

		const file = `${this.#screenshots}/${now()}.png`;
		Utils.ensureDirectory(this.#screenshots);

		if (type === "full") {
			await sh(`grim "${file}"`);
		} else if (type === "region") {
			const size = await sh("slurp");

			await sh(`grim -g "${size}" "${file}"`);
		} else if (type === "window") {
			const clients = hyprland.clients.filter(
				(c) => c.workspace.id === hyprland.active.workspace.id,
			);
			const boxes = clients
				.map((c) => {
					const [x, y] = c.at;
					const [w, h] = c.size;
					return `${x},${y} ${w}x${h}`;
				})
				.join(" ");

			const window = await bash(`slurp -r <<< "${boxes}"`);
			await sh(`grim -g "${window}" "${file}"`);
		}

		bash(`wl-copy < ${file}`);

		Utils.notify({
			image: file,
			summary: "Screenshot",
			body: file,
			actions: {
				"Show in Files": () => sh(`xdg-open ${this.#screenshots}`),
				View: () => sh(`xdg-open ${file}`),
				Edit: () => {
					if (dependencies("swappy")) sh(`swappy -f ${file}`);
				},
			},
		});
	}
}

const recorder = new Recorder();
Object.assign(globalThis, { recorder });
export default recorder;
