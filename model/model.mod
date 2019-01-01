# Set of utxo --- Key is the tuple [txid, trans_id, vout]
set UTXO, dimen 3;

# Set of transactions output --- Key is the tuple [trans_id, n]
set TRANS_OUTPUTS, dimen 2;

###### Params and Variables######
# Maximum size of a transaction
param TRANS_MAX_SIZE;
# Fee rate
param FEE_RATE;
# DUST THRESHOLD
param DUST_THRESHOLD;
# minimum of change output that is set to avoid creating a very small output
param EPSILON;
# utxo values
param TRANS_INPUTS_VALUE{UTXO};

param TRANS_INPUTS_ADDR{UTXO}, symbolic;

# transaction inputs size, which inputs choosen from UTXO set
param TRANS_INPUTS_SIZE{(txid, transid, vout) in UTXO}:=148;
# output values
param TRANS_OUTPUTS_VALUE{TRANS_OUTPUTS};
# output size
param TRANS_OUTPUTS_SIZE{(txid, n) in TRANS_OUTPUTS}:=34;
# Beta
param BETA;

# Import utxo
table utxo IN 
    'iODBC' 'DSN=aaa;UID=root;PWD=emerald'
    'SELECT txid, trans_id, vout, value, input_addr'
    ' FROM utxo WHERE trans_id in '
    '("a70d0a93348f79039897bbab6ff415b8cf46e75446b71953a363b3468d5ae03d",'
    '"b7ecb102f8ed4a6789a384f2434cab3a625c6e3e7b917527026306c63eed195f")':
    UTXO <- [txid, trans_id, vout], TRANS_INPUTS_VALUE ~ value, TRANS_INPUTS_ADDR ~ input_addr;

# Import output transaction
table output IN
    'iODBC' 'DSN=aaa;UID=root;PWD=emerald'
    'SELECT trans_id, n, valueSat'
    ' FROM output':
    TRANS_OUTPUTS <- [trans_id, n], TRANS_OUTPUTS_VALUE ~ valueSat;

# Decision variable (binary, indexed by set of utxo)
var x{UTXO}, binary;

# Sum of choosen UTXO value
var sum_inputs_value;
s.t. sum_inputs_value_sj: sum_inputs_value = sum {(txid, transid, vout) in UTXO} TRANS_INPUTS_VALUE[txid, transid, vout] * x[txid, transid, vout];
# Sum of outputs value
var sum_outputs_value;
s.t. sum_outputs_value_sj: sum_outputs_value = sum {(txid, n) in TRANS_OUTPUTS} TRANS_OUTPUTS_VALUE[txid, n];
# Sum of outputs size
var sum_outputs_size;
s.t. sum_outputs_size_sj: sum_outputs_size = sum {(txid, n) in TRANS_OUTPUTS} TRANS_OUTPUTS_SIZE[txid, n];

# Change value
var change_value;
s.t. change_value_sj: change_value = sum_inputs_value - sum_outputs_value;

# Change size
#var change_size;
#s.t. change_size_sj: change_size = (if change_value > EPSILON then BETA else 0);

# Transaction size
var trans_size;
s.t. trans_size_sj: trans_size = sum {(txid, transid, vout) in UTXO} TRANS_INPUTS_SIZE[txid, transid, vout] * x[txid, transid, vout] +
    sum {(txid, n) in TRANS_OUTPUTS} TRANS_OUTPUTS_SIZE[txid, n];
    # + change_size;

# Ojective
minimize y: sum {(txid, transid, vout) in UTXO} TRANS_INPUTS_SIZE[txid, transid, vout] * x[txid, transid, vout] +
    sum {(txid, n) in TRANS_OUTPUTS} TRANS_OUTPUTS_SIZE[txid, n];
    # + change_size;

###### Constraints ######

# A transaction size may not exceed maximum block data size
s.t. max_size: trans_size <= TRANS_MAX_SIZE;

# A transaction must have sufficient value for consuming.
s.t. sufficient_consuming: sum {(txid, transid, vout) in UTXO} TRANS_INPUTS_VALUE[txid, transid, vout] * x[txid, transid, vout] = 
    sum {(txid, n) in TRANS_OUTPUTS} TRANS_OUTPUTS_VALUE[txid, n] + FEE_RATE * trans_size;
    # + change_size;

# All the transaction outputs must be higher than the dust
# threshold to certain that this transaction is relayed to the
# network and confirmed
s.t. dust_threshold_on_output: sum {(txid, n) in TRANS_OUTPUTS} TRANS_OUTPUTS_VALUE[txid, n] >= DUST_THRESHOLD;

# The relation between change output value zv and its size
# zs is defined as follow
# Temporary disabled
#
# s.t. change_value_size_relation: change_size <= floor(change_value/EPSILON) * BETA;
#

display UTXO;

solve;

table res_utxos {(txid, transid, vout) in UTXO: x[txid, transid, vout].val * 2 > 1}  OUT
    'iODBC' 'DSN=aaa;UID=root;PWD=emerald'
    ' INSERT INTO res_utxos '
    ' (txid, value, vout, input_addr, trans_id) '
    ' VALUES (?,?,?,?,?)' :
    txid, TRANS_INPUTS_VALUE[txid, transid, vout], vout, TRANS_INPUTS_ADDR[txid, transid, vout], transid;

table res_trans {(txid, n) in TRANS_OUTPUTS} OUT
    'iODBC' 'DSN=aaa;UID=root;PWD=emerald'
    ' INSERT INTO res_trans '
    ' (trans_id, size) '
    ' VALUES (?,?)' :
    txid, y;

printf '#########################################################################\n';
printf 'All Done!!!\n';
printf '#########################################################################\n';

for {(txid, transid, vout) in UTXO: x[txid, transid, vout].val * 2 > 1}
{
    # curTx = txid
    printf "%s-%s-%d\n", txid, transid, vout;
}

# display x;
printf '#########################################################################\n';
printf 'Total size!!!\n';
printf '#########################################################################\n';
display y;

data;

# param TRANS_INPUTS_SIZE{input in UTXO}:=148;
# TRANS_INPUTS_SIZE[input] := 148;

# Each output size is 34
# param TRANS_OUTPUTS_SIZE{(txid, n) in TRANS_OUTPUTS} TRANS_OUTPUTS_SIZE[txid, n] = 34;
# param: TRANS_OUTPUTS: TRANS_OUTPUTS_SIZE := 34;

# Maximum transaction size is 100KB
param TRANS_MAX_SIZE := 100000;

# Average fee (4 satoshis/byte)
param FEE_RATE := 4;

# DUST THRESHOLD
param DUST_THRESHOLD := 546;

# minimum of change output that is set to avoid creating a very small output (satoshi unit)
param EPSILON := 5460;

# Beta - not use
param BETA := 40;

end;
