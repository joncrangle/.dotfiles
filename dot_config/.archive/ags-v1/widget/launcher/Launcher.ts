import type { Binding } from "lib/utils";
import PopupWindow, { Padding } from "widget/PopupWindow";
import icons from "lib/icons";
import options from "options";
import * as AppLauncher from "./AppLauncher";
import * as Cheatsheet from "./Cheatsheet";
import * as Cliphist from "./Cliphist";
import * as Emoji from "./Emoji";
import * as ShRun from "./ShRun";

const { width, margin, position } = options.launcher;

function Launcher() {
	const favs = AppLauncher.Favorites();
	const applauncher = AppLauncher.Launcher();
	const sh = ShRun.ShRun();
	const shicon = ShRun.Icon();
	const ch = Cliphist.Cliphist();
	const chicon = Cliphist.Icon();
	const emoji = Emoji.Emoji();
	const emojiicon = Emoji.Icon();
	const kb = Cheatsheet.Cheatsheet();
	const kbicon = Cheatsheet.Icon();

	function HelpButton(cmd: string, desc: string | Binding<string>) {
		return Widget.Box(
			{ vertical: true },
			Widget.Separator(),
			Widget.Button(
				{
					class_name: "help",
					on_clicked: () => {
						entry.grab_focus();
						entry.text = `:${cmd} `;
						entry.set_position(-1);
					},
				},
				Widget.Box([
					Widget.Label({
						class_name: "name",
						label: `:${cmd}`,
					}),
					Widget.Label({
						hexpand: true,
						hpack: "end",
						class_name: "description",
						label: desc,
					}),
				]),
			),
		);
	}

	const help = Widget.Revealer({
		child: Widget.Box(
			{ vertical: true },
			HelpButton("sh", "run a binary"),
			HelpButton("ch", "copy a clipboard history entry"),
			HelpButton("em", "copy an emoji"),
			HelpButton("kb", "view keybinds"),
		),
	});

	const entry = Widget.Entry({
		hexpand: true,
		primary_icon_name: icons.ui.search,
		on_accept: ({ text }) => {
			if (text?.startsWith(":sh")) sh.run(text.substring(3));
			else if (text?.startsWith(":ch")) {
				ch.runFirst();
			} else if (text?.startsWith(":em")) {
				emoji.copyFirst();
			} else if (text?.startsWith(":kb")) {
				kb.filter(text.substring(3));
			} else applauncher.launchFirst();

			App.toggleWindow("launcher");
			entry.text = "";
		},
		on_change: ({ text }) => {
			text ||= "";
			favs.reveal_child = text === "";
			help.reveal_child = text.length < 3 && text?.startsWith(":");

			if (text?.startsWith(":sh")) sh.filter(text.substring(3));
			else sh.filter("");

			if (text?.startsWith(":ch")) ch.filter(text.substring(3));
			else ch.clear();

			if (text?.startsWith(":em")) emoji.filter(text.substring(3));
			else emoji.clear();

			if (text?.startsWith(":kb")) kb.filter(text.substring(3));
			else kb.clear();

			if (!text?.startsWith(":")) applauncher.filter(text);
			else applauncher.clear();
		},
	});

	function focus() {
		entry.text = "Search";
		entry.set_position(-1);
		entry.select_region(0, -1);
		entry.grab_focus();
		favs.reveal_child = true;
	}

	Object.assign(globalThis, {
		launcher: {
			open: (text?: string) => {
				App.openWindow("launcher");
				if (text) {
					entry.grab_focus();
					entry.text = text;
					entry.set_position(-1);
					favs.reveal_child = false;
				}
			},
		},
	});

	const layout = Widget.Box({
		css: width.bind().as((v) => `min-width: ${v}pt;`),
		class_name: "launcher",
		vertical: true,
		vpack: "start",
		setup: (self) =>
			self.hook(App, (_, win, visible) => {
				if (win !== "launcher") return;

				entry.text = "";
				if (visible) focus();
			}),
		children: [
			Widget.Box([entry, shicon, chicon, emojiicon, kbicon]),
			favs,
			help,
			applauncher,
			sh,
			ch,
			emoji,
			kb,
		],
	});

	return Widget.Box(
		{ vertical: true },
		Padding("applauncher", {
			css: margin.bind().as((v) => `min-height: ${v}pt;`),
			vexpand: false,
		}),
		layout,
	);
}

const LauncherWindow = () =>
	PopupWindow({
		name: "launcher",
		exclusivity: "exclusive",
		transition: "slide_down",
		layout: position.value,
		child: Launcher(),
	})
		//.on(
		//	"hide",
		//	() =>
		//		options.launcher.position.value !== "top-center" &&
		//		options.launcher.position.setValue("top-center"),
		//)
		.on("notify::visible", (self) => {
			if (!self.visible) {
				//self.destroy();
				options.launcher.position.value !== "top-center" &&
					options.launcher.position.setValue("top-center");
			}
		});

export function setupLauncher() {
	App.addWindow(LauncherWindow());
	position.connect("changed", () => {
		App.removeWindow("launcher");
		App.addWindow(LauncherWindow());
	});
}
