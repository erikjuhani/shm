#!/usr/bin/env sh

set -e

readonly SHM_DIR="${HOME}/.shm"

readonly BOLD_WHITE='\033[1;37m'
readonly COLOR_RESET='\033[0m'

print() {
  [ -z "${SILENT}" ] || [ "${SILENT}" -eq 0 ] && printf "%b\n" "$@"
}

set_shm_to_path() {
  print "=> set ${SHM_DIR} to PATH in ${HOME}/.profile"
  print "export PATH=\"${SHM_DIR}:\$PATH\"" >> "${HOME}/.profile"
  print "   + set line export PATH=\"${SHM_DIR}:\$PATH\""
  print
  print "   ${BOLD_WHITE}To get started, run:"
  print "   source ${HOME}/.profile${COLOR_RESET}"
  print
}

setup() {
  print "=> create ${SHM_DIR} directory"
  mkdir "${SHM_DIR}"
  print "   + shm directory created ${SHM_DIR}"

  set_shm_to_path
}

[ ! -d "${SHM_DIR}" ] && {
  print "=> run shm setup"
  setup
}

help() {
  SILENT=0
  print "shm"
  print "A simple script manager for shell scripts"
  print
  print "USAGE"
  print "\tshm [<command>] [<args>] [-h | --help]"
  print
  print "COMMANDS"
  print
  print "\tget\tFetches a script from github repository"
  print "\tls\tLists all shm installed scripts"
  print
  print "OPTIONS"
  print "\t-h --help\t\t\tShow help"
  print
  print "For additional help use <command> -h"
  exit 2
}

help_get() {
  SILENT=0
  print "shm get"
  print "Fetches a script from github repository when given <owner>/<repository> as an argument."
  print "If commit sha is given using @<commit_sha>, any arbitrary version of the script can be fetched."
  print "Preferably you should use commit sha from a tag. By default HEAD is used."
  print
  print "USAGE"
  print "\tget <owner/repository>[@commit_sha] [-f | --file <filename>]\t"
  print
  print "OPTIONS"
  print "\t-f --file\t\t\tUse arbitrary filename instead of default repository name"
  print "\t-h --help\t\t\tShow help"
  print
  exit 2
}

help_ls() {
  SILENT=0
  print "shm ls"
  print "Lists all shm installed scripts"
  print
  print "USAGE"
  print "\tls"
  print
  print "OPTIONS"
  print "\t-h --help\t\t\tShow help"
  print
  exit 2
}

err() {
  printf >&2 "error: %s\n" "$@"
  exit 1
}

readonly GH_RAW_URL="https://raw.githubusercontent.com"

fetch() {
  [ "$#" -lt 2 ] || [ "$#" -gt 3 ] && err "Expected 2-3 arguments, got $#"

  url="$1"
  output_file="$2"
  info_message="$3"

  [ -n "${info_message}" ] && print "${info_message}"

  # if curl is not found try wget
  if command -v curl >/dev/null; then
    status_code="$(curl -sSL "${url}" -o "${output_file}" -w "%{http_code}")"
  else
    status_code="$(wget -Sq "${url}" -O "${output_file}" 2>&1 | grep 'HTTP/' | awk '{print $2}')"
  fi

  if [ -z "${status_code}" ] || [ "${status_code}" -gt 300 ]; then
    print "shm: The requested URL returned status: ${status_code}"
    print "${url}"
    exit 1
  fi
}

create_symlinks() {
  [ "$#" -ne 2 ] && err "Expected 2 arguments, got $#"

  name="$1"
  version="$2"
  filename="${name}@${version}"
  dir="${SHM_DIR}/${name}.d"

  mkdir -p "${dir}"
  mv -f "/tmp/${filename}" "${dir}"
  chmod +x "${dir}/${filename}"

  # Create a symlink
  print "=> creating symlink"

  if [ "$version" = "HEAD" ]; then
    ln -sf "${dir}/${filename}" "${SHM_DIR}/${name}"
    print "   + "${dir}/${filename}" -> ${SHM_DIR}/${name}"
  else
    ln -sf "${dir}/${filename}" "${SHM_DIR}/${filename}"
    print "   + "${dir}/${filename}" -> ${SHM_DIR}/${filename}"
  fi
}

get() {
  while [ $# -gt 0 ]; do
    case "$1" in
    -f | --filename)
      filename="$2"
      shift
      ;;
    -h | --help) help_get ;;
    -*) err "Unknown option $1" ;;
    *)
      [ -n "$repo" ] && err "Too many arguments, got $(($# + 1)) expected 1"
      repo="$1"
      ;;
    esac
    shift
  done

  [ -z "${repo}" ] && err "No get location provided, use \`shm get <owner>/<repo>\`"

  repo="${repo%@*}"
  readonly repo_url="github.com/${repo}"

  # Strip @... script version out of the url parameter
  sanitized_url="${repo_url%@*}"
  owner_repo="${sanitized_url#*/}"
  script_name="${owner_repo#*/}"

  commit_ref="$(commit_ref "${repo}")"

  fetch_commit_patch "${sanitized_url}" "${commit_ref}"

  fetch_script_file "${script_name}" "${commit_ref}"

  create_symlinks "${script_name}" "${commit_ref}"
}

commit_ref() {
  repo="$1"

  [ -z "${repo##*@*}" ] && commit_ref="${repo#*@}"
  commit_ref="${commit_ref:-HEAD}"

  case "$commit_ref" in
  *[0-9A-Fa-f]*) commit_ref="$(print "$commit_ref" | cut -c -7)" ;;
  esac

  print "${commit_ref}"
}

fetch_commit_patch() {
  sanitized_url="$1"
  commit_ref="$2"

  readonly patch_url="https://${sanitized_url}/commit/${commit_ref}.patch"

  fetch "${patch_url}" "/tmp/${commit_ref}.patch" "=> fetching commit sha"
  readonly commit_sha="$(awk 'NR==1{ print substr($2,0,7); }' "/tmp/${commit_ref}.patch")"
  print "   + ${commit_sha}"
}

fetch_script_file() {
  script_name="$1"
  commit_ref="$2"

  # strip out any file suffixes starting with dot like .sh
  readonly file="$([ -z "${filename}" ] && printf "%s" "${script_name%.*}.sh" || printf "%s" "${filename}")"
  readonly file_url="${GH_RAW_URL}/${repo}/${commit_ref}/${file}"

  filename="${script_name}@${commit_ref}"
  fetch "${file_url}" "/tmp/${filename}" "=> downloading ${filename}"
  print "   + ${file}"
}

ls() {
  for arg; do
    case "$arg" in
    -h | --help) help_ls ;;
    *) break ;;
    esac
  done

  set -- "$(command find "${SHM_DIR}" -type l)"

  sorted_args="$(print "$@" | sort)"

  for script in $sorted_args; do
    print "${script##*/}"
  done
}

shm() {
  [ "$#" -eq 0 ] && help

  for arg; do
    case "$arg" in
    get) readonly CMD="get" ;;
    ls) readonly CMD="ls" ;;
    -s | --silent) SILENT=1 ;;
    -h | --help) help ;;
    # Pass arguments to next command
    *) shift ; break ;;
    esac
  done

  case "${CMD}" in
  ls) ls "$@" ;;
  get) get "$@" ;;
  *) err "Unknown command ${CMD}" ;;
  esac
}

[ -n "${SHM_VERSION}" ] && readonly shm_version="@${SHM_VERSION}"

[ ! -f "${SHM_DIR}/shm" ] && get "erikjuhani/shm${shm_version}" || shm "$@"
