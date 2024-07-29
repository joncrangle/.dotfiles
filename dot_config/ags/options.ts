import { opt, mkOptions } from "lib/option";
import { distro } from "lib/variables";
import { icon } from "lib/utils";
import icons from "lib/icons";

const options = mkOptions(OPTIONS, {
	autotheme: opt(false),

	wallpaper: {
		resolution: opt<import("service/wallpaper").Resolution>(1920),
		market: opt<import("service/wallpaper").Market>("random"),
	},

	theme: {
		dark: {
			primary: {
				bg: opt("#cba6f7"),
				fg: opt("#313244"),
			},
			error: {
				bg: opt("#f38ba8"),
				fg: opt("#1e1e2e"),
			},
			bg: opt("#1e1e2e"),
			fg: opt("#cdd6f4"),
			widget: opt("#cdd6f4"),
			border: opt("#cba6f7"),
			hover: opt("#f5c2e7"),
			active: opt("#cba6f7"),
			accent: {
				fg: opt("#fab387"),
				bg: opt("#89b4fa"),
				tray: opt("#f9e2af"),
				settings: opt("#b4befe"),
			},
			success: opt("#a6e3a1"),
		},
		light: {
			primary: {
				bg: opt("#ca9ee6"),
				fg: opt("#414559"),
			},
			error: {
				bg: opt("#e78284"),
				fg: opt("#eeeeee"),
			},
			bg: opt("#303446"),
			fg: opt("#c6d0f5"),
			widget: opt("#c6d0f5"),
			border: opt("#ca9ee6"),
			hover: opt("#f4b8e4"),
			active: opt("#ef9f76"),
			accent: {
				bg: opt("#ef9f76"),
				fg: opt("#8caaee"),
				tray: opt("#e5c890"),
				settings: opt("#babbf1"),
			},
			success: opt("#a6d189"),
		},

		blur: opt(0),
		scheme: opt<"dark" | "light">("dark"),
		widget: { opacity: opt(94) },
		border: {
			width: opt(1),
			opacity: opt(96),
		},

		shadows: opt(true),
		padding: opt(6),
		spacing: opt(6),
		radius: opt(12),
	},

	transition: opt(200),

	font: {
		size: opt(12),
		name: opt("Liberation Sans"),
		fontfeatures: opt("ss06"),
	},

	bar: {
		flatButtons: opt(true),
		position: opt<"top" | "bottom">("top"),
		corners: opt(50),
		transparent: opt(true),
		layout: {
			start: opt<Array<import("widget/bar/Bar").BarWidget>>([
				"launcher",
				"workspaces",
				"activewindow",
				"expander",
				"messages",
			]),
			center: opt<Array<import("widget/bar/Bar").BarWidget>>(["date"]),
			end: opt<Array<import("widget/bar/Bar").BarWidget>>([
				"media",
				"expander",
				"systray",
				"colorpicker",
				"screenrecord",
				"system",
				"battery",
				"powermenu",
			]),
		},
		launcher: {
			icon: {
				colored: opt(true),
				icon: opt(icon(distro.logo, icons.ui.search)),
			},
		},
		date: {
			format: opt("%-l:%M %p - %a %b %e, %Y"),
			time: opt("%l:%M %p"),
			action: opt(() => App.toggleWindow("datemenu")),
		},
		battery: {
			bar: opt<"hidden" | "regular" | "whole">("regular"),
			charging: opt("#a6e3a1"),
			percentage: opt(false),
			blocks: opt(7),
			width: opt(50),
			low: opt(30),
		},
		activewindow: {
			iconSize: opt(16),
			monochrome: opt(false),
		},
		messages: {
			action: opt(() => App.toggleWindow("datemenu")),
		},
		systray: {
			ignore: opt(["KDE Connect Indicator", "spotify-client"]),
		},
		media: {
			monochrome: opt(false),
			preferred: opt("spotify"),
			direction: opt<"left" | "right">("right"),
			format: opt("{artists} - {title}"),
			length: opt(40),
		},
		powermenu: {
			monochrome: opt(false),
			action: opt(() => App.toggleWindow("powermenu")),
		},
		workspaces: {
			monochrome: opt(false),
			iconSize: opt(16),
		},
	},

	launcher: {
		width: opt(0),
		margin: opt(6),
		sh: {
			max: opt(16),
		},
		position: opt<
			| "center"
			| "top"
			| "top-left"
			| "top-center"
			| "top-right"
			| "bottom-left"
			| "bottom-center"
			| "bottom-right"
		>("top-center"),
		apps: {
			iconSize: opt(62),
			max: opt(6),
			favorites: opt([
				["Brave-browser", "wezterm", "plexamp", "spotify", "obsidian"],
			]),
		},
	},

	overview: {
		scale: opt(12),
		workspaces: opt(0),
		monochromeIcon: opt(false),
	},

	powermenu: {
		sleep: opt("systemctl suspend"),
		reboot: opt("systemctl reboot"),
		logout: opt("pkill Hyprland"),
		shutdown: opt("shutdown now"),
		layout: opt<"line" | "box">("line"),
		labels: opt(true),
	},

	quicksettings: {
		width: opt(380),
		position: opt<"left" | "center" | "right">("right"),
		networkSettings: opt("gtk-launch gnome-control-center"),
		media: {
			monochromeIcon: opt(false),
			coverSize: opt(100),
		},
	},

	datemenu: {
		position: opt<"left" | "center" | "right">("center"),
	},

	osd: {
		progress: {
			vertical: opt(true),
			pack: {
				h: opt<"start" | "center" | "end">("end"),
				v: opt<"start" | "center" | "end">("center"),
			},
		},
		microphone: {
			pack: {
				h: opt<"start" | "center" | "end">("center"),
				v: opt<"start" | "center" | "end">("end"),
			},
		},
	},

	notifications: {
		position: opt<Array<"top" | "bottom" | "left" | "right">>(["top", "right"]),
		blacklist: opt(["Spotify"]),
		width: opt(440),
	},
});

globalThis["options"] = options;
export default options;
