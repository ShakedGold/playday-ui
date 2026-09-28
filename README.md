# Playday UI
This is the repository for the front end of the playday application, it uses DVUI as the framework for the UI
This is the main entrypoint for the playday application

## Building
just run `zig build` and `zig-out/bin/playday-ui` will be created which is the binary you can run

## Developing on playday-api
When wanting to develop on both playday-api and this repo, you can use:

```bash
zig build -Dlocal-deps=true
```

Which tries to access: `../playday-api`, so you have to clone playday-api in the same root directory.

Then, the zig build system will pick it up from the local directory and you do not need to push you changes everytime
