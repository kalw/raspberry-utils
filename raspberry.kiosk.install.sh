#!/usr/bin/env bash

set -exo pipefail


GUI_USER="gui.user"
URL_CMD_LIST="echo 'http://google.com' 'http://yahoo.com'"
BROWSER_OPTS="" # "--proxy-server='socks5://1.2.3.4:1080'"
useradd -m -s /bin/bash -G tty ${GUI_USER}
su - ${GUI_USER} sh -c "mkdir ~/bin"
apt-get install -y --force-yes i3-wm synergy xserver-xorg xinit chromium-browser firefox-esr xserver-xorg-legacy omxplayer libttspico-utils xdotool jq

cat>/etc/X11/Xwrapper.config<<EOF
needs_root_rights=yes
allowed_users=anybody
EOF

cat>>/boot/config.txt<<EOF
hdmi_drive=2
EOF

mkdir -p /etc/systemd/system/getty@tty1.service.d/
touch /etc/systemd/system/getty@tty1.service.d/override.conf

cat>/etc/systemd/system/getty@tty1.service.d/override.conf<<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin ${GUI_USER} --noclear %I \$TERM
EOF

echo '[ "$(tty)" = "/dev/tty1" ] && exec startx' | tee -a /home/${GUI_USER}/.profile
systemctl set-default multi-user.target


cat>/home/${GUI_USER}/bin/i3.post.launch.sh<<EOF
URL_CMD_LIST="${URL_CMD_LIST}"
WORKSPACE_ID=1
sleep 10
i3-msg "exec xset dpms 0 0 0; xset s off"
\$((\$WORKSPACE_ID+1))
for url in \$(\${URL_CMD_LIST}) ; do
	sleep 10
	i3-msg "workspace \${WORKSPACE_ID}; exec chromium-browser --kiosk --new-window \${BROWSER_OPTS} \"\$url\""
	WORKSPACE_ID=\$((\$WORKSPACE_ID+1))	
	URL_FILE="\$(echo \$url | sed -e 's#.*://##;s#[:/].*##').sh"
	set +e
	cd /home/${GUI_USER}/bin/
	if [ -f \${URL_FILE}] ; then \$(\${URL_FILE}) ; fi  # if url = http://domain.gtld/toto.html , will execute /home/${GUI_USER}/bin/domain.gtld.sh if present
	set -e
done
sleep 15
while true ; do i3-msg 'workspace next' ; sleep 10  ; done
EOF

chmod +x /home/${GUI_USER}/bin/i3.post.launch.sh

su - ${GUI_USER} sh -c "mkdir /home/${GUI_USER}/.i3"
echo "exec --no-startup-id \"/home/${GUI_USER}/bin/i3.post.launch.sh &\"" | tee -a /home/${GUI_USER}/.i3/config

reboot
