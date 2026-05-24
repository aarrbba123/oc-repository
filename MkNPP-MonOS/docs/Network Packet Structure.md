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

### PNG (Ping)

(Used to ping computers to test responsiveness)
(Some systems/OSes optionally beep, but all send ACKs)
No additional params.

### ACK (Acknowledge)

No additional params

### DEC (Decline)

(Used to decline stuff)
(Most likely you sent smth that is a valid `hrf3-net` packet, BUT is an invalid command)

1. Decline Code String
2. Decline Reason (can ignore if you want to use a custom string)

#### Decline Code String

- `INV_CMD`     = Invalid command
- `INV_SUB_CMD` = Invalid subcommand
- `INV_LEN`     = Invalid paramater length
- `INV_BUF`     = Invalid buffer type

### GEN_REQ (General Request)

(Used for general requests i.e. what commands are supported)

1. Request Type

#### Request Type

`CMD` - Gets all available commands supported by a server
`MOD` - Gets serialization mode (Either `BASIC` or `ADVANCED` as a response)

### GEN_DAT (General Data)

(As a response to a general request)

1. Request Type

... (Request Data)

#### Request Type

- `CMD`, net_cmd_list (serialized)
- `MOD`, `BASIC` (null seperated lists) or `ADVANCED` (OpenOS, MineOS, etc.)

### LOG_DAT (Log data)

1. Log Type (`LOG` or `ERR` or pretty much anything)
2. Data Type

... (data)

#### Data Type

`LEN`, length_val
`LOG`, first_line, log_string

### LOG_REQ (Log Request)

1. Log Type
2. Request Type

... (Additional Params)

#### Request Type

`LEN`
`LOG`, first_line, last_line
