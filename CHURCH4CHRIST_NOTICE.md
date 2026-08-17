# Church4Christ Learning — Canvas Edition

Church4Christ Learning — Canvas Edition is based on Canvas LMS. Canvas is
developed and maintained by Instructure, Inc.

The official Canvas LMS upstream repository is
<https://github.com/instructure/canvas-lms>. This derivative is based on
upstream commit `1c9f0bb8013ed69c4f2efe11fd483025469b7e6c`.

Canvas is licensed under the GNU Affero General Public License, version 3
(GNU AGPL v3). The existing root-level [COPYRIGHT](COPYRIGHT) and
[LICENSE](LICENSE) files preserve the upstream copyright and license notices
and must remain with this derivative.

Church4Christ Learning — Canvas Edition is not affiliated with, sponsored by,
or endorsed by Instructure, Inc.

Church4Christ modifications will be tracked in this repository. Under GNU AGPL
v3 §5(a), when conveying modified source versions, the work must carry
prominent notices stating that it was modified and giving a relevant date.

Under GNU AGPL v3 §13, a deployed modified version that supports remote network
interaction must prominently offer every user who interacts with it remotely
an opportunity to receive its Corresponding Source. The offer must be made
through the application or network and provide access to copy the Corresponding
Source from a network server at no charge through a standard or customary
means. Merely maintaining the source in a repository, without making this
prominent offer to remote users, is insufficient.

## Maintainer checklist

- Preserve the upstream copyright, license, and attribution notices.
- When conveying modified source versions, ensure the work carries prominent
  notices stating that it was modified and giving a relevant date (GNU AGPL v3
  §5(a)).
- For every deployed modified version that supports remote network interaction,
  make the application prominently offer every remote user no-charge network
  access to copy its Corresponding Source; a repository that merely exists is
  not enough (GNU AGPL v3 §13).
- Update the pinned upstream baseline whenever changes are rebased or merged
  from a newer Canvas LMS commit.

## Church4Christ modification log

### 2026-08-17 — supported theme and source-offer baseline

- Added the `church4christ:configure` deployment task. It uses Canvas's
  supported Theme Editor `BrandConfig` mechanism for the Church4Christ color
  theme and Canvas account-level Help Links for the in-product Corresponding
  Source offer.
- Added non-secret `C4C_*` configuration for theme colors, root-account
  selection, and the required public Corresponding Source URL. The Help link
  preserves GNU AGPL v3, Instructure, Inc., and non-endorsement attribution.
- Added operational documentation for development and production deployment,
  services, secret handling, backups/restores, and upstream updates.

### 2026-08-17 — source-link validation and configuration safety

- Restricted the Corresponding Source offer to public HTTPS URLs and rejected
  loopback, private, link-local, local-name, credentialed, and fragment URLs.
- Validated the source offer before the configuration task mutates an account,
  and added regression coverage for idempotent account theme/help-link updates,
  featured-link constraints, and root-account task validation.

### 2026-08-17 — canonical numeric source hosts

- Rejected browser-ambiguous numeric IPv4 host forms, including shortened,
  octal, hexadecimal, and single-integer spellings that can resolve to
  loopback addresses. Canonical public DNS, IPv4, and IPv6 source URLs remain
  supported.
