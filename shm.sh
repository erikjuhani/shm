#!/usr/bin/env sh

set -e

readonly SHM_DIR="${HOME}/.shm"

# TODO: Move to shm install script
# Create .shm directory under $HOME if it does not exist
[ ! -d "${SHM_DIR}" ] && {
  mkdir "${SHM_DIR}"
  # TODO: Path setup
}

println() {
  printf "$1\n"
}

help() {
  println "shm"
  println "A simple package manager for simple shell scripts"
  println
  println "USAGE"
  println "\tshm [<command>] [<args>] [-h | --help]"
  println
  println "COMMANDS"
  println
  println "\tget\tFetches the script from github repository"
  println "\tls\tLists all installed scripts in SHM_DIR"
  println
  println
  println "OPTIONS"
  println "\t-h --help\t\t\tShow help"
  println
  println "For additional help use <command> -h"
  exit 2
}

help_get() {
  println "shm get"
  println "Fetches the script from github repository when given <owner>/<repository> string as the argument."
  println
  println "USAGE"
  println "\tget <owner/repository>[@version] [-f | --file <filename>]\t"
  println
  println "OPTIONS"
  println "\t-f --file\t\t\tUse arbitrary filename instead of default repository name"
  println "\t-h --help\t\t\tShow help"
  println
  exit 2
}

help_ls() {
  println "shm ls"
  println "Lists all installed scripts in SHM_DIR"
  println
  println "USAGE"
  println "\tls"
  println
  println "OPTIONS"
  println "\t-h --help\t\t\tShow help"
  println
  exit 2
}

print() {
  if [ -z "${SILENT_FLAG}" ]; then
    printf "$1\n"
  fi
}

# Error helper
err() {
  >&2 printf "error: %s\n" "$@"
  exit 1
}

get() {
  while [ $# -gt 0 ]; do
    case "$1" in
      -f|--filename)
        readonly FILENAME="$2"
        shift
      ;;
      *)
        # there can only be one
        readonly SCRIPT_REPO_LOCATION="$1"
      ;;
    esac
    shift
  done

  readonly REPO_URL="github.com/${SCRIPT_REPO_LOCATION}"
  readonly GH_RAW_URL="https://raw.githubusercontent.com"

  [ -z "${REPO_URL##*@*}" ] && {
    readonly SCRIPT_VERSION="${REPO_URL#*@}"
  }

  print "shm: downloading ${REPO_URL} ${SCRIPT_VERSION:-HEAD}"

  # Strip @... script version out of the url parameter
  readonly SANITIZED_URL="${REPO_URL%@*}"

  readonly OWNER_REPO="${SANITIZED_URL#*/}"
  readonly SCRIPT_NAME="${OWNER_REPO#*/}"
  readonly SCRIPT_FILE="$([ -z "${FILENAME}" ] && echo "${SCRIPT_NAME}.sh" || echo "${FILENAME}")"

  readonly DOWNLOAD_SCRIPT_LOCATION="${GH_RAW_URL}/${OWNER_REPO}/${SCRIPT_VERSION:-HEAD}/${SCRIPT_FILE}"

  download "${SCRIPT_NAME}" "${SCRIPT_VERSION:-HEAD}" "${DOWNLOAD_SCRIPT_LOCATION}"
}

download() {
  readonly script_name="$1"
  readonly version="$2"
  readonly script_url="$3"
  readonly tmp="/tmp/${script_name}"
  readonly status_code=$(curl -sSL "${script_url}" -o "${tmp}" -w "%{http_code}")

  if [ -z "${status_code}" ] || [ "${status_code}" -gt 300 ]; then
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

ls() {
  set -- $(command find "${SHM_DIR}" -type l)

  for script;
  do
    echo "${script##*/}"
  done
}

shm() {
  # When no arguments given display help
  if [ $# -eq 0 ]; then
    help
  fi

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
          *)
            help
          ;;
        esac
      ;;
      -s|--silent)
        readonly SILENT_FLAG=1
      ;;
      *)
        [ -z "${CMD}" ] && err "unknown option $1" || readonly ARG="$1"
      ;;
    esac
    shift
  done

  case "${CMD}" in
    ls)
      ls
    ;;
    get)
      get "$ARG"
    ;;
  esac
}

[ ! -f "${SHM_DIR}/shm" ] && get erikjuhani/shm || shm $*
