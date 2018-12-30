# Assignment Advance Algorithm (AAA)

<img src="https://upload.wikimedia.org/wikipedia/vi/c/cd/Logo-hcmut.svg" width="50">

## Đặc tả project
Nhiệm vụ chính của project là hiện thực một giải pháp để chọn lựa các UTXOs cho các transaction nhằm tối ưu một hoặc nhiều các tiêu chí và giải quyết các vấn đề hiện tại mà các transaction pool và minner đang gặp phải.

Project được sử dụng cho mục đích học tập ở trường Đại học Bách Khoa.

Ngôn ngữ sử dụng: **Python** (3.6)

Framework: **Flask** 

Tác giả: **Nguyễn Duy Minh** (nguyenduyminh2111@gmail.com), **Huỳnh Quang Bảo**, **Nguyễn Thành Công**

## Các công việc cần thực hiện
- [x] Tìm hiểu ảnh hưởng của UTXOs đến các transaction
- [x] Cách tính kích thước của một transaction
- [x] Tìm hiểu transaction pool của BTC và các vấn đề đang gặp phải 
- [x] Chuyển Raw Data thành SQL data
- [ ] Đề xuất giải thuật UTXOs Selection
- [ ] Hiện thực giải thuật đề xuất
- [ ] Hiện thực các giải thuật so sánh. Cụ thể: `HVF`, `LVF`, `Model1` (Paper), `Model2` (Paper)
- [ ] Kiểm thử trên các tập dữ liệu
- [ ] Đánh giá, so sánh kết quả

## Nguồn dữ liệu
### Giai đoạn I
Sử dụng các tập dữ liệu do giảng viên cung cấp

Tập dữ liệu được raw từ `14-05-2018` đến `19-05-2018` của BTC UTXOs.

Sau khi tiền xử lý tập dữ liệu gồm `13055` instances

### Giai đoạn II
Dựng một con Full Node để lấy data

Chi tiết hiện thực sẽ được trình bày trong một project khác

Ngôn ngữ: **NodeJs**

Thư viện: ```bitcore-p2p```

Tác giả: **Nguyễn Duy Minh** (nguyenduyminh2111@gmail.com)

Link: Đang được cập nhật...

## Quá trình thực hiện
### Bước 1: Chuyển dữ liệu thô về dạng dữ liệu có quan hệ
- Các file raw data được cung cấp có dạng `*.json` và `*.txt`
- Chuyển raw data về dạng dữ liệu có quan hệ. DBMS sử dụng là `mysql`
- Phân tích dữ liệu thành các đối tượng như sau: `transaction`, `input`, `output`, `utxo`
### Bước 2: Mô tả quá trình mô hình hoá
- Công cụ hỗ trợ: `glpk` 
- Các thông số:

| Tên                                  | Mô tả                                   | Ghi chú  |
| ------------------------------------ |:---------------------------------------:| -----:|
| `TRANS_MAX_SIZE`                     | Kích thước tối đa của một transaction   |       |
| `FEE_RATE`                           | Hệ số tính phí của một transaction      |       |
| `DUST_THRESHOLD`                     |                                         |       |
| `EPSILON`                            |                                         |       |
| `TRANS_INPUTS_VALUE{UTXO}`           |                                         |       |
| `TRANS_INPUTS_SIZE`                  |                                         |       |
| `TRANS_OUTPUTS_VALUE{TRANS_OUTPUTS}` |                                         |       |
| `TRANS_OUTPUTS_SIZE{TRANS_OUTPUTS}`  |                                         |       |
| `BETA`                               |                                         |       |

- Tính các giá trị liên quan

| Tên                                | Cách tính                                   |
| ---------------------------------- |:-------------------------------------------:|
| Sum of choosen UTXO value          | `var sum_inputs_value sum {input in UTXO} TRANS_INPUTS_VALUE[input] * x[input];`     |
| Sum of outputs value               | `var sum_outputs_value sum {output in TRANS_OUTPUTS} TRANS_OUTPUTS_VALUE[output];`   |
| Sum of outputs size                | `var sum_outputs_size = sum {output in TRANS_OUTPUTS} TRANS_OUTPUTS_SIZE[output];`   |
| Change value                       | `var change_value = sum_inputs_value - sum_outputs_value;`                           |
| Change size                        | `var change_size = if change_value > EPSILON then BETA else 0;`                      |
| Transaction size                   | `var trans_size sum {input in UTXO} TRANS_INPUTS_SIZE[input] * x[input] + sum {output in TRANS_OUTPUTS} TRANS_OUTPUTS_SIZE[output] + change_size;`|

