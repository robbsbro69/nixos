{...}: {
  fileSystems."/mnt/ssd" = {
    device = "/dev/disk/by-uuid/61764028-e6aa-4cd3-8bc5-44ad25df22e0";
    fsType = "ext4";
    options = ["defaults" "nofail"];
  };
}
