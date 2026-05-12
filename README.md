# NixOS Dotfiles

A NixOS-managed desktop built on **Hyprland + Quickshell**, with Home Manager for declarative user config, pywal-driven live theming, and a fully custom QML shell with panels for media, apps, wallpapers, anime/manga/movies, clipboard, notifications, calendar, clock, wifi, and bluetooth.

> `~/nixos-dotfiles/` is symlinked to `~/.config/` — all configs live under `~/nixos-dotfiles/config/` and are wired into place by Home Manager via `xdg.configFile` with `mkOutOfStoreSymlink`.

---

## Stack

| Component        | Choice                                      |
|------------------|---------------------------------------------|
| OS               | NixOS (nixos-25.11 stable + unstable overlay)|
| WM               | Hyprland (from nixpkgs-unstable)            |
| Shell / Bar      | Quickshell (QML, from upstream git flake)   |
| Terminal         | Kitty                                       |
| Editor           | Neovim (lazy.nvim)                          |
| File Manager     | Yazi + Thunar                               |
| Notifications    | Custom Python DBus daemon → Quickshell      |
| Theming          | pywal (wallpaper → colors.json → live QML)  |
| Music            | MPD + rmpc / Spicetify (Spotify)            |
| Launcher         | Quickshell LauncherPanel                    |
| Display Manager  | ly                                          |
| Fonts            | JetBrainsMono Nerd Font                     |
| Colorscheme      | Catppuccin Mocha (static) + pywal (dynamic) |

---

## Flake Inputs

| Input            | Source                                          |
|------------------|-------------------------------------------------|
| `nixpkgs`        | `github:NixOS/nixpkgs/nixos-25.11`             |
| `nixpkgs-unstable`| `github:NixOS/nixpkgs/nixos-unstable`         |
| `home-manager`   | `github:nix-community/home-manager/release-25.11`|
| `zen-browser`    | `github:0xc000022070/zen-browser-flake`        |
| `quickshell`     | `git+https://git.outfoxxed.me/outfoxxed/quickshell` (follows nixpkgs-unstable) |
| `spicetify-nix`  | `github:Gerg-L/spicetify-nix`                 |

---

## Directory Architecture

