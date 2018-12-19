from flask import jsonify
from flask import Blueprint
web = Blueprint('transaction', __name__, url_prefix='/transaction')


@web.route('/get-transaction', methods=['GET'])
def get_transaction():
    print("abcd")
    return jsonify({
        'msg': 'success',
        'data': {
            'id': 'd01c6a003f12448ed4e5db77884c1093db69006bb8bec44bd26171073fb5bbcf',
            'size': 1484,
            'time': 1523861668,
            'valueout': 0.136566
        }
    })
