# shm

A simple script manager for shell scripts

## Installation

Easiest way to install `shm` is with one of the below oneliners. You can also
just download `shm.sh` and place it in `$HOME/.shm` directory.

curl:

```sh
curl -sSL https://raw.githubusercontent.com/erikjuhani/shm/main/shm.sh | sh
```

wget:

```sh
wget -qO- https://raw.githubusercontent.com/erikjuhani/shm/main/shm.sh | sh
```

The initial setup handles setting `SHM_DIR` to `$PATH`. `shm` uses `.profile`
file. The instructions are printed for the user in the installation logs that
are output to stdout.

`shm` assumes that `SHM_DIR` exists for it to perform any regular actions,
otherwise it `shm` will try to install itself and initialize `SHM_DIR`.

## Usage

```sh
shm [<command>] [<args>] [-h | --help]
```

### Get

To download and install shell scripts use `get` command. Get command fetches
the script from github repository, when given `<owner>/<repository>` string as
the argument.

```sh
shm get erikjuhani/datef
```

The script is then dowloaded to appropriate directory under `SHM_DIR`. The file
is saved under following tree: `.shm/<scriptname>.d/<scriptname>[@<commit_sha>]`,
then the script is symlinked to root of `.shm` folder.

#### Gists

When given `-g | --gist` flag, get command fetches a `<gist>` with given
`<gist_id>` instead of `<owner>/<repository>`.

```sh
shm get -g baa58da5c3dd1f69fae9
=> fetching gist info
   + found gist
=> downloading jwtRS256.sh
   + jwtRS256.sh
=> creating symlink
   + /Users/erik/.shm/jwtRS256.d/jwtRS256@HEAD -> /Users/erik/.shm/jwtRS256
```

#### Binaries

When given `-b | --bin` flag, get command fetches a binary file associated with
the given repository. The binary file is fetched from github releases and
matched with the users operating system and architecture.

```sh
shm get --bin cli/cli
=> downloading binary
   + gh_2.39.2_macOS_arm64.zip
=> unpacking archive
   + unpacked gh_2.39.2_macOS_arm64.zip
=> copying binary
   + gh -> /Users/erik/.shm/gh
```

### List

Lists all installed symlinked scripts in SHM_DIR.

```sh
shm ls
```

### Add

Adds a script to shm from local path. All local scripts will be interpreted as
HEAD, which means only one version is ever kept of the local script file.

```sh
shm.sh add local_script.sh
=> copying file /Users/erik/local_script.sh
=> creating symlink
   + /Users/erik/.shm/local_script.d/local_script@HEAD -> /Users/erik/.shm/local_script
```

Any existing script can also be overwritten with the `-f` or `--force` flag.

```sh
shm.sh add -f local_script.sh
=> copying file /Users/erik/local_script.sh
=> creating symlink
   + /Users/erik/.shm/local_script.d/local_script@HEAD -> /Users/erik/.shm/local_script
```
