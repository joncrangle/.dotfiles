import type Gtk from "gi://Gtk?version=3.0";
import { Header } from "./widgets/Header";
import { Volume, Microphone, SinkSelector, AppMixer } from "./widgets/Volume";
import { Brightness } from "./widgets/Brightness";
import { NetworkToggle, WifiSelection } from "./widgets/Network";
import { BluetoothToggle, BluetoothDevices } from "./widgets/Bluetooth";
import { DND } from "./widgets/DND";
import { MicMute } from "./widgets/MicMute";
import { Media } from "./widgets/Media";
import Cava from "./widgets/Cava";
import PopupWindow from "widget/PopupWindow";
import options from "options";
import { sh } from "lib/utils";

const { bar, quicksettings } = options;
const media = await Service.import("mpris");
const layout = Utils.derive(
	[bar.position, quicksettings.position],
	(bar, qs) => `${bar}-${qs}` as const,
);
const smooth = false;

const Row = (
	toggles: Array<() => Gtk.Widget> = [],
	menus: Array<() => Gtk.Widget> = [],
) =>
	Widget.Box({
		vertical: true,
		children: [
			Widget.Box({
				homogeneous: true,
				class_name: "row horizontal",
				children: toggles.map((w) => w()),
			}),
			...menus.map((w) => w()),
		],
	});

const Settings = () =>
	Widget.Box({
		vertical: true,
		class_name: "quicksettings vertical",
		css: quicksettings.width.bind().as((w) => `min-width: ${w}px;`),
		children: [
			Header(),
			Widget.Box({
				class_name: "sliders-box vertical",
				vertical: true,
				children: [
					Row([Volume], [SinkSelector, AppMixer]),
					Microphone(),
					Brightness(),
				],
			}),
			Row([NetworkToggle, BluetoothToggle], [WifiSelection, BluetoothDevices]),
			Row([MicMute, DND]),
			Widget.Box({
				visible: media.bind("players").as((l) => l.length > 0),
				child: Media(),
			}),
			Widget.Box({
				visible: media.bind("players").as((l) => l.length > 0),
				class_name: "visualizer",
				css: "padding: 6px;",
				vertical: true,
			}).hook(media, (self) => {
				if (!media.bind("players").as((l) => l.length > 0)) return;
				sh("pkill cava");
				const limit = options.bar.media.length.value;
				const width = 10;
				const height = 80;
				const size = quicksettings.width.value;
				self.child = Cava({
					smooth,
					width,
					height,
					bars: (size < limit ? size : limit) * width,
				});
			}),
		],
	});

const QuickSettings = () =>
	PopupWindow({
		name: "quicksettings",
		exclusivity: "exclusive",
		transition: "slide_down",
		layout: layout.value,
		child: Settings(),
	});

export function setupQuickSettings() {
	App.addWindow(QuickSettings());
	layout.connect("changed", () => {
		App.removeWindow("quicksettings");
		App.addWindow(QuickSettings());
	});
}
