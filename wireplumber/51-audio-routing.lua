-- Audio output routing priorities (WirePlumber 0.4).
--
-- Built-in analog output ships at priority.session 1009. Default-sink
-- selection picks the highest-priority available node, so these rules pin the
-- ordering when no sink is explicitly configured:
--
--   G435 wireless headset (when its dongle is switched to this laptop) > speakers
--   built-in laptop speakers                                           > everything else
--   "Generic USB Audio" (001f:0b21, always attached through the USB switch)
--   is demoted so it never wins the default; it stays selectable by hand.

table.insert(alsa_monitor.rules, {
  matches = {
    { { "node.name", "matches", "alsa_output.usb-Logitech_G_series_G435_*" } },
  },
  apply_properties = {
    ["priority.session"] = 2000,
    ["priority.driver"] = 2000,
  },
})

table.insert(alsa_monitor.rules, {
  matches = {
    { { "node.name", "matches", "alsa_output.usb-Generic_USB_Audio_*" } },
  },
  apply_properties = {
    ["priority.session"] = 100,
    ["priority.driver"] = 100,
  },
})
