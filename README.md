# NixOS-dotfiles

A NixOS-managed desktop configuration built around **Hyprland** + **Quickshell**, featuring a fully declarative system setup with Home Manager, pywal-driven theming, and a custom QML shell.

> **Note:** `~/nixos-dotfiles/` is symlinked to `~/.config/` — configs live in `~/nixos-dotfiles/config/` and are symlinked into place by Home Manager via `xdg.configFile`.

---

## Screenshots / Stack

| Component | Choice |
|---|---|
| WM | Hyprland |
| Shell / Bar | Quickshell (QML) |
| Terminal | Kitty |
| Editor | Neovim (lazy.nvim) |
| File Manager | Yazi + Dolphin |
| Notifications | SwayNC |
| Theming | pywal (colorscheme from wallpaper) |
| Music | MPD + rmpc / Spicetify (Spotify) |
| Launcher | Custom Quickshell panel |
| Display Manager | ly |
| Fonts | JetBrainsMono Nerd Font |

---

## Directory Architecture

```
nixos-dotfiles/                        # ← also symlinked as ~/.config/
│
├── configuration.nix                  # NixOS system config (hardware, services, packages)
├── home.nix                           # Home Manager config (user packages, dotfiles, shell)
├── flake.nix                          # Flake inputs: nixpkgs, home-manager, quickshell, spicetify-nix
├── flake.lock
├── hardware-configuration.nix         # Auto-generated hardware config
│
└── config/                            # All application configs (symlinked into ~/.config/)
    │
    ├── hypr/
    │   ├── hyprland.conf              # Sources all sub-configs
    │   ├── hypridle.conf              # Idle / lock / DPMS timeouts
    │   ├── hyprlock.conf              # Lock screen layout
    │   └── hyprland/
    │       ├── env.conf               # Wayland env variables
    │       ├── execs.conf             # exec-once startup commands
    │       ├── general.conf           # Gaps, borders, animations, input, gestures
    │       ├── keybinds.conf          # All keybindings
    │       ├── mocha.conf             # Catppuccin Mocha color variables
    │       └── rules.conf             # Window rules
    │
    ├── quickshell/
    │   ├── shell.qml                  # Root ShellRoot — IPC handlers, state, processes
    │   ├── app_usage.json             # Persisted app launch frequency
    │   ├── state/
    │   │   └── gif-index              # Last selected music panel gif index
    │   ├── assets/
    │   │   ├── gifs/                  # Animated gifs for the music panel
    │   │   │   └── current.gif        # Symlink/copy of active gif
    │   │   └── pfps/
    │   │       └── pfp.jpg            # Active profile picture
    │   └── components/
    │       ├── Bar.qml                # Top bar: workspaces, clock, media, volume, battery, network
    │       ├── Dashboard.qml          # Right panel: system stats, sliders, power buttons
    │       ├── LauncherPanel.qml      # Left panel: app launcher + wallpaper picker
    │       ├── MusicPanel.qml         # Top-center: player controls, gif, track info
    │       ├── WifiPanel.qml          # Right panel: wifi toggle + network list
    │       └── BluetoothPanel.qml     # Right panel: BT toggle + device list
    │
    ├── nvim/
    │   ├── init.lua                   # Leader key, lazy.nvim bootstrap, options
    │   └── lua/plugins/
    │       ├── tokyonight.lua         # Colorscheme (transparent)
    │       ├── lsp.lua                # rust-analyzer via nvim-lspconfig
    │       ├── lsp-keymaps.lua        # LSP keybinds on LspAttach
    │       ├── cmp.lua                # blink.cmp completion
    │       ├── fzf.lua                # fzf-lua fuzzy finder
    │       ├── lualine.lua            # Statusline
    │       ├── dashboard.lua          # Snacks dashboard (ASCII art)
    │       ├── yazi.lua               # Yazi file manager integration
    │       ├── gitsigns.lua           # Git diff signs
    │       ├── autopairs.lua          # Auto bracket/quote pairs
    │       └── markdown-preview.lua   # Live markdown preview
    │
    ├── kitty/kitty.conf               # Terminal colors + font
    ├── mpv/mpv.conf                   # MPV colors + uosc theming
    ├── starship/starship.toml         # Prompt (Catppuccin Mocha palette)
    ├── fastfetch/config.jsonc         # Fastfetch layout + random logo
    ├── yazi/theme.toml                # Yazi Catppuccin Mocha theme
    ├── swaync/
    │   ├── config.json                # Notification daemon config
    │   └── style.css → ~/.cache/wal/colors-swaync.css   # Live pywal symlink
    ├── cava/
    │   ├── config                     # ncurses cava (bar widget in bar)
    │   ├── config_raw                 # raw/stdout cava (piped to Quickshell)
    │   └── shaders/                   # GLSL shaders for sdl_glsl output
    ├── wal/
    │   ├── templates/                 # pywal output templates
    │   │   ├── Colors.qml             # Qt/QML color singleton
    │   │   ├── colors-gtk.css         # GTK3 colors
    │   │   ├── colors-swaync.css      # SwayNC theming
    │   │   ├── fuzzel.ini             # Fuzzel launcher colors
    │   │   └── zathura                # Zathura PDF reader colors
    │   └── colorschemes/              # Static wal colorschemes (dark/light)
    ├── firefox-home/index.html        # Custom Firefox new-tab page
    └── scripts/
        ├── random-wallpaper.sh        # Pick random wallpaper via qs IPC
        ├── define.sh                  # Dictionary lookup → notify-send
        └── Music.sh                   # Launch rmpc + stop MPD
```

