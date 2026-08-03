# RFD 0018: M3 documentation removal

**State:** discussion
**Scope:** `docs/`

## Problem

The docs tree holds a fork of the M3 Character Studio site. M3 holds
the copyright for that content. The file `docs/LICENSE` records the
M3 copyright. The MIT terms require the repository to keep that
notice while the M3 content stays.

The site costs more than it returns. No pipeline builds the site. The
site keeps a separate package file and two lock files. The site has
caused seven dependency security commits.

The site config still names the M3 origin. It sets the M3 site URL,
the M3 organization, and the M3 copyright line. The rebrand changed
only the title. The config now claims the Weftspun name over the M3
identity.

The API reference under `Developers` copies the source. RFD 0000
forbids a copy of the source. The reference has also drifted. The
animation manager source holds 47 methods. The document lists 26
methods and misses the viewport and XR work.

## Decision

Delete the M3 API reference. Do not rewrite it. A code map replaces
it. The code map names each module and points at the source file.

Delete the Docusaurus site machinery. This step removes the M3 site
identity and the dependency cost. The markdown files stay, because
the README links to them.

Rewrite each remaining M3 guide in Weftspun words. Then delete the M3
original. A rewrite must describe the current code, not the M3 code.

Keep `docs/LICENSE` until the last M3 file goes. Delete `docs/LICENSE`
only after that step. A deletion before that step would drop a notice
that the MIT terms require.

## Plan

The work follows this order:

1. Delete the template blog and the template page.
2. Delete the `Developers` reference. Add the code map.
3. Rewrite the `Modders` manifest guides. Delete the originals.
4. Rewrite the `General` guides and the quickstart.
5. Rewrite the history page as a short lineage note.
6. Delete the site config, the sidebars, and the package files.
7. Delete `docs/LICENSE`.

Steps 1 and 2 are complete. Steps 3 to 7 remain open.

## Risk

The image folder holds 30 MB. The history page uses those images. A
rewrite of the history page must drop the unused images.

The GitHub Pages workflow named an M3 host. The workflow now runs as
a check only. It builds the app and runs the animation tests. It no
longer publishes to any host. RFD 0013 keeps Vercel as the deploy
path for the public demo.

## References

- M3 notice: `docs/LICENSE`
- Site config: `docs/docusaurus.config.js`
- Code map: `docs/CODE_MAP.md`
- DRY policy: `decisions/README.md`
- Attribution: `README.md`, section Third-Party Trademarks

## Related

RFD 0017 records the rebrand.
