# Building
You're gonna need [opam](http://opam.ocaml.org/) for the following ride.

## Setup
``` shell
cd server
opam switch create . ocaml-base-compiler.4.07.0
opam install containers tls cohttp-lwt-unix sqlite
```

## Build
``` shell
dune build src/main.exe
```

## Run
``` shell
_build/default/src/main.exe
```
This will run an instance at localhost:3222. Make sure to have a `matkonot.db` (read ../scrapers/README.md) file in the same directory!
