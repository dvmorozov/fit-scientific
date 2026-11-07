# fit-scientific

The scientific module of [Fit](https://github.com/dvmorozov/fit): the peak
shapes (Gauss, Lorentz, Voigt, pseudo-Voigt and its asymmetric and two-branch
forms, Pearson VII, Moffat, Doniach-Sunjic, EMG, skewed Gaussian, step), the
background shapes (polynomial, Chebyshev, exponential, power law) with the
search that proposes a profile's background and the search that finds its
peaks, the user's own formula as a curve type, the diffraction angles and
wavelength, the readers for diffractometer files, the Residual Spectrum, the
module's chapter of the guide, and the nine diffraction profiles Fit ships as
samples.

It is not a program and does not build on its own. Fit links it; a product for
another field leaves it out. It is a repository of its own, beside `fit`,
because the framework tree holds no module of any field.

## Where it goes

Check it out next to the others, so the directories sit side by side:

    git clone https://github.com/dvmorozov/fit
    git clone https://github.com/dvmorozov/fitgrids
    git clone https://github.com/dvmorozov/fitminimizers
    git clone https://github.com/dvmorozov/fit-scientific

`fit`'s projects name this repository's folders on their search paths
(`../../fit-scientific/Modules/scientific` and `.../Desktop/ScientificForms`),
and its build script (`scripts/build-app.ps1`) stops, naming the missing
directory, when it is not there.

## What is in it

| Folder | What |
|---|---|
| `Modules/scientific/` | the module: its curve types, rules, searches, formats, guide chapter and `module.json` |
| `Modules/scientific/tests/` | its tests (`scientific_tests` lists them); they run inside `fit`'s suites, wherever the module is linked |
| `Desktop/ScientificForms/` | the desktop client's windows for the module: the wavelength and background-fraction dialogs, the user-formula dialogs, the Residual Spectrum chart |
| `Data/` | the diffraction samples `1.dat` to `9.dat`, shipped by every package of a product that links the module |

`Modules/scientific/module.json` is what the build reads: the module's
directories, its front doors for the client, the server and the windows, its
tests and its sample folder. Nothing in `fit` names the module; see
[`AGENTS.md`](AGENTS.md).

## Building and testing

From the `fit` checkout, as for any other part of Fit (the build script is
documented in `fit/docs/user-guide/building-from-source.md`):

    ./scripts/build-app.ps1 -Task all

The module's tests are linked into the suites of every product that links it;
there is no suite of their own to run here.

## License

GPL-3.0-or-later, as `fit` - see [LICENSE](LICENSE). The nine sample profiles in
`Data/` are the ones Fit has always shipped. The one real instrument file used by the
tests (`Modules/scientific/tests/fixtures/sand-718-44.xrdml`) is CC-BY-4.0, with
its source recorded beside it.
