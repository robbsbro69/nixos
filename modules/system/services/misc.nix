{...}: {
  services.blueman.enable = true;
  services.gvfs.enable = true;
  services.dbus.enable = true;
  services.udisks2.enable = true;

  programs.ssh.startAgent = true;
  programs.dconf.enable = true;
}
