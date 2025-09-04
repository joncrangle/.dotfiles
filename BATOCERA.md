# 🎮 Batocera Configuration

## Install

1. [Download an Batocera image file](https://batocera.org/#download)
2. Flash the image to a USB using [Etcher](https://etcher.balena.io/)
3. Boot PC from USB
4. 'Menu' (`<Space>`) -> 'System Settings' -> 'Install Batocera on a New Disk'

## Keyboard Shortcuts

### Keyboard

| Key     | Action                |
| ------- | --------------------- |
| `Space` | Open main menu        |
| `Enter` | Main menu             |
| `Esc`   | Back/exit menu        |
| `BS`    | Contextual menu       |
| `F1`    | Open file manager     |


### Controller

`Hotkey` is the middle button.


| Key                           | Action                                                             |
| ----------------------------- | ------------------------------------------------------------------ |
| `Hotkey` + `×`                | Open emulator menu                                                 |
| `Hotkey` + `Start`            | Exit emulator and return to menu                                   |
| `Hotkey` + `○`                | Send the reset command to the emulated system (if available)       |
| `Hotkey` + `L1`               | Take an in-emulator screenshot/something specific to that emulator |
| `Hotkey` + `R1`               | Auto-translate/something specific to that emulator                 |
| `Hotkey` + `L2/R2`            | Select shader/something specific to that emulator                  |
| `Hotkey` + `D-pad up/down`    | Select current save slot                                           |
| `Hotkey` + `D-pad left/right` | Rewind (if enabled)/fast-forward (if available)                    |
| `Hotkey` + `□`                | Save state to current slot                                         |
| `Hotkey` + `△`                | Load state from current slot                                       |


## Configure Batocera

1. Menu -> System Settings -> Timezone
2. Menu -> Updates and Downloads -> Themes -> Iconic-ES.
     - [EmulationStation Themes](https://batocera.org/themes.php)
3. Menu -> User Inferface Settings -> Theme Set -> Iconic-ES
4. Menu -> User Inferface Settings -> Theme Configuration -> Color Scheme -> Dark

### DualShock PS3 controllers

1. Plug it via the USB-cable into the machine Batocera is running on
2. Wait 5-10 seconds
3. Unplug the cable and press the PlayStation button in the middle of the controller

### Wii Controllers

1. Menu -> Controller and Bluetooth Settings -> Pair a Bluetooth Device
2. Press the red button to put the controller in discovery mode (it may take Batocera multiple attempts until there is a successful pair)
3. To use the controller to play the Wii, first start a Wii game, then press the red button to put the controller in discovery mode

## Network Configuration

1. SSH?

```bash
# default password is `linux`
chown root:root / /userdata/ /userdata/system/
chmod 755 / /userdata/ /userdata/system/
mkdir -p ~/.ssh
touch ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

```bash
# Transfer ssh key from clients
ssh-copy-id root@batocera.local
```

2. ODSP?

## Add ROMs

## Configure Emulators

1. Copy `bios`, `roms`, `saves` and `system` directories to matching folders in Batocera's `share` directory (Replace All). Options include: File Manager (`<F1>`), Network Share (`\\Batocera`) or SSH (`mc` for Midnight Commander)
2. File Manager (`<F1>`) -> 'Applications'

### Switch

1. -> `xterm`

```bash
curl -L bit.ly/foclabroc-switchoff | bash
exit
```

2. Download firmware `18.1.0` and `prod.keys` and `title.keys` in `/bios/switch`
3. Ryujinx-config -> Tools -> Install Firmware -> Install a firmware from XCI or zip

#### Advanced System Options

- Emulator: Ryujinx-continuous
- Auto Controller Config: off
- Graphics Backend: Vulkan

Play a game, then press `<F4>`. Options -> Settings -> Input -> Input Device -> Select the controller and configure. Press `<F4>` again to return to fullscreen.

Sudachi emultor can leave auto controller on.

Then install DLC for games.

## Additional Resources

- [Batocera Nation](https://www.youtube.com/@BatoceraNation)
