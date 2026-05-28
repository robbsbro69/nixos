{...}: {
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  services.pipewire.wireplumber.extraConfig."99-bluetooth-default" = {
    "monitor.bluez.rules" = [
      {
        matches = [{"device.name" = "~bluez_card.*";}];
        actions = {
          update-props = {
            "priority.session" = 2000;
          };
        };
      }
    ];
  };
}
