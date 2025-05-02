#!/usr/bin/env python3
import socket
import time

def get_ip():
    for _ in range(10):  # próbuj przez 10 sekund
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        try:
            s.connect(('8.8.8.8', 80))
            ip = s.getsockname()[0]
            if not ip.startswith("127."):
                return ip
        except Exception:
            pass
        finally:
            s.close()
        time.sleep(1)
    return '127.0.0.1'

print("\n" + "#"*60)
print("The WebUI available at:")
print(f"http://{get_ip()}:8080")
print("#"*60 + "\n")
