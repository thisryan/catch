> [!Note]
> All functionality of this program can be achieved using `git` this is purely for educational purposes. Or in cases you really dont want to use a git repo for some reason.

# Catch

A simple program so save the state of a directory to later return it to this state.

To save the current state you simply call the program:

```bash
./catch
```

To return the directory to its saved state:

```bash
./catch release
or
./catch r
```


After doing `catch release` you can also return to the point before releasing with:

```bash
./catch reset
```

## General notes:

- `catch` will ignore any directories or files which start with `.`
- If you want to save guard against accidentaly overwriting data you can create a file `.relasestop`, this will stop catch from releasing in this directory.
