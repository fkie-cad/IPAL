FROM ubuntu:22.04

RUN apt-get -y update && apt-get install -y \
# offically, python3.9 is not supported
    python3.9 \
    pip \
    git \
    libgsl-dev \
    pkg-config \
    libhdf5-dev \
    pv

RUN echo "wireshark-common wireshark-common/install-setuid boolean true" | debconf-set-selections
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install tshark

RUN useradd -ms /bin/bash ipal
RUN usermod -aG wireshark ipal

# only for convenience
RUN apt-get -y install \
    nano \
    curl \
    vim \
    jq

RUN pip install -U pip

ENV PATH="/home/ipal/.local/bin:$PATH"

USER ipal
WORKDIR /home/ipal

# because pip ignores the install order for git-sourced packages
RUN pip install numpy
# incompatible with version 1.X.X
RUN pip install pomegranate==0.14.9

WORKDIR /home/ipal

# --chmod=777 requires BuildKit
# changing permissions in deploy_ipal.sh
COPY --chown=ipal entry.sh /home/ipal/

ENTRYPOINT ["/bin/bash", "-c", "/home/ipal/entry.sh"]
