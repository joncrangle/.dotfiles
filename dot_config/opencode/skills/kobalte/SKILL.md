---
name: kobalte
description: Specialist in Kobalte, a headless, accessible UI component library for SolidJS. Focuses on accessibility (ARIA), composability, and styling unstyled primitives.
---
<skill_doc>
<trigger_keywords>
## Trigger Keywords

Activate this skill when the user mentions any of:

**Core**: Kobalte, Headless UI, Unstyled components, Accessible UI, A11y

**Components**: Select, Combobox, Dialog, Popover, Toast, Tabs, Accordion, Tooltip, Menubar, DropdownMenu

**Concepts**: Portal, Trigger, Content, Root, Polymorphism (as prop)

**Styling**: data-attributes, data-expanded, data-disabled, @kobalte/tailwindcss
</trigger_keywords>

## ⛔ Forbidden Patterns

1.  **NO Built-in Styles**: Do NOT expect components to look "good" out of the box. They are unstyled. You MUST apply CSS/Tailwind classes.
2.  **NO Missing Portals**: Always use `<Component.Portal>` for overlays (Dialog, Popover, Tooltip, Select) to avoid z-index/clipping issues.
3.  **NO Manual ARIA**: Do NOT manually add `role`, `aria-expanded`, etc. Kobalte manages this.
4.  **NO Direct Input in Select**: Use `<Select>` for button-triggered lists. Use `<Combobox>` if you need a text input.
5.  **NO Skipping `Root`**: All parts must be nested within the `Root` component (or passed via Context).

## 🤖 Agent Tool Strategy

1.  **Styling Strategy**: Check if Tailwind is used. If so, recommend `@kobalte/tailwindcss` plugin for `ui-selected:` modifiers.
2.  **Composition**: Always show the full structure: `Root` -> `Trigger` -> `Portal` -> `Content`.
3.  **Accessibility**: Emphasize that Kobalte handles focus management and keyboard nav automatically.
4.  **Integration**: Kobalte works perfectly with `@opentui/solid` (if using standard DOM renderer) or web projects.

## Quick Reference (30 seconds)

Kobalte Specialist - Accessible, Headless Primitives for SolidJS.

**Philosophy**:
- **Headless**: Logic only. You bring the UI/CSS.
- **Accessible**: WAI-ARIA APG compliant out of the box.
- **Composable**: Build complex UIs from granular parts.

**Styling via Data Attributes**:
- `[data-expanded]`: Component is open.
- `[data-selected]`: Item is active.
- `[data-disabled]`: Component is inactive.
- `[data-highlighted]`: Item is focused via keyboard.

**Anatomy**:
1.  **Root**: State container.
2.  **Trigger**: Toggle button.
3.  **Portal**: Renders overlay at body root.
4.  **Content**: The actual popup/panel.

---

## Resources

- **Examples**: See `examples/examples.md` for detailed code patterns.
- **References**: See `references/reference.md` for official documentation links.
</skill_doc>
