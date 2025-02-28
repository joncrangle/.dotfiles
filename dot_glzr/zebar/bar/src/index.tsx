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

render(() => <App />, document.getElementById("root")!);

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
			return <i class="nf nf-fa-battery_4"></i>;
		if (batteryOutput.chargePercent > 70)
			return <i class="nf nf-fa-battery_3"></i>;
		if (batteryOutput.chargePercent > 40)
			return <i class="nf nf-fa-battery_2"></i>;
		if (batteryOutput.chargePercent > 20)
			return <i class="nf nf-fa-battery_1"></i>;
		return <i class="nf nf-fa-battery_0"></i>;
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
				<i class="logo nf nf-fa-windows"></i>

				<Show when={output.komorebi}>
					<div class="workspaces">
						<For each={output.komorebi.currentWorkspaces}>
							{(workspace, index) => {
								const isFocusedWorkspace = createMemo(
									() =>
										workspace.name === output.komorebi.focusedWorkspace.name &&
										output.komorebi.currentMonitor.name ===
											output.komorebi.focusedMonitor.name,
								);
								return (
									<button
										class={`workspace ${isFocusedWorkspace() && "focused"}`}
										onClick={() =>
											zebar.shellSpawn(
												"komorebic",
												`focus-workspace ${index().toString()}`,
											)
										}
									>
										{workspace.name}
									</button>
								);
							}}
						</For>
					</div>
					<div class="focused-window">
						<span class="sketchy-icon">{windowIcon()}</span>
						<span>{windowTitle()}</span>
					</div>
				</Show>
			</div>

			<div class="center">
				<div class="date">{output.date?.formatted}</div>
			</div>

			<div class="right">
				<div class="media-container">
					<Show when={output.media}>
						<div class="media">
							<i class="nf nf-fa-music"></i>
							{output.media?.currentSession.title} -
							{output.media?.currentSession?.artist}
						</div>
					</Show>
				</div>

				<div class="stats">
					<Show when={output.memory}>
						<div class="memory">
							<i class="nf nf-fae-chip"></i>
							{Math.round(output.memory.usage)}%
						</div>
					</Show>

					<Show when={output.cpu}>
						<div class="cpu">
							<span class={output.cpu.usage > 85 ? "high-usage" : ""}>
								<i class="nf nf-oct-cpu"></i>
								{Math.round(output.cpu.usage)}%
							</span>
						</div>
					</Show>

					<Show when={output.disk}>
						<div class="disk">
							<i class="nf nf-fa-hdd_o"></i>
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
								<i class="nf nf-md-power_plug charging-icon"></i>
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
