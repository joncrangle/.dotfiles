export type Action = "sleep" | "reboot" | "logout" | "shutdown";

class PowerMenu extends Service {
	static {
		Service.register(
			this,
			{},
			{
				title: ["string"],
				cmd: ["string"],
			},
		);
	}

	#title = "";
	#cmd = "";

	get title() {
		return this.#title;
	}

	action(action: Action) {
		[this.#cmd, this.#title] = {
			sleep: ["systemctl suspend", "Sleep"],
			reboot: ["systemctl reboot", "Reboot"],
			logout: ["pkill Hyprland", "Log Out"],
			shutdown: ["systemctl poweroff", "Shutdown"],
		}[action];

		this.notify("cmd");
		this.notify("title");
		this.emit("changed");
		App.closeWindow("powermenu");
		App.openWindow("verification");
	}

	readonly shutdown = () => {
		this.action("shutdown");
	};

	readonly exec = () => {
		App.closeWindow("verification");
		Utils.exec(this.#cmd);
	};
}

const powermenu = new PowerMenu();
Object.assign(globalThis, { powermenu });
export default powermenu;