---

## Keybinds

| Key | Action |
|---|---|
| `Super + Return` | Open Kitty terminal |
| `Super + D` | Toggle app launcher |
| `Super + A` | Toggle dashboard |
| `Super + M` | Toggle music panel |
| `Super + W` | Toggle wallpaper picker |
| `Super + Shift + W` | Random wallpaper |
| `Super + X` | Lock screen (hyprlock) |
| `Super + Q` | Kill active window |
| `Super + F` | Fullscreen |
| `Super + T` | Toggle floating |
| `Super + H/J/K/L` | Move focus |
| `Super + Shift + H/J/K/L` | Move window |
| `Super + Ctrl + H/J/K/L` | Resize window |
| `Super + 1–0` | Switch workspace |
| `Super + Shift + 1–0` | Move window to workspace |
| `Super + S` | Screenshot (grim + slurp) |
| `Super + N` | Toggle SwayNC |
| `Super + Shift + N` | Clear notifications |
| `Super + Shift + E` | Exit Hyprland |
| `Super + LMB drag` | Move window |
| `Super + RMB drag` | Resize window |
| `XF86Audio*` | Volume up/down/mute |

---

## Theming System

Theming is driven by **pywal** (`wal -i <wallpaper>`). On wallpaper change the shell:

1. Runs `wal -i <path> -n -q` to regenerate `~/.cache/wal/`
2. Copies `colors-swaync.css` → `~/.config/swaync/style.css` and sends `SIGUSR1` to reload SwayNC
3. Blurs the wallpaper and saves it as `~/wallpapers/.current-blurred.jpg` (used by hyprlock)
4. Quickshell reads `~/.cache/wal/colors.json` and updates all `walColor*` properties live

The `config/wal/templates/` directory contains pywal templates that are rendered on each `wal` run — including a `Colors.qml` singleton consumed by Quickshell and CSS for GTK/SwayNC.

---

## Installation

### Prerequisites

- An existing NixOS installation (or another distro — see non-NixOS section)
- Git
- An NVIDIA or AMD GPU (config has both `amdgpu` and `nvidia` drivers — adjust as needed)
- Flakes enabled in your Nix config

---

### On a Fresh or Existing NixOS System

#### 1. Enable flakes (if not already)

Add to your existing `/etc/nixos/configuration.nix`:

```nix
nix.settings.experimental-features = [ "nix-command" "flakes" ];
```

Then `sudo nixos-rebuild switch`.

#### 2. Clone the repo

```bash
git clone https://github.com/robbsbro69/nixos-dotfiles ~/nixos-dotfiles
```

#### 3. Symlink the dotfiles directory to ~/.config

```bash
ln -sf ~/nixos-dotfiles ~/.config
```

> This is how the repo is designed to work — `~/.config` **is** the repo. All app configs live under `~/nixos-dotfiles/config/` and Home Manager's `xdg.configFile` entries create symlinks from `~/.config/<app>` → `~/nixos-dotfiles/config/<app>`.

#### 4. Adjust hardware-specific settings

Edit `configuration.nix` before building:

- **GPU:** If you only have AMD, remove the `nvidia` block and adjust `services.xserver.videoDrivers` to just `[ "amdgpu" ]`. If only NVIDIA, remove `"amdgpu"` and keep the nvidia block.
- **Monitors:** Update `hypr/hyprland/general.conf` — the `monitor =` lines are set to `eDP-1` (laptop) and `HDMI-A-1`. Run `hyprctl monitors` to find your monitor names.
- **UUID mounts:** The `fileSystems` entries in `configuration.nix` reference specific disk UUIDs. Either remove them or update with your own (`lsblk -f`).
- **Username:** The config uses `alpha` as the username. Replace all occurrences if your username differs:
  ```bash
  grep -r "alpha" ~/nixos-dotfiles/configuration.nix ~/nixos-dotfiles/home.nix
  ```

