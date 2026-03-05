#!/usr/bin/env python3
"""
mic-mute-guard: Erkennt Hardware-Mute am Tonor Mikrofon (Stille = Hardware gemutet).
Synchronisiert den Hardware-Zustand mit dem Waybar recording-ctl Modul.

Verwendet einen persistenten parec-Prozess (kein Flackern in qpwgraph).
"""

import os
import struct
import subprocess
import sys
import time

MIC_SOURCE = "alsa_input.usb-TONOR_TONOR_TD520S_Dynamic_Mic_0000KT59300000745-00.analog-stereo"
SILENCE_THRESHOLD = 2     # RMS unter diesem Wert = echtes Schweigen (Hardware-Mute)
SILENCE_DURATION = 1.0    # Sekunden echtes Schweigen bis Mute erkannt

RATE = 16000
CHANNELS = 1
BYTES_PER_SAMPLE = 2      # s16le
CHUNK_SECONDS = 0.4       # Wie viel Audio pro Messung gelesen wird
CHUNK_SIZE = int(RATE * CHANNELS * BYTES_PER_SAMPLE * CHUNK_SECONDS)

RECORDING_CTL = os.path.join(os.path.dirname(os.path.abspath(__file__)), "recording-ctl.sh")
MIC_MUTED_FILE = "/tmp/waybar_rec_mic_muted"


def start_parec() -> subprocess.Popen:
    return subprocess.Popen(
        ["parec", f"--device={MIC_SOURCE}", "--format=s16le",
         "--channels=1", "--rate=16000", "--stream-name=mic-mute-guard"],
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
    )


def read_rms(proc: subprocess.Popen) -> float | None:
    try:
        data = proc.stdout.read(CHUNK_SIZE)
    except Exception:
        return None
    if len(data) < 2:
        return None
    n = len(data) // 2
    samples = struct.unpack(f"<{n}h", data[:n * 2])
    return (sum(s * s for s in samples) / n) ** 0.5


def sync_waybar_mic(muted: bool):
    """Synchronisiert Waybar-Mic-State mit Hardware-State – nur bei Abweichung."""
    waybar_muted = os.path.exists(MIC_MUTED_FILE)
    if muted != waybar_muted:
        subprocess.run([RECORDING_CTL, "toggle-mic"], check=False)


def main():
    print(f"mic-mute-guard gestartet – {MIC_SOURCE}")
    print("Strg+C zum Beenden\n")

    silence_since = None
    warned = False
    proc = start_parec()

    while True:
        try:
            # Prozess neu starten falls er unerwartet beendet wurde
            if proc.poll() is not None:
                proc = start_parec()

            rms = read_rms(proc)

            if rms is None:
                time.sleep(0.5)
                continue

            now = time.monotonic()

            if rms < SILENCE_THRESHOLD:
                if silence_since is None:
                    silence_since = now
                elif now - silence_since >= SILENCE_DURATION and not warned:
                    print(f"[MUTED] Hardware-Mute erkannt (RMS={rms:.0f})")
                    sync_waybar_mic(muted=True)
                    warned = True
            else:
                if warned:
                    print(f"[OK] Mikrofon aktiv (RMS={rms:.0f})")
                    sync_waybar_mic(muted=False)
                silence_since = None
                warned = False

        except KeyboardInterrupt:
            print("\nBeendet.")
            proc.kill()
            sys.exit(0)


if __name__ == "__main__":
    main()
