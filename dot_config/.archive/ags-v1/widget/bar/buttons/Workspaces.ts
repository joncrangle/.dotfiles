import { icon } from "lib/utils";
import icons from "lib/icons";
import options from "options";

const hyprland = await Service.import("hyprland");
const { monochrome, iconSize } = options.bar.workspaces;

const WorkspaceClients = (id: number) => {
	const icos = hyprland.clients
		.filter((client) => client.workspace.id === id)
		.map((client) => {
			return Widget.Icon({
				class_name: "app-icon",
				size: iconSize.bind(),
				icon: monochrome
					.bind()
					.as((m) =>
						icon(
							(client.class.toLowerCase() || client.title.toLowerCase()) +
								(m ? "-symbolic" : ""),
							icons.fallback.executable + (m ? "-symbolic" : ""),
						),
					),
			});
		});
	return Widget.Box({
		children: icos,
	});
};

const Workspace = (id: number) => {
	return Widget.Box({
		children: [Widget.Label({ label: id.toString() }), WorkspaceClients(id)],
	});
};

export default () => {
	const hyprWorkspaceDispatch = (ws: string) =>
		hyprland.messageAsync(`dispatch workspace ${ws}`);
	const activeId = hyprland.active.workspace.bind("id");
	const workspaces = hyprland.bind("workspaces").as((ws) =>
		ws
			.sort((a, b) => a.id - b.id)
			.map(({ id }) =>
				Widget.Button({
					class_name: activeId.as(
						(i) => `${i === id ? "active" : ""} workspace flat`,
					),
					onClicked: () => hyprland.messageAsync(`dispatch workspace ${id}`),
					child: Workspace(id),
				}),
			),
	);

	return Widget.EventBox({
		onScrollUp: () => hyprWorkspaceDispatch("-1"),
		onScrollDown: () => hyprWorkspaceDispatch("+1"),
		child: Widget.Box({
			class_name: "workspaces",
			children: workspaces,
		}),
	});
};
