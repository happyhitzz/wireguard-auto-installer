import os
import sys
import time
import subprocess
import json
import requests
from collections import Counter
import numpy as np

# --- Configuration ---
CHECK_INTERVAL = 10           # Seconds between checks
Z_THRESHOLD = 3.5             # Z-score threshold for anomaly detection
MIN_CONNECTIONS = 50          # Minimum connections to even consider an IP suspicious
BAN_TIME = 3600               # Ban duration in seconds (1 hour)
DISCORD_WEBHOOK = ""          # To be filled by the main script
TELEGRAM_CONF = "/etc/wireguard/telegram.conf"

class AIDDoSShield:
    def __init__(self):
        self.banned_ips = {}

    def get_connections(self):
        try:
            # Get all established and syn-recv connections
            output = subprocess.check_output(["ss", "-ntu", "state", "established", "state", "syn-recv"], encoding='utf-8')
            lines = output.splitlines()[1:]
            ips = []
            for line in lines:
                parts = line.split()
                if len(parts) >= 5:
                    # Extract remote IP (handle IPv6 and ports)
                    remote = parts[4]
                    ip = remote.rsplit(':', 1)[0].strip('[]')
                    if ip and not ip.startswith('127.') and not ip.startswith('10.0.0.'):
                        ips.append(ip)
            return Counter(ips)
        except Exception as e:
            print(f"Error getting connections: {e}")
            return Counter()

    def ban_ip(self, ip, count):
        if ip in self.banned_ips:
            return
        
        print(f"🚨 AI SHIELD: Anomalous traffic detected from {ip} ({count} connections). Banning...")
        try:
            subprocess.run(["iptables", "-I", "INPUT", "-s", ip, "-j", "DROP"], check=True)
            self.banned_ips[ip] = time.time()
            self.send_alert(ip, count)
        except Exception as e:
            print(f"Error banning IP {ip}: {e}")

    def unban_expired(self):
        current_time = time.time()
        to_unban = [ip for ip, ban_time in self.banned_ips.items() if current_time - ban_time > BAN_TIME]
        for ip in to_unban:
            print(f"✅ AI SHIELD: Unbanning {ip} (Ban expired).")
            subprocess.run(["iptables", "-D", "INPUT", "-s", ip, "-j", "DROP"])
            del self.banned_ips[ip]

    def send_alert(self, ip, count):
        msg = f"🛡️ AI DDoS Shield: Banned {ip} for anomalous traffic ({count} connections)."
        
        # Discord
        if DISCORD_WEBHOOK:
            payload = {"content": msg}
            try: requests.post(DISCORD_WEBHOOK, json=payload)
            except: pass
            
        # Telegram
        if os.path.exists(TELEGRAM_CONF):
            try:
                with open(TELEGRAM_CONF, 'r') as f:
                    conf = dict(line.replace('"', '').split('=') for line in f if '=' in line)
                if 'TG_TOKEN' in conf and 'TG_CHAT_ID' in conf:
                    requests.post(f"https://api.telegram.org/bot{conf['TG_TOKEN'].strip()}/sendMessage", 
                                  data={"chat_id": conf['TG_CHAT_ID'].strip(), "text": msg})
            except: pass

    def run(self):
        print("🛡️ AI DDoS Shield is active and monitoring traffic...")
        while True:
            counts = self.get_connections()
            if counts:
                values = list(counts.values())
                if len(values) > 1:
                    mean = np.mean(values)
                    std = np.std(values)
                    
                    if std > 0:
                        for ip, count in counts.items():
                            if count > MIN_CONNECTIONS:
                                z_score = (count - mean) / std
                                if z_score > Z_THRESHOLD:
                                    self.ban_ip(ip, count)
                elif len(values) == 1:
                    ip, count = list(counts.items())[0]
                    if count > MIN_CONNECTIONS * 2: # Higher threshold for single source
                        self.ban_ip(ip, count)

            self.unban_expired()
            time.sleep(CHECK_INTERVAL)

if __name__ == "__main__":
    shield = AIDDoSShield()
    try:
        shield.run()
    except KeyboardInterrupt:
        print("Shutting down AI DDoS Shield.")
