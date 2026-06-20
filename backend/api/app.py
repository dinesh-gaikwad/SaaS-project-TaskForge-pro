from flask import Flask, jsonify, request
from flask_sqlalchemy import SQLAlchemy
from auth.middleware import require_auth
from config.settings import Config

app = Flask(__name__)
app.config.from_object(Config)
db = SQLAlchemy(app)

@app.route('/api/health')
def health():
    return jsonify({'status': 'healthy', 'service': 'TaskForge Pro'})

@app.route('/api/tasks', methods=['GET'])
def get_tasks():
    return jsonify({'tasks': [], 'count': 0})

@app.route('/api/tasks', methods=['POST'])
@require_auth
def create_task():
    data = request.get_json()
    return jsonify({'task': data, 'id': 1}), 201

@app.route('/api/users', methods=['GET'])
@require_auth
def get_users():
    return jsonify({'users': [], 'count': 0})

if __name__ == '__main__':
    app.run(debug=True, port=5000)
