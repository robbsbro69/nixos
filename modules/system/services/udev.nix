{pkgs, ...}: {
  services.udev.packages = with pkgs; [libmtp];
}
