from flask import Flask, request, jsonify
from flask_cors import CORS
import sqlite3
import re
from urllib.parse import urlparse

app = Flask(__name__)
CORS(app)

DATABASE = "cybershield.db"


# =========================
# DATABASE
# =========================

def init_db():
    conn = sqlite3.connect(DATABASE)

    conn.execute("""
        CREATE TABLE IF NOT EXISTS scans (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            scan_type TEXT NOT NULL,
            input_text TEXT NOT NULL,
            risk_level TEXT NOT NULL,
            risk_score INTEGER NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    """)

    conn.commit()
    conn.close()


def save_scan(scan_type, input_text, risk_level, risk_score):
    conn = sqlite3.connect(DATABASE)

    conn.execute("""
        INSERT INTO scans
        (scan_type, input_text, risk_level, risk_score)
        VALUES (?, ?, ?, ?)
    """, (
        scan_type,
        input_text,
        risk_level,
        risk_score
    ))

    conn.commit()
    conn.close()


def get_history():
    conn = sqlite3.connect(DATABASE)
    conn.row_factory = sqlite3.Row

    rows = conn.execute("""
        SELECT
            id,
            scan_type,
            input_text,
            risk_level,
            risk_score,
            created_at
        FROM scans
        ORDER BY id DESC
    """).fetchall()

    conn.close()

    return [dict(row) for row in rows]


# =========================
# MESSAGE ANALYSIS
# =========================

def analyze_message(message):

    text = message.lower()

    score = 0
    warnings = []

    # Urgency
    urgency_words = [
        "urgent",
        "immediately",
        "hurry",
        "act now",
        "within 24 hours",
        "last chance"
    ]

    if any(word in text for word in urgency_words):
        score += 15
        warnings.append(
            "The message creates urgency or pressure to act quickly."
        )

    # Credentials
    credential_words = [
        "otp",
        "password",
        "pin",
        "cvv",
        "verification code",
        "login details"
    ]

    if any(word in text for word in credential_words):
        score += 25
        warnings.append(
            "The message requests sensitive credentials or verification information."
        )

    # Prize / reward
    prize_words = [
        "winner",
        "won",
        "prize",
        "reward",
        "lottery",
        "cash prize",
        "gift card"
    ]

    if any(word in text for word in prize_words):
        score += 20
        warnings.append(
            "The message contains prize, reward, or lottery-related claims."
        )

    # Payment
    payment_words = [
        "send money",
        "transfer money",
        "pay now",
        "payment",
        "bank account",
        "upi",
        "refund"
    ]

    if any(word in text for word in payment_words):
        score += 20
        warnings.append(
            "The message involves payment, money transfer, or financial information."
        )

    # Account verification
    account_words = [
        "verify your account",
        "account suspended",
        "account blocked",
        "confirm your account",
        "kyc"
    ]

    if any(word in text for word in account_words):
        score += 20
        warnings.append(
            "The message uses account verification or suspension language."
        )

    # URL detection
    if re.search(r"https?://|www\.", text):
        score += 15
        warnings.append(
            "The message contains a web link. Verify the destination before opening it."
        )

    # Phone number detection
    if re.search(r"\b\d{10}\b", text):
        score += 10
        warnings.append(
            "The message contains a phone number."
        )

    # Limit score
    score = min(score, 100)

    # Risk level
    if score >= 60:
        risk_level = "HIGH RISK"
        recommendation = (
            "Do not click links, share sensitive information, "
            "or make payments. Verify the message through an official source."
        )

    elif score >= 30:
        risk_level = "MEDIUM RISK"
        recommendation = (
            "Be cautious. Verify the sender and information "
            "before taking any action."
        )

    else:
        risk_level = "LOW RISK"
        recommendation = (
            "No obvious warning signs were detected, "
            "but remain cautious with unexpected messages."
        )

    if not warnings:
        warnings.append(
            "No obvious suspicious patterns were detected."
        )

    return {
        "risk_level": risk_level,
        "risk_score": score,
        "warnings": warnings,
        "recommendation": recommendation
    }


# =========================
# URL ANALYSIS
# =========================

