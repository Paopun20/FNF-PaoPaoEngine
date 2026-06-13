"""
Generate a self-signed CA and code-signing certificate chain.

Outputs under ./certs/:
  ca.key / ca.crt      — root certificate authority
  sign.key / sign.crt  — code-signing leaf certificate
  sign.pfx             — PKCS#12 bundle (no passphrase)

Also writes trusted-ca.crt to the project root so callers can
trust the CA without modifying the system certificate store.
"""

import shutil
import subprocess
from RootFile import ROOT_DIR
from pathlib import Path

CERTS_DIR = Path(__file__).parent / "certs"
TRUSTED_CA_PATH = ROOT_DIR / Path("trusted-ca.crt")

RSA_KEY_BITS = "4096"
CA_VALIDITY_DAYS = "3650"  # 10 years — long-lived root CA
LEAF_VALIDITY_DAYS = "825"  # ~2 years — matches Apple/browser maximums
PASSWORD = "v5Sdx4Hop344377216873789813367633800278636022682117385361995579514045560056750895267840"

SUBJECT = "/C=TH/ST=Bangkok/L=Bangkok/O=PaoPao/OU=Game/CN=PaoPao GitHub Actions"

CODE_SIGNING_EXTENSIONS = (
    "basicConstraints=CA:FALSE\n"
    "keyUsage=digitalSignature\n"
    "extendedKeyUsage=codeSigning\n"
)


def run_openssl(*args: str) -> None:
    """Run an openssl sub-command, raising CalledProcessError on failure."""
    subprocess.run(["openssl", *args], check=True)


def create_root_ca() -> None:
    """Generate a self-signed root CA key and certificate."""
    run_openssl("genrsa", "-out", str(CERTS_DIR / "ca.key"), RSA_KEY_BITS)
    run_openssl(
        "req",
        "-new",
        "-x509",
        "-nodes",
        "-days",
        CA_VALIDITY_DAYS,
        "-key",
        str(CERTS_DIR / "ca.key"),
        "-out",
        str(CERTS_DIR / "ca.crt"),
        "-subj",
        SUBJECT,
    )


def create_signing_request() -> None:
    """Generate a code-signing private key and certificate signing request."""
    run_openssl(
        "req",
        "-newkey",
        f"rsa:{RSA_KEY_BITS}",
        "-nodes",
        "-keyout",
        str(CERTS_DIR / "sign.key"),
        "-out",
        str(CERTS_DIR / "sign.req"),
        "-subj",
        SUBJECT,
    )


def write_code_signing_extensions() -> None:
    """Write the X.509 v3 extensions that restrict this cert to code signing."""
    (CERTS_DIR / "code_sign.ext").write_text(CODE_SIGNING_EXTENSIONS, encoding="utf-8")


def sign_leaf_certificate() -> None:
    """Sign the code-signing CSR with the root CA."""
    run_openssl(
        "x509",
        "-req",
        "-in",
        str(CERTS_DIR / "sign.req"),
        "-days",
        LEAF_VALIDITY_DAYS,
        "-CA",
        str(CERTS_DIR / "ca.crt"),
        "-CAkey",
        str(CERTS_DIR / "ca.key"),
        "-CAcreateserial",
        "-out",
        str(CERTS_DIR / "sign.crt"),
        "-extfile",
        str(CERTS_DIR / "code_sign.ext"),
    )


def export_pfx_bundle() -> None:
    """Bundle the signed cert and CA chain into a passphrase-free PFX file."""
    run_openssl(
        "pkcs12",
        "-export",
        "-out",
        str(CERTS_DIR / "sign.pfx"),
        "-inkey",
        str(CERTS_DIR / "sign.key"),
        "-in",
        str(CERTS_DIR / "sign.crt"),
        "-certfile",
        str(CERTS_DIR / "ca.crt"),
        "-passout",
        f"pass:{PASSWORD}",  # empty passphrase
    )


def export_trusted_ca() -> None:
    """Copy the CA certificate to the project root for easy trust installation."""
    shutil.copy(CERTS_DIR / "ca.crt", TRUSTED_CA_PATH)


def generate_certificate_chain() -> None:
    """Run the full CA + code-signing certificate generation pipeline."""
    CERTS_DIR.mkdir(parents=True, exist_ok=True)

    create_root_ca()
    create_signing_request()
    write_code_signing_extensions()
    sign_leaf_certificate()
    export_pfx_bundle()
    export_trusted_ca()


if __name__ == "__main__":
    generate_certificate_chain()
