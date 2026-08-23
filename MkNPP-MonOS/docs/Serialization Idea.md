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
<TODO: Use a serialization tool>

### Serialized:
<TODO: Use a serialization tool>

### Data Descriptors:
| s - string  
| n - number (int or float, lua doesn't discriminate)  
| b - boolean  
| t - table  

## Table Entry

| [key], [data type], [data]  
| - OR -  
| [key], 't', [table length, in elements], [data]  

### Why is the table length in elements?
- When you skip, instead of having to manually parse and calculate, we just `currentPtr = currentPtr + length + offset`
  Where `offset` is `2` (if your `currentPtr` @ table length) or `1` (if your `currentPtr` @ data)

## Caveats

1. The serialization format, at this stage, is not capable of resolving recursive tables, leading to bad days (to the sender)
2. The format uses a table as its root, meaning that you need to extract values, even if there's only one value to send.
3. The [key type] will be inferred through the `tonumber()` function. This means that the **key** cannot be using a `string` with **only** a `number` as its value.
