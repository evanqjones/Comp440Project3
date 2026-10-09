# GitHub Pages Web build

The repository is configured to export the Godot Demo Scene as a single-threaded Web build and deploy it to GitHub Pages after changes reach `main`.

## Before publishing

1. Merge the `feature/github-pages-ready` branch into `main`.
2. In the repository's **Settings → Pages → Build and deployment**, select **GitHub Actions** as the source.
3. Push or merge a commit to `main`. The workflow imports the portable school model, exports `build/index.html`, checks the packaged school, and deploys the result.
4. Find the published URL in **Settings → Pages** or the successful workflow's `github-pages` environment.

Pull requests targeting `main` run the Web export job without publishing. Manual workflow runs also build only; deployment is limited to pushes on `main`.

The export uses Godot 4.7.2 to match this project's editor version. Browser builds load `assets/school_web.glb`; desktop previews continue loading `assets.blend`. CI clears the old import cache and disables Blender importing in its temporary checkout. The finished package is checked in an isolated project, so missing school files cannot be masked by local assets. The build output is generated and is not committed.

After editing the school in Blender, save `assets.blend`, then run `blender --background assets.blend --python export_school_web.py` with your installed Blender executable. Commit both the Blender changes and the refreshed `assets/school_web.glb`. This export preserves the modeled rooms, roofs, fixtures, glass, and encounter props.

The Web preset disables threads and GDExtension support so the game does not require cross-origin isolation headers. The project uses the Compatibility renderer, which supports Godot Web exports. Browser mouse capture requires a click, and browser audio may require an initial user input.
