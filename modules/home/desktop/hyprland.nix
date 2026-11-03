{
  pkgs,
  pkgs-unstable,
  hyprland,
  ...
}: let
  system = pkgs.stdenv.hostPlatform.system;
  hctl = "${hyprland.packages.${system}.hyprland}/bin/hyprctl";
  notify = "${pkgs.libnotify}/bin/notify-send";
  # SUPER+SHIFT+Space — default layout dwindle <-> scrolling (workspace 4 always scrolls)
  layout-toggle = pkgs.writeShellScriptBin "layout-toggle" ''
    st="''${XDG_RUNTIME_DIR:-/tmp}/hypr-layout"
    if [ "$(cat "$st" 2>/dev/null)" = scrolling ]; then l=dwindle; else l=scrolling; fi
    ${hctl} eval "hl.config({ general = { layout = '$l' } })" >/dev/null && echo "$l" >"$st"
    ${notify} -a Layout -t 1500 "Layout: $l"
  '';
  # Hyprland's own polkit agent (falls back to polkit-gnome if the binary moved)
  polkit-agent = pkgs.writeShellScriptBin "polkit-agent" ''
    for p in ${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent ${pkgs.hyprpolkitagent}/bin/hyprpolkitagent; do
      [ -x "$p" ] && exec "$p"
    done
    exec ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1
  '';
  # video wallpaper: vidwall [toggle|on [file]|off] — random clip from ~/wallpapers/videos
  vidwall = pkgs.writeShellScriptBin "vidwall" ''
    dir="$HOME/wallpapers"
    on() {
      f="''${1:-$(find "$dir" -maxdepth 1 -type f \( -name '*.mp4' -o -name '*.webm' -o -name '*.mkv' \) 2>/dev/null | shuf -n1)}"
      [ -n "$f" ] || { ${pkgs.libnotify}/bin/notify-send -a Wallpaper "No videos" "put some .mp4/.webm in $dir"; exit 1; }
      ${pkgs.mpvpaper}/bin/mpvpaper -f -l bottom -o "no-audio loop hwdec=auto panscan=1.0" '*' "$f"
    }
    off() { pkill "^.?mpvpaper"; }
    case "''${1:-toggle}" in
      on) off; on "$2" ;;
      off) off ;;
      toggle) if pgrep "^.?mpvpaper" >/dev/null; then off; else on; fi ;;
    esac
  '';
in {
  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = false;
    package = hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
  };
  home.packages = with pkgs; [
    hyprlock
    hypridle
    hyprsunset
    hyprpicker
    hyprpolkitagent
    awww
    cliphist
    polkit_gnome
    mpvpaper
    polkit-agent
    vidwall
    layout-toggle
    pulseaudio # only for the pactl command (device names in the focus panel)
  ];

}
