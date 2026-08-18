# === MonOS Serialization V2 ===

Serialization & Deserialization in v1 uses null-terminated characters with data in-between.
v2 improves on it by adding data descriptors and multi-depth table support

---

Currently, this is the format:
(NOTE: the `\0` is a NULL character)

## Header 
### Deserialized:
{"MONOS-SER", 2, 0}

### Serialized:
"MONOS-SER\02\00"

| "MONOS-SER" - The 'magic' character to indentify MonOS serialization
| 2 - Version number
| 0 - Feature flags (Not implemented)

## Data

### Deserialized:
{'t', 3, "data1", 21, {"kiki"}}

### Semi-serialized:
{'t', 3, 's', "data1", 'n', 21, 't', 1, 's', "kiki"}

### Serialized:
"t\03\0s\0data1\0n\021\0t\01\0s\0kiki"

### Data Descriptors:
| s - string
| n - number (int or float, lua doesn't discriminate)
| b - boolean
| t - table

# === MonOS Data Server / Hrf3-Net Server v2 ===





