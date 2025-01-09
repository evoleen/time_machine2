# Culture compiler

The culture files contain locale-specific formatting rules for dates and times. (such as mm/dd/yyyy vs dd.mm.yyyy, day names, etc.) Culture files are contained in `data`, but only `data/culture_source.json` and `data/cultures.bin` are relevant. All other files are archived from the original Time Machine repository.

## Updating culture information

Make changes to culture data in `data/culture_source.json`. Then run

```sh
$ chmod +x tools/culture_compiler/refresh.sh
$ tools/culture_compiler/refresh.sh
```
