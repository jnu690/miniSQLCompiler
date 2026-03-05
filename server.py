from flask import Flask, request, jsonify
from flask_cors import CORS
import subprocess
import os

app = Flask(__name__)
CORS(app)  # Allow requests from HTML file

@app.route('/execute', methods=['POST'])
def execute_query():
    try:
        # Get the SQL query from the request
        data = request.json
        query = data.get('query', '')
        
        if not query:
            return jsonify({'error': 'No query provided'}), 400
        
        # Write query to file
        with open('query.sql', 'w') as f:
            f.write(query)
        
        # Run miniSQL.exe
        result = subprocess.run(
            ['miniSQL.exe'],
            stdin=open('query.sql', 'r'),
            capture_output=True,
            text=True,
            timeout=10
        )
        
        output = result.stdout
        if result.stderr:
            output += "\n" + result.stderr
        
        return jsonify({'output': output})
        
    except subprocess.TimeoutExpired:
        return jsonify({'error': 'Query execution timeout'}), 500
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    print("🚀 Mini-SQL Server starting...")
    print("📡 Server running on http://localhost:5000")
    print("💡 Open index.html in your browser")
    app.run(debug=True, port=5000)