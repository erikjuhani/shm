#!/usr/bin/env sh

set -e

readonly SHM_DIR="${HOME}/.shm"

readonly BOLD_WHITE='\033[1;37m'
readonly COLOR_RESET='\033[0m'

print() {
  [ -z "${SILENT}" ] || [ "${SILENT}" -eq 0 ] && printf "%b\n" "$@"
}

set_shm_to_path() {
  case $(basename "${SHELL}") in
    fish)
      config_path="${HOME}/.config/fish/config.fish"
      set_path="set -x PATH ${SHM_DIR} \$PATH"
      ;;
    zsh)
      config_path="${HOME}/.zshrc"
      set_path="export PATH=\"${SHM_DIR}:\$PATH\""
      ;;
    bash)
      config_path="${HOME}/.bashrc"
      set_path="export PATH=\"${SHM_DIR}:\$PATH\""
      ;;
    *)
      config_path="${HOME}/.profile"
      set_path="export PATH=\"${SHM_DIR}:\$PATH\""
      print "${0} is not directly supported. Should add shm manually to ${0} config"
  esac

  print "=> set ${SHM_DIR} to PATH in ${config_path}"

  if grep -q "${SHM_DIR}" "${config_path}"; then
    print "   + ${SHM_DIR} path configuration already exists in ${config_path}"
    print
  else
    print "${set_path}" >> "${config_path}"
    print "   + set line \"${set_path}\""
    print
  fi

  print "   ${BOLD_WHITE}To get started, run:"
  print "   source ${config_path}${COLOR_RESET}"
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
  cat <<EOF
shm
A simple script manager for shell scripts

USAGE

	shm [<command>] [<args>] [-h | --help]

COMMANDS
	get	Fetches a script from github repository
	ls	Lists all shm installed scripts

OPTIONS
	-h --help	Show help

For additional help use <command> -h
EOF
  exit 2
}

help_get() {
  cat <<EOF
shm get
Fetches a script from github repository when given <owner>/<repository> as an
argument. If commit sha is given using @<commit_sha>, any arbitrary version of
the script can be fetched. Preferably you should use commit sha from a tag. By
default HEAD is used.

When given \`-g | --gist\` flag, get command fetches a <gist> with given
<gist_id> instead of <owner>/<repository>.

USAGE
	get [-f | --file <filename>] <owner/repository>[@commit_sha]
	get [-g | --gist <gist_id>]

OPTIONS
	-f --file	Use arbitrary filename instead of default repository name
	-g --gist	Download a gist shell script with a given gist id
	-h --help	Show help

EOF
  exit 2
}

help_ls() {
  cat <<EOF
shm ls
Lists all shm installed scripts

USAGE
	ls

OPTIONS
	-h --help	Show help

EOF
  exit 2
}

err() {
  printf >&2 "error: %s\n" "$@"
  exit 1
}

readonly GH_RAW_URL="https://raw.githubusercontent.com"
readonly GH_GIST_API_URL="https://api.github.com/gists"

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
    cp "${dir}/${filename}" "${dir}/${name}@${commit_sha}"

    ln -sf "${dir}/${filename}" "${SHM_DIR}/${name}"
    print "   + "${dir}/${filename}" -> ${SHM_DIR}/${name}"
  else
    ln -sf "${dir}/${filename}" "${SHM_DIR}/${filename}"
    print "   + "${dir}/${filename}" -> ${SHM_DIR}/${filename}"
  fi
}

get_gist() {
  [ "$#" -ne 1 ] && err "Expected 1 argument, got $#"

  gist_id="$1"
  gist_url="${GH_GIST_API_URL}/${gist_id}"

  fetch "${gist_url}" "/tmp/gist_${gist_id}" "=> fetching gist info"
  print "   + found gist"

  raw_url="$(cat "/tmp/gist_${gist_id}" | grep raw_url | awk '{ print $2 }' | sed -e 's/,$//' -e 's/^"//' -e 's/"$//')"

  filename="${raw_url##*/}"

  file_suffix="${filename#*.}"

  [ "${file_suffix}" != "sh" ] && err "Expected file suffix .sh, got .${file_suffix}"

  script_name="${filename%*.sh}"

  fetch "${raw_url}" "/tmp/${script_name}@HEAD" "=> downloading ${filename}"
  print "   + ${filename}"

  create_symlinks "${script_name}" "HEAD"
  exit 0
}

get() {
  [ "$#" -eq 0 ] && err "No arguments provided, use \`shm get <owner>/<repo>\`"

  while [ "$#" -gt 0 ]; do
    case "$1" in
    -f | --filename)
      [ -z "$2" ] && err "No value provided for flag, expected $1 <value>, got $1"
      filename="$2"
      shift
      ;;
    -g | --gist) get_gist "$2" ;;
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

  sanitized_repo="${repo%@*}"
  readonly repo_url="github.com/${sanitized_repo}"

  # Strip @... script version out of the url parameter
  sanitized_url="${repo_url%@*}"
  owner_repo="${sanitized_url#*/}"
  script_name="${owner_repo#*/}"

  commit_ref="$(commit_ref "${repo}")"

  fetch_commit_patch "${sanitized_url}" "${commit_ref}"

  check_script_exists "${script_name}@${commit_sha}"

  fetch_script_file "${script_name}" "${commit_ref}" "${sanitized_repo}"

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

check_script_exists() {
  print "=> check $1"
  compare_script_name="$1"
  set -- $(command find "${SHM_DIR}" -type f)

  for arg; do
    _script_name="${arg##*/}"
    [ "${_script_name}" == "${compare_script_name}" ] && {
      print "   + ${compare_script_name} script already exists"
      exit
    }
  done

  print "   + ${compare_script_name} not found"
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
  repo_name="$3"

  # strip out any file suffixes starting with dot like .sh
  readonly file="$([ -z "${filename}" ] && printf "%s" "${script_name%.*}.sh" || printf "%s" "${filename}")"
  readonly file_url="${GH_RAW_URL}/${repo_name}/${commit_ref}/${file}"

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

  exit 0
}

shm() {
  [ "$#" -eq 0 ] && help

  for arg; do
    case "$arg" in
    get) readonly CMD="${arg}" ; shift ;;
    ls) readonly CMD="${arg}" ; shift ;;
    -s | --silent) SILENT=1 ; shift ;;
    -h | --help) [ -z "${CMD}" ] && help ;;
    # Pass arguments to next command
    *) break ;;
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
