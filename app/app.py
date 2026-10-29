import os
import psycopg2
from flask import Flask, jsonify, request

app = Flask(__name__)

def db():
    return psycopg2.connect(
        host=os.environ["DB_HOST"], dbname=os.environ.get("DB_NAME", "orders"),
        user=os.environ["DB_USER"], password=os.environ["DB_PASSWORD"],
    )

@app.get("/health")
def health():
    return jsonify(status="ok")

@app.get("/orders")
def list_orders():
    with db() as c, c.cursor() as cur:
        cur.execute("SELECT id, item, qty FROM orders ORDER BY id DESC LIMIT 100")
        return jsonify([{"id": r[0], "item": r[1], "qty": r[2]} for r in cur.fetchall()])

@app.post("/orders")
def create_order():
    d = request.get_json()
    with db() as c, c.cursor() as cur:
        cur.execute("INSERT INTO orders(item, qty) VALUES (%s,%s) RETURNING id", (d["item"], d["qty"]))
        return jsonify(id=cur.fetchone()[0]), 201

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
