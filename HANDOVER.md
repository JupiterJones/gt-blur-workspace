# Handover: GT / Bloc / Sparta / Skia blur-below compositor work

## Goal

Make `BlBlurBelowEffect` work correctly in the Bloc compositor renderer, suitable for upstream GT/Bloc contribution.

This workspace spans:

- `Bloc`
- `sparta`
- `libskia`
- `compositor-rs`

Do not touch Catalyst Runtime, Catalyst Foundation, Magritte UI, or unrelated app code unless explicitly asked.

## User rules

- Do not guess. Use probes/logging when evidence is missing.
- Do not make broad refactors.
- Do not add silent guards like `ifNil: [ ^ self ]` for required state.
- Keep terminology as `blur below` / `filter below`.
- Avoid Catalyst-specific monkey patches.
- Strip debug logging before final patch.

## Current status

Native support for a generic `FilterBelowLayer` has been added through the stack.

### compositor-rs

Added:

- `Filter`
- `BlurFilter`
- `FilterBelowLayer`
- compositor trait hook `compose_filter_below`
- FFI:
  - `compositor_filter_blur_new`
  - `compositor_filter_drop`
  - `compositor_filter_below_layer_new`

The Skia implementation uses:

```rust
skia_safe::canvas::SaveLayerRec::default()
    .backdrop(&filter)
```

and converts `Filter::Blur` to `skia_safe::image_filters::blur`.

Native probes proved:

- direct Skia backdrop blur works;
- `FilterBelowLayer` works;
- `PictureLayer` cached and uncached before `FilterBelowLayer` works;
- sigma `2` preserves visible stripe structure;
- sigma `18` collapses to a near-uniform magenta slab.

Relevant probe command:

```bash
cd compositor-rs
cargo run -p compositor-skia --example filter_below_probe
```

### libskia

For local development, `libskia/libskia/Cargo.toml` may need local sibling paths for compositor-rs crates:

```toml
compositor = { path = "../../compositor-rs/compositor" }
compositor-skia = { path = "../../compositor-rs/compositor-skia" }
compositor-ffi = { path = "../../compositor-rs/compositor-ffi" }
compositor-skia-ffi = { path = "../../compositor-rs/compositor-skia-ffi" }
compositor-skia-platform = { path = "../../compositor-rs/compositor-skia-platform" }
```

Build/deploy actions are in `.codex/config.toml` and `scripts/`.

### sparta

Added Smalltalk wrappers:

- `SkiaCompositorFilter`
- `SkiaCompositionFilterBelowLayer`
- `SkiaCompositorFilterBelowLayerBuilder`

Required globals in GT:

```smalltalk
Smalltalk globals includesKey: #SkiaCompositorFilter.
Smalltalk globals includesKey: #SkiaCompositorFilterBelowLayerBuilder.
Smalltalk globals includesKey: #SkiaCompositionFilterBelowLayer.
```

All should answer `true`.

`SkiaCompositorFilter blur: 2` should work.

### Bloc

Added:

- `BlCompositionBlurFilter`
- `BlCompositionFilterBelowLayer`
- `BlCompositionLayeredPainter>>pushFilterBelow:filter:offset:bounds:compositing:thenPaint:`
- `BlBlurBelowEffect` compositor hook.
- Diagnostic examples in `BlCompositionPainterBlurEffectExamples`.

Important fix discovered:

```smalltalk
BlBlurBelowEffect >> wantsCompositionLayer
    ^ false
```

Reason:

`BlurBelowEffect` must be composed in the parent/backdrop-owning surface. If it forces a separate compositing layer, the backdrop sample is taken from the blur panel’s local `0@0` surface instead of the parent surface.

Evidence:

Before the fix, Transcript showed:

```text
[filter-below] BlCompositionFilterBelowLayer offset=(0@0) children=0
```

After the fix:

```text
[filter-below] BlCompositionFilterBelowLayer offset=(110.0@164.1956787109375) children=1
[filter-below] BlCompositionBlurFilter radius=2
[filter-below] SkiaCompositorFilter blurSigmaX=2 sigmaY=2
```

So the precomposition bug is proven and fixed.

## Current unresolved issue

Even after the no-precompose fix, the same object renders differently in three GT hosts:

1. Inspector Live view:
   - panel often appears flat magenta.
2. Code preview popup:
   - panel shows stripe structure, but at a different apparent scale/frequency.
3. Tab preview:
   - panel appears to sample/blur a different render surface or preview snapshot.

This suggests the remaining issue is host/render-target/transform specific, not simple sigma or missing FFI.

The latest useful observation:

- The origin probe has green/yellow stripes in the top-left area and red/blue behind the blur panel.
- Live view shows the panel sampling the red/blue target area, not the green/yellow origin area.
- The preview popup/tab preview still differs, suggesting GT preview hosts use different render paths/surfaces.

## Latest diagnostic requested

A file logger patch should write to:

```text
/tmp/compositor-filter-below-debug.log
```

when GT is launched with:

```bash
COMPOSITOR_FILTER_BELOW_DEBUG=1 /path/to/MyProject.app/Contents/MacOS/MyProject
```

Then run in GT:

```smalltalk
BlCompositionPainterBlurEffectExamples new blurBelowOriginProbe
```

Inspect:

```bash
cat /tmp/compositor-filter-below-debug.log
```

Important lines to add/check:

- current Skia canvas matrix before `save_layer`;
- matrix after clip;
- geometry bounds;
- layer offset;
- filter sigma;
- possibly current clip bounds if available.

Expected purpose:

Prove whether Inspector Live, code preview popup, and tab preview enter `SaveLayerRec::backdrop` with different matrices/transforms/render targets.

## Diagnostic examples

Run:

```smalltalk
BlCompositionPainterBlurEffectExamples new blurBelowOnVerticalStripedBackground
```

Expected if correct:

- radius `2`;
- vertical red/blue stripes should remain visible through the rounded panel with softened edges.

Run:

```smalltalk
BlCompositionPainterBlurEffectExamples new blurBelowOriginProbe
```

Interpretation:

- red/blue inside panel = samples correct behind-panel area;
- green/yellow inside panel = samples top-left/local origin;
- different results across preview hosts = host-specific render target/transform path.

## Things already disproved

- Missing native symbols: not current issue.
- sparta classes undeclared: was a stale load-order issue, not current issue.
- GT passing radius `18`: disproved; Transcript shows radius `2`.
- `PictureLayer` cache interaction in simple compositor scene: disproved by Rust probe.
- Pure compositor `FilterBelowLayer` implementation in simple scene: works.

## Likely next steps

1. Verify the file logger actually writes to `/tmp/compositor-filter-below-debug.log`.
2. If not, fix the logger first; do not continue visual guessing.
3. Compare native logs for:
   - Inspector Live view;
   - code preview popup;
   - tab preview.
4. Look specifically for matrix/scale/translation/render target differences at `compose_filter_below`.
5. Once proven, adjust where/how `FilterBelowLayer` is emitted or how it interprets offset/geometry under GT preview render targets.
6. Strip all Transcript/file logging.
7. Produce clean patches for:
   - compositor-rs
   - libskia local dependency patch, if still needed only for local testing
   - sparta
   - Bloc
