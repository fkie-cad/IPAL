#!/usr/bin/env python3
from datetime import datetime
import gzip
import json
import matplotlib.pyplot as plt
import sys

def open_file(filename, mode):
    if filename.endswith(".gz"):
        return gzip.open(filename, mode=mode)
    else:
        return open(filename, mode=mode, buffering=1)

def plot(filename):
    x = []
    y = []

    with open_file(filename, "r") as f:

        for line in f.readlines():
            js = json.loads(line)

            x.append(datetime.fromtimestamp(js["timestamp"]))
            y.append(js["state"]["PLC:pressure"])

    plt.plot(x, y)
    plt.show()


def main():
    if len(sys.argv) != 2:
        print("Usage: ./plot.py <path to IPAL state file")
        sys.exit(-1)

    plot(sys.argv[1])

if __name__ == "__main__":
    main()