- Các ràng buộc:

| Ràng buộc                          | Mô tả                                   | 
| ---------------------------------- |:---------------------------------------:| 
| `s.t. max_size: trans_size <= TRANS_MAX_SIZE;`| A transaction size may not exceed maximum block data size  |
| `s.t. sufficient_consuming: sum {input in UTXO} TRANS_INPUTS_VALUE[input] * x[input] = sum {output in TRANS_OUTPUTS} TRANS_OUTPUTS_VALUE[output] + FEE_RATE * trans_size + change_size;`| A transaction must have sufficient value for consuming |
| `s.t. dust_threshold_on_output: sum {output in TRANS_OUTPUTS} TRANS_OUTPUTS_VALUE[output] >= DUST_THRESHOLD;`|All the transaction outputs must be higher than the dust threshold to certain that this transaction is relayed to the network and confirmed  |
|`s.t. change_value_size_relation: change_size <= floor(change_value/EPSILON) * BETA;`|The relation between change output value zv and its size zs is defined as follow|

- Hàm mục tiêu:
`minimize y: sum {input in UTXO} TRANS_INPUTS_SIZE[input] * x[input] +
    sum {output in TRANS_OUTPUTS} TRANS_OUTPUTS_SIZE[output] + change_size;`

### Bước 3: Hiện thực mô hình hoá
- Kích thước của một utxo sẽ là `148 bytes`
- Kích thước của một vout sẽ là `34 bytes`
```
# Set of utxo
set UTXO;

# Set of transactions output
set TRANS_OUTPUTS;

###### Params  and Variables######
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
# transaction inputs size, which inputs choosen from UTXO set
param TRANS_INPUTS_SIZE;
# output values
param TRANS_OUTPUTS_VALUE{TRANS_OUTPUTS};
# output size
param TRANS_OUTPUTS_SIZE{TRANS_OUTPUTS};
# Beta
param BETA;

# Decision variable (binary, indexed by set of utxo)
var x{UTXO}, binary;

# Sum of choosen UTXO value
var sum_inputs_value sum {input in UTXO} TRANS_INPUTS_VALUE[input] * x[input];
# Sum of outputs value
var sum_outputs_value sum {output in TRANS_OUTPUTS} TRANS_OUTPUTS_VALUE[output];
# Sum of outputs size
var sum_outputs_size = sum {output in TRANS_OUTPUTS} TRANS_OUTPUTS_SIZE[output];

# Change value
var change_value = sum_inputs_value - sum_outputs_value;
# Change size
var change_size = if change_value > EPSILON then BETA else 0;

# Transaction size
var trans_size sum {input in UTXO} TRANS_INPUTS_SIZE[input] * x[input] +
    sum {output in TRANS_OUTPUTS} TRANS_OUTPUTS_SIZE[output] + change_size;

# Ojective
minimize y: sum {input in UTXO} TRANS_INPUTS_SIZE[input] * x[input] +
    sum {output in TRANS_OUTPUTS} TRANS_OUTPUTS_SIZE[output] + change_size;

###### Constraints ######

# A transaction size may not exceed maximum block data size
s.t. max_size: trans_size <= TRANS_MAX_SIZE;

# A transaction must have sufficient value for consuming.
s.t. sufficient_consuming: sum {input in UTXO} TRANS_INPUTS_VALUE[input] * x[input] = 
    sum {output in TRANS_OUTPUTS} TRANS_OUTPUTS_VALUE[output] + FEE_RATE * trans_size + change_size;

# All the transaction outputs must be higher than the dust
# threshold to certain that this transaction is relayed to the
# network and confirmed
s.t. dust_threshold_on_output: sum {output in TRANS_OUTPUTS} TRANS_OUTPUTS_VALUE[output] >= DUST_THRESHOLD;

# The relation between change output value zv and its size
# zs is defined as follow
s.t. change_value_size_relation: change_size <= floor(change_value/EPSILON) * BETA;

solve;

```

### Bước 4: Đề xuất giải thuật và cải tiến
- Đang được cập nhật....

## Kết qủa thực nghiệm
- Đang được cập nhật...

## License
Code released under [The HCMUT license] 

Copyright 2018-2019

