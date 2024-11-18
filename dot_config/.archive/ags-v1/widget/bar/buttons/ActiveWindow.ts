import { icon } from "lib/utils";
import icons from "lib/icons";
import options from "options";

const hyprland = await Service.import("hyprland");
const { monochrome, iconSize } = options.bar.activewindow;

const AppItem = () => {
	const client = hyprland.active.client;
	const title = hyprland.active.client.bind("title");

	const ico = Utils.merge([title, monochrome.bind()], (title, monochrome) => {
		const icon_name = client.class;

		if (client.class === "org.wezfurlong.wezterm") {
			const cmd = title.split(" ")[1];
			if (cmd) {
				return icon(cmd, icon_name);
			}
		}

		return icon(
			icon_name.toLowerCase() + (monochrome ? "-symbolic" : ""),
			icons.fallback.executable + (monochrome ? "-symbolic" : ""),
		);
	});

	return Widget.Box({
		class_name: "content",
		child: Widget.Box([
			Widget.Icon({
				size: iconSize.bind(),
				icon: ico,
			}),
			Widget.Label({
				label: title,
				truncate: "end",
				maxWidthChars: 50,
			}),
		]),
	});
};

export default () =>
	Widget.Box({
		class_name: "activewindow",
		child: AppItem(),
	});
