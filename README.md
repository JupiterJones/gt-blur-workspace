# GT Blur Workspace

Workspace repo for GT/Bloc/Sparta/libskia/compositor-rs blur-below work.

## First-time setup

```bash
git submodule update --init --recursive --jobs 4
cp .env.example .env
# edit .env and set GT_APP
chmod +x scripts/*.sh
```

Or run:

```bash
scripts/setup.sh
```

## Codex

Open Codex at this workspace root so it can see all four submodules and the shared actions.

Useful actions:

- `setup`
- `build_libskia`
- `deploy_libskia`

`build_libskia` uses the compositor revision recorded in `libskia/Cargo.lock`.
During compositor development, use temporary sibling path dependencies in
`libskia/libskia/Cargo.toml`; restore the git dependencies before contributing.

## Coordinated contribution

The `blur_below` branches in `compositor-rs`, `libskia`, `sparta`, and `Bloc`
form one coordinated change. The native compositor support must be merged first.
After that, update `libskia/Cargo.lock` to the merged compositor revision before
submitting the libskia dependency update. The Sparta and Bloc changes depend on
the resulting native symbols being present in `libSkia.dylib`.

## Submodule contribution workflow

Each child project is its own Git repository. Commit and push changes inside the relevant submodule, then commit the updated submodule pointer in this workspace repo.

Example:

```bash
cd Bloc
git status
git add ...
git commit -m "Add blur-below compositor support"
git push

cd ..
git status
git add Bloc
git commit -m "Update Bloc submodule"
git push
```
