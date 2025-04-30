from flask import Flask, render_template_string, request
from datetime import datetime
import socket

app = Flask(__name__)
visit_count = 0

TEMPLATE = """
<!DOCTYPE html>
<html>
<head>
    <title>My WebPage</title>
</head>
<body>
    <h1>Hello, World!</h1>
    <p>Aktualna data i godzina: {{ now }}</p>
    <p>Liczba odwiedzin tej strony: {{ count }}</p>
    <form method="get">
        <button type="submit">Odśwież stronę</button>
    </form>
</body>
</html>
"""

@app.route("/", methods=["GET"])
def hello():
    global visit_count
    visit_count += 1
    return render_template_string(
        TEMPLATE,
        now=datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        count=visit_count
    )

def get_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        # nie musi być osiągalny, ważne by uzyskać lokalny IP
        s.connect(('8.8.8.8', 80))
        ip = s.getsockname()[0]
    except Exception:
        ip = '127.0.0.1'
    finally:
        s.close()
    return ip

if __name__ == "__main__":
    ip = get_ip()
    print(f"WebUI dostępne pod adresem: http://{ip}:8080")
    app.run(host="0.0.0.0", port=8080)
