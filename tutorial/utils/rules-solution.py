import struct

def to_float(vars):
    # Ignore if any value is none
    if vars[0] is None or vars[1] is None:
        return None

    # Convert to float
    bytestr = vars[0].to_bytes(2, "big") + vars[1].to_bytes(2, "big")
    return struct.unpack("!f", bytestr)[0]


JS = {
    "protocols": ["modbus"],

    "rename": {
        "192\.168\.1\.2\:.*": "PLC",
        "192\.168\.1\.1\:.*": "HMI",
    },

    "rules": [
        {
            "src": ".*",
            "dest": ".*",
            "type": "3",
            "var": ["holding.register.3006", "holding.register.3007"],
            "method": to_float,
            "name": "pressure",
            "remove": True,
        },

        {
            "src": ".*",
            "dest": ".*",
            "type": "3",
            "var": ["holding.register.2999", "holding.register.3000", "holding.register.3001", "holding.register.3002", "holding.register.3003", "holding.register.3004", "holding.register.3005"],
            "remove": True,
        },
    ],
}
