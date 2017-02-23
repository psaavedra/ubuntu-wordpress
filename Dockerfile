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
ADD root/setup-wp.sh /root/setup-wp.sh
ADD root/header.jpg /root/header.jpg

# Set environment variables.
ENV HOME /root

# Define working directory.
WORKDIR /root

# Install.
RUN \
  sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list && \
  apt-get update && \
  apt-get -y upgrade
RUN \
  apt-get install -y software-properties-common && \
  apt-get install -y curl git unzip pwgen wget apache2-utils
# RUN apt-get install -y net-tools inetutils-ping vim 
RUN chmod +x /root/install-wp.sh 
RUN chmod +x /root/setup-wp.sh
RUN /root/install-wp.sh
RUN apt-get clean

# Define default command.
CMD ["/etc/rc.local"]
