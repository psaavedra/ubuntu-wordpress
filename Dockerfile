#
# Ubuntu Dockerfile
#
# https://github.com/dockerfile/ubuntu
#

# Pull base image.
FROM ubuntu:16.04

# Add files.
ADD root/.bashrc /root/.bashrc
ADD root/.gitconfig /root/.gitconfig
ADD root/.scripts /root/.scripts
ADD root/install-wp.sh /root/install-wp.sh

# Set environment variables.
ENV HOME /root

# Define working directory.
WORKDIR /root

# Install.
RUN \
  sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list && \
  apt-get update && \
  apt-get -y upgrade && \
  apt-get install -y software-properties-common && \
  apt-get install -y curl git unzip vim wget && \
  apt-get install -y pwgen && \
  rm -rf /var/lib/apt/lists/* && \
  chmod +x /root/install-wp.sh
  # /root/install-wp.sh

# Define default command.
CMD ["bash"]
