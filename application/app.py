import os
import time

from flask import Flask, jsonify, Response, request
from prometheus_client import (
    Counter,
    Histogram,
    generate_latest,
    CONTENT_TYPE_LATEST,
)

app = Flask(__name__)

APP_VERSION = os.getenv("APP_VERSION", "1.1.0")
APP_ENV = os.getenv("APP_ENV", "development")

REQUEST_COUNT = Counter(
    "http_requests_total",
    "Total number of HTTP requests",
    ["method", "endpoint", "status"],
)

REQUEST_LATENCY = Histogram(
    "http_request_duration_seconds",
    "HTTP request latency in seconds",
    ["method", "endpoint"],
)


@app.before_request
def start_timer():
    request.start_time = time.perf_counter()


@app.after_request
def record_metrics(response):
    elapsed = time.perf_counter() - request.start_time

    REQUEST_COUNT.labels(
        method=request.method,
        endpoint=request.path,
        status=response.status_code,
    ).inc()

    REQUEST_LATENCY.labels(
        method=request.method,
        endpoint=request.path,
    ).observe(elapsed)

    return response


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


@app.route("/metrics")
def metrics():
    return Response(
        generate_latest(),
        mimetype=CONTENT_TYPE_LATEST,
    )


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)