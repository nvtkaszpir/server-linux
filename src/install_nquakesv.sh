#!/bin/sh
# nQuakesv Installer Script v1.8 (for Linux)
# by Empezar & dimman
nqversion="1.8"

# Usage info
show_help() {
cat << EOF
usage: install_nquakesv.sh [-h|--help] [-n|--non-interactive] [-h|--hostname=<hostname>]
                           [-p|--number-of-ports=<count>] [-t|--qtv] [-f|--qwfwd]
                           [-a|--admin=<name>] [-e|--admin-email=<email>]
                           [-r|--rcon-password=<password>] [-y|--qtv-password=<password>]
                           [-s|--search-pak[=<path>]] [-q|--quiet] [-qq|--extra-quiet] [TARGETDIR]

    -h, --help              display this help and exit.
    -n, --non-interactive   non-interactive mode (use defaults or command line
                            parameters, and do not prompt for anything).
    -q, --quiet             do not output informative messages during setup. this
                            will not silence messages that require interaction.
    -qq, --extra-quiet      do not output errors during setup.
    -d, --docker            use dependencies used by docker image.
    --hostname              hostname of the server.
    --number-of-ports       number of ports to run.
    --qtv                   install qtv.
    --qwfwd                 install qwfwd proxy.
    --admin                 administrator name
    --admin-email           administrator e-mail.
    --rcon-password         rcon password.
    --qtv-password          qtv password.
    --search-pak            search for pak1.pak during setup, specify a directory
                            to start searching there instead of in home folder.
EOF
}

created=0
nondefaultrcon=

# Parse command line parameters
noninteractive=""
quiet=""
extraquiet=""
docker=""
nqinstalldir=""
nqhostname=""
nqnumports=""
nqinstallqtv=""
nqinstallqwfwd=""
nqipaddr=""
nqadmin=""
nqemail=""
nqrcon=""
nqqtvpassword=""
nqsearchpak=""
searchdir=""

for i in "$@"; do
  case ${i} in
    -h|--help)
      show_help
      exit 0
      ;;
    -n|--non-interactive)
      noninteractive=1
      shift
      ;;
    -q|--quiet)
      quiet=1
      shift
      ;;
    -qq|--extra-quiet)
      extraquiet=1
      shift
      ;;
    -d|--docker)
      docker=1
      shift
      ;;
    --hostname=*)
      nqhostname="${i#*=}"
      shift
      ;;
    --number-of-ports=*)
      nqnumports="${i#*=}"
      shift
      ;;
    --qtv)
      nqinstallqtv="y"
      shift
      ;;
    --qwfwd)
      nqinstallqwfwd="y"
      shift
      ;;
    --listen-address=*)
      nqipaddr="${i#*=}"
      shift
      ;;
    --admin=*)
      nqadmin="${i#*=}"
      shift
      ;;
    --admin-email=*)
      nqemail="${i#*=}"
      shift
      ;;
    --rcon-password=*)
      nqrcon="${i#*=}"
      nondefaultrcon=1
      shift
      ;;
    --qtv-password=*)
      nqqtvpassword="${i#*=}"
      shift
      ;;
    --search-pak=*)
      nqsearchpak="y"
      searchdir="${i#*=}"
      shift
      ;;
    --search-pak)
      nqsearchpak="y"
      shift
      ;;
    *)
      nqinstalldir="${i#*=}"
      ;;
  esac
done

# Defaults (use cmdline parameters)
defaultdir=${nqinstalldir:-\~/nquakesv}
defaulthostname=${nqhostname:-"KTX Allround"}
defaultports=${nqnumports:-4}
defaultqtv=${nqinstallqtv:-n}
defaultqwfwd=${nqinstallqwfwd:-n}
defaultadmin=${nqadmin:-${USER}}
defaultemail=${nqemail:-${defaultadmin}@example.com}
defaultrcon=${nqrcon:-$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c12;echo)}
defaultqtvpass=${nqqtvpassword:-$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c12;echo)}
defaultsearchoption=${nqsearchpak:-n}
defaultsearchdir=${searchdir:-\~/}

