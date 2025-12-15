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

### NOTE

This project is very unfinished.

### References
- [grim](https://gitlab.freedesktop.org/emersion/grim)
