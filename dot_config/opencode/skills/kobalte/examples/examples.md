# Kobalte Examples

## 1. Select (Dropdown)
Standard single-select dropdown with Tailwind styling.

```tsx
import { Select } from "@kobalte/core/select";
import { VsChevronDown, VsCheck } from "solid-icons/vs";

const MySelect = () => (
  <Select
    options={["Apple", "Banana", "Blueberry", "Grapes"]}
    placeholder="Select a fruit…"
    itemComponent={(props) => (
      <Select.Item item={props.item} class="flex items-center justify-between p-2 hover:bg-zinc-100 data-[selected]:bg-zinc-200 cursor-pointer">
        <Select.ItemLabel>{props.item.rawValue}</Select.ItemLabel>
        <Select.ItemIndicator><VsCheck /></Select.ItemIndicator>
      </Select.Item>
    )}
  >
    <Select.Trigger class="inline-flex items-center justify-between w-48 p-2 border rounded bg-white">
      <Select.Value<string>>{(state) => state.selectedOption()}</Select.Value>
      <Select.Icon><VsChevronDown /></Select.Icon>
    </Select.Trigger>
    
    <Select.Portal>
      <Select.Content class="bg-white border rounded shadow-lg p-1 animate-content-hide data-[expanded]:animate-content-show">
        <Select.Listbox class="max-h-64 overflow-auto" />
      </Select.Content>
    </Select.Portal>
  </Select>
);
```

## 2. Dialog (Modal)
Modal with overlay and focus trap.

```tsx
import { Dialog } from "@kobalte/core/dialog";
import { VsClose } from "solid-icons/vs";

const MyDialog = () => (
  <Dialog>
    <Dialog.Trigger class="btn-primary">Open Settings</Dialog.Trigger>
    
    <Dialog.Portal>
      <Dialog.Overlay class="fixed inset-0 bg-black/50 z-50 animate-overlay-show" />
      <Dialog.Content class="fixed top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 bg-white p-6 rounded-lg shadow-xl z-50 w-full max-w-md">
        <div class="flex justify-between items-center mb-4">
          <Dialog.Title class="text-xl font-bold">Edit Profile</Dialog.Title>
          <Dialog.CloseButton><VsClose /></Dialog.CloseButton>
        </div>
        <Dialog.Description class="text-zinc-500 mb-4">
          Make changes to your profile here. Click save when you're done.
        </Dialog.Description>
        
        {/* Form Content */}
        
        <div class="flex justify-end gap-2 mt-6">
          <Dialog.CloseButton class="btn-ghost">Cancel</Dialog.CloseButton>
          <button class="btn-primary">Save Changes</button>
        </div>
      </Dialog.Content>
    </Dialog.Portal>
  </Dialog>
);
```

## 3. Tabs
Tabbed interface with manual activation.

```tsx
import { Tabs } from "@kobalte/core/tabs";

const MyTabs = () => (
  <Tabs defaultValue="account" class="w-full">
    <Tabs.List class="flex border-b border-zinc-200">
      <Tabs.Trigger 
        value="account" 
        class="px-4 py-2 border-b-2 border-transparent data-[selected]:border-blue-500 data-[selected]:text-blue-600"
      >
        Account
      </Tabs.Trigger>
      <Tabs.Trigger 
        value="password" 
        class="px-4 py-2 border-b-2 border-transparent data-[selected]:border-blue-500 data-[selected]:text-blue-600"
      >
        Password
      </Tabs.Trigger>
    </Tabs.List>
    
    <Tabs.Content value="account" class="p-4">
      Account settings...
    </Tabs.Content>
    <Tabs.Content value="password" class="p-4">
      Password settings...
    </Tabs.Content>
  </Tabs>
);
```

## 4. Toast (Notifications)
Using the Toaster singleton pattern.

```tsx
import { Toast, toaster } from "@kobalte/core/toast";
import { Portal } from "solid-js/web";

// 1. Setup Region (Root of App)
const ToastRegion = () => (
  <Portal>
    <Toast.Region limit={3}>
      <Toast.List class="fixed bottom-0 right-0 p-4 flex flex-col gap-2 z-[100]" />
    </Toast.Region>
  </Portal>
);

// 2. Custom Toast Component
const showNotification = (title: string, msg: string) => {
  toaster.show((props) => (
    <Toast toastId={props.toastId} class="bg-white border rounded shadow-lg p-4 w-80 animate-slide-in-right">
      <div class="flex justify-between">
         <Toast.Title class="font-bold">{title}</Toast.Title>
         <Toast.CloseButton class="text-zinc-400 hover:text-zinc-600">×</Toast.CloseButton>
      </div>
      <Toast.Description>{msg}</Toast.Description>
    </Toast>
  ));
};

// 3. Usage
// <button onClick={() => showNotification("Success", "Data saved!")}>Save</button>
```

## 5. Combobox (Autocomplete)
Searchable input with filtering.

```tsx
import { Combobox } from "@kobalte/core/combobox";

const MyCombobox = () => (
  <Combobox
    options={["React", "Solid", "Vue", "Svelte"]}
    placeholder="Select framework..."
    itemComponent={(props) => (
      <Combobox.Item item={props.item} class="p-2 cursor-pointer data-[highlighted]:bg-zinc-100">
        <Combobox.ItemLabel>{props.item.rawValue}</Combobox.ItemLabel>
      </Combobox.Item>
    )}
  >
    <div class="relative">
      <Combobox.Control class="flex items-center border rounded p-2">
        <Combobox.Input class="outline-none bg-transparent" />
        <Combobox.Trigger class="ml-auto opacity-50">▼</Combobox.Trigger>
      </Combobox.Control>
    </div>
    
    <Combobox.Portal>
      <Combobox.Content class="bg-white border rounded shadow mt-1">
        <Combobox.Listbox />
      </Combobox.Content>
    </Combobox.Portal>
  </Combobox>
);
```