error() {
  printf "ERROR: %s\n" "$*"
  [ "${created}" -eq 1 ] && {
    cd
    nqeecho "The directory ${directory} is about to be removed, press ENTER to confirm or CTRL+C to exit."
    read
    rm -rf "${directory}"
  }
  exit 1
}

nqecho() {
  nqnecho "$* \n"
}

nqnecho() {
  [ -z "${quiet}" ] && printf "$*"
}

nqeecho() {
  [ -z "${extraquiet}" ] && printf "$*"
}

nqiecho() {
  [ -z "${noninteractive}" ] && nqecho $*
}

nqwget() {
  [ -n "${quiet}" ] && {
    wget -q $* >/dev/null 2>&1
  } || {
    wget $*
  }
}

githubdl() {
  localpath=$1
  remotepath=$2
  nqwget -q -O "${localpath}" "https://raw.githubusercontent.com/nQuake/server-linux/master/${remotepath}"
  chmod +x "${localpath}"
}

# Check if unzip, curl, wget and screen is installed
which unzip >/dev/null || error "The package 'unzip' is not installed. Please install it and run the nQuakesv installation again."
which curl >/dev/null || error "The package 'curl' is not installed. Please install it and run the nQuakesv installation again."
which wget >/dev/null || error "The package 'wget' is not installed. Please install it and run the nQuakesv installation again."
[ -z "${docker}" ] && (which screen >/dev/null || error "The package 'screen' is not installed. Please install it and run the nQuakesv installation again.")

nqecho
nqecho "Welcome to the nQuakesv v${nqversion} installation"
nqecho "========================================="
nqiecho
nqiecho "Press ENTER to use [default] option."
nqiecho

# Interactive stuff
[ -z "${noninteractive}" ] && {
  # Install dir
  printf "Where do you want to install nQuakesv? [%s]: " "${defaultdir}"
  read directory
  eval directory="${directory}"

  # Hostname
  printf "Enter a descriptive hostname [%s]: " "${defaulthostname}"
  read hostname

  # IP/dns
  [ -z "${nqipaddr}" ] && {
          printf "Enter your server's DNS. [use external IP]: "
  } || {
          printf "Enter your server's DNS. [%s]: " "${nqipaddr}"
  }
  read hostdns

  # Ports
  printf "How many ports of KTX do you wish to run (max 10)? [%s]: " "${defaultports}"
  read ports

  # Rcon
  printf "What should the rcon password be? [%s]: " "${defaultrcon}"
  read rcon

  # QTV
  printf "Do you wish to run a qtv proxy? (y/n) [%s]: " "${defaultqtv}"
  read qtv
  [ "${qtv}" = "y" ] && {
    printf "What should the qtv admin password be? [%s]: " "${defaultqtvpass}"
    read qtvpass
  }

  # QWFWD
  printf "Do you wish to run a qwfwd proxy? (y/n) [%s]: " "${defaultqwfwd}"
  read qwfwd

  # Admin name
  printf "Who is the admin of this server? [%s]: " "${defaultadmin}"
  read admin

  # Admin email
  printf "What is the admin's e-mail? [%s]: " "${defaultemail}"
  read email

  # Search for Pak1
  printf "Do you want setup to search for pak1.pak? (y/n) [%s]: " "${defaultsearchoption}"
  read search
  [ "${search}" = "y" ] || ([ "${defaultsearchoption}" = "y" ] && [ -z "${search}" ]) && {
    printf "Enter path to recursively search for pak1.pak [$%s]: " "{defaultsearchdir}"
    read path
  }
}

