import "lib/session";
import "style/style";
import init from "lib/init";
import options from "options";
import Bar from "widget/bar/Bar";
import NotificationPopups from "widget/notifications/NotificationPopups";
import OSD from "widget/osd/OSD";
import Overview from "widget/overview/Overview";
import PowerMenu from "widget/powermenu/PowerMenu";
import ScreenCorners from "widget/bar/ScreenCorners";
import SettingsDialog from "widget/settings/SettingsDialog";
import Verification from "widget/powermenu/Verification";
import { forMonitors } from "lib/utils";
import { resetCss } from "style/style";
import { setupDateMenu } from "widget/datemenu/DateMenu";
import { setupLauncher } from "widget/launcher/Launcher";
import { setupQuickSettings } from "widget/quicksettings/QuickSettings";

App.config({
	onConfigParsed: () => {
		setupDateMenu();
		setupQuickSettings();
		setupLauncher();
		init();
		resetCss();
	},
	closeWindowDelay: {
		launcher: options.transition.value,
		overview: options.transition.value,
		quicksettings: options.transition.value,
		datemenu: options.transition.value,
	},
	windows: [
		...forMonitors(Bar),
		...forMonitors(NotificationPopups),
		...forMonitors(OSD),
		...forMonitors(ScreenCorners),
		Overview(),
		PowerMenu(),
		SettingsDialog(),
		Verification(),
	],
});

export { };
