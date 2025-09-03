/* @refresh reload */
import "./index.css";
import iconMap from "./icon_map.json";
import { For, render, Show } from "solid-js/web";
import { createMemo, createSignal, onCleanup } from "solid-js";
import { createStore } from "solid-js/store";
import * as zebar from "zebar";
import {
	type GlazeWmOutput,
	type MediaOutput,
	type MemoryOutput,
	type CpuOutput,
	type DiskOutput,
	type BatteryOutput,
	type Disk,
} from "zebar";

type Workspace = GlazeWmOutput["currentWorkspaces"][0];
type Window = GlazeWmOutput & {
	focusedContainer: {
		title?: string;
		processName?: string;
	};
};

type IconMapEntry = {
	appNames: string[];
	iconName: string;
};

const BATTERY_THRESHOLDS = [
	{ min: 90, icon: "nf nf-fa-battery_4" },
	{ min: 70, icon: "nf nf-fa-battery_3" },
	{ min: 40, icon: "nf nf-fa-battery_2" },
	{ min: 20, icon: "nf nf-fa-battery_1" },
	{ min: 0, icon: "nf nf-fa-battery_0" },
];

const VOLUME_THRESHOLDS = [
	{ min: 100, icon: "nf nf-md-volume_high" },
	{ min: 70, icon: "nf nf-md-volume_high" },
	{ min: 40, icon: "nf nf-md-volume_medium" },
	{ min: 20, icon: "nf nf-md-volume_low" },
	{ min: 0, icon: "nf nf-md-volume_off" },
];

const HIGH_CPU_THRESHOLD = 85;

const providers = zebar.createProviderGroup({
	glazewm: { type: "glazewm" },
	date: { type: "date", formatting: "EEE d MMM t" },
	disk: { type: "disk" },
	audio: { type: "audio" },
	media: { type: "media" },
	cpu: { type: "cpu" },
	battery: { type: "battery" },
	memory: { type: "memory" },
});

// Utility functions
const parseTitle = (input: string): string => {
	const match = input.match(/\\([\w\d\-]+\.exe)$/i);
	return match ? match[1] : input;
};

const getBatteryIcon = (chargePercent: number): string => {
	const threshold = BATTERY_THRESHOLDS.find((t) => chargePercent >= t.min);
	return (
		threshold?.icon || BATTERY_THRESHOLDS[BATTERY_THRESHOLDS.length - 1].icon
	);
};

const getVolumeIcon = (volume: number): string => {
	const threshold = VOLUME_THRESHOLDS.find((t) => volume >= t.min);
	return (
		threshold?.icon || VOLUME_THRESHOLDS[VOLUME_THRESHOLDS.length - 1].icon
	);
};

const normalizeAppName = (name: string): string =>
	name
		.toLowerCase()
		.replace(/\*/g, "")
		.replace(/\.exe$/, "");

const getAppIcon = (title: string, exe: string): string => {
	if (!Array.isArray(iconMap)) {
		return ":default:";
	}

	const normalizedTitle = title.toLowerCase();
	const normalizedExe = exe.toLowerCase();
	const iconMapTyped = iconMap as IconMapEntry[];

	// Try exact exe match first
	const exactMatch = iconMapTyped.find((item) =>
		item.appNames.some(
			(name) => normalizedExe === `${normalizeAppName(name)}.exe`,
		),
	);
	if (exactMatch) return exactMatch.iconName;

	// Try exe contains match
	const exeMatch = iconMapTyped.find((item) =>
		item.appNames.some((name) =>
			normalizedExe.includes(normalizeAppName(name)),
		),
	);
	if (exeMatch) return exeMatch.iconName;

	// Try title contains match
	const titleMatch = iconMapTyped.find((item) =>
		item.appNames.some((name) =>
			normalizedTitle.includes(normalizeAppName(name)),
		),
	);

	return titleMatch?.iconName || ":default:";
};

const calculateDiskUsage = (disk: Disk): number => {
	if (!disk?.availableSpace?.iecValue || !disk?.totalSpace?.iecValue) return 0;
	return Math.round(
		100 - (disk.availableSpace.iecValue / disk.totalSpace.iecValue) * 100,
	);
};

const WorkspaceButton = (props: {
	workspace: Workspace;
	glazewm: GlazeWmOutput;
}) => {
	// Create a memoized filtered list of windows for this workspace
	const workspaceWindows = createMemo(() => {
		if (!props.glazewm?.allWindows || !props.workspace) return [];
		return props.glazewm.allWindows.filter(
			(window) => window.parentId === props.workspace.id,
		);
	});
	return (
		<button
			type="button"
			class={`workspace ${props.workspace.hasFocus ? "focused" : ""}`}
			onClick={() =>
				props.glazewm.runCommand(`focus --workspace ${props.workspace.name}`)
			}
		>
			{props.workspace.name}
			<Show when={workspaceWindows().length > 0} fallback={<span>—</span>}>
				<For each={workspaceWindows()}>
					{(window) => {
						const appIcon = createMemo(() =>
							window
								? getAppIcon(window.title || "", window.processName || "")
								: ":default:",
						);
						return <span class="sketchy-icon">{appIcon()}</span>;
					}}
				</For>
			</Show>
		</button>
	);
};

