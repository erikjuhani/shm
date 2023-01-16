# shm
A simple package manager for simple shell scripts

## Installation

Easiest way to install `shm` is with the below oneliner. You can also just
download `shm.sh` and place it in `$HOME/.shm` directory.

```sh
curl -sSL https://raw.githubusercontent.com/erikjuhani/shm/main/shm.sh | sh
```

By default the shm script assumes that `SHM_DIR` exists for it to perform it's regular actions otherwise it will try to install itself.
For now shm needs be added to PATH manually, it is enough that `SHM_DIR` is added, which is `$HOME/.shm`.

## Usage

```sh
shm [<command>] [<args>] [-h | --help]
```

### Get

To download and install shell scripts use `get` command. Get command fetches
the script from github repository when given `<owner>/<repository>` string as
the argument.

```sh
shm get erikjuhani/datef
```

The script is then dowloaded to appropriate directory under `SHM_DIR`. The file
is saved under following tree: `.shm/<scriptname>.d/<version>/<scriptname>`,
then the script is symlinked to root of `.shm`

### List

Lists all installed symlinked scripts in SHM_DIR.

```sh
shm ls
```
