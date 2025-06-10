#!/usr/bin/env bash
# Sometimes USB freezes after a KVM switch
echo -n "0000:00:14.0" | sudo tee /sys/bus/pci/drivers/xhci_hcd/unbind
sleep 2
echo -n "0000:00:14.0" | sudo tee /sys/bus/pci/drivers/xhci_hcd/bind
