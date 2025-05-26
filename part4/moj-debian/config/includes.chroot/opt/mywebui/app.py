from flask import Flask, render_template_string, request
from datetime import datetime

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

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)