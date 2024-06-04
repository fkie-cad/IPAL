#!/bin/bash

cd /home/ipal

if ! test -f ".installed"
then
    echo "Did not find installed flag. Proceeding with installation."
    pip install -e ids/ && \
    pip install -e transcriber/ && \
    pip install -e evaluate/ && \
    touch .installed && \
    echo "Successfully installed. You can now use IPAL. Have fun!" || \
    echo "Installation failed. Good luck fixing the issue!"
else
    echo "Assuming IPAL is already installed."
fi

exec /bin/bash
