# === MonOS Serialization V2 ===

Serialization & Deserialization in v1 uses null-terminated characters with data in-between.
v2 improves on it by adding data descriptors (enabling multi-data support) and multi-depth table support

---

Currently, this is the format:
(NOTE: the `\0` is a NULL character)

## Data

### Deserialized:
{"data1", 21, {"kiki"}, "janiel" = "AKeyValue", [6] = 21}

### Semi-serialized:
{'t', 5, ...}

### Serialized:
"t\05\0s\0data1\0n\021\0t\01\0s\0kiki\0k\0s\0janiel\0s\0AKeyValue\0k\0i\06\0i\021"

### Data Descriptors:
| s - string
| n - number (int or float, lua doesn't discriminate)
| b - boolean
| t - table

## Table Entry

| [key], [data type], [data]
| - OR -
| [key], 't', [table length, in elements (starting with the first element in data)], [data]

Why in elements?
- When you skip, instead of having to manually parse and calculate, we just currentPtr = currentPtr + length + 2 (if your currentPtr @ table length) or 1 (if your currentPtr @ data)
