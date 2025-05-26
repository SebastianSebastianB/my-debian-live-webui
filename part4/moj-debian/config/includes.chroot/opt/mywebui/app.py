from flask import Flask, render_template_string, request
from datetime import datetime

app = Flask(__name__)
visit_count = 0

TEMPLATE = """
<!DOCTYPE html>
<html>
<head>
    <title>MojDebian WebUI</title>
    <style>
        body { 
            font-family: Arial, sans-serif; 
            margin: 40px; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        .container { 
            max-width: 800px; 
            margin: 0 auto; 
            background: rgba(255,255,255,0.1); 
            padding: 30px; 
            border-radius: 15px;
            backdrop-filter: blur(10px);
        }
        h1 { 
            text-align: center; 
            color: #fff; 
            text-shadow: 2px 2px 4px rgba(0,0,0,0.5);
        }
        .info { 
            background: rgba(255,255,255,0.2); 
            padding: 15px; 
            margin: 10px 0; 
            border-radius: 8px;
        }
        button { 
            background: #4CAF50; 
            color: white; 
            padding: 10px 20px; 
            border: none; 
            border-radius: 5px; 
            cursor: pointer;
            margin: 5px;
        }
        button:hover { background: #45a049; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🐧 MojDebian WebUI</h1>
        <div class="info">
            <strong>📅 Aktualna data i godzina:</strong> {{ now }}
        </div>
        <div class="info">
            <strong>👥 Liczba odwiedzin tej strony:</strong> {{ count }}
        </div>
        <div class="info">
            <strong>🖥️ Status systemu:</strong> Działa poprawnie
        </div>
        <form method="get" style="text-align: center;">
            <button type="submit">🔄 Odśwież stronę</button>
        </form>
        <div style="text-align: center; margin-top: 30px; font-size: 12px; opacity: 0.8;">
            MojDebian v1.0 - Custom Debian Live System
        </div>
    </div>
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
