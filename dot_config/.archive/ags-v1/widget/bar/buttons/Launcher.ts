import PanelButton from "../PanelButton";
import options from "options";

const { icon } = options.bar.launcher;

export default () =>
	PanelButton({
		window: "launcher",
		on_clicked: () => {
			options.launcher.position.setValue("top-left");
			App.toggleWindow("launcher");
		},
		child: Widget.Box({
			child: Widget.Icon({
				icon: icon.icon.bind(),
				class_name: icon.colored.bind().as((c) => (c ? "colored" : "")),
			}),
		}),
	});
