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
            "src": ,
            "dest": ,
            "type": add the message type here,
            "var": [ list variables this rule should affect ],
            "method": call a method which converts the variables,
            "name": provide a new name,
            "remove": True,
        },

        {
            write a remove rule
        },
    ],
}