def analyze_url(url):

    score = 0
    warnings = []

    parsed = urlparse(url)

    # HTTPS check
    if parsed.scheme != "https":
        score += 20
        warnings.append(
            "The URL does not use HTTPS."
        )

    # Suspicious keywords
    suspicious_keywords = [
        "login",
        "verify",
        "account",
        "free",
        "winner",
        "prize",
        "urgent",
        "password",
        "confirm"
    ]

    keyword_count = 0

    for keyword in suspicious_keywords:
        if keyword in url.lower():
            keyword_count += 1

    keyword_score = min(keyword_count * 10, 40)

    if keyword_count > 0:
        score += keyword_score
        warnings.append(
            "The URL contains words commonly associated with suspicious links."
        )

    # Long URL
    if len(url) > 100:
        score += 15
        warnings.append(
            "The URL is unusually long."
        )

    # IP address
    hostname = parsed.hostname

    if hostname and re.fullmatch(
        r"\d{1,3}(\.\d{1,3}){3}",
        hostname
    ):
        score += 30
        warnings.append(
            "The URL uses an IP address instead of a normal domain name."
        )

    # @ symbol
    if "@" in url:
        score += 20
        warnings.append(
            "The URL contains an @ symbol, which can be misleading."
        )

    # Too many subdomains
    if hostname and hostname.count(".") > 4:
        score += 15
        warnings.append(
            "The domain contains an unusually large number of subdomains."
        )

    # Invalid URL
    if not parsed.netloc:
        score += 20
        warnings.append(
            "The URL format appears invalid."
        )

    # Limit score
    score = min(score, 100)

    # Risk level
    if score >= 60:
        risk_level = "HIGH RISK"
        recommendation = (
            "Avoid opening this link. Verify the website "
            "through an official source."
        )

    elif score >= 30:
        risk_level = "MEDIUM RISK"
        recommendation = (
            "Be cautious with this link. Check the domain "
            "carefully before continuing."
        )

    else:
        risk_level = "LOW RISK"
        recommendation = (
            "No obvious warning signs were detected, "
            "but always verify unexpected links."
        )

    if not warnings:
        warnings.append(
            "No obvious warning signs were detected."
        )

    return {
        "risk_level": risk_level,
        "risk_score": score,
        "warnings": warnings,
        "recommendation": recommendation
    }


# =========================
# HOME / STATUS
# =========================

@app.route("/")
def home():

    return jsonify({
        "app": "CYBERSHIELD",
        "status": "Backend is running",
        "version": "1.0"
    })


# =========================
# URL API
# =========================

@app.route("/api/analyze-url", methods=["POST"])
def analyze_url_api():

    data = request.get_json()

    if not data or "url" not in data:
        return jsonify({
            "error": "URL is required"
        }), 400

    url = data["url"]

    result = analyze_url(url)

    save_scan(
        "URL",
        url,
        result["risk_level"],
        result["risk_score"]
    )

    return jsonify(result)


# =========================
# MESSAGE API
# =========================

@app.route("/api/analyze-message", methods=["POST"])
def analyze_message_api():

    data = request.get_json()

    if not data or "message" not in data:
        return jsonify({
            "error": "Message is required"
        }), 400

    message = data["message"]

    result = analyze_message(message)

    save_scan(
        "MESSAGE",
        message,
        result["risk_level"],
        result["risk_score"]
    )

    return jsonify(result)


# =========================
# SCREENSHOT API
# =========================

@app.route("/api/analyze-screenshot", methods=["POST"])
def analyze_screenshot_api():

    data = request.get_json()

    if not data or "text" not in data:
        return jsonify({
            "error": "Screenshot text is required"
        }), 400

    text = data["text"]

    result = analyze_message(text)

    save_scan(
        "SCREENSHOT",
        text,
        result["risk_level"],
        result["risk_score"]
    )

    return jsonify(result)


# =========================
# HISTORY API
# =========================

@app.route("/api/history", methods=["GET"])
def history_api():

    history = get_history()

    return jsonify({
        "history": history
    })


# =========================
# START SERVER
# =========================

if __name__ == "__main__":

    init_db()

    app.run(
        host="0.0.0.0",
        port=5000,
        debug=True
    )