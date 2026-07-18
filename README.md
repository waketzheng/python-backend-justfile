# python-backend-justfile
General just recipes for python backend development

# Quickstart
- In your python backend project, create a justfile with following content:
```
#!/usr/bin/env -S just --justfile
set allow-duplicate-recipes

import? '.common-just/justfile'

system-info:
    @echo "This is an {{ arch() }} machine running on {{ os_family() }}"
    just --list

init:
  git submodule add https://github.com/waketzheng/python-backend-justfile .common-just
```

Run:
```
just init
just
```