```
nixos-dotfiles/                         ← also symlinked as ~/.config/
│
├── configuration.nix                   NixOS system config
├── home.nix                            Home Manager user config
├── flake.nix                           Flake inputs and outputs
├── flake.lock
├── hardware-configuration.nix          Auto-generated hardware config
│
└── config/                             All app configs → symlinked into ~/.config/
    │
    ├── hypr/
    │   ├── hyprland.conf               Sources all sub-configs
    │   ├── hypridle.conf               Idle / lock / DPMS (lock only, DPMS disabled)
    │   ├── hyprlock.conf               Lock screen: blurred wallpaper + clock + input
    │   └── hyprland/
    │       ├── env.conf                Wayland env vars (OZONE_WL, cursors, Qt theme)
    │       ├── execs.conf              exec-once: swww, wal, spotify, ticktick,
    │       │                           hypridle, cliphist, gammastep, quickshell
    │       ├── general.conf            Gaps, borders, animations, input, gestures,
    │       │                           decorations (blur/shadow/dim), misc, binds, cursor
    │       ├── keybinds.conf           All keybindings (SUPER + …)
    │       ├── mocha.conf              Catppuccin Mocha color variables
    │       └── rules.conf              Window/layer rules (blur on quickshell layer)
    │
    ├── quickshell/
    │   ├── shell.qml                   Root ShellRoot — global state, IPC handlers,
    │   │                               wifi/bluetooth/wallpaper/app processes
    │   ├── UIState.qml                 Singleton: notification state + DBus daemon bridge
    │   ├── Colors.qml                  Singleton: reads ~/.cache/wal/colors.json live
    │   ├── Animations.qml              Singleton: animation duration constants
    │   ├── app_usage.json              Persisted app launch frequency for launcher sorting
    │   ├── anilist_token               AniList OAuth token (for library sync)
    │   ├── tmdb_token                  TMDB API token
    │   ├── tmdb_account_id             TMDB account ID (optional, for watchlist sync)
    │   │
    │   ├── state/
    │   │   ├── gif-index               Last selected music panel gif index
    │   │   ├── media-display-mode      gif or vinyl
    │   │   ├── media-vinyl-with-art    vinyl art toggle state
    │   │   └── theme-mode              dark / light
    │   │
    │   ├── assets/
    │   │   ├── get-player.sh           playerctl wrapper: resolves best active player,
    │   │   │                           outputs status/title/artist/arturl/pos/len
    │   │   ├── notif-daemon.py         DBus org.freedesktop.Notifications service:
    │   │   │                           prints nid|app|summary|body to stdout for UIState
    │   │   ├── Vinyl.png               Default vinyl center art
    │   │   ├── gifs/                   Animated GIFs for music panel (25 gifs)
    │   │   │   └── current.gif         Active gif (copied from picker)
    │   │   └── pfps/                   Profile picture options for dashboard
    │   │       └── pfp.jpg             Active profile picture
    │   │
    │   ├── components/
    │   │   ├── Bar.qml                 Top bar: workspaces (Hyprland IPC), clock,
    │   │   │                           media notch (cava + track + progress), volume,
    │   │   │                           battery, wifi/bt, system tray, clipboard,
    │   │   │                           anime/movies toggle, dashboard toggle
    │   │   ├── Dashboard.qml           Right panel: profile pic picker, power buttons,
    │   │   │                           laptop screen toggle, battery, CPU/RAM/disk rings,
    │   │   │                           volume/brightness sliders, clock
    │   │   ├── LauncherPanel.qml       Left panel: app launcher (usage-sorted, fzf-style)
    │   │   │                           + wallpaper picker (thumbnails, pywal apply)
    │   │   ├── MusicPanel.qml          Top-center: player controls, seek, gif animation
    │   │   │                           or vinyl disc, player selector dropdown,
    │   │   │                           gif/vinyl picker
    │   │   ├── AnimePanel.qml          Left panel: Anime browse/detail/episodes (AniList),
    │   │   │                           Manga browse/chapters (AniList + MangaDex fallback),
    │   │   │                           My Lists (AniList username lookup), library
    │   │   ├── MoviesPanel.qml         Right panel: Movies/TV trending/discover/search
    │   │   │                           (TMDB), watchlist, favorites, My List, saved
    │   │   ├── WifiPanel.qml           Right panel: wifi toggle + network list + password
    │   │   ├── BluetoothPanel.qml      Right panel: BT toggle + paired/available devices
    │   │   ├── CalendarPanel.qml       Left panel: AD/BS calendar (Bikram Sambat
    │   │   │                           conversion built-in), keyboard navigable
    │   │   ├── ClockPanel.qml          Left panel: analog clock + timer + stopwatch
    │   │   │                           + alarm (sound + notify-send)
    │   │   ├── ClipboardPanel.qml      Right panel: cliphist clipboard + emoji picker
    │   │   │                           + kaomoji picker, search, image thumbnails
    │   │   ├── NotifCenter.qml         Right panel: notification history, DND toggle
    │   │   └── NotificationPopup.qml   Top-right toast notifications (animated,
    │   │                               auto-dismiss, progress bar)
    │   │
    │   ├── services/
    │   │   ├── Anime.qml               Singleton: anime backend HTTP client
    │   │   │                           (talks to anime_server.py on :5050)
    │   │   ├── Manga.qml               Singleton: manga backend HTTP client
    │   │   │                           (talks to manga_server.py on :5150)
    │   │   └── Movies.qml              Singleton: movies backend HTTP client
    │   │                               (talks to movies_server.py on :5250)
    │   │
    │   ├── scripts/
    │   │   ├── anime_server.py         Flask-style HTTP server (port 5050):
    │   │   │                           AniList GQL browse/search/detail/episodes,
    │   │   │                           SQLite local library, AniList list write (token)
    │   │   ├── manga_server.py         HTTP server (port 5150): AniList manga browse,
    │   │   │                           MangaDex chapter/page fetch, SQLite library,
    │   │   │                           favorites + update tracking
    │   │   └── movies_server.py        HTTP server (port 5250): TMDB trending/search/
    │   │                               discover/detail, local watchlist/favorites/userlist
    │   │                               (SQLite), optional TMDB account sync
    │   │
    │   └── files/
    │       ├── emoji.json              Emoji data for clipboard panel emoji picker
    │       └── kaomoji.json            Kaomoji data for clipboard panel
    │
    ├── nvim/
    │   ├── init.lua                    Leader key, options, keymaps, lazy.nvim bootstrap
    │   └── lua/plugins/
    │       ├── tokyonight.lua          Colorscheme (storm, transparent bg)
    │       ├── lsp.lua                 nvim-lspconfig: rust_analyzer (clippy) + lua_ls
    │       ├── cmp.lua                 nvim-cmp completion (LSP, LuaSnip, path, buffer)
    │       ├── autoformat.lua          conform.nvim: format on save (rust, lua, JS/TS,
    │       │                           HTML, CSS, JSON, nix)
    │       ├── telescope.lua           Fuzzy finder + ui-select extension
    │       ├── lualine.lua             Statusline (tokyonight theme)
    │       ├── dashboard.lua           Snacks.nvim dashboard (ASCII art)
    │       ├── treesitter.lua          Syntax highlighting + indent
    │       ├── harpoon.lua             Quick file navigation (harpoon2)
    │       ├── gitsigns.lua            Git diff signs in gutter
    │       ├── git-conflict.lua        Git conflict resolution helpers
    │       ├── autopairs.lua           Auto bracket/quote pairs
    │       ├── mini.lua                mini.ai (text objects) + mini.surround
    │       ├── neotree.lua             File tree sidebar
    │       ├── oil.lua                 Directory editing as buffer
    │       ├── yazi.lua                Yazi file manager integration
    │       ├── silicon.lua             Code screenshot to clipboard (visual mode)
    │       ├── tabout.lua              Tab to jump out of brackets
    │       ├── colorizer.lua           Inline color highlighting
    │       ├── which-key.lua           Keybind helper popup
    │       └── markdown-preview.lua    Live markdown preview in browser
    │
    ├── kitty/kitty.conf                Font (JetBrainsMono NF 12.5), 16-color theme
    ├── mpv/mpv.conf                    Catppuccin colors, uosc theming, ytdl cookies,
    │                                   watch history, MPRIS script
    ├── starship/starship.toml          Prompt: Catppuccin Mocha palette
    ├── fastfetch/config.jsonc          Layout: random logo from ~/fastfetch/logo/,
    │                                   OS/kernel/packages/display/WM/terminal/shell/
    │                                   CPU/GPU/memory/storage/uptime, color circles
    ├── yazi/theme.toml                 Catppuccin Mocha: manager, tabs, mode, status,
    │                                   input, filetype colors, icon rules
    ├── cava/
    │   ├── config                      ncurses cava (visual)
    │   ├── config_raw                  Raw/ASCII stdout cava (piped to Bar.qml)
    │   └── shaders/                    GLSL shaders for sdl_glsl output
    ├── wal/
    │   ├── templates/
    │   │   ├── Colors.qml              pywal template → Quickshell color singleton
    │   │   ├── colors-gtk.css          GTK3/4 @define-color variables
    │   │   ├── colors-swaync.css       SwayNC notification styling
    │   │   ├── colors-eww.scss         eww color variables
    │   │   ├── colors-waybar.css       Waybar color variables
    │   │   ├── colors-polybar.ini      Polybar color variables
    │   │   ├── colors-rofi.rasi        Rofi color variables
    │   │   ├── fuzzel.ini              Fuzzel launcher colors
    │   │   └── zathura                 Zathura PDF reader colors
    │   └── colorschemes/               Static wal schemes (dark/ light/)
    ├── scripts/
    │   ├── random-wallpaper.sh         Pick random wallpaper → qs ipc call
    │   ├── define.sh                   Dictionary lookup (dictionaryapi.dev) → notify-send
    │   ├── Music.sh                    Launch rmpc + stop MPD
    │   ├── record-external.sh          wf-recorder on HDMI-A-1
    │   ├── record-laptop.sh            wf-recorder on eDP-1
    │   └── record-region.sh            wf-recorder with slurp region select
    └── starship/starship.toml
```

