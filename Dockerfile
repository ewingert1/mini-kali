ARG IMAGE_NAME=kali

# FROM kalilinux/kali-rolling:latest
FROM debian:sid

# the base system
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends build-essential file patch bzip2 xz-utils curl wget bash git openssh-client procps netbase dirmngr gnupg libssl-dev && \
    apt-get install -y gdb gdbserver strace vim upx python3-dev poppler-utils ruby netcat bsdmainutils sshpass gawk bash-completion && \
    apt-get install -y ltrace libc6-i386 gcc-multilib g++-multilib && \
    apt-get install -y radare2 && \
    apt-get install -y --no-install-recommends binwalk && \
    apt-get install -y john foremost sqlmap && \
    apt-get clean

# set locales to UTF-8
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y locales && \
    sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen en_US.UTF-8 && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    /usr/sbin/update-locale LANG=en_US.UTF-8 && \
    apt-get clean
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# get last version of pip
RUN curl -sL https://bootstrap.pypa.io/get-pip.py | python3 -

# the tools
RUN set -ex && \
    mkdir -p /opt/tools && \
    \
    # http://docs.pwntools.com/  (+ ROPgadget)
    pip3 --no-cache-dir install --upgrade pwntools && \
    \
    # gdb extensions
    git clone --depth 1 https://github.com/longld/peda.git /opt/tools/peda && \
    git clone --depth 1 https://github.com/hugsy/gef.git /opt/tools/gef && \
    git clone --depth 1 https://github.com/gdbinit/Gdbinit /opt/tools/Gdbinit && \
    git clone --depth 1 https://github.com/pwndbg/pwndbg /opt/tools/pwndbg && \
    \
    # other tools
    git clone --depth 1 https://github.com/slimm609/checksec.sh /opt/tools/checksec.sh && \
    ln -rsf /opt/tools/checksec.sh/checksec /usr/local/bin/checksec && \
    \
    # ropper, pyasn1, PIL, pycrypto
    pip3 install --no-cache-dir ropper pyasn1 Pillow bitarray pycrypto && \
    \
    # villoc: Visualization of heap operations.
    git clone --depth 1 https://github.com/wapiflapi/villoc.git /opt/tools/villoc && \
    ln -rsf /opt/tools/villoc/villoc.py /usr/local/bin/villoc

RUN set -ex ;\
    \
    # zsteg: https://github.com/zed-0xff/zsteg
    gem install zsteg ;\
    \
    # http://angr.io
    pip3 install --no-cache-dir angr ;\
    \
    # https://blog.didierstevens.com/programs/pdf-tools/
    curl -sL http://didierstevens.com/files/software/pdf-parser_V0_7_4.zip | funzip > /usr/local/bin/pdf-parser.py ;\
    chmod a+x /usr/local/bin/pdf-parser.py

# the user profile
RUN ln -f /etc/skel/.bashrc /root/.bashrc
COPY bash_aliases /root/.bash_aliases
COPY vimrc /root/.vimrc
COPY gdbinit /root/.gdbinit
COPY disasm.sh asm.sh rootme_ssh *-wrapper /usr/local/bin/
RUN /usr/local/bin/rootme_ssh --add

ARG IMAGE_NAME

VOLUME /${IMAGE_NAME}
WORKDIR /${IMAGE_NAME}

# too many six.py are present...
RUN rm -f /usr/local/lib/python3.8/dist-packages/six.py
RUN touch ~/.hushlogin

CMD ["bash", "-l"]