const FocusedWindow = (props: { glazewm: Window }) => {
	const focusedContainer = () => props.glazewm.focusedContainer;
	const windowTitle = createMemo(() =>
		focusedContainer()?.title ? parseTitle(focusedContainer().title) : "—",
	);
	return (
		<div class="focused-window">
			<span>{windowTitle()}</span>
		</div>
	);
};

const MediaInfo = (props: { media: MediaOutput }) => (
	<Show when={props.media?.currentSession}>
		<div class="media">
			<i class="nf nf-fa-music" />
			{props.media.currentSession.title} - {props.media.currentSession.artist}
		</div>
	</Show>
);

const TeamsStatus = () => {
	const [isConnected, setIsConnected] = createSignal(false);
	const [ws, setWs] = createSignal<WebSocket | null>(null);

	const connectWebSocket = () => {
		try {
			const websocket = new WebSocket("ws://127.0.0.1:8765/ws");

			websocket.onopen = () => {
				setIsConnected(true);
			};

			websocket.onmessage = (event) => {
				try {
					const data = JSON.parse(event.data);

					// Handle ping messages by sending a pong response
					if (data.type === "ping") {
						const pongResponse = {
							type: "pong",
							timestamp: new Date().toISOString(),
						};
						websocket.send(JSON.stringify(pongResponse));
					}
				} catch (error) {

					console.error("Error parsing message:", error);
				}
			};

			websocket.onclose = () => {
				setIsConnected(false);
				// Retry connection after 5 seconds
				setTimeout(connectWebSocket, 5000);
			};

			websocket.onerror = () => {
				setIsConnected(false);
			};

			setWs(websocket);
		} catch (error) {
			setIsConnected(false);
			// Retry connection after 5 seconds
			setTimeout(connectWebSocket, 5000);
		}
	};

	// Initial connection attempt
	connectWebSocket();

	// Cleanup on component unmount
	onCleanup(() => {
		const websocket = ws();
		if (websocket) {
			websocket.close();
		}
	});

	return (
		<div
			class={
				isConnected() ? "teams-status connected" : "teams-status disconnected"
			}
		>
			<span class="sketchy-icon">:microsoft_teams:</span>
		</div>
	);
};

const SystemStats = (props: {
	memory: MemoryOutput;
	cpu: CpuOutput;
	disk: DiskOutput;
	battery: BatteryOutput;
}) => {
	const diskUsage = createMemo(() =>
		props.disk?.disks?.[0] ? calculateDiskUsage(props.disk.disks[0]) : 0,
	);

	return (
		<div class="stats">
			<Show when={props.memory}>
				<div class="memory">
					<i class="nf nf-fae-chip" />
					{Math.round(props.memory.usage)}%
				</div>
			</Show>

			<Show when={props.cpu}>
				<div class="cpu">
					<span
						class={props.cpu.usage > HIGH_CPU_THRESHOLD ? "high-usage" : ""}
					>
						<i class="nf nf-oct-cpu" />
						{Math.round(props.cpu.usage)}%
					</span>
				</div>
			</Show>

			<Show when={props.disk}>
				<div class="disk">
					<i class="nf nf-fa-hdd_o" />
					{diskUsage()}%
				</div>
			</Show>

			<Show when={props.battery}>
				<div class="battery">
					<Show when={props.battery.isCharging}>
						<i class="nf nf-md-power_plug charging-icon" />
					</Show>
					<i class={getBatteryIcon(props.battery.chargePercent)} />
					{Math.round(props.battery.chargePercent)}%
				</div>
			</Show>
		</div>
	);
};

function App() {
	const [output, setOutput] = createStore(providers.outputMap);
	providers.onOutput(setOutput);

	return (
		<div class="app">
			<div class="left">
				<i class="logo nf nf-fa-windows" />
				<Show when={output.glazewm}>
					<Show
						when={output.glazewm.tilingDirection === "horizontal"}
						fallback={<i class="logo nf nf-fa-arrows_v" />}
					>
						<i class="logo nf nf-fa-arrows_h" />
					</Show>

					<div class="workspaces">
						<For each={output.glazewm.currentWorkspaces}>
							{(workspace) => (
								<WorkspaceButton
									workspace={workspace}
									glazewm={output.glazewm}
								/>
							)}
						</For>
					</div>

					<FocusedWindow glazewm={output.glazewm} />
				</Show>
			</div>

			<div class="center">
				<div class="date">{output.date?.formatted}</div>
				<TeamsStatus />
			</div>

			<div class="right">
				<div class="media-container">
					<Show when={output.media}>
						<MediaInfo media={output.media} />
					</Show>
					<Show when={output.audio?.defaultPlaybackDevice}>
						<i
							class={getVolumeIcon(output.audio.defaultPlaybackDevice.volume)}
						/>
					</Show>
				</div>

				<SystemStats
					memory={output.memory}
					cpu={output.cpu}
					disk={output.disk}
					battery={output.battery}
				/>
			</div>
		</div>
	);
}

render(() => <App />, document.getElementById("root"));