---

## Keybinds

| Key                    | Action                              |
|------------------------|-------------------------------------|
| `Super + Return`       | Kitty terminal                      |
| `Super + D`            | Toggle app launcher                 |
| `Super + A`            | Toggle dashboard                    |
| `Super + M`            | Toggle music panel                  |
| `Super + W`            | Toggle wallpaper picker             |
| `Super + Shift + W`    | Random wallpaper                    |
| `Super + N`            | Toggle notification center          |
| `Super + C`            | Toggle clipboard panel              |
| `Super + X`            | Lock screen (hyprlock)              |
| `Super + Q`            | Kill active window                  |
| `Super + F`            | Fullscreen                          |
| `Super + T`            | Toggle floating                     |
| `Super + H/J/K/L`      | Move focus                          |
| `Super + Shift + H/J/K/L` | Move window                     |
| `Super + Ctrl + H/J/K/L`  | Resize window                   |
| `Super + 1–0`          | Switch workspace                    |
| `Super + Shift + 1–0`  | Move window to workspace            |
| `Super + S`            | Screenshot (grim + slurp)           |
| `Super + R`            | Record external screen              |
| `Super + Alt + R`      | Record laptop screen                |
| `Super + Ctrl + R`     | Record region                       |
| `Super + Shift + E`    | Exit Hyprland                       |
| `Super + LMB drag`     | Move window                         |
| `Super + RMB drag`     | Resize window                       |
| `XF86Audio*`           | Volume up / down / mute             |
| Bar media notch LMB    | Play / pause                        |
| Bar media notch RMB    | Toggle music panel                  |
| Bar media notch MMB    | Next track                          |
| Bar media notch scroll | Next / previous track               |
| Bar wifi notch LMB     | Toggle wifi panel                   |
| Bar wifi notch RMB     | Toggle bluetooth panel              |
| Bar dashboard notch LMB| Toggle dashboard                   |
| Bar dashboard notch RMB| Toggle notification center         |
| Bar anime/movie notch LMB | Toggle movies panel             |
| Bar anime/movie notch RMB | Toggle anime panel              |

