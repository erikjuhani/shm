#!/usr/bin/env sh

set -e

readonly SHM_DIR="${HOME}/.shm"

# TODO: Move to shm install script
# Create .shm directory under $HOME if it does not exist
[ ! -d "${SHM_DIR}" ] && {
  mkdir "${SHM_DIR}"
  # TODO: Path setup
}

help() {
  echo "shm"
  echo "A simple package manager for simple shell scripts"
  echo
  echo "USAGE"
  echo "\tshm [<command>] [<args>] [-h | --help]"
  echo
  echo "COMMANDS"
  echo
  echo "\tget\tFetches the script from github repository"
  echo "\tls\tLists all installed scripts in SHM_DIR"
  echo
  echo
  echo "OPTIONS"
  echo "\t-h --help\t\t\tShow help"
  echo
  echo "For additional help use <command> -h"
  exit 2
}

help_get() {
  echo "shm get"
  echo "Fetches the script from github repository when given <owner>/<repository> string as the argument."
  echo
  echo "USAGE"
  echo "\tget <owner/repository>[@version] [-f | --file <filename>]\t"
  echo
  echo "OPTIONS"
  echo "\t-f --file\t\t\tUse arbitrary filename instead of default repository name"
  echo "\t-h --help\t\t\tShow help"
  echo
  exit 2
}

help_ls() {
  echo "shm ls"
  echo "Lists all installed scripts in SHM_DIR"
  echo
  echo "USAGE"
  echo "\tls"
  echo
  echo "OPTIONS"
  echo "\t-h --help\t\t\tShow help"
  echo
  exit 2
}

print() {
  if [ -z "${SILENT_FLAG}" ]; then
    echo "$1"
  fi
}

# Error helper
err() {
  >&2 printf "error: %s\n" "$@"
  exit 1
}

get() {
  args=()
  while [ $# -gt 0 ]; do
    case "$1" in
      -f|--filename)
        FILENAME="$2"
        shift
      ;;
      *)
        args+="$1"
      ;;
    esac
    shift
  done

  readonly REPO_URL="github.com/${args[0]}"
  readonly GH_RAW_URL="https://raw.githubusercontent.com"

  [ -z "${REPO_URL##*@*}" ] && {
    readonly SCRIPT_VERSION="${REPO_URL#*@}"
  }

  print "shm: downloading ${REPO_URL} ${SCRIPT_VERSION:-HEAD}"

  # Strip @... script version out of the url parameter
  readonly SANITIZED_URL="${REPO_URL%@*}"

  readonly OWNER_REPO="${SANITIZED_URL#*/}"
  readonly SCRIPT_NAME="${OWNER_REPO#*/}"
  #readonly SCRIPT_FILE="${SCRIPT_NAME}.sh"
  readonly SCRIPT_FILE="$([ -z "${FILENAME}" ] && echo "${SCRIPT_NAME}.sh" || echo "${FILENAME}")"

  readonly DOWNLOAD_SCRIPT_LOCATION="${GH_RAW_URL}/${OWNER_REPO}/${SCRIPT_VERSION:-HEAD}/${SCRIPT_FILE}"

  download "${SCRIPT_NAME}" "${SCRIPT_VERSION:-HEAD}" "${DOWNLOAD_SCRIPT_LOCATION}"
}

download() {
  local script_name="$1"
  local version="$2"
  local script_url="$3"
  local tmp="/tmp/${script_name}"
  local status_code=$(curl -sSL "${script_url}" -o "${tmp}" -w "%{http_code}")

  if [ "$status_code" -gt 300 ]; then
    print "shm: The requested URL returned error: ${status_code}"
    print "${script_url}"
    exit 1
  fi

  readonly script_dir="${SHM_DIR}/${script_name}.d/${version}"
  mkdir -p "${script_dir}"
  mv -f "${tmp}" "${script_dir}"
  chmod +x "${script_dir}/${script_name}"
  # Create a symlink
  if [ $version != "HEAD" ]; then
    sym_ver="@${version}"
  fi
  ln -sf "${script_dir}/${script_name}" "${SHM_DIR}/${script_name}${sym_ver}"
}

version() {
  echo "$VERSION"
  exit
}

ls() {
  tmp=($(command find "${SHM_DIR}" -type l))

  for script in "${tmp[@]}"
  do
    echo "${script##*/}"
  done
}

shm() {
  # When no arguments given then display help
  if [ $# -eq 0 ]; then
    help
  fi

  local HELP_FLAG=0
  local VERSION_FLAG=0

  local args=()
  while [ $# -gt 0 ]; do
    case "$1" in
      get)
        readonly CMD="get"
      ;;
      ls)
        readonly CMD="ls"
      ;;
      -h|--help)
        case "${CMD}" in
          get)
            help_get
          ;;
          ls)
            help_ls
          ;;
          ?)
            help
          ;;
        esac
      ;;
      -v|--version)
        version
      ;;
      -s|--silent)
        readonly SILENT_FLAG=1
      ;;
      *)
        [ -z "${CMD}" ] && err "unknown option $1" || args+="$1"
      ;;
    esac
    shift
  done

  case "${CMD}" in
    ls)
      ls
    ;;
    get)
      get "$args"
    ;;
  esac
}

[ ! -f "${SHM_DIR}/shm" ] && get erikjuhani/shm || shm $*