review=""
nqecho
nqiecho "Please review the following settings:"
nqecho "========================================="
# Set defaults if nothing was entered (non-interactive mode or just use defaults)
[ -z "${directory}" ] && eval directory="${defaultdir}"
[ -z "${hostname}" ] && hostname=${defaulthostname}
[ -z "${hostdns}" ] && hostdns=${nqipaddr}
[ -z "${ports}" ] && ports=${defaultports}
[ -z "${rcon}" ] && rcon=${defaultrcon}
[ -z "${qtv}" ] && qtv=${defaultqtv}
[ -z "${qtvpass}" ] && qtvpass=${defaultqtvpass}
[ -z "${qwfwd}" ] && qwfwd=${defaultqwfwd}
[ -z "${admin}" ] && admin=${defaultadmin}
[ -z "${email}" ] && email=${defaultemail}
[ -z "${search}" ] && search=${defaultsearchoption}
[ -z "${path}" ] && path=${defaultsearchdir}

nqecho "Install directory:   ${directory}"
nqecho "Hostname:            ${hostname}"
nqnecho "Listen address:      "
[ -z "${hostdns}" ] && nqecho "<resolve address>" || nqecho "${hostdns}"
nqecho "Number of ports:     ${ports}"
nqecho "RCON password:       ${rcon}"
nqnecho "Install QTV:         "
[ "${qtv}" = "y" ] && nqecho "yes (password: ${qtvpass})" || nqecho "no"
nqnecho "Install QWFWD:       "
[ "${qwfwd}" = "y" ] && nqecho "yes" || nqecho "no"
nqecho "Admin:               ${admin} <${email}>"
nqnecho "Search for pak1:     "
[ "${search}" = "y" ] && nqecho "${path}" || nqecho "<do not search>"
nqecho "========================================="

[ -z "${noninteractive}" ] && {
  nqecho
  nqecho "Press any key to continue..."
  read
}

# Adjust invalid ports
[ "${ports}" -gt 10 ] && ports=10
[ "${ports}" -lt 1 ] && ports=1

nqecho "Installation proceeding..."

# Create the nQuakesv folder
[ -d "${directory}" ] && {
  [ -w "${directory}" ] && {
    created=0
  } || error "You do not have write access to '${directory}'. Exiting."
} || {
  [ -e "${directory}" ] && {
    error "'${directory}' already exists but is a file, not a directory. Exiting."
  } || {
    mkdir -p "${directory}" 2>/dev/null || error "Failed to create install directory: '${directory}'"
    created=1
  }
}

[ -w "${directory}" ] && {
  cd "${directory}"
  directory=$(pwd)
} || error "You do not have write access to ${directory}. Exiting."

# Search for pak1.pak
pak=""
[ "${search}" = "y" ] && {
  eval path="${path}"
  paks_found=$(find "${path}" -type f -iname "pak1.pak" -size 33M -exec echo "{}" \; 2> /dev/null)
  pak=$(echo "${paks_found}" | head -n1 )
  [ -n "${pak}" ] && {
    nqecho
    nqecho "* Found pak1.pak at location: ${pak}"
  } || {
    nqecho
    nqecho "* Could not find pak1.pak"
  }
}
nqecho

# Download nquake.ini
nqwget -q -O nquake.ini https://raw.githubusercontent.com/nQuake/client-win32/master/etc/nquake.ini || error "Failed to download nquake.ini"
[ ! -s "nquake.ini" ] && error "Downloaded nquake.ini but file is empty?! Exiting."

# List all the available mirrors
[ -z "${noninteractive}" ] && {
  nqecho "From what mirror would you like to download nQuakesv?"
  grep "[0-9]\{1,2\}=\".*" nquake.ini | cut -d "\"" -f2 | sed -r 's/([0-9]{1,2})="(.+?)"/  \1  \2/g'
  nqnecho "Enter mirror number [random]: "
  read mirror
  mirror=$(grep "^${mirror}=[fhtp]\{3,4\}://[^ ]*$" nquake.ini | cut -d "=" -f2)
  nqecho
}
[ -z "${mirror}" ] && {
  nqnecho "Using mirror: "
  range=$(expr $(grep -c "[0-9]\{1,2\}=\".*" nquake.ini) + 1)
  while [ -z "${mirror}" ]; do
    random=$(od -A n -N 2 -t u2 /dev/urandom)
    number=$((((random<<15)|random) % range + 1))
    mirror=$(grep "^${number}=[fhtp]\{3,4\}://[^ ]*$" nquake.ini | cut -d "=" -f2)
    mirrorname=$(grep "^${number}=\".*" nquake.ini | cut -d "\"" -f2)
  done
  nqecho "${mirrorname}"
}
mkdir -p id1
nqecho

