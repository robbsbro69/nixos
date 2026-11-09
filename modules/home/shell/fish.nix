{ ... }: {
 programs.fish = {
   enable = true;

   shellAliases = {
     btw = "echo i use nixos, btw";
     nrs = "sudo nixos-rebuild switch --impure --flake ~/nixos-dotfiles#nixos";
     nuprs = "nix flake update && sudo nixos-rebuild switch --impure --flake ~/nixos-dotfiles#nixos";
     gnrs = "git add . && git commit -m 'update' && nrs";
     ls = "eza --icons --group-directories-first";
     ll = "eza -l --icons --git --group-directories-first --time-style=relative";
     la = "eza -la --icons --git --group-directories-first --time-style=relative";
     lt = "eza --tree --level=2 --icons --group-directories-first";
   };


functions.reel-dev = ''
  cd ~/projects/reel
  source ~/.config/reel-test/env.fish
  opencode $argv
'';

   functions = {
     ff = "fastfetch --logo (find ~/.config/fastfetch/logo -type f | shuf -n 1) --logo-type kitty --logo-height 18";
     gf = "fastfetch --logo (find ~/Pictures/Dump_fastfetch_logo/FastFetch -type f | shuf -n 1) --logo-type kitty --logo-height 18";
     webp2png = ''
       for f in *.webp
         magick $f (string replace -r '\.webp$' '.png' $f); and rm $f
       end
     '';
     zip2cbz = ''
       for f in *.zip
         mv -- $f (string replace -r '\.zip$' '.cbz' $f)
       end
     '';
     rmpc = ''
       mpd-mpris &
       set -l mpris_pid $last_pid
       command rmpc $argv
       kill $mpris_pid 2>/dev/null
     '';
   };

   interactiveShellInit = ''
     set -g fish_greeting

     # catppuccin-mocha syntax colours
     set -g fish_color_normal cdd6f4
     set -g fish_color_command f5c2e7
     set -g fish_color_keyword cba6f7
     set -g fish_color_param f2cdcd
     set -g fish_color_quote a6e3a1
     set -g fish_color_redirection b4befe
     set -g fish_color_end fab387
     set -g fish_color_comment 7f849c
     set -g fish_color_error f38ba8
     set -g fish_color_operator 89dceb
     set -g fish_color_escape eba0ac
     set -g fish_color_option a6e3a1
     set -g fish_color_autosuggestion 6c7086
     set -g fish_color_valid_path --underline
     set -g fish_color_selection --background=313244
     set -g fish_color_search_match --background=313244
     set -g fish_pager_color_prefix f5c2e7 --bold
     set -g fish_pager_color_completion cdd6f4
     set -g fish_pager_color_description 6c7086
     set -g fish_pager_color_progress 7f849c
     set -gx FZF_DEFAULT_OPTS "--color=bg+:#313244,bg:#1E1E2E,spinner:#F5E0DC,hl:#F38BA8 --color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC --color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8 --color=selected-bg:#45475A --color=border:#6C7086,label:#CDD6F4"
     type -q zoxide; and zoxide init fish | source
     type -q fzf; and fzf --fish | source
   '';
 };
}
