#!/usr/bin/env python3
from http.server import BaseHTTPRequestHandler, HTTPServer
import subprocess
import re
import time

class PKIHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        # 1. Check Easy-RSA service status
        try:
            status = subprocess.check_output(
                ["systemctl", "is-active", "easy-rsa"],
                stderr=subprocess.STDOUT,
                text=True,
                timeout=5
            ).strip()
            easy_rsa_status = 1 if status == "active" else 0
        except:
            easy_rsa_status = 0

        # 2. Check CA certificate expiry
        try:
            expiry = subprocess.check_output(
                ["openssl", "x509", "-enddate", "-noout", "-in", "/etc/easy-rsa/pki/ca.crt"],
                stderr=subprocess.STDOUT,
                text=True,
                timeout=5
            ).strip()
            # Extract date like "notAfter=Dec 31 23:59:59 2025 GMT"
            expiry_date = expiry.split('=')[1] if '=' in expiry else "unknown"
        except:
            expiry_date = "error"

        # Generate Prometheus metrics
        metrics = f"""# HELP easy_rsa_status Easy-RSA service status (1=active, 0=inactive)
# TYPE easy_rsa_status gauge
easy_rsa_status {easy_rsa_status}

# HELP ca_expiry_date Root CA certificate expiry date
# TYPE ca_expiry_date gauge
ca_expiry_date{{expiry="{expiry_date}"}} {int(time.time())}
"""
        
        self.send_response(200)
        self.send_header("Content-type", "text/plain")
        self.end_headers()
        self.wfile.write(metrics.encode())

if __name__ == "__main__":
    server = HTTPServer(("0.0.0.0", 8080), PKIHandler)
    print("PKI metrics server running on port 8080")
    server.serve_forever()
