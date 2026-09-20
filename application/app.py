import os

from flask import Flask, jsonify

app = Flask(__name__)

APP_VERSION = os.getenv("APP_VERSION", "1.1.0")
APP_ENV = os.getenv("APP_ENV", "development")


@app.route("/")
def home():
    return jsonify(
        {
            "application": "Project 4 DevOps Platform",
            "version": APP_VERSION,
            "environment": APP_ENV,
            "message": "Application is running successfully!",
        }
    )


@app.route("/health")
def health():
    return jsonify(
        {
            "status": "healthy"
        }
    )


@app.route("/version")
def version():
    return jsonify(
        {
            "version": APP_VERSION
        }
    )


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)