# Find out what architecture to use
binary=$(uname -i)

# Download all the packages
nqecho "=== Downloading ==="
nqwget -O qsw106.zip ${mirror}/qsw106.zip || error "Failed to download ${mirror}/qsw106.zip"
nqwget -O sv-gpl.zip ${mirror}/sv-gpl.zip || error "Failed to download ${mirror}/sv-gpl.zip"
nqwget -O sv-non-gpl.zip ${mirror}/sv-non-gpl.zip || error "Failed to download ${mirror}/sv-non-gpl.zip"
nqwget -O sv-configs.zip ${mirror}/sv-configs.zip || error "Failed to download ${mirror}/sv-configs.zip"
[ "$binary" = "x86_64" ] && {
  nqwget -O sv-bin-x64.zip ${mirror}/sv-bin-x64.zip || error "Failed to download ${mirror}/sv-bin-x64.zip"
  [ ! -s "sv-bin-x64.zip" ] && error "Downloaded sv-bin-x64.zip but file is empty?!"
} || {
  nqwget -O sv-bin-x86.zip ${mirror}/sv-bin-x86.zip || error "Failed to download ${mirror}/sv-bin-x86.zip"
  [ ! -s "sv-bin-x86.zip" ] && error "Downloaded sv-bin-x86.zip but file is empty?!"
}

[ ! -s "qsw106.zip" ] && error "Downloaded qwsv106.zip but file is empty?!"
[ ! -s "sv-gpl.zip" ] && error "Downloaded sv-gpl.zip but file is empty?!"
[ ! -s "sv-non-gpl.zip" ] && error "Downloaded sv-non-gpl.zip but file is empty?!"
[ ! -s "sv-configs.zip" ] && error "Downloaded sv-configs.zip but file is empty?!"

