# Run test suite

## local

Example:

```sh
./build_test.d --buildType local --dubConfig minimal
./local/test
```

## idf

Example:

```sh
./build_test.d --buildType idf --dubConfig minimal --triple=xtensa-esp32-none-elf --dflags=--mcpu=esp32
(cd idf && idf.py flash -b 460800 && idf.py monitor)
```
