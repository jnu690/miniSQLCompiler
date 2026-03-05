from flask import Flask, request, jsonify
from flask_cors import CORS
import subprocess
import os
from werkzeug.utils import secure_filename

app = Flask(__name__)
CORS(app)

UPLOAD_FOLDER = 'uploads'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

@app.route('/upload', methods=['POST'])
def upload_and_execute():
    try:
        # Check if file was uploaded
        if 'file' not in request.files:
            return jsonify({'error': 'No file uploaded'}), 400
        
        file = request.files['file']
        query = request.form.get('query', '')
        
        if not query:
            return jsonify({'error': 'No query provided'}), 400
        
        if file.filename == '':
            return jsonify({'error': 'No file selected'}), 400
        
        # Save the uploaded file with sanitized filename
        original_filename = file.filename
        
        # Clean the filename: remove spaces, parentheses, brackets, etc.
        import re
        # Keep only alphanumeric, underscore, hyphen, and dot
        clean_name = re.sub(r'[^\w\-.]', '_', original_filename)
        # Remove multiple consecutive underscores
        clean_name = re.sub(r'_+', '_', clean_name)
        # Remove leading/trailing underscores
        clean_name = clean_name.strip('_')
        
        filename = secure_filename(clean_name)
        filepath = os.path.join(UPLOAD_FOLDER, filename)
        
        print(f"📁 Original filename: {original_filename}")
        print(f"✨ Cleaned filename: {filename}")
        file.save(filepath)
        
        # Update query to use the uploaded file path
        # Replace the filename in the query with the actual path
        updated_query = query.replace(f'"{filename}"', f'"{filepath}"')
        updated_query = updated_query.replace(f"'{filename}'", f"'{filepath}'")
        
        # Write query to file
        with open('query.sql', 'w') as f:
            f.write(updated_query)
        
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
        
        # Clean up uploaded file after execution
        try:
            os.remove(filepath)
        except:
            pass
        
        return jsonify({'output': output})
        
    except subprocess.TimeoutExpired:
        return jsonify({'error': 'Query execution timeout'}), 500
    except Exception as e:
        return jsonify({'error': str(e)}), 500

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
    print("🚀 Mini-SQL Server with File Upload")
    print("📡 Server running on http://localhost:5000")
    print("💡 Open index_with_upload.html in your browser")
    print("📁 Files will be saved to: uploads/")
    app.run(debug=True, port=5000)