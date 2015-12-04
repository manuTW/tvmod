#!/bin/bash

DOCKER_OPTS="--storage-opt dm.basesize=50G --insecure-registry 172.17.23.195:5000 --insecure-registry 192.168.81.5:5000"

. /etc/os-release


SUPPORTED_PLATFORM_MSG="Only support on Ubuntu 14/15, Fedora 21/22, Debian 7/8 currently."

# check execution ID
if [ "$EUID" -ne 0 ]; then
    echo
    echo "Please run as root or sudo user."
    echo
    exit
fi

# check docker
hash docker 2>/dev/null || { echo; echo >&2 "Docker is not installed on this system"; echo; exit; }

# should use docker 1.6 or above, otherwise NFS dir in docker host cannot be
# -v mount into container
req_version=(1 6)
for cmd in docker; do
   [[ $("$cmd" --version) =~ ([0-9][.][0-9.]*) ]] && IFS=. read -ra version <<< "${BASH_REMATCH[1]}"
   for (( i=0; i < "${#req_version[@]}"; i++)); do
      if (( "${req_version[i]}" > "${version[i]}" )); then
         printf '%s version 1.6 or higher required\n' "$cmd"
         exit
      fi
   done
done

# check overlay filesystem
OVERLAY_EXIST=$(cat /proc/filesystems | grep overlay | wc -l)
if [ "$OVERLAY_EXIST" == "0" ]; then
    echo
    echo "Please update to Linux kernel 3.19 or aboved & enable overlay filesystem"
    echo
    exit
fi

# check Linux distro
if [ -z "$ID" ] || [ -z "$VERSION_ID" ]; then
    echo
    echo "Platform not recognized."
    echo $SUPPORTED_PLATFORM_MSG
    echo
    exit
fi

echo "Distro = " $ID $VERSION_ID

# config the docker by distro
if  ([ "$ID" = "fedora" ]) ||
    ([ "$ID" = "ubuntu" ] && [ "${VERSION_ID:0:2}" = "15" ]); then
    # ubuntu 15, fedora 21/22
    echo
    echo "Systemd Service Manager!!!"
    DOCKER_SERVICE_FILE=$(systemctl show -p FragmentPath docker | awk -F = '{print $2}')
    sed -i "s/\(ExecStart=\/usr\/bin\/docker\).*/\1 $DOCKER_OPTS -d/" $DOCKER_SERVICE_FILE
    systemctl daemon-reload
    systemctl restart docker
    systemctl enable docker
    echo
elif [ "$ID" = "debian" ] || [ "$ID" = "ubuntu" ]; then
    #ubuntu 14, debian 7/8
    echo
    echo "Upstart Service Manager!!!"
    sed -i "/--dns /a DOCKER_OPTS=\"$DOCKER_OPTS\"" /etc/default/docker
    sed -i "/--dns /d" /etc/default/docker
    service docker stop
    rm -fr /var/lib/docker
    service docker start
    echo
else
    echo
    echo $SUPPORTED_PLATFORM_MSG
    echo
    exit
fi

# deploy success, print the further instruction
echo
echo "----------------------------------------------------------"
echo "Use the following command to add users to the docker group"
echo "sudo gpasswd -M user1,user2,user3 docker"
echo "----------------------------------------------------------"