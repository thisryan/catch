# Catch

A simple program so save the state of a directory to later return it to this state.

To save the current state you simply call the program:

```bash
./catch
```

To return the directory to its saved state:

```bash
./catch release
```

## General notes:

- `catch` will ignore any directories or files which start with `.`
- If you want to save guard against accidentaly overwriting data you can create a file `.relasestop`, this will stop catch from releasing in this directory.