# Get remote IP address
nqnecho "Resolving external IP address... "
remote_ip=$(curl -s http://myip.dnsomatic.com)
[ -z "${hostdns}" ] && hostdns=${remote_ip}
nqecho "Resolved: ${remote_ip}"
nqecho

# Extract all the packages
nqecho "=== Installing ==="
nqnecho "* Extracting Quake Shareware..."
(unzip -qqo qsw106.zip ID1/PAK0.PAK 2>/dev/null && nqecho ok) || nqecho fail
nqnecho "* Extracting nQuakesv setup files (1 of 2)..."
(unzip -qqo sv-gpl.zip 2>/dev/null && nqecho ok) || nqecho fail
nqnecho "* Extracting nQuakesv setup files (2 of 2)..."
(unzip -qqo sv-non-gpl.zip 2>/dev/null && nqecho ok) || nqecho fail
nqnecho "* Extracting nQuakesv binaries..."
[ "$binary" = "x86_64" ] && {
  (unzip -qqo sv-bin-x64.zip 2>/dev/null && nqecho ok) || nqecho fail
} || {
  (unzip -qqo sv-bin-x86.zip 2>/dev/null && nqecho ok) || nqecho fail
}
nqnecho "* Extracting nQuakesv configuration files..."
(unzip -qqo sv-configs.zip 2>/dev/null && nqecho ok) || nqecho fail
[ -n "$pak" ] && {
  nqecho "* Copying pak1.pak..."
  (cp "${pak}" "${directory}/id1/pak1.pak" 2>/dev/null && nqecho ok) || nqecho fail
}
nqnecho "* Downloading shell scripts..."
(githubdl "${directory}/start_servers.sh" scripts/start_servers.sh && \
githubdl "${directory}/stop_servers.sh" scripts/stop_servers.sh && \
githubdl "${directory}/update_binaries.sh" scripts/update_binaries.sh && \
githubdl "${directory}/update_configs.s"h scripts/update_configs.sh && \
githubdl "${directory}/update_maps.sh" scripts/update_maps.sh && echo ok) || nqecho fail
nqecho

# Rename files
nqecho "=== Cleaning up ==="
nqnecho "* Renaming files..."
(mv "${directory}/ID1/PAK0.PAK" "${directory}/id1/pak0.pa"k 2>/dev/null && rm -rf "${directory}/ID1" && nqecho ok) || nqecho fail

# Remove distribution files
nqnecho "* Removing distribution files..."
(rm -rf "${directory}/qsw106.zip" "${directory}/sv-gpl.zip" "${directory}/sv-non-gpl.zip" "${directory}/sv-configs.zip" "${directory}/sv-bin-x86.zip" "${directory}/sv-bin-x64.zip" "${directory}/nquake.ini" && nqecho ok) || nqecho fail

# Convert DOS files to UNIX
nqnecho "* Converting DOS files to UNIX..."
for file in $(find "${directory}" -iname "*.cfg" -or -iname "*.txt" -or -iname "*.sh" -or -iname "README"); do
  [ -f "${file}" ] && sed -i 's/^M//g' "${file}"
done
nqecho "done"

# Set the correct permissions
nqnecho "* Setting permissions..."
find "${directory}" -type f -exec chmod -f 644 "{}" \;
find "${directory}" -type d -exec chmod -f 755 "{}" \;
chmod -f +x "${directory}/mvdsv" 2>/dev/null
chmod -f +x "${directory}/ktx/mvdfinish.qws" 2>/dev/null
chmod -f +x "${directory}/qtv/qtv.bin" 2>/dev/null
chmod -f +x "${directory}/qwfwd/qwfwd.bin" 2>/dev/null
chmod -f +x "${directory}/*.sh" 2>/dev/null
chmod -f +x "${directory}/run/*.sh" 2>/dev/null
chmod -f +x "${directory}/addons/*.sh" 2>/dev/null
nqecho "done"

# Update configuration files
nqnecho "* Updating configuration files..."
mkdir -p ~/.nquakesv
echo "${directory}" > ~/.nquakesv/install_dir
echo "${remote_ip}" > ~/.nquakesv/ip
echo "${admin} <${email}>" > ~/.nquakesv/admin
# Generate config file
echo "SV_HOSTNAME=\"${hostname}\"" > ~/.nquakesv/config
# shellcheck disable=SC2129
echo "SV_ADMININFO=\"${admin} <${email}>\"" >> ~/.nquakesv/config
echo "SV_RCON=\"${rcon}\"" >> ~/.nquakesv/config
echo "SV_QTVPASS=\"${qtvpass}\"" >> ~/.nquakesv/config
# qtv
[ "{$qtv}" = "y" ] && {
  echo 28000 > ~/.nquakesv/qtv
  ln -s "${directory}/ktx/demos" "${directory}/qtv/demos"
} || rm -f ~/.nquakesv/qtv
# qwfwd
[ "$qwfwd" = "y" ] && {
  echo 30000 > ~/.nquakesv/qwfwd
} || rm -f ~/.nquakesv/qwfwd
nqecho "done"

# Create port files
nqnecho "* Adjusting amount of ports..."
mkdir -p ~/.nquakesv/ports
i=1
while [ ${i} -le ${ports} ]; do
  [ ${i} -gt 9 ] && port=285${i} || port=2850${i}
  touch ~/.nquakesv/ports/${port}
  i=$((i+1))
done
nqecho "done"

[ -d "/etc/cron.d" ] && {
  nqecho
  nqnecho "Add nQuake server to crontab (ensures servers are always on) [y/N]: "
  read addcron
  [ "${addcron}" = "y" ] && {
    echo "*/10 * * * * \$(cat ~/.nquakesv/install_dir)/start_servers.sh >/dev/null 2>&1" | sudo tee /etc/cron.d/nquakesv >/dev/null
  }
}

nqecho
nqecho "Installation complete. Please read the README in ${directory}."
nqecho

exit 0
