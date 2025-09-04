# 🎮 Batocera Configuration

## Install

1. [Download an Batocera image file](https://batocera.org/#download)
2. Flash the image to a USB using [Etcher](https://etcher.balena.io/)
3. Boot PC from USB
4. 'Menu' (`<Space>`) -> 'System Settings' -> 'Install Batocera on a New Disk'

## Shortcuts

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

1. Connect to Batocera via SSH

```bash
ssh root@batocera.local
# default password is `linux`
```

2. Add SSH Keys

```bash
chown root:root / /userdata/ /userdata/system/
chmod 755 / /userdata/ /userdata/system/
mkdir -p ~/.ssh
touch ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys

# Transfer ssh key from clients
ssh-copy-id root@batocera.local
```

3. Mount `smb://batocera.local/share` and any source locations
4. Copy `bios`, `roms`, `saves` and `system` directories to matching folders in Batocera's `share` directory (Replace All)
5. Copy ROMs to the `roms` folder
6. Copy any additional saves to the `saves` folder
7. Menu -> Scraper -> Scrape from: theGameDB
8. Menu -> Game Settings -> Update gamelists

## Configure Emulators

> [!TODO]
> Document emulator configurations for specific emulators

### Switch

1. File Manager -> Applications -> `xterm` or use SSH

```bash
curl -L bit.ly/foclabroc-switchoff | bash
```

2. Move zip file of firmware `18.1.0` and `prod.keys` and `title.keys` into `/bios/switch`
3. File Manager -> Applications -> Ryujinx-config -> Tools -> Install Firmware -> Install a firmware from XCI or zip

#### Advanced System Options

- Emulator: Ryujinx-continuous
- Auto Controller Config: off
- Graphics Backend: Vulkan

Play a game, then press `<F4>`. Options -> Settings -> Input -> Input Device -> Select the controller and configure. Press `<F4>` again to return to fullscreen.

Sudachi emulator can leave auto controller on.

Then install DLC for games.

## Additional Resources

- [Batocera Wiki](https://wiki.batocera.org/start)
- [Batocera Nation](https://www.youtube.com/@BatoceraNation)