#### 5. Copy or generate hardware config

```bash
sudo nixos-generate-config --show-hardware-config > ~/nixos-dotfiles/hardware-configuration.nix
```

#### 6. Point NixOS at the new flake

```bash
sudo nixos-rebuild switch --flake ~/nixos-dotfiles#nixos
```

The flake provides everything: system packages, Home Manager, Quickshell (from the outfoxxed git source), and Spicetify.

#### 7. Post-install

```bash
# Apply a wallpaper to bootstrap pywal colors
wal -i ~/wallpapers/<your-wallpaper>

# Start Quickshell manually once to verify, then relogin via ly
quickshell -p ~/.config/quickshell
```

---

### Rebuilding After Changes

The `nrs` alias is defined in `home.nix`:

```bash
nrs          # sudo nixos-rebuild switch --flake ~/nixos-dotfiles#nixos
nuprs        # nix flake update && nrs
gnrs         # git add . && git commit -m "update" && nrs
```

---

### On Another Linux Distro (Non-NixOS)

This configuration is NixOS-first, but the application configs themselves are plain files and work anywhere. You will need to manually install each dependency and link the configs.

#### Dependencies to install via your distro's package manager

| Package | Purpose |
|---|---|
| `hyprland` | Window manager |
| `hyprlock` | Lock screen |
| `hypridle` | Idle daemon |
| `hyprpaper` | Wallpaper daemon |
| `swww` | Animated wallpaper daemon |
| `quickshell` | Shell |
| `kitty` | Terminal |
| `neovim` | Editor |
| `yazi` | File manager |
| `starship` | Prompt |
| `fastfetch` | System info |
| `cava` | Audio visualizer |
| `playerctl` | Media control |
| `brightnessctl` | Brightness control |
| `pipewire` + `wireplumber` + `wpctl` | Audio |
| `grim` + `slurp` | Screenshots |
| `wl-clipboard` | Clipboard |
| `swaync` | Notifications |
| `pywal` | Color theming |
| `gammastep` | Blue light filter |
| `mpd` + `rmpc` | Music |
| `spicetify-cli` | Spotify theming |
| `imagemagick` | Wallpaper blur + thumbnail generation |
| `vips` / `libvips` | Fast thumbnail generation |
| `jq` | JSON parsing |
| `upower` | Battery info |
| `networkmanager` | WiFi management |
| `bluetoothctl` | Bluetooth |
| `eza` | ls replacement |
| `fzf` | Fuzzy finder |
| `zoxide` | cd replacement |
| `ripgrep` | Grep for Neovim |
| `ttf-jetbrains-mono-nerd` | Font |
| `nodejs` + `gcc` | Neovim LSP/Treesitter build deps |
| `rust` + `cargo` | Rust toolchain |
| `nil` + `nixpkgs-fmt` | Nix LSP (optional if not on NixOS) |

#### Linking configs

```bash
git clone https://github.com/robbsbro69/nixos-dotfiles ~/nixos-dotfiles

# Link individual configs (do NOT symlink the whole directory to ~/.config
# unless you want the repo to replace it entirely)
ln -sf ~/nixos-dotfiles/config/hypr       ~/.config/hypr
ln -sf ~/nixos-dotfiles/config/quickshell ~/.config/quickshell
ln -sf ~/nixos-dotfiles/config/kitty      ~/.config/kitty
ln -sf ~/nixos-dotfiles/config/nvim       ~/.config/nvim
ln -sf ~/nixos-dotfiles/config/yazi       ~/.config/yazi
ln -sf ~/nixos-dotfiles/config/starship   ~/.config/starship
ln -sf ~/nixos-dotfiles/config/fastfetch  ~/.config/fastfetch
ln -sf ~/nixos-dotfiles/config/cava       ~/.config/cava
ln -sf ~/nixos-dotfiles/config/mpv        ~/.config/mpv
ln -sf ~/nixos-dotfiles/config/swaync     ~/.config/swaync
ln -sf ~/nixos-dotfiles/config/wal        ~/.config/wal
ln -sf ~/nixos-dotfiles/config/scripts    ~/.config/scripts
```

#### Changes needed on non-NixOS