---

## Quickshell IPC Targets

```bash
qs ipc call launcher toggle          # App launcher / wallpaper picker
qs ipc call dashboard toggle         # Dashboard panel
qs ipc call music toggle             # Music panel
qs ipc call wallpaper toggle         # Wallpaper tab of launcher
qs ipc call randomwallpaper apply "<path>"  # Apply specific wallpaper
qs ipc call wifi toggle              # WiFi panel
qs ipc call bluetooth toggle         # Bluetooth panel
qs ipc call notifcenter toggle       # Notification center
qs ipc call calendar toggle          # Calendar panel
qs ipc call clipboard toggle         # Clipboard panel
qs ipc call anime toggle             # Anime/manga panel
qs ipc call movies toggle            # Movies/TV panel
```

---

## Theming System

Theming is driven by **pywal**. On wallpaper change via the launcher or random-wallpaper script, the shell:

1. Runs `swww img <path> --transition-type any --transition-duration 2` for animated transitions.
2. Runs `wal -i <path> -n -q` to regenerate `~/.cache/wal/colors.json` and all templates.
3. Links `colors-gtk.css` into `~/.config/gtk-{3,4}.0/gtk.css`.
4. Copies `colors-swaync.css` → `~/.config/swaync/style.css` and sends `SIGUSR1` to reload SwayNC.
5. Blurs the wallpaper with ImageMagick and saves it as `~/wallpapers/.current-blurred.jpg` (used by hyprlock).
6. Quickshell's `Colors.qml` singleton and `shell.qml` both re-read `colors.json` and update all `walColor*` properties live — the entire UI recolors without restart.

The `config/wal/templates/` directory contains pywal templates rendered on each `wal` run. `Colors.qml` is the main bridge: it's generated into `~/.cache/wal/Colors.qml` and Quickshell reads it at startup and after wallpaper changes.

---

## Media/Entertainment Backends

Three Python HTTP servers launch automatically via Quickshell `Process` objects:

| Server             | Port | Backend         | Features                                          |
|--------------------|------|-----------------|---------------------------------------------------|
| `anime_server.py`  | 5050 | AniList GraphQL | Browse, search, episodes, local SQLite library, AniList list write (optional token) |
| `manga_server.py`  | 5150 | AniList + MangaDex | Browse, search, chapters (MangaDex fallback for ongoing), favorites, library |
| `movies_server.py` | 5250 | TMDB            | Trending, discover, search, watchlist, favorites, My List (SQLite), optional TMDB account sync |

Tokens are stored in plaintext files:
- `~/.config/quickshell/anilist_token` — AniList OAuth token (optional; enables list writes)
- `~/.config/quickshell/tmdb_token` — TMDB read token (required for movies)
- `~/.config/quickshell/tmdb_account_id` — TMDB account ID (optional; enables watchlist sync)

---

## Notification System

A custom Python DBus daemon (`assets/notif-daemon.py`) registers as `org.freedesktop.Notifications` and prints `nid|app|summary|body` to stdout. `UIState.qml` reads this via a Quickshell `Process` + `SplitParser`, adds entries to the notification list, and emits a signal that both the toast popup and notification center listen to. The daemon auto-restarts on exit.

---

## Neovim

Plugin manager: **lazy.nvim** (auto-bootstrapped).

