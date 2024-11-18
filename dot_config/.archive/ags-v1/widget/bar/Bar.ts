import ActiveWindow from "./buttons/ActiveWindow";
import BatteryBar from "./buttons/BatteryBar";
import Date from "./buttons/Date";
import ColorPicker from "./buttons/ColorPicker";
import Launcher from "./buttons/Launcher";
import Media from "./buttons/Media";
import Messages from "./buttons/Messages";
import PowerMenu from "./buttons/PowerMenu";
import ScreenRecord from "./buttons/ScreenRecord";
import SystemIndicators from "./buttons/SystemIndicators";
import SysTray from "./buttons/SysTray";
import Workspaces from "./buttons/Workspaces";
import options from "options";

const { start, center, end } = options.bar.layout;
const { transparent, position } = options.bar;

export type BarWidget = keyof typeof widget;

const widget = {
	activewindow: ActiveWindow,
	battery: BatteryBar,
	colorpicker: ColorPicker,
	date: Date,
	launcher: Launcher,
	media: Media,
	messages: Messages,
	powermenu: PowerMenu,
	screenrecord: ScreenRecord,
	system: SystemIndicators,
	systray: SysTray,
	workspaces: Workspaces,
	expander: () => Widget.Box({ expand: true }),
};

export default (monitor: number) =>
	Widget.Window({
		monitor,
		class_name: "bar",
		name: `bar${monitor}`,
		exclusivity: "exclusive",
		anchor: position.bind().as((pos) => [pos, "right", "left"]),
		child: Widget.CenterBox({
			css: "min-width: 2px; min-height: 2px;",
			startWidget: Widget.Box({
				hexpand: true,
				children: start.bind().as((s) => s.map((w) => widget[w]())),
			}),
			centerWidget: Widget.Box({
				hpack: "center",
				children: center.bind().as((c) => c.map((w) => widget[w]())),
			}),
			endWidget: Widget.Box({
				hexpand: true,
				children: end.bind().as((e) => e.map((w) => widget[w]())),
			}),
		}),
		setup: (self) =>
			self.hook(transparent, () => {
				self.toggleClassName("transparent", transparent.value);
			}),
	});
