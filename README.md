# mrpenishot

_Wayland screenshot application written in the V programming language_

![mrpenishot](https://avatars.githubusercontent.com/u/165158232)

### Dependencies
- [V compiler](https://vlang.io/)
- [wayland & wayland-scanner](https://gitlab.freedesktop.org/wayland/wayland)
- [wayland-protocols](https://gitlab.freedesktop.org/wayland/wayland-protocols)
- [pixman-1](https://gitlab.freedesktop.org/pixman/pixman)
- pkg-config

### Building
```sh
v run build.vsh  # generate protocols
v .              # build
```

### NOTE

This project is very unfinished, it currently only takes a screenshot of your entire screen and only PPM images are supported.

### References
- [grim](https://gitlab.freedesktop.org/emersion/grim)
