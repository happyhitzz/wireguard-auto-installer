#!/bin/bash

# =================================================================
# WireGuard Zero-Config Auto-Installer (v6.1) - FULL CONTROL
# =================================================================
# Features: Zero-Config, Stealth Mode, Performance Tuning,
# User Expiration, Anti-DDoS, AI Detection, Auto-Update,
# Telegram Alerts, MTU Optimizer, Multi-Hop, AI DDoS Shield,
# Web Dashboard, Geo-IP Blocking, Automated Cloud Backups,
# Fail2Ban, Port Knocking, Panic Button, Multi-Protocol,
# Traffic Shaping (QoS), Health Checks, Advanced Analytics.
# NEW: Toggle (ON/OFF) support for EVERY feature.
# =================================================================

# --- Configuration & Defaults ---
WG_DIR="/etc/wireguard"
WG_CONF="$WG_DIR/wg0.conf"
WG_PORT="51820"
WG_PROTO="udp"
STEALTH_PORT="443"
STEALTH_PASS="mypassword123"
EXPIRY_LOG="$WG_DIR/expiry.log"
BLACKHOLE_CONF="/etc/sysctl.d/99-anti-ddos.conf"
AI_DETECTOR_SCRIPT="$WG_DIR/ai_attack_detector.py"
AI_SHIELD_SCRIPT="$WG_DIR/ai_ddos_shield.py"
AI_DETECTOR_SERVICE="wg-ai-detector"
AI_SHIELD_SERVICE="wg-ai-shield"
DASHBOARD_SERVICE="wg-dashboard"
HEALTH_CHECK_SERVICE="wg-health-check"
SCRIPT_URL="https://raw.githubusercontent.com/happyhitzz/wireguard-auto-installer/main/wireguard_installer.sh"
AI_SCRIPT_URL="https://raw.githubusercontent.com/happyhitzz/wireguard-auto-installer/main/ai_attack_detector.py"
SHIELD_SCRIPT_URL="https://raw.githubusercontent.com/happyhitzz/wireguard-auto-installer/main/ai_ddos_shield.py"
TELEGRAM_CONF="$WG_DIR/telegram.conf"
FEATURE_STATE_FILE="$WG_DIR/features.state"

# --- Colors for Output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# --- Helper Functions ---

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Error: This script must be run as root.${NC}"
        exit 1
    fi
}

detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$ID
    else
        echo -e "${RED}Unsupported OS.${NC}"
        exit 1
    fi
}

get_public_ip() {
    SERVER_IP=$(curl -s ifconfig.me || curl -s api.ipify.org || echo "YOUR_SERVER_IP")
}

get_main_interface() {
    INTERFACE=$(ip route get 8.8.8.8 | awk '{print $5; exit}')
    if [[ -z "$INTERFACE" ]]; then
        INTERFACE=$(ip -o link show | awk -F': ' '{print $2}' | grep -v "lo" | head -n1)
    fi
}

# --- Feature State Management ---

init_feature_states() {
    if [[ ! -f $FEATURE_STATE_FILE ]]; then
        touch $FEATURE_STATE_FILE
    fi
}

get_feature_state() {
    local feature=$1
    grep "^$feature=" $FEATURE_STATE_FILE | cut -d= -f2 || echo "OFF"
}

set_feature_state() {
    local feature=$1
    local state=$2
    if grep -q "^$feature=" $FEATURE_STATE_FILE; then
        sed -i "s/^$feature=.*/$feature=$state/" $FEATURE_STATE_FILE
    else
        echo "$feature=$state" >> $FEATURE_STATE_FILE
    fi
}

# --- Toggle Functions ---

toggle_mtu_optimizer() {
    local current=$(get_feature_state "MTU_OPTIMIZER")
    if [[ "$current" == "ON" ]]; then
        echo -e "${YELLOW}Disabling Auto-MTU Optimizer...${NC}"
        sed -i "s/^MTU = .*/MTU = 1420/" $WG_CONF
        systemctl restart wg-quick@wg0
        set_feature_state "MTU_OPTIMIZER" "OFF"
        echo -e "${GREEN}Auto-MTU disabled. Reset to default 1420.${NC}"
    else
        echo -e "${YELLOW}Enabling Auto-MTU Optimizer...${NC}"
        optimize_mtu
        set_feature_state "MTU_OPTIMIZER" "ON"
        echo -e "${GREEN}Auto-MTU enabled.${NC}"
    fi
}

toggle_traffic_shaping() {
    local current=$(get_feature_state "TRAFFIC_SHAPING")
    if [[ "$current" == "ON" ]]; then
        echo -e "${YELLOW}Disabling Traffic Shaping (QoS)...${NC}"
        get_main_interface
        tc qdisc del dev $INTERFACE root 2>/dev/null
        set_feature_state "TRAFFIC_SHAPING" "OFF"
        echo -e "${GREEN}Traffic shaping disabled.${NC}"
    else
        setup_traffic_shaping
        set_feature_state "TRAFFIC_SHAPING" "ON"
    fi
}

