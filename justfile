#!/usr/bin/env -S just --justfile
# ^ A shebang isn't required, but allows a justfile to be executed
#   like a script, with `./justfile lint`, for example.

# NOTE: You can run the following command to install `just`:
#   uv tool install rust-just

default:
    @just _just_fmt
    @just _just_eval
    just --list

# Use powershell for Windows so that 'Git Bash' and 'PyCharm Terminal' get the same result
set windows-powershell

PROJECT_NAME := file_name(justfile_directory())
PY_EXEC := if os_family() == "windows" { ".venv/Scripts/python.exe" } else { ".venv/bin/python" }
SRC := if path_exists("src") == "true" { "src" } else { replace(PROJECT_NAME, "-", "_") }

# ---------- virtualenv ----------
[unix]
_pdm *args:
    @if test -e ~/.local/bin/pdm; then pdm {{ args }}; else uvx pdm {{ args }}; fi

[windows]
_pdm *args:
    @if (Test-Path '~/AppData/Roaming/uv/tools/pdm') { pdm {{ args }} } else { uvx pdm {{ args }} }

_venv_create *args:
    @just _pdm venv create --with-pip {{ args }}

_uv_venv *args:
    @just _venv_create --with uv {{ args }}

# Create virtual environment with uv/pip by pdm if .venv not exists
[unix]
venv *args:
    @if test ! -e .venv; then just _uv_venv {{ args }}; fi

# Create virtual environment with uv/pip by pdm if .venv not exists
[windows]
venv *args:
    @if (-Not (Test-Path '.venv')) { just _uv_venv {{ args }} }

_venv313 *args:
    @just venv 3.13 {{ args }}

[unix]
_fast command *args:
    @if test ! -e ~/.local/bin/fast; then just _uvx_py --from fast-dev-cli fast {{ command }} {{ args }}; else just _uv_run fast {{ command }} {{ args }}; fi

[windows]
_fast command *args:
    if (-Not (Test-Path '~/.local/bin/fast.exe')) { just _uvx_py --from fast-dev-cli fast {{ command }}} {{ args }} } else { just _uv_run fast {{ command }} {{ args }} }

# ---------- pypi mirror helpers ----------
# Update the registry in `uv.lock` to use the mirror set by the config.
_pypi_reverse *args:
    @just pypi --reverse {{ args }}

# Change registry in uv.lock to be pypi.org
pypi *args:
    @just _fast pypi --quiet {{ args }}

_pypi_wrap command *args:
    @just _pypi_reverse
    @just {{ command }} {{ args }}
    @just pypi

_auto_wrap command *args:
    @bash -c 'if grep -q "pypi.org" uv.lock 2> /dev/null; then just _pypi_wrap {{ command }} {{ args }}; else just {{ command }} {{ args }}; fi'

# ---------- dependency installation ----------
_pdm_deps *args:
    just _pdm install --frozen -G :all {{ args }}

_uv_sync *args:
    @just _fast deps --uv {{ args }}

_uv_deps *args:
    @just _auto_wrap _uv_sync {{ args }}

# Use uv to install dependencies
install *args: venv
    @just _uv_deps {{ args }}

alias deps := install

# ---------- lock ----------
_uv_lock *args:
    uv lock {{ args }}
    @just _uv_deps --frozen

_lock *args: venv
    @just _auto_wrap _uv_lock {{ args }}

# Run `uv lock` or `pdm lock` to update lock file
lock *args: venv
    @just _lock {{ args }}

# ---------- add / remove ----------
_pypi_wrap_uv *args:
    @just _auto_wrap uv {{ args }}

# Run `uv add` to update deps and keep register to be pypi.org
add *args: venv
    @just _pypi_wrap_uv add {{ args }}

# Run `uv remove` to update deps and keep register to be pypi.org
remove *args: venv
    @just _pypi_wrap_uv remove {{ args }}

# ---------- upgrade ----------
_up *args:
    @just _uv_lock --upgrade {{ args }}

