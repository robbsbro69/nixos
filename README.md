# nixos-dotfiles

A NixOS desktop built on **Hyprland + Quickshell** — fully declarative system config via NixOS flakes, user config via Home Manager, pywal-driven live theming, and a custom QML shell with panels for media, apps, wallpapers, anime/manga/movies, clipboard, notifications, calendar, clock, wifi, and bluetooth.

> `~/nixos-dotfiles/` is symlinked to `~/.config/` — all app configs live under `config/` and are wired into place by Home Manager via `xdg.configFile` with `mkOutOfStoreSymlink`.

<div align="center">

![NixOS](https://img.shields.io/badge/NixOS-25.11-5277C3?style=flat&logo=nixos)
![Hyprland](https://img.shields.io/badge/Hyprland-unstable-58E1FF?style=flat)
![Quickshell](https://img.shields.io/badge/Quickshell-git-CBA6F7?style=flat)
![License](https://img.shields.io/badge/License-MIT-A6E3A1?style=flat)

</div>

---

## Stack

| Component       | Choice                                                         |
| --------------- | -------------------------------------------------------------- |
| OS              | NixOS (nixos-25.11 stable + unstable overlay)                  |
| WM              | Hyprland (nixpkgs-unstable)                                    |
| Shell / Bar     | Quickshell (QML, upstream git flake)                           |
| Terminal        | Kitty                                                          |
| Editor          | Neovim (lazy.nvim)                                             |
| File Manager    | Yazi + Thunar                                                  |
| Notifications   | Custom Python DBus daemon → Quickshell                         |
| Theming         | pywal (wallpaper → colors.json → live QML)                     |
| Music           | MPD + rmpc / Spicetify (Spotify)                               |
| Launcher        | Quickshell LauncherPanel                                       |
| Display Manager | SDDM (Catppuccin Mocha Mauve)                                  |
| Fonts           | JetBrainsMono Nerd Font                                        |
| Colorscheme     | Catppuccin Mocha (static) + pywal (dynamic)                    |
| Browsers        | Zen Browser (default) + Brave                                  |
| Media           | Jellyfin + MPV + Spotify (Spicetify) + rmpc                    |

---

## Flake Inputs

| Input              | Source                                                          |
| ------------------ | --------------------------------------------------------------- |
| `nixpkgs`          | `github:NixOS/nixpkgs/nixos-25.11`                              |
| `nixpkgs-unstable` | `github:NixOS/nixpkgs/nixos-unstable`                           |
| `home-manager`     | `github:nix-community/home-manager/release-25.11`               |
| `zen-browser`      | `github:0xc000022070/zen-browser-flake`                         |
| `quickshell`       | `git+https://git.outfoxxed.me/outfoxxed/quickshell` (upstream)  |
| `spicetify-nix`    | `github:Gerg-L/spicetify-nix`                                   |

---

## Directory Structure

```
nixos-dotfiles/                         ← symlinked as ~/.config/
│
├── configuration.nix                   NixOS system config
├── home.nix                            Home Manager user config
├── flake.nix                           Flake inputs and outputs
├── flake.lock
├── hardware-configuration.nix
├── modules/
│   ├── home/                           Home Manager modules
│   │   ├── browsers/
│   │   │   └── default.nix             Zen Browser + Brave
│   │   ├── desktop/
│   │   │   ├── default.nix             Imports all desktop sub-modules
│   │   │   ├── hyprland.nix            Wayland WM + desktop packages
│   │   │   ├── gtk.nix                 GTK theme (adw-gtk3-dark)
│   │   │   ├── qt.nix                  Qt theme (adwaita-dark)
│   │   │   └── cursor.nix              Cursor + dconf dark mode
│   │   ├── dev/
│   │   │   ├── default.nix             Imports all dev sub-modules
│   │   │   ├── git.nix                 Git config
│   │   │   ├── ssh.nix                 SSH config + GitHub host
│   │   │   ├── editors.nix             Neovim + LSPs + formatters
│   │   │   ├── languages.nix           Node, GCC, Rustup
│   │   │   └── tools.nix               ripgrep, fzf, jq, tmux, htop…
│   │   ├── media/
│   │   │   ├── default.nix             Imports all media sub-modules
│   │   │   ├── spotify.nix             Spicetify (Catppuccin Mocha)
│   │   │   ├── mpv.nix                 MPV + MPRIS script
│   │   │   ├── mpd-client.nix          rmpc, mpc, cava, playerctl, mpd-mpris
│   │   │   └── apps.nix                vesktop, obsidian, telegram, quickshell…
│   │   ├── shell/
│   │   │   ├── default.nix             Imports all shell sub-modules
│   │   │   ├── bash.nix                Bash + aliases + FZF colors
│   │   │   └── starship.nix            Starship prompt
│   │   ├── packages.nix                General CLI tools (yazi, eza, pywal…)
│   │   └── symlinks.nix                xdg.configFile mkOutOfStoreSymlink wiring
│   │
│   └── system/                         NixOS system modules
│       ├── boot/
│       │   ├── default.nix             Imports boot sub-modules
│       │   ├── plymouth.nix            Plymouth (Catppuccin Mocha) + quiet boot
│       │   └── kernel.nix              Kernel, blacklist nouveau, kvm-amd
│       ├── hardware/
│       │   ├── default.nix             Imports hardware sub-modules
│       │   ├── gpu.nix                 NVIDIA modesetting
│       │   ├── bluetooth.nix           Bluetooth + power on boot
│       │   └── filesystem.nix          Extra mount points (SSD)
│       ├── display/
│       │   ├── default.nix             Imports display sub-modules
│       │   ├── hyprland.nix            programs.hyprland + appimage + nix-ld + vbox
│       │   ├── portal.nix              xdg-desktop-portal (GTK + Hyprland)
│       │   └── xserver.nix             Xserver + video drivers + repeat rate
│       ├── networking/
│       │   ├── default.nix             Imports networking sub-modules
│       │   ├── base.nix                Hostname, NetworkManager, timezone
│       │   ├── dns.nix                 systemd-resolved, DoT (Cloudflare + Quad9)
│       │   └── wireguard.nix           System-wide wg-quick ProtonVPN interface
│       ├── services/
│       │   ├── default.nix             Imports services sub-modules
│       │   ├── audio.nix               Pipewire + WirePlumber Bluetooth priority
│       │   ├── display-manager.nix     SDDM (Catppuccin Mocha Mauve)
│       │   ├── jellyfin.nix            Jellyfin media server
│       │   ├── media.nix               MPD system service + PipeWire + FIFO output
│       │   ├── misc.nix                blueman, gvfs, dbus, udisks2, ssh-agent, dconf
│       │   └── udev.nix                udev rules (MTP)
│       ├── fonts.nix                   JetBrainsMono NF, Noto fonts
│       ├── nix.nix                     GC, optimise, binary caches
│       ├── packages.nix                System-wide packages (wayland tools, Thunar…)
│       ├── security.nix                rtkit, polkit, pam hyprlock
│       ├── users.nix                   User, groups, sudo rules, session variables
│       └── vpn.nix                     ProtonVPN netns + Transmission kill-switch
└── config/                             App configs → symlinked into ~/.config/
    ├── hypr/
    │   ├── hyprland.conf               Sources all sub-configs
    │   ├── hypridle.conf               Idle / lock config
    │   ├── hyprlock.conf               Lock screen: blurred wallpaper + clock
    │   └── hyprland/
    │       ├── env.conf                Wayland env vars
    │       ├── execs.conf              exec-once: swww, wal, spotify, quickshell…
    │       ├── general.conf            Gaps, borders, animations, blur, input
    │       ├── keybinds.conf           All keybindings
    │       ├── mocha.conf              Catppuccin Mocha color variables
    │       └── rules.conf              Window/layer rules
    │
    ├── quickshell/
    │   ├── shell.qml                   Root ShellRoot — global state, IPC handlers
    │   ├── UIState.qml                 Singleton: notifications + DBus daemon bridge
    │   ├── Colors.qml                  Singleton: reads ~/.cache/wal/colors.json live
    │   ├── Animations.qml              Singleton: animation duration constants
    │   │
    │   ├── components/
    │   │   ├── Bar.qml                 Top bar: workspaces, clock, media notch (cava),
    │   │   │                           volume, battery, wifi/bt, tray, clipboard, anime/movies
    │   │   ├── Dashboard.qml           Right panel: profile, power, battery, CPU/RAM/disk,
    │   │   │                           volume/brightness sliders, clock
    │   │   ├── LauncherPanel.qml       Left panel: app launcher (usage-sorted) + wallpaper picker
    │   │   ├── MusicPanel.qml          Top-center: player controls, seek, gif or vinyl disc,
    │   │   │                           player selector, gif/vinyl picker
    │   │   ├── AnimePanel.qml          Left panel: Anime + Manga browse/detail/chapters
    │   │   │                           (AniList + MangaDex), My Lists, library
    │   │   ├── MoviesPanel.qml         Right panel: Movies/TV trending/discover/search
    │   │   │                           (TMDB), watchlist, favorites, My List, saved
    │   │   ├── WifiPanel.qml           Right panel: wifi toggle + network list + password
    │   │   ├── BluetoothPanel.qml      Right panel: BT toggle + paired/available devices
    │   │   ├── CalendarPanel.qml       Left panel: AD/BS calendar (Bikram Sambat built-in)
    │   │   ├── ClockPanel.qml          Left panel: analog clock + timer + stopwatch + alarm
    │   │   ├── ClipboardPanel.qml      Right panel: cliphist + emoji picker + kaomoji picker
    │   │   ├── NotifCenter.qml         Right panel: notification history + DND toggle
    │   │   └── NotificationPopup.qml   Top-right toast notifications (animated, auto-dismiss)
    │   │
    │   ├── services/
    │   │   ├── Anime.qml               Singleton: anime HTTP client (:5050)
    │   │   ├── Manga.qml               Singleton: manga HTTP client (:5150)
    │   │   └── Movies.qml              Singleton: movies HTTP client (:5250)
    │   │
    │   ├── scripts/
    │   │   ├── anime_server.py         Flask-style HTTP server: AniList GQL, SQLite library
    │   │   ├── manga_server.py         HTTP server: AniList + MangaDex chapters, SQLite
    │   │   └── movies_server.py        HTTP server: TMDB trending/search/detail, SQLite watchlist
    │   │
    │   └── assets/
    │       ├── get-player.sh           playerctl wrapper: resolves best active player
    │       ├── notif-daemon.py         DBus org.freedesktop.Notifications service
    │       ├── timer.wav               Alarm/timer sound
    │       ├── Vinyl.png               Default vinyl center art
    │       ├── gifs/                   35+ animated GIFs for the music panel
    │       └── pfps/                   Profile picture options for the dashboard
    │
    ├── nvim/                           Neovim: lazy.nvim + full LSP/cmp/treesitter setup
    ├── kitty/kitty.conf                Font + 16-color theme
    ├── mpv/mpv.conf                    Catppuccin colors, ytdl cookies, MPRIS
    ├── starship/starship.toml          Catppuccin Mocha prompt
    ├── fastfetch/config.jsonc          Random logo, system info, color circles
    ├── yazi/theme.toml                 Catppuccin Mocha
    ├── cava/                           ncurses + raw ASCII configs + GLSL shaders
    ├── rmpc/                           MPD TUI client: config + theme
    ├── wal/templates/                  pywal templates (Colors.qml, gtk.css, swaync.css…)
    └── scripts/                        Wallpaper, recording, dictionary scripts
```

---

## Quickshell Panels

Every panel slides in/out with a `NumberAnimation` on its margin. All panels are keyboard-navigable and close on `Escape`.

| Panel             | Trigger              | Position     | Features                                                          |
| ----------------- | -------------------- | ------------ | ----------------------------------------------------------------- |
| Launcher          | `Super+D`            | Left         | Usage-sorted app list, search, app icons                          |
| Wallpaper picker  | `Super+W`            | Left (tab 2) | Thumbnail grid, apply with pywal, current indicator               |
| Music             | `Super+M`            | Top-center   | Playerctl controls, seek bar, cava visualizer, GIF or vinyl disc  |
| Dashboard         | `Super+A`            | Right        | Profile pic, power buttons, CPU/RAM/disk rings, vol/bright sliders |
| Notification center | `Super+N`          | Right        | History, DND toggle, per-notification dismiss                     |
| Clipboard         | `Super+C`            | Right        | cliphist history, image thumbnails, emoji picker, kaomoji picker  |
| Wifi              | Bar → wifi notch LMB | Right        | Toggle, network list, password entry, disconnect                  |
| Bluetooth         | Bar → wifi notch RMB | Right        | Toggle, paired devices, scan for new, connect/disconnect/forget   |
| Calendar          | Bar → clock RMB      | Left         | AD calendar + BS (Bikram Sambat) with full BS↔AD conversion       |
| Clock             | Bar → clock LMB      | Left         | Analog clock, countdown timer, stopwatch with laps, alarms        |
| Anime / Manga     | Bar → anime notch RMB | Left        | AniList browse/search/detail, MangaDex chapters, local library    |
| Movies / TV       | Bar → anime notch LMB | Right       | TMDB trending/discover/search, watchlist, favorites, My List      |

---

## Theming System

Theming is driven by **pywal**. On wallpaper change:

1. `swww img <path> --transition-type any --transition-duration 2`
2. `wal -i <path> -n -q` → regenerates `~/.cache/wal/colors.json` and all templates
3. `colors-gtk.css` symlinked into `~/.config/gtk-{3,4}.0/gtk.css`
4. Wallpaper blurred with ImageMagick → `~/wallpapers/.current-blurred.jpg` (for hyprlock)
5. `Colors.qml` re-reads `colors.json` live — all `walColor*` properties update instantly

The `config/wal/templates/` directory contains templates rendered on each `wal` run, including `Colors.qml`, `colors-gtk.css`, `colors-swaync.css`, `fuzzel.ini`, and more.

---

## Media / Entertainment Backends

Three Python HTTP servers start automatically via Quickshell `Process` objects and restart on exit.

| Server            | Port | Virtualenv       | Backend              | Features                                                    |
| ----------------- | ---- | ---------------- | -------------------- | ----------------------------------------------------------- |
| `anime_server.py` | 5050 | `~/ani-env/`     | AniList GraphQL      | Browse, search, episodes, SQLite library, AniList list sync |
| `manga_server.py` | 5150 | `~/.venv/manga/` | AniList + MangaDex   | Browse, chapters/pages, SQLite library, favorites           |
| `movies_server.py`| 5250 | `~/.venv/movies/`| TMDB                 | Trending, discover, search, watchlist, favorites, SQLite    |

**One-time venv setup** (after first rebuild):

```bash
python3 -m venv ~/ani-env && ~/ani-env/bin/pip install requests
python3 -m venv ~/.venv/manga && ~/.venv/manga/bin/pip install requests
python3 -m venv ~/.venv/movies && ~/.venv/movies/bin/pip install requests
```

**API tokens** (stored in plaintext):

```bash
echo 'YOUR_TOKEN' > ~/.config/quickshell/anilist_token   # optional — enables list writes
echo 'YOUR_TOKEN' > ~/.config/quickshell/tmdb_token       # required for movies
echo 'YOUR_ID'    > ~/.config/quickshell/tmdb_account_id  # optional — enables watchlist sync
```

---

## Notification System

A custom Python DBus daemon (`assets/notif-daemon.py`) registers as `org.freedesktop.Notifications` and pipes `nid|app|summary|body` to stdout. `UIState.qml` reads this via a Quickshell `Process` + `SplitParser`, pushes entries to the notification list, and emits a signal that both the toast popup and notification center listen to. The daemon auto-restarts on exit.

---

## Neovim

Plugin manager: **lazy.nvim** (auto-bootstrapped from `init.lua`).

| Plugin                  | Purpose                                          |
| ----------------------- | ------------------------------------------------ |
| `tokyonight.nvim`       | Colorscheme (storm, transparent)                 |
| `nvim-lspconfig`        | LSP: rust_analyzer (clippy), lua_ls              |
| `nvim-cmp`              | Completion (LSP + LuaSnip + path + buffer)       |
| `conform.nvim`          | Format on save (alejandra, stylua, prettier)     |
| `telescope.nvim`        | Fuzzy finder + LSP navigation                    |
| `lualine.nvim`          | Statusline (tokyonight theme)                    |
| `snacks.nvim`           | Dashboard (ASCII art)                            |
| `nvim-treesitter`       | Syntax + indent                                  |
| `harpoon` (v2)          | Quick file marks (up to 5 slots)                 |
| `gitsigns.nvim`         | Git diff in gutter                               |
| `git-conflict.nvim`     | Conflict resolution helpers                      |
| `nvim-autopairs`        | Auto bracket/quote pairs                         |
| `mini.nvim`             | mini.ai text objects + mini.surround             |
| `neo-tree.nvim`         | File tree (`<leader>n`)                          |
| `oil.nvim`              | Directory editing as buffer (`<leader>o`)        |
| `yazi.nvim`             | Yazi integration (`<leader>y`)                   |
| `nvim-silicon`          | Code screenshot to clipboard (`<leader>sc`)      |
| `tabout.nvim`           | Tab to jump out of brackets                      |
| `nvim-colorizer.lua`    | Inline color highlighting                        |
| `which-key.nvim`        | Keybind popup helper                             |
| `markdown-preview.nvim` | Live browser preview                             |
| `Comment.nvim`          | Smart commenting                                 |

---

## Keybinds

| Key                       | Action                              |
| ------------------------- | ----------------------------------- |
| `Super + Return`          | Kitty terminal                      |
| `Super + D`               | Toggle app launcher                 |
| `Super + A`               | Toggle dashboard                    |
| `Super + M`               | Toggle music panel                  |
| `Super + W`               | Toggle wallpaper picker             |
| `Super + Shift + W`       | Random wallpaper                    |
| `Super + Shift + P`       | Random personal wallpaper           |
| `Super + N`               | Toggle notification center          |
| `Super + C`               | Toggle clipboard panel              |
| `Super + X`               | Lock screen (hyprlock)              |
| `Super + Q`               | Kill active window                  |
| `Super + F`               | Fullscreen                          |
| `Super + T`               | Toggle floating                     |
| `Super + H/J/K/L`         | Move focus                          |
| `Super + Shift + H/J/K/L` | Move window                         |
| `Super + Ctrl + H/J/K/L`  | Resize window                       |
| `Super + 1–0`             | Switch workspace                    |
| `Super + Shift + 1–0`     | Move window to workspace            |
| `Super + S`               | Screenshot (grim + slurp)           |
| `Super + R`               | Record external screen              |
| `Super + Alt + R`         | Record laptop screen                |
| `Super + Ctrl + R`        | Record region                       |
| `Super + Shift + E`       | Exit Hyprland                       |
| `Super + LMB drag`        | Move window                         |
| `Super + RMB drag`        | Resize window                       |
| `XF86Audio*`              | Volume up / down / mute             |
| Bar media notch LMB       | Play / pause                        |
| Bar media notch RMB       | Toggle music panel                  |
| Bar media notch MMB       | Next track                          |
| Bar media notch scroll    | Next / previous track               |
| Bar wifi notch LMB        | Toggle wifi panel                   |
| Bar wifi notch RMB        | Toggle bluetooth panel              |
| Bar clock LMB             | Toggle clock panel                  |
| Bar clock RMB             | Toggle calendar panel               |
| Bar apps notch LMB        | Toggle launcher                     |
| Bar apps notch RMB        | Toggle wallpaper picker             |
| Bar dashboard notch LMB   | Toggle dashboard                    |
| Bar dashboard notch RMB   | Toggle notification center          |
| Bar anime/movie notch LMB | Toggle movies panel                 |
| Bar anime/movie notch RMB | Toggle anime panel                  |

---

## Quickshell IPC

```bash
qs ipc call launcher      toggle
qs ipc call dashboard     toggle
qs ipc call music         toggle
qs ipc call wallpaper     toggle
qs ipc call wifi          toggle
qs ipc call bluetooth     toggle
qs ipc call notifcenter   toggle
qs ipc call calendar      toggle
qs ipc call clipboard     toggle
qs ipc call anime         toggle
qs ipc call movies        toggle
qs ipc call randomwallpaper apply "<path>"
```

---

## Aliases

```bash
nrs        # sudo nixos-rebuild switch --flake ~/nixos-dotfiles#nixos
nuprs      # nix flake update && nrs
gnrs       # git add . && git commit -m "update" && nrs
ff         # fastfetch with random logo from ~/.config/fastfetch/logo/
gf         # fastfetch with random logo from ~/Pictures/Dump_fastfetch_logo/
ls         # eza --icons
ll         # eza -l --icons
btw        # echo "i use nixos, btw"
webp2png   # batch convert all *.webp → *.png in current directory
zip2cbz    # batch rename all *.zip → *.cbz in current directory
```

---

## Installation

### Prerequisites

- NixOS with flakes enabled
- NVIDIA or AMD GPU (config has both — adjust `hardware.nvidia` and `videoDrivers` as needed)

### Steps

```bash
# 1. Clone
git clone https://github.com/robbsbro69/nixos-dotfiles ~/nixos-dotfiles

# 2. Symlink as ~/.config
ln -sf ~/nixos-dotfiles ~/.config

# 3. Generate hardware config
sudo nixos-generate-config --show-hardware-config > ~/nixos-dotfiles/hardware-configuration.nix

# 4. Adjust before building:
#    • GPU drivers in modules/system/hardware.nix (nvidia block, videoDrivers)
#    • Monitor names in config/hypr/hyprland/general.conf (run: hyprctl monitors)
#    • Mount UUIDs in modules/system/hardware.nix (run: lsblk -f)
#    • Username: grep -r "alpha" . and replace with your username

# 5. Build
sudo nixos-rebuild switch --flake ~/nixos-dotfiles#nixos

# 6. Bootstrap theming
wal -i ~/wallpapers/<your-wallpaper>

# 7. Set up Python venvs for media backends
python3 -m venv ~/ani-env && ~/ani-env/bin/pip install requests
python3 -m venv ~/.venv/manga && ~/.venv/manga/bin/pip install requests
python3 -m venv ~/.venv/movies && ~/.venv/movies/bin/pip install requests
```

### Rebuilding

```bash
nrs      # rebuild
nuprs    # update flake inputs + rebuild
gnrs     # commit + rebuild
```

---

## Wallpapers

Expected in `~/wallpapers/`. The picker scans for `.jpg`, `.jpeg`, `.png`, `.webp`, `.gif`. Thumbnails are cached in `~/.cache/wallpaper-thumbs/`. The active wallpaper is symlinked at `~/wallpapers/current` and blurred to `~/wallpapers/.current-blurred.jpg` for the lock screen.

Personal wallpapers can live in `~/Bangers_Walls/` and are cycled with `Super+Shift+P`.

---

## Notes

- Quickshell is pulled from upstream Git (not nixpkgs) via the `quickshell` flake input, following `nixpkgs-unstable`.
- The bar's cava visualizer only runs when media is `Playing`. It reads raw ASCII values from `cava/config_raw` and decays to zero when paused.
- `WLR_DRM_DEVICES=/dev/dri/card1` forces Hyprland to a specific GPU. Run `ls /dev/dri/` and adjust or remove if your setup differs.
- The Bikram Sambat calendar in `CalendarPanel.qml` has full BS↔AD conversion built in with a lookup table covering BS 2000–2090.
- All three backend servers (anime/manga/movies) are started by Quickshell and restart automatically on exit.
- Media backend Python venvs are **not** managed by Nix — create them manually after the first rebuild (see setup above).
- The music panel supports multiple players simultaneously — use the player selector dropdown to lock to a specific one or leave it on Auto.
- DNS is set to Cloudflare + Quad9 over TLS via `systemd-resolved` (opportunistic mode).
- The networking module uses `systemd-resolved` as the NetworkManager DNS backend with DNSSEC enabled.
- The transmission VPN kill-switch (`modules/system/vpn.nix`) runs Transmission inside an isolated network namespace with ProtonVPN WireGuard — if the VPN drops, Transmission loses all connectivity.

---

## Credits

- [NixOS](https://nixos.org)
- [Hyprland](https://hyprland.org)
- [Quickshell](https://quickshell.org) by outfoxxed
- Quickshell config inspiration: [Harman1307/dotfiles-Hyprland](https://github.com/Harman1307/dotfiles-Hyprland)

---

## License

MIT — do whatever you want with it.
