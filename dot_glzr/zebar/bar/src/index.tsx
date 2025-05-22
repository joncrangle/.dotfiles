/* @refresh reload */
import "./index.css";
import iconMap from "./icon_map.json";
import { For, render, Show } from "solid-js/web";
import { createStore } from "solid-js/store";
import * as zebar from "zebar";
import { createMemo } from "solid-js";

const providers = zebar.createProviderGroup({
	komorebi: { type: "komorebi" },
	date: { type: "date", formatting: "EEE d MMM t" },
	disk: { type: "disk" },
	media: { type: "media" },
	cpu: { type: "cpu" },
	battery: { type: "battery" },
	memory: { type: "memory" },
});

type IconMapEntry = {
	appNames: string[];
	iconName: string;
};

render(() => <App />, document.getElementById("root"));

function WorkspaceList(props: {
	workspaces: { name: string }[];
	focusedWorkspaceName?: string;
	currentMonitorName?: string;
	focusedMonitorName?: string;
	onWorkspaceClick: (index: number) => void;
}) {
	return (
		<div class="workspaces">
			<For each={props.workspaces}>
				{(workspace, index) => {
					const isFocused = () =>
						workspace.name === props.focusedWorkspaceName &&
						props.currentMonitorName === props.focusedMonitorName;
					return (
						<button
							type="button"
							class={`workspace ${isFocused() && "focused"}`}
							onClick={() => props.onWorkspaceClick(index())}
						>
							{workspace.name}
						</button>
					);
				}}
			</For>
		</div>
	);
}

function App() {
	const parseTitle = (input: string) => {
		// Regular expression to match strings with a file path to an executable
		const regex = /\\([\w\d\-]+\.exe)$/i;

		const match = input.match(regex);
		if (match) {
			return match[1];
		}

		return input;
	};

	const getBatteryIcon = (batteryOutput: zebar.BatteryOutput) => {
		if (batteryOutput.chargePercent > 90)
			return <i class="nf nf-fa-battery_4" />;
		if (batteryOutput.chargePercent > 70)
			return <i class="nf nf-fa-battery_3" />;
		if (batteryOutput.chargePercent > 40)
			return <i class="nf nf-fa-battery_2" />;
		if (batteryOutput.chargePercent > 20)
			return <i class="nf nf-fa-battery_1" />;
		return <i class="nf nf-fa-battery_0" />;
	};

	const getAppIcon = (title: string, exe: string) => {
		if (!Array.isArray(iconMap)) {
			console.error("iconMap is not an array", iconMap);
			return ":default:";
		}

		const normalizedTitle = title.toLowerCase();
		const normalizedExe = exe.toLowerCase();

		const exactExeMatch = (iconMap as IconMapEntry[]).find((item) =>
			item.appNames.some((name) => {
				const normalizedAppName = name.toLowerCase().replace(/\*/g, "");
				return normalizedExe === `${normalizedAppName}.exe`;
			}),
		);

		if (exactExeMatch) return exactExeMatch.iconName;

		const exeContainsMatch = (iconMap as IconMapEntry[]).find((item) =>
			item.appNames.some((name) => {
				const normalizedAppName = name
					.toLowerCase()
					.replace(/\*/g, "")
					.replace(/\.exe$/, "");
				return normalizedExe.includes(normalizedAppName);
			}),
		);

		if (exeContainsMatch) return exeContainsMatch.iconName;

		const titleContainsMatch = (iconMap as IconMapEntry[]).find((item) =>
			item.appNames.some((name) => {
				const normalizedAppName = name
					.toLowerCase()
					.replace(/\*/g, "")
					.replace(/\.exe$/, "");
				return normalizedTitle.includes(normalizedAppName);
			}),
		);

		return titleContainsMatch ? titleContainsMatch.iconName : ":default:";
	};

	const [output, setOutput] = createStore(providers.outputMap);

	providers.onOutput((outputMap) => setOutput(outputMap));

	const focusedWindow = createMemo(() => {
		const komorebi = output?.komorebi;
		if (!komorebi?.focusedWorkspace) return null;
		return komorebi.focusedWorkspace.tilingContainers?.[
			komorebi.focusedWorkspace.focusedContainerIndex
		]?.windows?.[0];
	});

	const windowTitle = createMemo(() => {
		const window = focusedWindow();
		return window ? parseTitle(window.title) : "-";
	});

	const windowIcon = createMemo(() => {
		const window = focusedWindow();
		return window ? getAppIcon(window.title, window.exe) : ":default:";
	});

	return (
		<div class="app">
			<div class="left">
				<i class="logo nf nf-fa-windows" />

				<Show
					when={output.komorebi}
					fallback={
						<WorkspaceList
							workspaces={[
								{ name: "1" },
								{ name: "2" },
								{ name: "3" },
								{ name: "4" },
								{ name: "5" },
							]}
							currentMonitorName="main"
							focusedMonitorName="main"
							onWorkspaceClick={(idx) =>
								zebar.shellSpawn("komorebic", `focus-workspace ${idx}`)
							}
						/>
					}
				>
					<WorkspaceList
						workspaces={output.komorebi.currentWorkspaces ?? []}
						focusedWorkspaceName={output.komorebi?.focusedWorkspace?.name}
						currentMonitorName={output.komorebi?.currentMonitor?.name}
						focusedMonitorName={output.komorebi?.focusedMonitor?.name}
						onWorkspaceClick={(idx) =>
							zebar.shellSpawn("komorebic", `focus-workspace ${idx}`)
						}
					/>
				</Show>
			</div>

			<div class="center">
				<div class="date">{output.date?.formatted}</div>
			</div>

			<div class="right">
				<div class="media-container">
					<Show when={output.media}>
						<div class="media">
							<i class="nf nf-fa-music" />
							{output.media?.currentSession.title} -
							{output.media?.currentSession?.artist}
						</div>
					</Show>
				</div>

				<div class="stats">
					<Show when={output.memory}>
						<div class="memory">
							<i class="nf nf-fae-chip" />
							{Math.round(output.memory.usage)}%
						</div>
					</Show>

					<Show when={output.cpu}>
						<div class="cpu">
							<span class={output.cpu.usage > 85 ? "high-usage" : ""}>
								<i class="nf nf-oct-cpu" />
								{Math.round(output.cpu.usage)}%
							</span>
						</div>
					</Show>

					<Show when={output.disk}>
						<div class="disk">
							<i class="nf nf-fa-hdd_o" />
							{Math.round(
								100 -
									(output.disk.disks[0].availableSpace.iecValue /
										output.disk.disks[0].totalSpace.iecValue) *
										100,
							)}
							%
						</div>
					</Show>

					<Show when={output.battery}>
						<div class="battery">
							{output.battery.isCharging && (
								<i class="nf nf-md-power_plug charging-icon" />
							)}
							{getBatteryIcon(output.battery)}
							{Math.round(output.battery.chargePercent)}%
						</div>
					</Show>
				</div>
			</div>
		</div>
	);
}
