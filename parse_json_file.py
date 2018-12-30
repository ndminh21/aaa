import json
from pprint import pprint
import mysql.connector

config = {
  'user': 'root',
  'password': 'nhuquynh1207',
  'host': '127.0.0.1',
  'database': '3a',
  'raise_on_warnings': True
}

cnx = mysql.connector.connect(**config)
cursor = cnx.cursor()

add_transaction = ("INSERT INTO transaction" 
                   "(id, raw, size, time, valueout)"
                   "VALUES (%s, %s, %s, %s, %s)")

add_input = ("INSERT INTO input" 
             "(addr, trans_id)"
             "VALUES (%s, %s)")

add_utxo = ("INSERT INTO utxo" 
                   "(choosen, confirmations, scriptpubkey, txid, type, value, vout, input_addr, trans_id)"
                   "VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)")

add_output = ("INSERT INTO output" 
                   "(n, spentHeight, spentIndex, spentTxId, value, valueSat, trans_id)"
                   "VALUES (%s, %s, %s, %s, %s, %s, %s)")

with open('data/22k_instances.json') as f:
    count = 0
    for line in f:
        try:
            raw_data = json.loads(line)

            data_transaction = (raw_data.get('id'),
                                raw_data.get('raw'),
                                raw_data.get('size'),
                                raw_data.get('time'),
                                raw_data.get('valueOut'))

            cursor.execute(add_transaction, data_transaction)
            cnx.commit()

            for vin in raw_data.get('vin'):
                data_input = (vin.get('addr'), raw_data.get('id'))
                cursor.execute(add_input, data_input)
                cnx.commit()
                for utxo in vin.get('utxo'):
                    data_utxo = (utxo.get('choosen'),
                                 utxo.get('confirmations'),
                                 utxo.get('scriptPubkey'),
                                 utxo.get('txid'),
                                 utxo.get('type'),
                                 int(utxo.get('value')),
                                 utxo.get('vout'),
                                 vin.get('addr'),
                                 raw_data.get('id'))
                    cursor.execute(add_utxo, data_utxo)
                    cnx.commit()

            for vout in raw_data.get('vout'):
                data_output = (vout.get('n'),
                               vout.get('spentHeight'),
                               vout.get('spentHeight'),
                               vout.get('spentTxId'),
                               vout.get('value'),
                               vout.get('valueSat'),
                               raw_data.get('id'))
                cursor.execute(add_output, data_output)
                cnx.commit()

        except Exception as e:
            cnx.rollback()
            print(e)

        count += 1
        print("Parse line", count)
    cursor.close()
    cnx.close()
