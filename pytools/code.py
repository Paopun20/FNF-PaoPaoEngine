import string
import secrets

code = secrets.token_hex(32)
reset_token = secrets.token_urlsafe(32)
alphabet = string.ascii_letters + string.digits


def gen():
    while True:
        yield secrets.choice(alphabet)

random_char = []
secure_int = secrets.randbelow(64)
integer_value = int(code, 16)
print(f"{''.join([next(gen()) for _ in range(10)])}{integer_value >> secure_int << secure_int}")
