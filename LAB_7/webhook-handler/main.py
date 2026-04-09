import subprocess
import json
from flask import Flask, request, jsonify

app = Flask(__name__)

def send_desktop_notification(status, alert_name, summary, description):
    icon = "dialog-error" if status == "firing" else "dialog-information"
    urgency = "critical" if status == "firing" else "normal"
    color = "#ff5555" if status == "firing" else "#55ff55"

    title = "Grafana Alert"
    msg = (
        f"<span size='30000' weight='bold' color='{color}'>{status.upper()}</span>\n"
        f"<b>{summary}</b>\n"
        f"<span size='large'>{description}</span>"
    )

    subprocess.check_call([
        "notify-send",
        "-t",
        "5000",  # timeout 5s
        "-i",
        f"{icon}",
        "-u",
        f"{urgency}",
        f"{title}",
        f"{msg}"
    ])

@app.route('/alerts', methods=['POST'])
def grafana_webhook():
    data = request.json

    print("--- Received Webhook Payload ---")
    # print(json.dumps(data, indent=4, ensure_ascii=False))  # full
    print(json.dumps(data.get('alerts', []), indent=4, ensure_ascii=False))
    print(80*"-")

    for alert in data.get('alerts', []):
        status = alert.get('status', 'unknown')
        alert_name = alert.get('labels', {}).get('alertname', 'Alert')
        description = alert.get('annotations', '').get('description','No details')
        summary = alert.get('annotations', '').get('summary', 'No details')
        print(f"[{status.upper()}] {alert_name}:\n{summary}\n{description}")
        send_desktop_notification(status, alert_name, summary, description)

    return jsonify({"status": "sent"}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)

