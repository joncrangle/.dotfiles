import lowBattery from "./battery";
import notifications from "./notifications";

export default function init() {
	try {
		lowBattery();
		notifications();
	} catch (error) {
		logError(error);
	}
}
