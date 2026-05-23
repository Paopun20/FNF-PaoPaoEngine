"""
useless certificate
"""

import subprocess
from pathlib import Path

certs = Path(__file__).parent / "certs"
certs.mkdir(parents=True, exist_ok=True)

def run(cmd):
    subprocess.run(cmd, check=True)

# Root CA
run([
    "openssl", "genrsa",
    "-out", str(certs / "ca.key"),
    "4096"
])

run([
    "openssl", "req",
    "-new", "-x509",
    "-nodes",
    "-days", "3650",
    "-key", str(certs / "ca.key"),
    "-out", str(certs / "ca.crt"),
    "-subj", "/C=TH/ST=Bangkok/L=Bangkok/O=PaoPao/OU=Game/CN=PaoPao GitHub Actions"
])

# Signing cert request
run([
    "openssl", "req",
    "-newkey", "rsa:4096",
    "-nodes",
    "-keyout", str(certs / "sign.key"),
    "-out", str(certs / "sign.req"),
    "-subj", "/C=TH/ST=Bangkok/L=Bangkok/O=PaoPao/OU=Game/CN=PaoPao GitHub Actions"
])

# Extensions
ext_content = """basicConstraints=CA:FALSE
keyUsage=digitalSignature
extendedKeyUsage=codeSigning
"""

with open(certs / "code_sign.ext", "w", encoding="utf-8") as f:
    f.write(ext_content)

# Sign cert
run([
    "openssl", "x509",
    "-req",
    "-in", str(certs / "sign.req"),
    "-days", "825",
    "-CA", str(certs / "ca.crt"),
    "-CAkey", str(certs / "ca.key"),
    "-CAcreateserial",
    "-out", str(certs / "sign.crt"),
    "-extfile", str(certs / "code_sign.ext")
])

# Generate PFX
run([
    "openssl", "pkcs12",
    "-export",
    "-out", str(certs / "sign.pfx"),
    "-inkey", str(certs / "sign.key"),
    "-in", str(certs / "sign.crt"),
    "-certfile", str(certs / "ca.crt"),
    "-passout", "pass:"
])

# Copy trusted CA
with open(certs / "ca.crt", "rb") as src, open("trusted-ca.crt", "wb") as dst:
    dst.write(src.read())

print("Done.")