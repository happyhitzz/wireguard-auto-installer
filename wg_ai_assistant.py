import sys
import os

def main():
    print("\n--- WireGuard AI Assistant ---")
    print("I can help you with questions about your VPN, security features, or troubleshooting.")
    print("Type 'exit' to return to the main menu.\n")
    
    while True:
        user_input = input("You: ").strip().lower()
        
        if user_input in ['exit', 'quit', 'q']:
            break
            
        if "mtu" in user_input:
            print("AI: MTU (Maximum Transmission Unit) determines the largest packet size. Our Auto-MTU optimizer finds the best value to prevent fragmentation and boost speed.")
        elif "stealth" in user_input or "obfuscation" in user_input:
            print("AI: Stealth Mode uses udp2raw or Shadowsocks to mask VPN traffic as standard HTTPS, helping you bypass strict firewalls.")
        elif "ddos" in user_input:
            print("AI: We have multiple layers of DDoS protection: a Blackhole toggle, an AI DDoS Shield for traffic anomalies, and Fail2Ban for brute-force.")
        elif "quantum" in user_input:
            print("AI: Quantum-Resistant VPN uses post-quantum cryptography to ensure your data remains secure even against future quantum computers.")
        elif "help" in user_input or "how" in user_input:
            print("AI: You can manage clients, toggle security features, or run speed tests from the main menu. Just select the corresponding number!")
        else:
            print("AI: That's a great question! For specific technical details, you can check our README on GitHub or ask about MTU, Stealth Mode, or DDoS protection.")

if __name__ == "__main__":
    main()
