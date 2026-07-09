---
name: gt-bloc-blur
description: Use when working on GT/Bloc/Sparta/libskia/compositor-rs blur-below, filter-below, Skia backdrop filters, or related compositor patches.
---

This workspace spans four projects:

- Bloc: Smalltalk compositor painter/effect layer.
- sparta: Smalltalk Skia native wrapper and FFI objects.
- libskia: Rust dylib shipped into GT.
- compositor-rs: Rust compositor layer model and Skia implementation.

Rules:
- Do not make Catalyst-specific changes.
- Do not change unrelated GT/Bloc rendering behaviour.
- Do not guess. Add probes/logging when evidence is missing.
- Keep terminology as "blur below" or "filter below"; avoid "backdrop" except when referring to Skia APIs.
- Required wiring should fail visibly; do not add silent ifNil returns.
- Preserve British spelling where relevant.

Debug rule:
- First prove whether the bug is in Bloc, sparta, libskia, or compositor-rs.
- Prefer small, reversible diagnostic patches.
- Strip Transcript/file logging before final patch.
