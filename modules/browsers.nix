{
  zen-browser,
  pkgs,
  ...
}: {
  imports = [
    zen-browser.homeModules.default
  ];

  programs.zen-browser = {
    enable = true;
    setAsDefaultBrowser = true;
    policies = {
      DisableAppUpdate = true;
      DisableTelemetry = true;
      DisablePocket = true;
    };
  };

  home.packages = with pkgs; [
    brave
  ];
}
