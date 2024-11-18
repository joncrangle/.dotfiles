import icons from "lib/icons";
import keyBindings, { KeyBinding } from "service/cheatsheet";

const iconVisible = Variable(false);

function Item(kb: KeyBinding) {
	const keybinding = Widget.Label({
		class_name: "title",
		label: kb.keybinding,
		hexpand: true,
		xalign: 0,
		vpack: "center",
		truncate: "end",
		margin_end: 10,
	});

	const description = Widget.Label({
		class_name: "description",
		label: kb.description,
		hexpand: true,
		wrap: true,
		max_width_chars: 30,
		xalign: 1,
		justification: "left",
		vpack: "center",
	});

	return Widget.Box({
		attribute: { keyBinding: kb, vertical: true },
		class_name: "keybinding",
		vpack: "center",
		children: [keybinding, description],
	});
}

export function Icon() {
	const icon = Widget.Icon({
		icon: icons.ui.keyboard,
		className: "spinner",
	});

	return Widget.Revealer({
		transition: "slide_left",
		child: icon,
		reveal_child: iconVisible.bind(),
	});
}

export const Cheatsheet = () => {
	const list = Widget.Box<ReturnType<typeof Item>>({
		vertical: true,
	});

	const revealer = Widget.Revealer({
		child: list,
	});

	async function filter(term: string) {
		term = term.trim();
		iconVisible.value = true;
		const found = await keyBindings.query(term);
		list.children = found.map((k) => Item(k));
		revealer.reveal_child = true;
	}

	function clear() {
		iconVisible.value = false;
		list.children = [];
		revealer.reveal_child = false;
	}

	return Object.assign(revealer, {
		filter,
		clear,
	});
};
