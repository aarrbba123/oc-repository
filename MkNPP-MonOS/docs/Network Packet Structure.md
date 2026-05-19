# Network Structures

Normally, I would use an existing format. But since either they're unavailable or too '''heavy''' for the current implementation, we'll just have to use our own.

## General sending structure

1. Address
2. Port

... (payload)

(if you're wondering, when called, it will directly `table.unpack` to an invoke. The first two, if not initialized/set properly, will crash the system (REMEMBER: UNSAFE))

## Payloads

### General

1. NetworkID/Magic string (`hrf3-net`)
2. PayloadID string

... (Rest of Payload Data)

### ACK (Acknowledge)

No additional params

### DEC (Decline)

(Used when there are multiple of the same servers)
No additional params

### LOG_DAT (Log data)

1. Log Type
2. Data Type

... (data)

#### Data Type

`LEN`, length_val
`LOG`, first_line, log_string_1, ..., log_string_n

### LOG_REQ (Log Request)

1. Log Type
2. Request Type

... (Additional Params)

#### Request Type

`LEN`
`LOG`, first_line, last_line
