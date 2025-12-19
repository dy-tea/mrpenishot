# mrpenishot

_Wayland screenshot application written in the V programming language_

![mrpenishot](https://avatars.githubusercontent.com/u/165158232)

### Dependencies
- [V compiler](https://vlang.io/)
- [wayland & wayland-scanner](https://gitlab.freedesktop.org/wayland/wayland)
- [wayland-protocols](https://gitlab.freedesktop.org/wayland/wayland-protocols)
- [pixman-1](https://gitlab.freedesktop.org/pixman/pixman)
- [libjxl](https://github.com/libjxl/libjxl)
- [libpng16](https://github.com/pnggroup/libpng)
- pkg-config

### Building
```sh
v run build.vsh  # generate protocols
v .              # build
```

### Usage
```sh
mrpenishot                                      # all outputs
mrpenishot -c                                   # including cursor
mrpenishot out.png                              # output to file
mrpenishot -f jxl                               # output to jxl
mrpenishot -g "100,200 300x400"                 # geometry
mrpenishot -g "$(slurp)"                        # geometry from slurp
mrpenishot -t "$(awmsg t f | jq -j '.foreign')" # capture toplevel in awm
mrpenishot - | wl-copy                          # copy image to clipboard
```

### References
- [grim](https://gitlab.freedesktop.org/emersion/grim)
