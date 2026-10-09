# GitHub Pages Web build

The repository is configured to export the Godot Demo Scene as a single-threaded Web build and deploy it to GitHub Pages after changes reach `main`.

## Before publishing

1. Merge the `feature/github-pages-ready` branch into `main`.
2. In the repository's **Settings → Pages → Build and deployment**, select **GitHub Actions** as the source.
3. Push or merge a commit to `main`. The workflow imports Blender assets, exports `build/index.html`, and deploys the result.
4. Find the published URL in **Settings → Pages** or the successful workflow's `github-pages` environment.

Pull requests targeting `main` run the Web export job without publishing. Manual workflow runs also build only; deployment is limited to pushes on `main`.

The export uses Godot 4.7.2 to match this project's editor version. Blender is installed in CI because the Demo Scene imports `assets.blend`. Keep Godot and Blender source assets in the repository so clean runners can rebuild the scene. The build output is generated and is not committed.

The Web preset disables threads and GDExtension support so the game does not require cross-origin isolation headers. The project uses the Compatibility renderer, which supports Godot Web exports. Browser mouse capture requires a click, and browser audio may require an initial user input.
