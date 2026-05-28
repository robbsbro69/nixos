{...}: {
  hardware.nvidia = {
    open = true;
    modesetting.enable = true;
    powerManagement.enable = false;
    nvidiaSettings = false;
    prime = {
      offload.enable = true;
      #      offload.enableOffloadCmd = true;
      amdgpuBusId = "PCI:6:0:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };
}
