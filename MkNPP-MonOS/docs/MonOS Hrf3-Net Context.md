# Context format for Hrf3-Net on MonOS

In order to function properly, the server/client have to store context data
This is the MonOS' server/client

This is a breakdown for an entry on `addrContext`:

The key is the sender's address

## Root Table

### user
The username that the sender is using. Mostly for logging purposes.
`nil` if not logged in.

### TCP_context
A table containing context data for `TCP Mode`
If this is defined, it means `TCP Mode` is on.

#### code
A list (table) containing context data for the server to know what operations is currently being done

### prev_packet (SERVER-MODE EXCLUSIVE)
A table containing:
- Packet ID
- Previous data

Used for resending packets that are dropped


