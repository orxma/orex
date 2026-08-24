---
name: Hosted script cache
description: Deployment and CDN behavior for scripts served from the project’s external installation domain.
---

Scripts served from `sc.orx.ma` can remain stale after local repository edits, including old CRLF line endings.

**Why:** The installer is downloaded directly from the external host, and the host may serve a cached copy even when the workspace contains the corrected file.

**How to apply:** After changing installer or updater scripts, publish the files to the external host and purge or bypass its CDN cache. Validate the complete downloaded file with `grep` for carriage returns and `bash -n` before running it.