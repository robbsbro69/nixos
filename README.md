# nixos-dotfiles

A NixOS desktop built around **Hyprland** (configured in Lua) and a hand-written **Quickshell** shell. The system and user environment are declared with flakes and Home Manager. Every app config under `config/` is live-symlinked into `~/.config`, so editing it in the repo applies immediately — no rebuild.

<div align="center">

![NixOS](https://img.shields.io/badge/NixOS-26.05-5277C3?style=flat&logo=nixos&logoColor=white)
![Hyprland](https://img.shields.io/badge/Hyprland-unstable%20·%20Lua-58E1FF?style=flat)
![Quickshell](https://img.shields.io/badge/Quickshell-git-F5C2E7?style=flat)
![Theme](https://img.shields.io/badge/Catppuccin-Mocha%20Pink-F5C2E7?style=flat)
![License](https://img.shields.io/badge/License-MIT-A6E3A1?style=flat)

</div>

https://github.com/user-attachments/assets/370773de-65d8-40f3-ad4d-80987ba59b45



---

## Contents

- [Stack](#stack)
- [Layout](#layout)
- [The bar](#the-bar)
- [Panels](#panels)
- [Lyrics & subtitles](#lyrics--subtitles)
- [Pomodoro & focus mode](#pomodoro--focus-mode)
- [Theming](#theming)
- [Hyprland](#hyprland)
- [Neovim](#neovim)
- [Services](#services)
- [Keybinds](#keybinds)
- [IPC](#ipc)
- [Install](#install)
- [Day-to-day](#day-to-day)
- [Notes](#notes)

---

## Stack

| Area          | Choice                                                                  |
| ------------- | ----------------------------------------------------------------------- |
| OS            | NixOS `nixos-26.05`, with `nixos-unstable` available as `pkgs-unstable` |
| Compositor    | Hyprland (unstable), Lua config                                         |
| Shell / bar   | Quickshell (upstream git flake), custom QML                             |
| Login / boot  | SDDM + Plymouth (Catppuccin), systemd-boot, latest kernel               |
| GPU           | AMD iGPU + NVIDIA (open driver, PRIME offload)                          |
| Terminal      | Kitty + Starship                                                        |
| Editors       | Neovim (lazy.nvim), VS Code, Arduino IDE, PlatformIO                    |
| Files         | Thunar + Yazi                                                           |
| Browsers      | Zen (default, flake) + Brave                                            |
| Music / video | MPD + rmpc, Spotify (Spicetify), Kopuz, mpv (MPRIS)                     |
| Media server  | Jellyfin, Transmission, Honne (Podman)                                  |
| Notifications | own Python D-Bus daemon → Quickshell                                    |
| Audio         | PipeWire + WirePlumber                                                  |
| DNS           | systemd-resolved, DNS-over-TLS, DNSSEC                                  |
| Remote        | Tailscale, NFS                                                          |
| AI            | opencode (unstable)                                                     |
| Font          | JetBrainsMono Nerd Font                                                 |

### Flake inputs

| Input              | Source                                              |
| ------------------ | --------------------------------------------------- |
| `nixpkgs`          | `github:NixOS/nixpkgs/nixos-26.05`                  |
| `nixpkgs-unstable` | `github:NixOS/nixpkgs/nixos-unstable`               |
| `home-manager`     | `github:nix-community/home-manager/release-26.05`   |
| `zen-browser`      | `github:0xc000022070/zen-browser-flake`             |
| `quickshell`       | `git+https://git.outfoxxed.me/outfoxxed/quickshell` |
| `spicetify-nix`    | `github:Gerg-L/spicetify-nix`                       |
| `kopuz`            | `github:temidaradev/kopuz` (+ `kopuz.cachix.org`)   |

---

## Layout

```
nixos-dotfiles/
├── flake.nix / flake.lock
├── configuration.nix            system entry → modules/system/*
├── home.nix                     Home Manager entry → modules/home/*
├── hardware-configuration.nix
├── pkgs/pomodoro-bomb/          the original PySide6 dynamite timer (own derivation)
├── modules/
│   ├── system/
│   │   ├── boot/                kernel, plymouth
│   │   ├── hardware/            nvidia PRIME, bluetooth, /mnt/ssd, i2c
│   │   ├── display/             hyprland, portals, xserver, appimage, nix-ld, VirtualBox, Podman
│   │   ├── networking/          NetworkManager, firewall, resolved + DoT
│   │   ├── services/            pipewire, sddm, jellyfin, mpd, honne, transmission, nfs, tailscale, udev
│   │   └── fonts.nix  nix.nix  packages.nix  security.nix  users.nix
│   └── home/
│       ├── browsers/            zen, brave, mime defaults
│       ├── desktop/             hyprland pkgs, GTK, Qt, cursor
│       ├── dev/                 git, ssh, editors, languages, tools, ai
│       ├── media/               spicetify, mpv, mpd client tools, apps, mime
│       ├── office/              libreoffice, obsidian, xournal++
│       ├── shell/               bash aliases, starship
│       ├── packages.nix
│       └── symlinks.nix         mkOutOfStoreSymlink: config/* → ~/.config/*
└── config/
    ├── hypr/                    hyprland.lua + hyprland/*.lua, hypridle, hyprlock
    ├── quickshell/              the shell
    │   ├── shell.qml            global state, palettes, processes, IPC
    │   ├── UIState.qml / Colors.qml / Animations.qml
    │   ├── assets/              get-player.sh, notif-daemon.py, lyrics.py, subs.py, gifs …
    │   ├── state/               saved UI settings (bar, theme, eq, pomodoro …)
    │   └── components/          Bar, panels, overlays (one file each)
    ├── scripts/                 record, theme, nightlight, eq, power, screentime-poll …
    ├── cava/  nvim/  kitty/  mpv/  rmpc/  yazi/  starship/  fastfetch/  vesktop/  wal/
    └── zen/chrome/              userChrome / userContent
```

---

## The bar

Top or bottom, picked from the bar menu (`󰏘` button or `Super+Ctrl+B`). Settings are saved and restored at login.

| Setting      | Options                                                                         |
| ------------ | ------------------------------------------------------------------------------- |
| Position     | Top · Bottom (`Super+Shift+B` flips)                                            |
| Visibility   | Always · Auto-hide (touch the edge) · Hidden (`Super+B` toggles)                |
| Style        | **Default** · **i3bar** · **Enjoy** (Default without the work components) |
| Layout       | Attached · Floating (equal gap on every side, square corners)                   |
| Transparency | Opaque · Transparent · Blur                                                     |
| Theme        | Catppuccin · Rosé Pine · Nord · Dracula · Gruvbox · Tokyo Night · Monochrome, light/dark |

### Default style, left to right

| Component        | Left click                 | Right click         | Other                              |
| ---------------- | -------------------------- | ------------------- | ---------------------------------- |
| NixOS logo       | App launcher               | Wallpaper picker    |                                    |
| Clock / date     | Clock panel                | Calendar            |                                    |
| Workspaces       | Switch                     | Workspace overview  | Scroll to cycle                    |
| Music            | Play / pause               | Music panel         | Middle: next · scroll: next / prev |
| Lyrics ticker    | —                          | —                   | see [Lyrics & subtitles](#lyrics--subtitles) |
| Battery          | Screen time                |                     | animated while charging            |
| Volume           | Mute                       | Equalizer           | Scroll ±5 %                        |
| Network          | Wi-Fi panel                | Bluetooth panel     |                                    |
| Tray             | Activate                   | Menu                |                                    |
| Pomodoro bomb    | Pomodoro panel             | Start / pause       | Middle: reset · scroll: minutes    |
| Recorder `󰑋`     | Recorder menu / stop       | Recorder menu       | red timer while recording          |
| Sticky notes `󰎚` | Show / hide notes          |                     |                                    |
| Clipboard        | Clipboard panel            | Sticky notes        |                                    |
| Bar menu `󰏘`     | Bar & theme menu           | Next theme          |                                    |
| Dashboard        | Dashboard                  | Notification center |                                    |

While something plays, a mirrored cava visualizer runs behind the whole bar (attached layout).

### i3bar style

A look-alike of i3bar + i3status: black bar, monospace text, i3 workspace buttons (blue focused, grey others, red urgent), and a status line with grey separators and i3status colours (green good, yellow degraded, red bad):

```
 1 2 3 | ♪ track | POMO 18:20 | REC | W: (73% at ssid) | BT: on | E: down | /: 120 GiB | load: 0.4 | MEM: 4.1 GiB | VOL: 45% | BAT 85% | 2026-10-26 13:10:06 | tray | CLIP | DASH | ≡
```

Every block keeps its click / scroll actions. `≡` or right-click on empty bar space opens the bar menu. Clock and calendar panels open on the right in this style.

---

## Panels

All panels slide in from their edge, take keyboard focus, and close with `Esc`.

- **Dashboard** — avatar, power row (poweroff / reboot / lock / suspend / logout), night light (scroll for 1500–6500 K) and light/dark toggles, battery, CPU / RAM / disk rings, volume and brightness sliders, clock.
- **Launcher** — usage-sorted apps, plus a wallpaper tab.
- **Music** — opens right under the music component in the bar. Title, artist, seek bar, controls on a live cava backdrop; dancing GIF or draggable vinyl; player picker (Auto or a pinned MPRIS player).
- **Sticky notes** — a floating note you **drag anywhere** by its header (position remembered). Tabs, six paper colours, autosave to `~/.local/share/quickshell/notes.json` (outside the repo). Stays open while you use other panels. `Ctrl+N` new · `Ctrl+W` delete · `Ctrl+Tab` switch.
- **Screen recorder** — full screen, a specific monitor, or a `slurp` region, with a **Sound** switch: laptop audio · laptop + mic · off. Uses [gpu-screen-recorder](https://git.dec05eba.com/gpu-screen-recorder/about/) (hardware encoding, 60 fps), records to `.mkv` so nothing is lost if it crashes, then remuxes to `.mp4` in `~/Videos/screen-recordings/`. A watchdog saves and notifies if the recorder stalls; stop always works. Also `config/scripts/record.sh full|output NAME|region|stop|toggle|status`, log in `~/.cache/qs-record.log`.
- **Clipboard** — cliphist history with image thumbnails, emoji and kaomoji search.
- **Notification center** — 50-item history and Do Not Disturb.
- **Wi-Fi / Bluetooth** — connect with password; pair / connect / forget.
- **Calendar** — AD and Bikram Sambat (BS 2000–2090, full BS ↔ AD conversion).
- **Clock** — analog clock, timer, stopwatch with laps, alarms.
- **Equalizer** — 10 bands (32 Hz – 16 kHz, ±12 dB), presets, response curve; runs a PipeWire filter-chain (`scripts/eq.sh`).
- **Workspace overview** — every occupied workspace with a live mini-map of its windows. Click a window to jump to it, **drag it onto another workspace (or `＋ new workspace`) to move it there**, `1`–`9` to switch.
- **Screen time** — today's total, hourly chart, 7-day view with **previous-week navigation** (arrows, or the `this week` / `today` button to jump back), most-used apps. Counts time at the computer: pauses after 2 min without input or when locked, but **keeps counting while a video plays** (browser, mpv, VLC, Jellyfin…). Music alone doesn't count when you're idle. Days split at midnight. Data in `~/.local/share/quickshell/screentime.json`, 35 days kept.
- **Bar menu** — every bar setting from the table above, plus theme previews.

---

## Lyrics & subtitles

The music sits on the left of the bar; the free space up to the battery shows a **ticker** that keeps scrolling right → left, synced to playback. The line being sung/spoken is highlighted (pink for lyrics, teal for subtitles), upcoming lines are dimmed on the right, past ones fade out on the left. It follows pause and seek.

| Playing                                       | Source                                                            | Speed       |
| --------------------------------------------- | ----------------------------------------------------------------- | ----------- |
| Songs — Spotify, YouTube (Music), mpv, mpd …  | synced lyrics from [LRCLIB](https://lrclib.net) (`assets/lyrics.py`) | ~1 s     |
| Other YouTube videos in the browser           | the video's own captions via yt-dlp (`assets/subs.py`)            | ~20–30 s    |
| Netflix / anime sites / local files           | nothing — those don't expose subtitles                            |             |

`subs.py` finds the video by its title, retrieves captions anonymously by default, and tries YouTube clients that don't need a PO token (`web_embedded`, `tv`, `android_vr`) when the default one hides captions. It prefers captions made from the video's own audio, joins auto-caption word fragments into readable chunks, and retries on rate limits.

- Language: the video's own language by default. `echo en > ~/.config/quickshell/subs-lang` prefers English (YouTube translation if needed); delete the file to go back.
- Cache: `~/.cache/quickshell/{lyrics,subs}/` — rewatches are instant.
- Debug: `SUBS_DEBUG=1 python3 ~/.config/quickshell/assets/subs.py x "<title>" "<channel>" <seconds> "<youtube-url>"`

---

### Optional browser cookies

Subtitle fetching does not discover or read browser profiles by default. To let
`yt-dlp` use a specific Zen/Firefox session, put that profile's absolute directory
in `~/.config/quickshell/subs-cookie-profile` (one line). For example:

```sh
printf '%s\n' "$HOME/.config/zen/your-profile" > ~/.config/quickshell/subs-cookie-profile
```

Choose the directory containing `cookies.sqlite`, not the database file itself.
This lets yt-dlp access that browser session and make authenticated requests.
Delete or empty the setting file to return to anonymous requests. Cookies are
optional; anonymous requests can still be rate limited or require login.

## Pomodoro & focus mode

The pomodoro lives in Quickshell: bomb notch with countdown and burning fuse, a panel with the dynamite, start / pause / reset / skip, focus / break / long-break steppers and session dots. When a phase ends: notification, explosion sound and a click-through fullscreen BOOM. Settings are saved in `state/pomodoro`.

**Focus mode** kicks in automatically while a *focus* session is running:

- the bar is fully hidden — no edge peek, no panels bringing it back
- Do Not Disturb on (your previous setting returns afterwards; the pomodoro's own alerts still come through)
- a small click-through timer pill at the top with a progress line
- optional jump to a dedicated workspace — `pomoZenWs` in `shell.qml` (`0` = stay where you are)

Pausing, stopping or reaching the break ends focus mode. `qs ipc call pomozen on|off|toggle` enables / disables it (resets to on at restart).

---

## Theming

Colours come from official palettes defined once in `shell.qml` (`palettes`, exposed as `root.wal*`), mirrored by `Colors.qml`. `root.card(a)` / `root.hover(a)` give insets and hovers that work in both light and dark. With Catppuccin, both accents are pink (`#f5c2e7`), so the shell doesn't drift into mauve.

The rest of the desktop is Catppuccin Mocha Pink: GTK, SDDM, Plymouth, Spicetify, Zen, Starship, Yazi, rmpc, mpv, fzf. Hyprland runs `wal --theme catppuccin-mocha-pink` at startup for the pywal templates. The light/dark toggle also flips the desktop colour-scheme hint and the GTK3 theme via `config/scripts/theme.sh`.

Wallpapers live in `~/wallpapers/`. Picking one runs `awww img` with a transition, links it as `~/wallpapers/current` and writes a blurred copy for hyprlock. `Super+Shift+W` plays a shuffled queue.

---

## Hyprland

`hyprland.lua` requires `monitors`, `env`, `execs`, `general`, `mocha`, `animations`, `gestures`, `keybinds` and `rules` from `config/hypr/hyprland/`.

- **Monitors** — external only right now: `HDMI-A-1` 1920×1080@60, `eDP-1` disabled. Dual-screen (laptop at 144 Hz + HDMI side by side) and laptop-only layouts are kept commented in `monitors.lua`.
- **Startup** — ssh-add, `awww-daemon`, pywal, night light restore, hypridle, cliphist watchers, polkit agent, Quickshell.
- **Idle** — dim at 4 min, lock at 8 min, screen off at 8.5 min.
- **Gestures** — 3-finger vertical: switch workspace · 3-finger horizontal: scroll-move · 4-finger pinch out / in: fullscreen on / off.
- **Rules**
  - Zen → workspace 1, Obsidian → 2, Spotify → 3 (silent, no focus steal)
  - Picture-in-Picture: floating, pinned, aspect-locked, bottom-right at ¼ size
  - screen-sharing indicator: floating, pinned, bottom-centre · Telegram media viewer floats
  - idle inhibit for mpv / celluloid, YouTube in Zen, and fullscreen Zen
  - no shadow on tiled windows, 4 px rounding on floating ones, square XWayland windows, JetBrains dialog fixes
  - dim behind polkit / keyring / file-picker dialogs
  - pomodoro-bomb pinned top-right without chrome; its blast overlay covers the whole monitor
  - Quickshell layers: blur, alpha thresholds and no-anim rules for the bar, popups and notifications

---

## Neovim

lazy.nvim, bootstrapped from `init.lua`; one file per plugin in `config/nvim/lua/plugins/`.

| Plugin                                      | Purpose                                                    |
| ------------------------------------------- | ---------------------------------------------------------- |
| tokyonight                                  | colour scheme                                              |
| lsp (nvim-lspconfig)                        | language servers (rust_analyzer, lua_ls …)                 |
| cmp                                         | completion + snippets                                      |
| autoformat (conform.nvim)                   | format on save: rustfmt, stylua, biome / prettier, alejandra |
| telescope                                   | files, grep, buffers, LSP pickers                          |
| treesitter                                  | highlighting / indent                                      |
| harpoon                                     | quick file slots                                           |
| gitsigns, git-conflict                      | git in the gutter, conflict helpers                        |
| oil, neotree, yazi                          | file browsing three ways                                   |
| dashboard                                   | start screen                                               |
| lualine, which-key                          | statusline, key hints                                      |
| mini, autopairs, tabout, comment            | editing comfort                                            |
| silicon, markdown-preview, colorizer        | code screenshots, live markdown, colour swatches           |

---

## Services

| What          | Where                     | Notes                                                       |
| ------------- | ------------------------- | ----------------------------------------------------------- |
| Jellyfin      | `services/jellyfin.nix`   | runs as `alpha`, waits for `/mnt/ssd`, library scan every 15 min (`/etc/jellyfin-api-key`) |
| Transmission  | `services/transmission.nix` | web UI on `:9091` |
| MPD           | `services/media.nix`      | PipeWire output + `/tmp/mpd.fifo` for visualizers            |
| Honne         | `services/media.nix`      | Podman container on `:7417`, env in `/etc/honne.env`         |
| Tailscale     | `services/tailscale.nix`  | MagicDNS (`100.100.100.100`)                                 |
| VirtualBox / Podman / nix-ld | `display/hyprland.nix` | extension pack, `dockerCompat`, CUDA libs for foreign binaries |
| gpu-screen-recorder | `display/hyprland.nix` | `programs.gpu-screen-recorder` (capture permission) for the recorder |
| Nix           | `nix.nix`                 | weekly GC (> 7 days), auto-optimise, Hyprland / nix-community / kopuz caches |

---

## Keybinds

| Keys                                   | Action                              |
| -------------------------------------- | ----------------------------------- |
| `Super+Return`                         | Kitty                               |
| `Super+D` / `Super+W`                  | Launcher / wallpaper picker         |
| `Super+Shift+W`                        | Next shuffled wallpaper             |
| `Super+A`                              | Dashboard                           |
| `Super+M`                              | Music panel                         |
| `Super+N`                              | Notification center                 |
| `Super+C`                              | Clipboard                           |
| `Super+Shift+N`                        | Sticky notes                        |
| `Super+P`                              | Pomodoro panel                      |
| `Super+B` / `Super+Shift+B` / `Super+Ctrl+B` | Bar show-hide / flip top-bottom / bar menu |
| `Super+Shift+R`                        | Screen recorder menu                |
| `Super+R` / `Super+Alt+R` / `Super+Ctrl+R` | Record external / laptop / region |
| `Super+Tab`                            | Workspace overview                  |
| `Super+S`                              | Region screenshot                   |
| `Super+X`                              | Lock                                |
| `Super+Q` / `F` / `T`                  | Close / fullscreen / float          |
| `Super+H J K L` (arrows, `[` `]`)      | Focus                               |
| `Super+Shift+H J K L`                  | Move window                         |
| `Super+Ctrl+H J K L`                   | Resize                              |
| `Super+1…0` / `Super+Shift+1…0`        | Workspace / move window there       |
| `Super+Shift/Alt+scroll`               | Move window to next / prev workspace |
| `Super+LMB` / `Super+RMB`              | Drag / resize                       |
| `Super+Shift+E`                        | Exit Hyprland                       |

---

## IPC

```bash
qs ipc call launcher | wallpaper | dashboard | music | notifcenter | clipboard toggle
qs ipc call calendar | wifi | bluetooth | notes | overview | eq | screentime toggle
qs ipc call record       menu | full | region | stop | toggle
qs ipc call pomodoro     toggle | startPause | reset | skip
qs ipc call pomozen      on | off | toggle
qs ipc call bar          toggle | autohide | cycle | menu | nextstyle | floating
qs ipc call bar          style <default|i3|enjoy> | position <top|bottom> | mode <shown|auto|hidden> | transparency <opaque|transparent|blur>
qs ipc call theme        toggle | next | set <mocha|rosepine|nord|dracula|gruvbox|tokyonight|mono>
qs ipc call nightlight   toggle
qs ipc call randomwallpaper apply "<path>"
```

---

## Install

Needs NixOS with flakes. The config assumes the user `alpha`; change it in `flake.nix`, `home.nix`, `modules/system/users.nix`, the MPD / Jellyfin services, `execs.lua` and the SSH config if yours differs.

```bash
git clone https://github.com/robbsbro69/nixos ~/nixos-dotfiles
cd ~/nixos-dotfiles
sudo nixos-generate-config --show-hardware-config > hardware-configuration.nix

# check before the first build:
#   modules/system/hardware/gpu.nix          PRIME bus IDs (lspci) or drop the nvidia block
#   modules/system/display/xserver.nix       videoDrivers
#   modules/system/hardware/filesystem.nix   /mnt/ssd UUID (lsblk -f) or remove it
#   modules/system/users.nix + hyprland/env.lua   AQ_DRM_DEVICES (ls /dev/dri)
#   config/hypr/hyprland/monitors.lua        output names (hyprctl monitors)
#   modules/system/networking/base.nix       time zone

sudo nixos-rebuild switch --impure --flake ~/nixos-dotfiles#nixos
```

Add some images to `~/wallpapers/` and log in through SDDM.

---

## Day-to-day

```bash
nrs     # rebuild
nuprs   # flake update + rebuild
gnrs    # git add . && commit "update" && rebuild
```

Configs under `config/` are symlinked, so no rebuild is needed for them:

```bash
pkill -f 'quickshell -p'; sleep 0.5; setsid -f quickshell -p ~/.config/quickshell   # restart the shell
hyprctl reload                                                                      # re-read Hyprland
```

New files must be `git add`-ed before `nrs` — flakes ignore untracked files.

Other aliases: `ff` / `gf` (fastfetch with a random logo), `ls` / `ll` (eza), `webp2png`, `zip2cbz`, `btw`.

---

## Notes

- NVIDIA runs in PRIME offload; Hyprland is pinned to DRM cards via `AQ_DRM_DEVICES`.
- The bar and music panel each run their own cava, only while something plays.
- Shell updates are backed up to `~/.cache/qs-update-backups/<time>-<name>/` before files are changed.
- Sticky notes, screen time and caches live outside the repo on purpose.
- `nrs` builds with `--impure` so it can pick up an optional private module directory outside the repo.

## Credits

[NixOS](https://nixos.org) · [Hyprland](https://hyprland.org) · [Quickshell](https://quickshell.org) by outfoxxed · [Catppuccin](https://catppuccin.com) · [LRCLIB](https://lrclib.net) · [yt-dlp](https://github.com/yt-dlp/yt-dlp) · [gpu-screen-recorder](https://git.dec05eba.com/gpu-screen-recorder/about/) · Quickshell inspiration from [Harman1307/dotfiles-Hyprland](https://github.com/Harman1307/dotfiles-Hyprland)

## License

MIT
