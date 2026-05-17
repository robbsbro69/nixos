{pkgs, ...}: {
  boot.kernelPackages = pkgs.linuxPackages;
  boot.blacklistedKernelModules = ["nouveau"];
  boot.kernelModules = ["kvm-amd"];
}
