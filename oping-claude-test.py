#!/usr/bin/env python3

import os
import sys
import tty
import time
import select
import socket
import struct
import termios
import argparse
import datetime
import threading
import subprocess
from dataclasses import dataclass
from typing import List, Dict, Optional, Tuple, Set

@dataclass
class PingStats:
    successful: List[float]
    unsuccessful: List[int]

class PingResult:
    def __init__(self, host: str, rtt: Optional[float], ip: Optional[str], port: Optional[int] = None):
        self.host = host
        self.rtt = rtt
        self.ip = ip
        self.port = port
        self.success = rtt is not None

class KeyboardReader:
    def __init__(self):
        self.old_settings = None

    def __enter__(self):
        self.old_settings = termios.tcgetattr(sys.stdin)
        tty.setraw(sys.stdin.fileno())
        return self

    def __exit__(self, type, value, traceback):
        termios.tcsetattr(sys.stdin, termios.TCSADRAIN, self.old_settings)

    def get_key(self) -> Optional[str]:
        if select.select([sys.stdin], [], [], 0)[0]:
            return sys.stdin.read(1)
        return None

class Pinger:
    def __init__(self, timeout: int = 1, ping_type: str = 'icmp', ports: List[int] = None):
        self.timeout = timeout
        self.ping_type = ping_type
        self.ports = ports or [80]  # Default to port 80 if none specified
        self.stats: Dict[str, Dict[str, PingStats]] = {}
        self.verbose = False
        self.debug = False
        self.lost_only = False
        self.sleep = 0
        self.running = True
        self.paused = False
        self.interface_ip = ''

    def create_icmp_packet(self) -> bytes:
        # """Create an ICMP echo request packet."""
        icmp_type = 8  # Echo request
        icmp_code = 0
        checksum = 0
        identifier = os.getpid() & 0xFFFF
        sequence = 1

        header = struct.pack('!BBHHH', icmp_type, icmp_code, checksum, identifier, sequence)
        data = b'Python Ping'

        checksum = self._calculate_checksum(header + data)
        header = struct.pack('!BBHHH', icmp_type, icmp_code, checksum, identifier, sequence)

        return header + data

    def _calculate_checksum(self, data: bytes) -> int:
        if len(data) % 2:
            data += b'\0'
        words = struct.unpack('!%dH' % (len(data) // 2), data)
        checksum = sum(words)
        high = checksum >> 16
        while high:
            checksum = (checksum & 0xFFFF) + high
            high = checksum >> 16
        return ~checksum & 0xFFFF

    def ping(self, host: str) -> List[PingResult]:
        try:
            if self.ping_type == 'icmp':
                return [self._icmp_ping(host)]
            elif self.ping_type == 'syn':
                return [self._syn_ping(host, port) for port in self.ports]
            else:
                raise ValueError(f"Unsupported ping type: {self.ping_type}")
        except Exception as e:
            if self.debug:
                printrn(f"Error pinging {host}: {e}")
            return [PingResult(host, None, None)]

    def _icmp_ping(self, host: str) -> PingResult:
        try:
            with socket.socket(socket.AF_INET, socket.SOCK_RAW, socket.IPPROTO_ICMP) as sock:
                sock.settimeout(self.timeout)
                ip = socket.gethostbyname(host)

                packet = self.create_icmp_packet()
                start_time = time.time()
                sock.sendto(packet, (ip, 0))

                while True:
                    ready = select.select([sock], [], [], self.timeout)
                    if not ready[0]:
                        return PingResult(host, None, None)

                    receive_time = time.time()
                    recv_packet, addr = sock.recvfrom(1024)

                    icmp_header = recv_packet[20:28]
                    type, code, checksum, p_id, sequence = struct.unpack('!BBHHH', icmp_header)

                    if type == 0:  # Echo Reply
                        rtt = (receive_time - start_time) * 1000
                        return PingResult(host, rtt, ip)

        except socket.error as e:
            if e.errno == 1:
                printrn("Operation not permitted - ICMP messages can only be sent by root user")
            return PingResult(host, None, None)

    def _syn_ping(self, host: str, port: int) -> PingResult:
        try:
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
                sock.settimeout(self.timeout)
                ip = socket.gethostbyname(host)

                start_time = time.time()
                result = sock.connect_ex((ip, port))
                end_time = time.time()

                if result == 0:
                    rtt = (end_time - start_time) * 1000
                    return PingResult(host, rtt, ip, port)

                return PingResult(host, None, None, port)

        except socket.error:
            return PingResult(host, None, None, port)

    def update_stats(self, host: str, result: PingResult) -> None:
        port_key = 'icmp' if self.ping_type == 'icmp' else str(result.port)
        if host not in self.stats:
            self.stats[host] = {}
        if port_key not in self.stats[host]:
            self.stats[host][port_key] = PingStats([], [])

        stats = self.stats[host][port_key]
        if result.success:
            stats.successful.append(result.rtt)
        else:
            stats.unsuccessful.append(len(stats.successful) + len(stats.unsuccessful) + 1)

    def show_stats(self):
        printrn("Ping statistics:")
        printrn("-" * 40)
        for host, ports in self.stats.items():
            for port_key, stats in ports.items():
                successful = len(stats.successful)
                unsuccessful = len(stats.unsuccessful)
                total = successful + unsuccessful
                loss_percent = (unsuccessful / total * 100) if total > 0 else 0
                avg_rtt = sum(stats.successful) / successful if successful > 0 else 0

                port_display = "proto=icmp" if port_key == 'icmp' else f"port={port_key:5}"
                printrn(f"{host:>30}: ",
                      f"{port_display:<10} ",
                      f"{successful:3d} succ ",
                      f"{unsuccessful:3d} unsucc ",
                      f"{loss_percent:5.1f}% loss ",
                      f"{avg_rtt:6.2f}ms/avg")
        printrn("-" * 40)

    def show_help(self):
        hr = "-" * 40
        printrn(f"{hr}")
        printrn("[q]uit, [v]erbose toggle, [p]ause, [s]tats up to now")
        printrn("[l]ost packets only, [1-9] set extra sleep time")
        printrn("[+/-] adjust sleep time, [d]ebug toggle")
        printrn(f"{hr}")

def get_default_gateway_interface():
    #
    # Gets the interface associated with the default gateway on macOS.
    #
    # Returns:
    #     str: The name of the interface, or None if not found.
    #
    try:
        output = subprocess.check_output(["route", "-n", "get", "default"], text=True)
        lines = output.splitlines()
        for line in lines:
            if "interface:" in line:
                interface = line.split()[1]
                return interface
    except subprocess.CalledProcessError:
        pass  # Handle potential errors (e.g., command not found)
    return None

def get_ip_address(interface):
    #
    # Gets the IP address of the specified network interface.
    #
    # Args:
    #     interface (str): The name of the network interface.
    #
    # Returns:
    #     str: The IP address, or None if not found.
    #
    try:
        output = subprocess.check_output(["ipconfig", "getifaddr", interface], text=True)
        return output.strip()
    except subprocess.CalledProcessError:
        pass  # Handle potential errors (e.g., interface not found)
    return None

def handle_keyboard_input(pinger: Pinger):
    with KeyboardReader() as reader:
        while pinger.running:
            time.sleep(0.1)  # Reduced CPU usage while paused
            key = reader.get_key()
            if key:
                if key.lower() == 'q':
                    pinger.running = False
                elif key == 'v':
                    pinger.verbose = not pinger.verbose
                    printrn(f"\nVerbose mode: {'on' if pinger.verbose else 'off'}")
                elif key == 'd':
                    pinger.debug = not pinger.debug
                    printrn(f"\nDebug mode: {'on' if pinger.debug else 'off'}")
                elif key == 's':
                    pinger.show_stats()
                elif key == 'l':
                    pinger.lost_only = not pinger.lost_only
                    printrn(f"\rShowing {'only lost packets' if pinger.lost_only else 'all packets'}")
                elif key == 'p':
                    pinger.paused = True
                    printrn("\nPAUSED - Press Enter to continue: ", end='', flush=True)
                    while pinger.running:
                        if reader.get_key() == '\r':
                            pinger.paused = False
                            printrn("\nResuming...\r")
                            break
                elif key.isdigit():
                    pinger.sleep = int(key)
                    printrn(f"\rSleep time set to: {pinger.sleep} seconds")
                elif key in ['+', '=']:
                    pinger.sleep += 1
                    printrn(f"\rSleep time increased to: {pinger.sleep} seconds")
                elif key == '-':
                    pinger.sleep = max(0, pinger.sleep - 1)
                    printrn(f"\rSleep time decreased to: {pinger.sleep} seconds")
                elif key == 'h':
                    pinger.show_help()

def parse_port(port_str: str) -> int:
    # """Convert a port string to integer, handling service names."""
    try:
        return int(port_str)
    except ValueError:
        try:
            return socket.getservbyname(port_str)
        except OSError:
            printrn(f"Warning: Unknown service '{port_str}', defaulting to 80")
            return 80

def printrn(*string):
    # For some reason, probably the keyboard input handling, the line breaking
    # is hosed unless you do \r\n
    for cur in string:
        print(cur, end='')

    print('', end="\r\n")

def main():
    parser = argparse.ArgumentParser(description='Interactive Python ping utility')
    parser.add_argument('hosts',        nargs='+',                                  help='Hosts to ping')
    parser.add_argument('--count',      type=int,                   default=0,      help='Number of pings to send (0 = infinite)')
    parser.add_argument('--sleep',      type=int,                   default=0,      help='Sleep for specified seconds after each count cycle')
    parser.add_argument('--timeout',    type=int,                   default=1,      help='Timeout in seconds')
    parser.add_argument('--type',       choices=['icmp', 'syn'],    default='icmp', help='Type of ping')
    parser.add_argument('--port',       action='append',                            help='Port(s) to use for TCP SYN ping (repeatable)')

    args = parser.parse_args()

    if args.type == 'icmp' and os.geteuid() != 0:
        printrn("Error: ICMP ping requires root privileges")
        sys.exit(1)

    # Parse ports if specified
    ports = None
    if args.port:
        ports = [parse_port(p) for p in args.port]

    pinger = Pinger(timeout=args.timeout, ping_type=args.type, ports=ports)
    counter = 1

    # Start keyboard input handler in a separate thread
    keyboard_thread = threading.Thread(target=handle_keyboard_input, args=(pinger,))
    keyboard_thread.daemon = True
    keyboard_thread.start()

    try:
        printrn("Press 'h' for help with keyboard commands")
        while pinger.running:

            interface = get_default_gateway_interface()

            if interface:
                ip_address = get_ip_address(interface)
                if ip_address:
                    pinger.interface_ip = f"({interface}) {ip_address}"
                else:
                    printrn(f"Could not get IP address for interface: {interface}")
                    pinger.interface_ip = f"({interface}) NO IP"
            else:
                pinger.interface_ip = '(IFACE UNKNOWN)'

            if not pinger.paused:
                for host in args.hosts:
                    results = pinger.ping(host)
                    for result in results:
                        pinger.update_stats(host, result)

                        if result.success and ( (not pinger.lost_only) or result.rtt > 200):
                            output = f"{pinger.interface_ip:>20} {result.ip:>20}: {result.rtt:6.2f}ms  pass={counter:<3}"
                            if pinger.verbose:
                                port_info = f" port={result.port}" if result.port else ""
                                output += f" timeout={pinger.timeout} proto={pinger.ping_type}{port_info} timestamp={datetime.datetime.now()}"
                            printrn(output)
                        elif not result.success:
                            output = f"{pinger.interface_ip:>20} {host:>30}: LOST     pass={counter:<3}"
                            if pinger.verbose:
                                port_info = f" port={result.port}" if result.port else ""
                                output += f" timeout={pinger.timeout} proto={pinger.ping_type}{port_info} timestamp={datetime.datetime.now()}"
                            printrn(output)

                if args.count > 0:
                    if counter >= args.count:
                        if args.sleep > 0:  # If --sleep is specified
                            printrn(f"Completed {args.count} pings, sleeping for {args.sleep} seconds...")
                            time.sleep(args.sleep)
                            counter = 1  # Reset counter to start next cycle
                            continue
                        else:
                            break  # Exit if no sleep specified

                if pinger.sleep > 0:
                    time.sleep(pinger.sleep)
                time.sleep(1)  # Base delay
                counter += 1
            else:
                time.sleep(0.1)  # Reduced CPU usage while paused

    except KeyboardInterrupt:
        pinger.running = False
        printrn("Stopping ping...")

    # Show final statistics
    pinger.show_stats()

if __name__ == "__main__":
    main()