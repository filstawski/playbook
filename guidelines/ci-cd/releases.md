# Releases

Shipping versioned artifacts: tagged tool releases and container images. How
those images reach servers is in [../deployment/](../deployment/README.md).

## Tag main after CI is green, then verify what was published

**SHOULD** · 2026-10 · CLI tool

Push to main, wait for main's CI, then create an annotated tag and push it.
The tag workflow re-runs the checks, builds every artifact with a
`SHA256SUMS` file and installers pinned to that version, and creates the
GitHub release. Tags with a suffix (`-rc.1`) become prereleases, which
"latest" skips.

```sh
git tag -a v1.4.0 -m "<Tool> v1.4.0"
git push origin v1.4.0
# in the workflow:
gh release create "$GITHUB_REF_NAME" --generate-notes --verify-tag dist/*
```

After the workflow finishes, run the README's install commands against the
live "latest" URLs in a temp directory. For signed artifacts, check the
signer fingerprint.

## If the harness blocks a tag push, hand over the command

**MUST** · 2026-10 · CLI tool

When a safety check denies pushing a release tag, stop. Don't retry another
way. Give the user the exact one-liner to run themselves, then watch the
release run and verify the assets. Mention that a permission rule would let
agents push tags in future sessions.

## Version bump commit plus annotated tag with the changelog

**CONSIDER** · 2026-08 · browser extension

For "bump the version and tag": bump `package.json` (minor for features),
commit as `chore(release): vX.Y.Z`, and create an annotated tag whose
message lists the commits since the previous tag. Give the push commands
rather than running them, unless pushing was asked for.

**Why:** the extension's build injects the `package.json` version into its
manifest.

## Container images: one per commit, keep five

**SHOULD** · 2026-10 · dashboard app

Release on push to main. Tag images with the commit SHA plus a moving `:main`
tag, and keep the newest five in the registry (GitHub Free has 500 MB).
Turn off provenance and SBOM attestations so each commit is exactly one
package version. Secrets the build needs (e.g. a source-map upload token)
go in as BuildKit secrets, never as build args. Add the OCI `image.source`
label so the package links to its repo.

```yaml
- uses: docker/build-push-action@v6
  with:
    push: true
    tags: |
      ghcr.io/${{ github.repository }}:${{ github.sha }}
      ghcr.io/${{ github.repository }}:main
    provenance: false
    sbom: false
    secrets: |
      upload_token=${{ secrets.UPLOAD_TOKEN }}
- uses: actions/delete-package-versions@v5
  with:
    package-name: <APP>
    package-type: container
    min-versions-to-keep: 5
```