| Plugin                | Purpose                                        |
|-----------------------|------------------------------------------------|
| `tokyonight.nvim`     | Colorscheme (storm, transparent)               |
| `nvim-lspconfig`      | LSP: rust_analyzer (clippy), lua_ls            |
| `nvim-cmp`            | Completion (LSP + LuaSnip + path + buffer)     |
| `conform.nvim`        | Format on save (alejandra, stylua, prettier)   |
| `telescope.nvim`      | Fuzzy finder + LSP navigation                  |
| `lualine.nvim`        | Statusline                                     |
| `snacks.nvim`         | Dashboard (ASCII art)                          |
| `nvim-treesitter`     | Syntax + indent                                |
| `harpoon` (v2)        | Quick file marks (up to 5 slots)               |
| `gitsigns.nvim`       | Git diff in gutter                             |
| `git-conflict.nvim`   | Conflict resolution helpers                    |
| `nvim-autopairs`      | Auto bracket/quote pairs                       |
| `mini.nvim`           | mini.ai text objects + mini.surround           |
| `neo-tree.nvim`       | File tree (`<leader>n`)                        |
| `oil.nvim`            | Directory editing as buffer (`<leader>o`)      |
| `yazi.nvim`           | Yazi integration (`<leader>y`)                 |
| `nvim-silicon`        | Code screenshot to clipboard (`<leader>sc`)    |
| `tabout.nvim`         | Tab to jump out of brackets                    |
| `nvim-colorizer.lua`  | Inline color highlighting                      |
| `which-key.nvim`      | Keybind popup helper                           |
| `markdown-preview.nvim`| Live browser preview                          |

---

## Useful Aliases

Defined in `home.nix` → `programs.bash.shellAliases`:

```bash
nrs        # sudo nixos-rebuild switch --flake ~/nixos-dotfiles#nixos
nuprs      # nix flake update && nrs
gnrs       # git add . && git commit -m "update" && nrs
ff         # fastfetch with random logo from ~/fastfetch/logo/
gf         # fastfetch with random logo from ~/Pictures/Dump_fastfetch_logo/
ls         # eza --icons
ll         # eza -l --icons
btw        # echo "i use nixos, btw"
webp2png   # batch convert all *.webp → *.png in current directory
```

---

## Installation (NixOS)

### Prerequisites

- NixOS with flakes enabled (`nix.settings.experimental-features = ["nix-command" "flakes"]`)
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
#    - GPU drivers in configuration.nix (nvidia block, videoDrivers)
#    - Monitor names in hypr/hyprland/general.conf (run: hyprctl monitors)
#    - UUID mounts in configuration.nix (run: lsblk -f)
#    - Username: grep -r "alpha" configuration.nix home.nix and replace

# 5. Build
sudo nixos-rebuild switch --flake ~/nixos-dotfiles#nixos

# 6. Bootstrap theming
wal -i ~/wallpapers/<your-wallpaper>
```

### Rebuilding

```bash
nrs      # rebuild
nuprs    # update flake inputs + rebuild
gnrs     # commit + rebuild
```

---

## Wallpapers

Expected in `~/wallpapers/`. The picker scans for `.jpg`, `.jpeg`, `.png`, `.webp`, `.gif`. Thumbnails are cached in `~/.cache/wallpaper-thumbs/`. The active wallpaper is symlinked at `~/wallpapers/current` and blurred to `~/wallpapers/.current-blurred.jpg`.

```bash
# Random wallpaper (Super+Shift+W or directly):
~/.config/scripts/random-wallpaper.sh
```

---

## Notes

- The `swaync/style.css` is overwritten by pywal on each wallpaper change — don't edit it manually.
- Quickshell is pulled from upstream Git (not nixpkgs) via the `quickshell` flake input, following nixpkgs-unstable.
- The bar's cava visualizer only runs when media is `Playing` (`running: bar.mediaClass === "playing"`). It reads raw ASCII values from `cava/config_raw` and decays to zero when paused.
- `WLR_DRM_DEVICES=/dev/dri/card1` forces Hyprland to a specific GPU. Run `ls /dev/dri/` and adjust or remove if your setup differs.
- The Bikram Sambat calendar in `CalendarPanel.qml` has full BS↔AD conversion built in with a lookup table covering BS 2000–2090.
- All three backend servers (anime/manga/movies) are started by Quickshell itself and restart automatically on exit.

---

## Credits

- [NixOS](https://nixos.org)
- [Hyprland](https://hyprland.org)
- [Quickshell](https://quickshell.org) by outfoxxed
- Quickshell config inspiration: [Harman1307/dotfiles-Hyprland](https://github.com/Harman1307/dotfiles-Hyprland)

---

## License

MIT — do whatever you want with it.
