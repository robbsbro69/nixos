import Quickshell.Wayland

// Idle detector for screen time — loaded through a Loader so a missing protocol
// can't break the shell. Video players that inhibit idle keep counting as active.
IdleMonitor {
	timeout: 300
	respectInhibitors: true
}
