#!/usr/bin/env python3
"""Resolve the currently loaded B1 roll through its RFID code and NIIMBOT API."""

import argparse
import json
import sys
import urllib.error
import urllib.request

from niimprint import PrinterClient, SerialTransport
from niimprint.printer import RequestCodeEnum

API_URL = "https://print.niimbot.com/api/template/getCloudTemplateByOneCode"
DPI = 203
MM_PER_INCH = 25.4


def read_one_code(port: str) -> str:
    transport = SerialTransport(port)
    try:
        printer = PrinterClient(transport)
        printer.heartbeat()
        packet = printer._transceive(RequestCodeEnum.GET_RFID, b"\x01")
    finally:
        transport._serial.close()

    if packet is None or len(packet.data) < 10:
        raise RuntimeError("the B1 returned no readable RFID payload")

    barcode_length = packet.data[8]
    barcode_end = 9 + barcode_length
    if barcode_length == 0 or barcode_end > len(packet.data):
        raise RuntimeError("the B1 RFID payload has no usable oneCode")

    return packet.data[9:barcode_end].decode("ascii")


def fetch_template(one_code: str) -> dict:
    request = urllib.request.Request(
        API_URL,
        data=json.dumps({"oneCode": one_code}).encode(),
        headers={
            "Content-Type": "application/json",
            "niimbot-user-agent": "AppVersionName/6.6.5 Client/niimprint-local",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(request, timeout=15) as response:
            payload = json.load(response)
    except urllib.error.URLError as error:
        raise RuntimeError(f"NIIMBOT template lookup failed: {error}") from error

    if payload.get("code") != 1 or not isinstance(payload.get("data"), dict):
        raise RuntimeError(f"NIIMBOT did not resolve oneCode {one_code}")
    return payload["data"]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", default="/dev/ttyACM0")
    args = parser.parse_args()

    one_code = read_one_code(args.port)
    template = fetch_template(one_code)
    api_width = template.get("width")
    api_height = template.get("height")
    rotate = template.get("rotate", template.get("canvasRotate", 0))
    if not all(isinstance(value, (int, float)) for value in (api_width, api_height)):
        raise RuntimeError("NIIMBOT template response has no dimensions")
    if rotate not in (0, 90, 180, 270):
        raise RuntimeError(f"unsupported canvas rotation: {rotate}")

    width_mm, height_mm = api_width, api_height
    if rotate in (90, 270):
        width_mm, height_mm = height_mm, width_mm

    result = {
        "oneCode": one_code,
        "labelName": next(
            (
                entry["name"]
                for entry in template.get("labelNames", [])
                if entry.get("languageCode") == "en"
            ),
            None,
        ),
        "dimensions": {
            "widthMm": width_mm,
            "heightMm": height_mm,
            "canvasRotate": rotate,
        },
        "b1Canvas": {
            "widthPx": 384,
            "heightPx": round(height_mm * DPI / MM_PER_INCH),
            "dpi": DPI,
        },
    }
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    try:
        main()
    except RuntimeError as error:
        print(f"error: {error}", file=sys.stderr)
        raise SystemExit(1)
