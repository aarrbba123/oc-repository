# Hrf3-Net v2 Packet Structure

This version uses the new "advanced" deserialization system made for MonOS, and provides new features
For compatibilty purposes, ~~~some features of Hrf3-Net from v1 is available~~~ Yea, after commit `3c42978`, `Sender Address` is now required, breaking compatibility with older devices.

## Packet Structure

1. Magic String (`hrf3-net`)
2. Sender address
3. PayloadID String

... [PayloadID-Dependant Data]

## PayloadID String

### PNG (Ping)

Used to know the addresses of valid Hrf3-Net servers
ALL SERVERS that support the protocol MUST `ACK` back.

Optionally, some servers (i.e, ones found in MonOSv1, also beep)

No additional params

### ACK (Acknowledge)

Used as a response for `PNG`.

No additional params

### DEC (Decline)

Used as a way to invalidate a valid, but malformed or unrecognisable `hrf3-net` packet.
Either that or something has gone horribly wrong the server just rejects your command outright.

1. Decline Code
2. Decline String (leave an empty string if there are no valid messages to send)

#### Decline Codes

- `INV_CMD`     = Invalid command
- `INV_SUB_CMD` = Invalid subcommand (code, type, etc.)
- `INV_LEN`     = Invalid packet length
- `INV_PRM`     = Invalid paramater

- `INV_PATH`    = Invalid Path (Used for file-based codes (mostly for `SYS` I/O codes))

- `INV_LOGIN`   = Invalid login (Used to indicate a wrong username/password, or attempting to `LOGOUT` without valid credentials)
- `ACC_DENIED`  = Access denied (Used when attempting to use a `SYS` code without obtaining access)

- `OTHER`       = A 'catch-all' term for malformed packets

### GEN_REQ (General Request)

Used as a way to request things about the server itself
(i.e. What network version, serialization mode, etc.)

1. Request Code

#### Request Codes

- `VER` = Gets server/protocol version (Major, Minor)
- `MOD` = Gets serialization mode
- `CMD` = Gets supported commands

### GEN_DAT (General Data)

Used as a response to a `GEN_REQ`, returning data.

1. Request Code
2 - n. Request Data

#### Request Code + Data Returns

##### `VER`

1. Major Version
2. Minor Version

##### `MOD`

1. Serialization Code
    - `BASIC`    = Basic serialization, character-terminated strings 
    - `ADVANCED` = Advanced serialization, used by MineOS/OpenOS
    - `MONOS`    = MonOS' proprietary serialization, does (almost) the same job as MineOS/OpenOS' `ADVANCED` serialization

2. Serialization Char (`BASIC` serialization only, use string.tochar() to convert back) or Serialization Header (`MONOS` serialization only)

##### `CMD`

1. List of commands, in a table (serialized)

### SYS_REQ (System Request)

A system-specific request, used for system information, log data retreival, data r/w, etc, etc.
Dependant on system. (this is the MonOS variant)

1. Request Code
2 - n. Additional request data/paramaters

#### Request Code + Additional Request Data

##### `CMDS`

Gets a list of supported request codes

##### `INFO`

Gets system information, serialized.

No additional request data.

##### `LOGIN`

Logs the system (sender) in.
Requires a valid password and username.
Used as access control to prevent unauthorized access.
Sends an `ACK` packet, if successful.

!!! NOTE: USING THE SUBCOMMANDS BELOW THIS NEEDS ACCESS

1. username
2. password

##### `LIST`

List a directory.

1. FilePath

##### `READ`

Read a file. 
Server MUST respond with a `TCP_ST` or `DEC`

1. FilePath
2. Mode

##### `WRITE`

Write to file. Initiates `TCP mode`.
Server MUST respond with a `TCP_ST` or `DEC`

1. FilePath
2. Mode

### SYS_DAT (System Data)

A system-specific data, usually used as a response to a `SYS_DAT` packet.
Mostly used for anything related to data (that is small)

1. Request Code
2. Data (Serialized)

#### Request Code + Data info

##### `CMDS`

The data will be a list of commands (`SYS_REQ` codes)

##### `INFO`

The data will be based on an OS basis, but normally:

- `platform` = OS identifier, used to know what OS this is from
- `version` = A table containing the 3 version numbers, which is `major`, `minor` and `patch`. Used to know what version is the OS.

##### `LIST`

A list of files or directories

## PayloadID String (TCP Mode-Specific Commands)

Unlike the above (Which is called 'basic' mode), `TCP mode` is used to transmit extremely large chunks of data.
As such, special packets are sent (context is stored address-wise)
The receiver MUST send an `ACK` or `DEC` within the specified `TIMEOUT`, or `TCP_DSC` will occur.

### TCP_ST (TCP Start)

Initiates `TCP Mode`, contains the data needed to know what to do here

1. Header Data (Serialized)

#### Header Data Breakdown

The header uses string key-pairs

- `TIMEOUT`    = How long until the system re-sends the previous packet, in seconds. (Default: 5)
- `TOLERANCE`  = How many timed out packets will be sent before the system forcefully disconnects and stops `TCP Mode`. (Default: 3)
- `PACKETAMT` = How many packets will be sent to the system. Used for fixed-size data, and is for readability. (Default: nil)

### TCP_DAT (TCP Data)

Used to send data to/from the server.

1. Packet ID
2. Data (serialized)

### TCP_DSC (TCP Disconnect)

Stops `TCP Mode` and any data transmission.

1. Reason Code

#### Reason Code

##### `SUCCESS`

Disconnect due to operation being a success.
Typically indicate the end of a successful data transmission

##### `TIMEOUT`

Disconnect due to timeout.

##### `CANCEL`

Disconnect due to the operation being cancelled
