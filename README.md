# shm

A simple script manager for shell scripts

## Installation

Easiest way to install `shm` is with one of the below oneliners. You can also
just download `shm.sh` and place it in `$HOME/.shm` directory.

```sh
curl -sSL https://raw.githubusercontent.com/erikjuhani/shm/main/shm.sh | sh
```

```sh
wget -qO- https://raw.githubusercontent.com/erikjuhani/shm/main/shm.sh | sh
```

`shm` assumes that `SHM_DIR` exists for it to perform any regular actions,
otherwise it `shm` will try to install itself and initialize `SHM_DIR`.

### Path

For now shm needs be added to PATH manually. `SHM_DIR` needs to be found in
PATH, otherwise no `shm` installed scripts can be run directly from terminal.

```fish
# config.fish
set -gx PATH $HOME/.shm $PATH
```

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

### List

Lists all installed symlinked scripts in SHM_DIR.

```sh
shm ls
```
