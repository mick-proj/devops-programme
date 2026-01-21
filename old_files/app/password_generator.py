from flask import Flask
import random
import string

app = Flask(__name__)

@app.route('/')
def generate_password():
    characters = string.ascii_letters + string.digits + string.punctuation
    password = ''.join(random.choice(characters) for _ in range(10))
    return f'Randomly Generated Password: {password}\n'

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=3000)

