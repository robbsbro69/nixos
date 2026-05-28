{pkgs, ...}: {
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  hardware.firmware = [pkgs.linux-firmware];
}
