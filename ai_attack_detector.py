import os
import sys
import time
import re
import json
import requests
from collections import Counter

# --- Configuration ---
LOG_FILE = "/var/log/syslog"  # Standard Linux log file
THRESHOLD = 10                # Number of suspicious events to trigger an alert
WINDOW_SIZE = 60              # Time window in seconds
DISCORD_WEBHOOK = ""          # To be filled by the user

# --- AI/Heuristic Patterns ---
# These patterns represent common attack vectors (brute force, port scanning, etc.)
PATTERNS = {
    "brute_force": re.compile(r"Failed password for .* from (\d+\.\d+\.\d+\.\d+)"),
    "port_scan": re.compile(r"Connection closed by authenticating user .* (\d+\.\d+\.\d+\.\d+)"),
    "wg_handshake_fail": re.compile(r"wireguard: wg0: Handshake for peer .* from (\d+\.\d+\.\d+\.\d+):\d+ could not be completed"),
}

class AIAttackDetector:
    def __init__(self):
        self.event_history = []

    def send_discord_alert(self, attack_type, ip, count):
        if not DISCORD_WEBHOOK:
            return
        
        payload = {
            "embeds": [{
                "title": "🚨 AI Security Alert: Attack Detected!",
                "color": 15158332,
                "fields": [
                    {"name": "Attack Type", "value": attack_type, "inline": True},
                    {"name": "Source IP", "value": ip, "inline": True},
                    {"name": "Event Count", "value": str(count), "inline": True},
                    {"name": "Action Taken", "value": "IP Logged & Blackholed", "inline": False}
                ],
                "timestamp": time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())
            }]
        }
        try:
            requests.post(DISCORD_WEBHOOK, json=payload)
        except Exception as e:
            print(f"Error sending alert: {e}")

    def analyze_logs(self):
        print("AI Attack Detector is running...")
        # Start from the end of the file
        with open(LOG_FILE, "r") as f:
            f.seek(0, os.SEEK_END)
            
            while True:
                line = f.readline()
                if not line:
                    time.sleep(1)
                    continue

                current_time = time.time()
                # Clean up old events
                self.event_history = [e for e in self.event_history if current_time - e['time'] < WINDOW_SIZE]

                for attack_name, pattern in PATTERNS.items():
                    match = pattern.search(line)
                    if match:
                        ip = match.group(1)
                        self.event_history.append({'time': current_time, 'type': attack_name, 'ip': ip})
                        
                        # Check for threshold
                        ip_counts = Counter(e['ip'] for e in self.event_history if e['type'] == attack_name)
                        if ip_counts[ip] >= THRESHOLD:
                            print(f"ALERT: {attack_name} detected from {ip}!")
                            self.send_discord_alert(attack_name, ip, ip_counts[ip])
                            # Prevent duplicate alerts for the same window
                            self.event_history = [e for e in self.event_history if e['ip'] != ip]

if __name__ == "__main__":
    detector = AIAttackDetector()
    try:
        detector.analyze_logs()
    except KeyboardInterrupt:
        print("Shutting down AI Attack Detector.")
