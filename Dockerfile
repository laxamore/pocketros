FROM golang:1.14-buster AS easy-novnc-build
WORKDIR /src
RUN go mod init build && \
    go get github.com/geek1011/easy-novnc@v1.1.0 && \
    go build -o /bin/easy-novnc github.com/geek1011/easy-novnc

FROM ros:noetic-ros-core-focal

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends openbox tigervnc-standalone-server supervisor gosu && \
    rm -rf /var/lib/apt/lists && \
    mkdir -p /usr/share/desktop-directories

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends lxterminal nano wget openssh-client rsync ca-certificates xdg-utils htop tar xzip gzip bzip2 zip unzip && \
    rm -rf /var/lib/apt/lists

COPY --from=easy-novnc-build /bin/easy-novnc /usr/local/bin/
COPY menu.xml /etc/xdg/openbox/
COPY supervisord.conf /etc/
EXPOSE 8080

RUN echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.lists
RUN apt update
RUN apt -y install rviz

RUN apt -y install python3-rosdep
RUN sudo rosdep init
RUN rosdep update

RUN apt -y install python3-rosdep python3-rosinstall python3-rosinstall-generator python3-wstool build-essential python3-catkin-tools
RUN apt -y install ros-noetic-gazebo-ros-pkgs ros-noetic-gazebo-ros-control
RUN apt -y install iproute2 ssh curl git vim

RUN groupadd --gid 1000 pocketros && \
    useradd --home-dir /home/pocketros --shell /bin/bash --uid 1000 --gid 1000 -p "$(openssl passwd -1 pocketros)" pocketros && \
    mkdir -p /home/pocketros
VOLUME /home/pocketros

RUN echo "pocketros ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/pocketros
RUN echo "source /opt/ros/noetic/setup.bash" >> ~/.bashrc

USER pocketros
CMD ["sh", "-c", "sudo service ssh start && sudo chown -R pocketros:pocketros /home/pocketros /dev/stdout && sudo gosu pocketros supervisord"]
