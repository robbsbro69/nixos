import dbus, dbus.service, dbus.mainloop.glib
from gi.repository import GLib

dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
bus = dbus.SessionBus()
name = dbus.service.BusName('org.freedesktop.Notifications', bus)

class NotifDaemon(dbus.service.Object):
    def __init__(self):
        super().__init__(bus, '/org/freedesktop/Notifications')
        self.nid = 0

    @dbus.service.method('org.freedesktop.Notifications', in_signature='susssasa{sv}i', out_signature='u')
    def Notify(self, app, rid, icon, summary, body, actions, hints, timeout):
        self.nid += 1
        print(f"{self.nid}|{app}|{summary}|{body}", flush=True)
        return dbus.UInt32(self.nid)

    @dbus.service.method('org.freedesktop.Notifications', out_signature='ssss')
    def GetServerInformation(self):
        return ('quickshell', 'quickshell', '1.0', '1.2')

    @dbus.service.method('org.freedesktop.Notifications', out_signature='as')
    def GetCapabilities(self):
        return dbus.Array(['body', 'actions'], signature='s')

    @dbus.service.method('org.freedesktop.Notifications', in_signature='u')
    def CloseNotification(self, id):
        pass

NotifDaemon()
GLib.MainLoop().run()