- **`hypr/hyprland/execs.conf`:** The `QML2_IMPORT_PATH` is set to `/run/current-system/sw/lib/qt-6/qml` which is NixOS-specific. Change it to wherever Qt6 QML modules are installed on your system, e.g.:
  ```
  exec-once = QML2_IMPORT_PATH=/usr/lib/qt6/qml quickshell -p ~/.config/quickshell
  ```
- **`hypr/hyprland/env.conf`:** Remove or adjust `NIXOS_OZONE_WL` if not needed (it's safe to keep, just unused).
- **Spicetify:** Without Nix, configure it manually via `spicetify-cli`. Apply Catppuccin Mocha theme separately: https://github.com/catppuccin/spicetify
- **Fonts:** Install JetBrainsMono Nerd Font manually from https://www.nerdfonts.com/
- **Shell aliases** in `home.nix` (like `nrs`, `gnrs`, etc.) won't exist — add them manually to your `~/.bashrc` or `~/.zshrc` as needed.
- **pywal templates:** Copy `config/wal/templates/colors-swaync.css` to `~/.config/wal/templates/` so pywal regenerates it on each run.

---

## Quickshell IPC

The shell exposes IPC targets you can call from scripts or keybinds:

| Key | Action |
| --- | --- |
| `Super + D` | qs ipc call launcher toggle       # Toggle app launcher
| `Super + A` | qs ipc call dashboard toggle      # Toggle dashboard panel
| `Super + M` | qs ipc call music toggle          # Toggle music panel
| `Super + W` | qs ipc call wallpaper toggle      # Toggle wallpaper picker
| N\A | qs ipc call wifi toggle           # Toggle WiFi panel
| N\A | qs ipc call bluetooth toggle      # Toggle Bluetooth panel
| `Super + SHIFT + W` | qs ipc call randomwallpaper apply "<path>"  # Apply specific wallpaper

---

## Wallpapers

Wallpapers are expected in `~/wallpapers/`. The wallpaper picker in Quickshell scans this directory for `.jpg`, `.jpeg`, `.png`, `.webp`, and `.gif` files.

Thumbnails are cached in `~/.cache/wallpaper-thumbs/`. A blurred version of the active wallpaper is written to `~/wallpapers/.current-blurred.jpg` and used by hyprlock.

```bash
# Random wallpaper via keybind (Super+Shift+W) or directly:
~/.config/scripts/random-wallpaper.sh
```

---

## Neovim

Plugin manager: **lazy.nvim** (auto-bootstrapped on first launch).

| Plugin | Purpose |
|---|---|
| `tokyonight.nvim` | Colorscheme (storm, transparent) |
| `blink.cmp` | Completion engine |
| `nvim-lspconfig` | LSP (rust-analyzer with clippy) |
| `fzf-lua` | Fuzzy finder |
| `lualine.nvim` | Statusline |
| `snacks.nvim` | Dashboard |
| `gitsigns.nvim` | Git diff in gutter |
| `nvim-autopairs` | Auto bracket/quote pairs |
| `yazi.nvim` | File manager |
| `markdown-preview.nvim` | Live preview |

---

## Useful Aliases

Defined in `home.nix` → `programs.bash.shellAliases`:

```bash
nrs      # sudo nixos-rebuild switch --flake ~/nixos-dotfiles#nixos
nuprs    # nix flake update && nrs
gnrs     # git add . && git commit -m "update" && nrs
ff       # fastfetch with random logo
ls       # eza --icons
ll       # eza -l --icons
btw      # echo "i use nixos, btw"
webp2png # batch convert *.webp → *.png in current dir
```

---

## Notes

- The `swaync/style.css` is a **symlink** to `~/.cache/wal/colors-swaync.css`. Don't manually edit it — it's regenerated by pywal on every wallpaper change.
- Quickshell is pulled from the upstream Git source (not nixpkgs) via the `quickshell` flake input, which follows `nixpkgs-unstable`.
- The bar's cava visualizer only runs when media is `Playing`. It reads from `cava/config_raw` (stdout/ascii mode) and gracefully decays when paused.
- The `WLR_DRM_DEVICES=/dev/dri/card1` env variable forces Hyprland to use a specific GPU. Adjust or remove if your setup differs (`ls /dev/dri/` to check).


 
---
 
## 📝 Credits

- [NixOS](https://github.com/nixos)
- [Hyprland](https://hyprland.org)
- [Quickshell](https://quickshell.org) by outfoxxed
- [Quickshell Config](https://github.com/Harman1307/dotfiles-Hyprland) by Harman

---
 
## 📄 License
 
MIT — do whatever you want with it.

