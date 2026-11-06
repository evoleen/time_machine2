# CLDR Windows time zone mappings

`windowsZones-<version>.xml` files are copies of CLDR's
[`common/supplemental/windowsZones.xml`](https://github.com/unicode-org/cldr/blob/main/common/supplemental/windowsZones.xml),
taken from the [unicode-org/cldr](https://github.com/unicode-org/cldr) repository at the tag
`release-<version>` (for example `windowsZones-48-2.xml` from `release-48-2`). Version 30 is
from `release-30-0-3`, whose data matches Noda Time's copy of 30.

The set of versions matches [Noda Time's `data/cldr`](https://github.com/nodatime/nodatime/tree/main/data/cldr).
As in Noda Time, files are added by hand when CLDR publishes a release, and the TZDB compiler
picks the most recent file whose TZDB version is no newer than the TZDB release being compiled.
The CLDR version comes from the file name, so keep the `windowsZones-<version>.xml` naming.

Files taken from git tags contain unexpanded `$Revision$` / `$Date$` keywords where Noda Time's
older copies (from CLDR's Subversion-era release archives) have them expanded; the mapping data
is otherwise identical.
