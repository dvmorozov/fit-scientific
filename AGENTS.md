# Working on fit-scientific - a guide for AI agents

**Read [`../fit/AGENTS.md`](../fit/AGENTS.md) first.** Every rule there applies
here unchanged: the non-negotiables, "read the mechanism that exists before you
add one", red-green-refactor through the surface the user reaches, the comment
conventions. This file adds only what is true because this is a module's
repository rather than the framework.

**What this is, in the framework's own terms.** A module is an entity that
covers one class of fitting tasks and is fully responsible for it - its
interface, its model elements, its rules and its computations - and explains
every one of them. This one covers the decomposition of a measured profile (a
spectrum, a diffraction pattern) into peaks on a background. The contract it is
written against is
[`../fit/docs/contributing/module-architecture.md`](../fit/docs/contributing/module-architecture.md),
shared by every module; nothing this module needs may be added to it except as
a field-neutral seam that meets that page's criteria. The module is public, and
so is this repository.

## The dependency runs one way

This repository uses `fit`'s published contracts; `fit` compiles with no
knowledge that it exists. No file exists in two repositories, and the framework
may not name this module - the boundary tests in `fit` (`testcase_framework_boundary`,
`client_without_engine`, `product_closure`, the leak gate) fail by name when it
does. If a change here seems to need an edit to a framework file, a seam is
missing in the framework: add the seam there, never a branch.

## How a build finds it

- **The build finds it by what it carries.** `Modules/scientific/module.json` is
  read by `fit/tools/build-lib/product_modules.ps1`
  (`Get-ModuleManifests` looks in `Modules/*` of this repository, as of every
  sibling repository `Get-SiblingRepoNames` lists). A product lists it in its
  `build.modules`; free Fit does. Fit Pro links every module there is.
- **Four front doors, three hosts.** `scientific_module` (both hosts, through
  the product's `app_modules`), `scientific_server_module` (the compute server
  alone - the background arithmetic and the peak search, which the desktop
  client must never link: non-negotiable 1), `scientific_forms` (the desktop
  client's windows for the module, in `Desktop/ScientificForms`, through
  `client_modules`; the module itself names no LCL type) and `scientific_tests`
  (the tests, through `module_tests`). A product's four composition units are
  written by the build from `module.json`; never edit them.
- **Its curve types keep the owner `Standard`**, the framework's own name
  (`scientific_module.pas` says why): a peak, a background and the user's
  formula have always gone in one model together.
- **Its samples travel with it.** `Data/` is the module's `data` folder: a
  package ships it for a product that links this module and for no other
  (`Get-ProductSampleDirs`), and `-DataFile sample` and the scenarios' `fitdata`
  read it through `Get-FitSampleDir`. A product that leaves the module out has
  no diffraction samples.

## Testing

- The tests are linked into the framework's and the module repository's suites
  through `scientific_tests`; nothing here builds a suite of its own. Run them
  through `fit`'s orchestrator, on the remote PC: `-Task test-pro -Suite <Class>`
  (the Pro suite links every module), or `-Task test-full`.
- The suites' binary is built into `fit/tests`, so a test finds this
  repository's files through `scientific_test_paths` (`ScientificSampleDir`,
  `ScientificFile`) - two folders up from the binary and over into
  `fit-scientific` - never by a path of its own. Add a fixture under
  `Modules/scientific/tests/fixtures/` and read it through that unit.
- Real-data tests read `Data/1.dat` and `Data/2.dat`; a test about the framework
  must not (the framework's own suite builds without this repository on its
  path).

## Where the reasoning is

The reasons behind the module's decisions are recorded where they were made, in
`fit`: `docs/contributing/findings.md` (the lineshape conventions - "Three
lineshapes, three conventions, one parameter name"; the user's formula - "Two
user curves created in the same millisecond overwrite each other", "A malformed
formula was accepted the second time it was refused", "Sixteen of the
twenty-three keypad buttons built a formula nothing could evaluate"; the
wavelength - "A typo in the wavelength box disconnected the user from the
server"; and the background and peak search) and `docs/internal/decisions.md`.
Read the entry for what you touch before changing it.
