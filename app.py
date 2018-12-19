from flask import Flask
from flask import render_template
from flask_sqlalchemy import SQLAlchemy
import os

app = Flask(__name__)
# app.config.from_object(os.environ['APP_SETTINGS'])
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['SQLALCHEMY_DATABASE_URI'] = "postgresql://postgres:postgres@localhost:5432/aaa"
db = SQLAlchemy(app)


@app.route('/', methods=['GET'])
def get_transaction():
    return render_template('transaction.html')


@app.route('/utxo', methods=['GET'])
def get_utxo():
    return render_template('utxo.html')


@app.route('/input', methods=['GET'])
def get_input():
    return render_template('input.html')


if __name__ == '__main__':
    app.run()
