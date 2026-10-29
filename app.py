import os
from flask import Flask, render_template_string
from supabase import create_client, Client

app = Flask(__name__)

# Kết nối Supabase từ biến môi trường
url = os.environ.get("SUPABASE_URL")
key = os.environ.get("SUPABASE_KEY")
supabase = create_client(url, key)

@app.route("/")
def home():
    return "<h1>🚀 Online Judge chạy trên Koyeb & Supabase thành công!</h1>"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000)
