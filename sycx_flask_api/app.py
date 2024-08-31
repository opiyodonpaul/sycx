from flask import Flask, request, jsonify

app = Flask(__name__)

@app.route('/', methods=['GET'])
def greet():
    name = request.args.get('name', 'World')
    greeting = f'Hello, {name}!'
    return jsonify({'message': greeting})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