_prek command *args:
    @just _uvx_or_uv prek {{ command }} {{ args }}

_pre_commit *args:
    @just _prek run --all-files

# Upgrade dependencies/pre-commit-hooks/.common-just
up *args: venv
    git submodule update --init --recursive --merge --remote
    @just _up {{ args }}
    @just _prek autoupdate

# Install project dependencies and remove those that not are not required
clear *args:
    @just _uv_sync {{ args }}

# ---------- code quality ----------
_uvx_py *args:
    uvx --python={{ PY_EXEC }} {{ args }}

_uv_run *args:
    uv run --no-sync {{ args }}

[unix]
_uvx_or_uv command *args:
    @if test ! -e ~/.local/bin/{{ command }}; then just _uvx_py {{ command }} {{ args }}; else just _uv_run {{ command }} {{ args }}; fi

[windows]
_uvx_or_uv command *args:
    if (-Not (Test-Path '~/.local/bin/{{ command }}')) { just _uvx_py {{ command }}} {{ args }} } else { just _uv_run {{ command }} {{ args }} }

_mypy *args:
    @just _uvx_or_uv mypy {{ args }}

_pyright *args:
    @just _uvx_or_uv pyright {{ args }}

mypy path=(SRC) *args:
    @just _mypy --python-executable={{ PY_EXEC }} {{ path }} {{ args }}

_mypy310 path=(SRC) *args:
    uv export --python=3.10 --no-hashes --all-extras --all-groups --frozen -o dev_requirements.txt
    uvx --python=3.10 --with-requirements=dev_requirements.txt mypy --cache-dir=.mypy310_cache {{ path }} {{ args }}

# Run `pyright` to check type hints
right path=(SRC) *args:
    @just _pyright --pythonpath={{ PY_EXEC }} {{ path }} {{ args }}

_just_fmt:
    just --fmt

_just_eval:
    just --evaluate

_format *args:
    @just _just_fmt
    @just _fast lint --ty {{ args }}

_codeqc *args:
    @just _just_eval
    @just mypy {{ args }}
    @just right {{ args }}

_lint *args:
    @just _format --bandit {{ args }}
    @just _codeqc {{ args }}

# Run `fast lint` to auto reformat code and check style
lint *args: install
    @just _lint {{ args }}

# make style without installing deps
fmt *args:
    @just _format --skip-mypy {{ args }}

alias _style := fmt

# install deps and make style
style *args: install
    @just fmt {{ args }}

_check *args:
    @just _fast check --ty {{ args }}
    @just _codeqc {{ args }}

# install deps and check style
check *args: install
    @just _check {{ args }}

# ---------- build / test ----------
_build *args:
    uv build --offline --clear {{ args }}

build *args: install
    just _pdm build {{ args }}

_test *args:
    @just _fast test {{ args }}

# Run `pytest` or `scripts/test.py` for unittest
test *args: install
    @just _test {{ args }}

# Run `fast dev` to start fastapi development mode
dev *args: venv
    @just _fast dev {{ args }}

# Install production dependencies
prod *args: venv
    uv sync --no-dev {{ args }}

# Run `uv pip install` to install package
pipi *args: venv
    uv pip install {{ args }}

# ---------- project setup ----------
# Install pre-commit hooks and project dependencies
prepare:
    @just _uvx_or_uv prek install
    @just install

# ---------- versioning ----------
_version part="patch" *args:
    @just _fast bump {{ part }} {{ args }}

# Bump version with patch part
bump *args:
    @just _version patch --commit {{ args }}

# Make git tag with project version and empty message
tag *args:
    @just _fast tag {{ args }}

_log:
    git --no-pager log -1

_publish *args:
    @just _fast upload {{ args }}

# Bump version with patch part(0.1.1->0.1.2) and auto mark tag
release: venv bump tag _publish _log

# Bump version with minor part(0.1.1->0.2.0) and auto mark tag
minor *args:
    @just _version minor --commit {{ args }}
    @just _publish
    @just _log
