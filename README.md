Canvas LMS
======

Canvas is a modern, open-source [LMS](https://en.wikipedia.org/wiki/Learning_management_system)
developed and maintained by [Instructure Inc.](https://www.instructure.com/) It is released under the
AGPLv3 license for use by anyone interested in learning more about or using
learning management systems.

> **Church4Christ derivative notice:** This repository contains Church4Christ
> Learning — Canvas Edition. See [CHURCH4CHRIST_NOTICE.md](CHURCH4CHRIST_NOTICE.md)
> for upstream provenance, licensing obligations, and the non-affiliation notice.

## Church4Christ Learning — Canvas Edition

This branch is the separately operated Canvas provider for Church4Christ's
optional Learning module. It remains Canvas LMS under GNU AGPLv3, preserves the
upstream Instructure, Inc. copyright and license notices, and is based on exact
upstream commit
[`1c9f0bb8013ed69c4f2efe11fd483025469b7e6c`](https://github.com/instructure/canvas-lms/commit/1c9f0bb8013ed69c4f2efe11fd483025469b7e6c).
It is not affiliated with, sponsored by, or endorsed by Instructure, Inc.

The Church4Christ-specific layer deliberately uses supported Canvas extension
points rather than patching course or submission behavior:

* Canvas Theme Editor `BrandConfig` supplies the Church4Christ visual theme and
  regenerates branded descendants through Canvas's native workflow.
* An account-level Help link prominently offers the exact Corresponding Source
  required for a deployed modified network service under GNU AGPLv3.
* A deployment task validates the public HTTPS source URL, preserves effective
  default Help links, and applies the configuration idempotently.
* Canvas stays a separate service with its own PostgreSQL, Redis/job state,
  uploaded files, secrets, backups, restores, and upstream-update lifecycle.

Read [the Church4Christ Canvas operations guide](doc/church4christ/deployment.md)
before deployment and keep
[the dated modification and source-offer notice](CHURCH4CHRIST_NOTICE.md) with
every corresponding-source release.

| Church4Christ learner experience | Provider connection administration |
|---|---|
| [![Genesis 1 course in the Church4Christ learner experience](https://raw.githubusercontent.com/leveo/church4christ/main/docs/images/learning/genesis-1-en.png)](https://github.com/leveo/church4christ/blob/main/docs/features/learning.md) | [![Canvas and Google Classroom provider administration](https://raw.githubusercontent.com/leveo/church4christ/main/docs/images/learning/admin-overview.png)](https://github.com/leveo/church4christ/blob/main/docs/features/learning.md) |

[Please see our main wiki page for more information](http://github.com/instructure/canvas-lms/wiki)

Installation
=======

Detailed instructions for installation and configuration of Canvas are provided
on our wiki.

 * [Quick Start](http://github.com/instructure/canvas-lms/wiki/Quick-Start)
 * [Production Start](http://github.com/instructure/canvas-lms/wiki/Production-Start)