toggle_health_checks() {
    local current=$(get_feature_state "HEALTH_CHECKS")
    if [[ "$current" == "ON" ]]; then
        echo -e "${YELLOW}Disabling Health Checks...${NC}"
        crontab -l | grep -v "health_check.sh" | crontab -
        set_feature_state "HEALTH_CHECKS" "OFF"
        echo -e "${GREEN}Health checks disabled.${NC}"
    else
        setup_health_checks
        set_feature_state "HEALTH_CHECKS" "ON"
    fi
}

toggle_analytics() {
    local current=$(get_feature_state "ANALYTICS")
    if [[ "$current" == "ON" ]]; then
        echo -e "${YELLOW}Disabling Advanced Analytics...${NC}"
        echo "module wireguard -p" > /sys/kernel/debug/dynamic_debug/control 2>/dev/null
        set_feature_state "ANALYTICS" "OFF"
        echo -e "${GREEN}Advanced analytics disabled.${NC}"
    else
        setup_advanced_analytics
        set_feature_state "ANALYTICS" "ON"
    fi
}

# --- Menu ---

show_menu() {
    init_feature_states
    echo -e "\n${PURPLE}=====================================${NC}"
    echo -e "${PURPLE}   WireGuard Full Control v6.1       ${NC}"
    echo -e "${PURPLE}=====================================${NC}"
    echo "1) Install WireGuard"
    echo "2) Add New Client (with Expiry)"
    echo "3) List Clients"
    echo "4) Monitor Connections (Real-time)"
    echo "5) Run Speed Test"
    echo "6) Toggle Performance Tuning (Kernel/BBR) [$(get_feature_state "PERF_TUNING")]"
    echo "7) Toggle Auto-MTU Optimizer [$(get_feature_state "MTU_OPTIMIZER")]"
    echo "8) Toggle Stealth Mode (udp2raw) [$(get_feature_state "STEALTH_MODE")]"
    echo "9) Toggle Anti-DDoS Blackhole [$(get_feature_state "ANTI_DDOS")]"
    echo "10) Toggle AI Attack Detector [$(get_feature_state "AI_DETECTOR")]"
    echo "11) Toggle AI DDoS Shield [$(get_feature_state "AI_SHIELD")]"
    echo "12) Toggle Web Dashboard [$(get_feature_state "WEB_DASHBOARD")]"
    echo "13) Toggle Geo-IP Blocking [$(get_feature_state "GEOIP_BLOCK")]"
    echo "14) Toggle Fail2Ban Protection [$(get_feature_state "FAIL2BAN")]"
    echo "15) Toggle Port Knocking [$(get_feature_state "PORT_KNOCK")]"
    echo "16) Toggle Traffic Shaping (QoS) [$(get_feature_state "TRAFFIC_SHAPING")]"
    echo "17) Toggle Health Checks [$(get_feature_state "HEALTH_CHECKS")]"
    echo "18) Toggle Advanced Analytics [$(get_feature_state "ANALYTICS")]"
    echo "19) Toggle Multi-Protocol (Shadowsocks) [$(get_feature_state "MULTI_PROTO")]"
    echo "20) Setup Telegram Alerts"
    echo "21) Setup Multi-Hop Relay"
    echo "22) Run Cloud Backup Now"
    echo "23) Check for Updates Now"
    echo "24) ${RED}PANIC BUTTON (Lockdown)${NC}"
    echo "25) Uninstall"
    echo "26) Exit"
    read -p "Select [1-26]: " OPTION
}

# --- Main ---
check_root
detect_os

if [[ ! -d $WG_DIR ]]; then
    install_wg
    add_client
else
    while true; do
        show_menu
        case $OPTION in
            1) echo -e "${YELLOW}Already installed.${NC}" ;;
            2) add_client ;;
            3) grep "# Client:" $WG_CONF | cut -d: -f2 ;;
            4) watch -n 1 wg show ;;
            5) command -v speedtest-cli &> /dev/null || apt install -y speedtest-cli || dnf install -y speedtest-cli; speedtest-cli ;;
            6) toggle_performance_tuning ;;
            7) toggle_mtu_optimizer ;;
            8) toggle_stealth_mode ;;
            9) toggle_anti_ddos ;;
            10) toggle_ai_detector ;;
            11) toggle_ai_shield ;;
            12) toggle_web_dashboard ;;
            13) toggle_geoip_blocking ;;
            14) toggle_fail2ban ;;
            15) toggle_port_knocking ;;
            16) toggle_traffic_shaping ;;
            17) toggle_health_checks ;;
            18) toggle_analytics ;;
            19) toggle_multi_protocol ;;
            20) setup_telegram ;;
            21) setup_multi_hop ;;
            22) cloud_backup ;;
            23) self_update; update_ai_module ;;
            24) panic_button ;;
            25) systemctl stop wg-quick@wg0; rm -rf $WG_DIR; echo "Uninstalled."; exit 0 ;;
            26) exit 0 ;;
            *) echo -e "${RED}Invalid option.${NC}" ;;
        esac
    done
fi
