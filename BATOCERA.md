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


### Controller Reconnection Issues

1. Create `services` directory

```bash
mkdir -p /userdata/system/services
```

2. Create `bluetoothfix` (no file extension) in `/userdata/system/services`

```bash
#!/bin/bash
sleep 5
btmgmt ssp off

while true; do
  # check if bt scan is active
  result=$(bluetoothctl show | grep -c 'Discovering: yes')

  if [ $result -eq 1 ]; then
    # SSP turn on
    btmgmt ssp on

    # wait 1 min
    sleep 60

    # SSP turn off
    btmgmt ssp off
  fi

  # wait 5 seconds for the next check
  sleep 5
done
```

3. Reboot Batocera
4. Menu -> System Settings -> Services
5. Activate the service called "bluetoothfix" (Batocera can become unresponsive, if it does just reboot by pressing the Powerbutton on your machine)

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
3. To use the Wii Controller to play the Wii, first start a Wii game, then press the red button to put the controller in discovery mode

> [!TODO]
> Try to determine why Bluetooth controllers are not reconnecting
> [Issue #9006](https://github.com/batocera-linux/batocera.linux/issues/9006)

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
7. UI: Add logins/passwords for ScreenScraper and IGDB in Menu -> Scraper -> ????
   SSH: Edit `/userdata/system/configs/emulationstation/es_settings.cfg`:
   For Screenscraper:

   ```xml
   <string name="ScreenScraperUser" value="your_login" />
   <string name="ScreenScraperPass" value="your_pass" />
   ```

   For IGDB:

   ```xml
   <string name="IGDBClientID" value="your_id" />
   <string name="IGDBSecret" value="your_secret" />
   ```

   Make sure EmulationStation is stopped before editing this file, otherwise **ES will reverse your modifications**.
8. Menu -> Scraper -> Scrape from: ScreenScraper -> `Scrape Now`.
9. Menu -> Game Settings -> Update gamelists

## Configure Emulators

## Aspect Ratio and Scaling

> [!INFO]
Update for MAME, Commodore 64, FB Neo, PC Engine , NES, SNES, GBA, NDS DS, Ports, Sega Megadrive, Dreamcast and PSX

<Select> -> Advanced System Options -> Game Aspect Ratio -> Core Provided 

<Select> -> Advanced System Options -> Game Rendering & Shaders -> Integer Scaling -> On

### Nintendo DS

<Select> -> Advanced System Options -> Emulator -> Libretto: MelonDSDS

### Nintendo GameCube

<Select> -> Advanced System Options -> GameCube Controller 1 -> GameCube Port 1 Type -> GameCube Controller

### Nintendo Switch

1. File Manager -> Applications -> `xterm` or use SSH

```bash
curl -L bit.ly/foclabroc-switchoff | bash
```

2. Move zip file and extracted `firmware` folder of Nintendo Switch firmware `18.1.0` into `/bios/switch`
3. Move `prod.keys` and `title.keys` into `/bios/switch`

#### Advanced System Options

##### Eden

1. File Manager -> Applications -> `eden-config`
2. Tools -> Install Decryption Keys -> `bios/switch/prod.keys`
3. Tools -> Install Firmware -> `/bios/switch/firmware`
4. File -> Install NAND -> Select all DLC and Update files
5. Emulation -> Configure -> Controls -> Input Device -> Select the controller and configure

##### Ryujinx

1. File Manager -> Applications -> `ryujinx-config`
2. Actions -> Install Decryption Keys -> `bios/switch/prod.keys`
3. Actions -> Install Firmware -> Install Firmware (.XCI or .ZIP) -> `bios/switch/Firmware 18.1.0.zip`

### PlayStation 3

1. File Manager -> Applications -> `rpcs3-config`
2. File -> Install Firmware select `PS3UPDAT.PUP`
3. Use [RPCS3 Wiki](https://wiki.rpcs3.net/index.php?title=Main_Page) to determine individual game settings
4. File -> Install Packages/Raps/Edats -> Install pkg files, DLC and updates

### Xbox 360

1. File Manager -> Applications -> `xenia-config` -> Create a Gamertag

## Wake On LAN

Configure Wake on LAN settings within the PC BIOS/UEFI.

## Remove `._*` files

To remove files beginning with `._`:

```bash
find /userdata/ -name "._*" -exec rm {} \;
```

## Additional Resources

- [Batocera Wiki](https://wiki.batocera.org/start)
- [Batocera Nation](https://www.youtube.com/@BatoceraNation)
