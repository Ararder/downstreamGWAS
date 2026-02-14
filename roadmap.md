# downstreamGWAS Roadmap

## Goal

Make downstream GWAS analysis reproducible and low-friction by
standardizing:

1.  input data contracts
2.  method-specific transformations
3.  containerized execution on HPC
4.  reference data acquisition and tracking

This roadmap formalizes the core abstractions needed to scale from a few
wrappers (`run_clumping`, `run_sbayesrc`, `run_sbayess`) to a stable
method ecosystem that coding agents can operate safely.

## Design Principles

1.  **One canonical GWAS input**: tidyGWAS format is the only accepted
    raw input contract.
2.  **Method modules, not ad hoc wrappers**: every method follows the
    same lifecycle and interfaces.
3.  **Reproducibility by default**: every run produces machine-readable
    provenance.
4.  **Separation of concerns**: data prep, path resolution, execution,
    and reference management are independent layers.
5.  **HPC-first, runtime-agnostic**: support Apptainer/Singularity and
    schedulers through adapters.
6.  **Concrete user-facing contract**: every `pipeline_*` method behaves
    consistently for inputs, outputs, and script writing.

## Function Contract (Concrete)

This is the package-level contract for all method wrappers.

1.  Every `pipeline_*` method takes `parent_dir`.
2.  `parent_dir` points to a directory created by
    [`tidyGWAS::tidyGWAS()`](https://ararder.github.io/tidyGWAS/reference/tidyGWAS.html).
3.  Every `pipeline_*` method accepts `output_dir = NULL`.
4.  If `output_dir` is `NULL`, output defaults to:
    `<parent_dir>/analysis/<method_name>/`
5.  If `output_dir` is set, all method outputs are written there. This
    is the standard pattern for parameter sweeps.
6.  Every `pipeline_*` method supports `write_script` so users can
    generate scripts without executing jobs immediately.

Standard signatures (target):

- `pipeline_clumping(parent_dir, output_dir = NULL, write_script = TRUE, execute = FALSE, ...)`
- `pipeline_sbayesrc(parent_dir, output_dir = NULL, write_script = TRUE, execute = FALSE, ...)`
- `pipeline_sbayess(parent_dir, output_dir = NULL, write_script = TRUE, execute = FALSE, ...)`

Notes:

1.  `write_script = TRUE` remains the default for HPC-first workflows.
2.  `execute = FALSE` keeps script generation and execution clearly
    separated.
3.  Parameter sweeps should always pass explicit `output_dir` values per
    run.

## Core Abstractions

### 1) Dataset Contract

Represents one trait summary-statistics dataset in tidyGWAS format.

- **Identity**: `dataset_id`, trait name, source metadata
- **Schema**: required columns, optional columns, schema version
- **Location**: root folder + derived analysis subfolders
- **Validation**: explicit preflight checks before any method runs

Planned API:

- `dataset_open()`
- `dataset_validate()`
- `dataset_paths()`

### 2) Method Spec

Represents one analysis method (clumping, SBayesRC, SBayesS, LDSC,
coloc, MR, etc.).

Each method must implement a standard contract:

1.  `prepare`: convert tidyGWAS to method input (`to_*`)
2.  `requirements`: declare references, container, and required columns
3.  `build`: generate executable commands/scripts
4.  `parse`: read method outputs to standardized tables
5.  `manifest`: define run parameters and output artifacts

Planned API shape:

- `method_prepare_<name>()`
- `method_run_<name>()`
- `method_parse_<name>()`
- `method_requirements_<name>()`

### 3) Path Resolver

Single source of truth for all host/container paths.

Responsibilities:

- resolve analysis directories from dataset root
- resolve reference paths from registry/config
- map host paths to container mounts deterministically
- handle quoting/safety for shell commands

This removes hardcoded paths and reduces breakage from mixed path
styles.

Planned helper contract:

- `method_output_dir(parent_dir, method_name, output_dir = NULL)`
  - returns `output_dir` if provided
  - otherwise returns `fs::path(parent_dir, "analysis", method_name)`

### 4) Runtime Adapter

Encapsulates execution backend details.

Responsibilities:

- container runtime abstraction (`apptainer` vs `singularity`)
- scheduler abstraction (start with SLURM headers)
- dry-run script generation
- optional execution helpers (`submit`, `run_local`)

This keeps method logic independent of infrastructure.

### 5) Reference Registry

Machine-readable catalog of large reference assets (10-100GB+).

Per reference entry:

- `ref_id`, version, source URL
- expected checksum(s)
- expected size
- ancestry/build tags
- local storage path

Planned API:

- `ref_list()`
- `ref_status()`
- `ref_download()`
- `ref_verify()`

### 6) Run Manifest + Artifact Model

Every method run writes a structured manifest in its output directory.

Manifest should include:

- dataset id and input paths
- method name and version
- parameters used
- container image path/digest
- reference versions/checksums
- generated command/script
- output artifact list
- timestamps + status

This is the core interface for reproducibility and agent orchestration.

Each run directory should minimally contain:

- `run.sh` (if `write_script = TRUE`)
- `run_manifest.json`
- `status.json`
- method outputs

### 7) Orchestration Layer

Composable workflow planner across multiple methods and traits.

Planned API:

- `plan_analysis()` creates executable plan objects (DAG-ready)
- `run_analysis()` executes plan steps with status updates
- `read_status()` reports current/finished/failed states

This allows agents to reason over analysis state instead of parsing ad
hoc files.

## Target Repository Structure

Proposed additions over current layout:

- `inst/extdata/references.yml` (reference registry)
- `R/methods-*.R` (method specs and wrappers)
- `R/runtime-*.R` (runtime and scheduler adapters)
- `R/refs-*.R` (reference manager)
- `R/manifests.R` (run manifest utilities)

Standard output per method:

- `analysis/<method>/run.sh`
- `analysis/<method>/run_manifest.json`
- `analysis/<method>/status.json`
- `analysis/<method>/results/*`

## Phased Delivery

### Phase 0: Stabilize Existing Core (Immediate)

Focus methods: clumping, SBayesRC, SBayesS.

Deliverables:

1.  fix existing filepath/runtime inconsistencies
2.  remove hardcoded reference paths in wrappers
3.  enforce `parent_dir` + default/custom `output_dir` behavior
    consistently
4.  standardize `write_script` behavior and return values across core
    methods
5.  add strict preflight checks for required files/columns
6.  add script snapshot tests for generated commands

### Phase 1: Method Spec Standardization

Deliverables:

1.  formal `method_*` contract
2.  refactor clumping/SBayesRC/SBayesS to contract
3.  standardized output folder + manifest per method

### Phase 2: Reference Data Product

Deliverables:

1.  implement reference registry and verification
2.  download/verify/status commands
3.  pin references by version/checksum in run manifests

### Phase 3: Orchestration + Agent Interface

Deliverables:

1.  plan/run/status APIs
2.  dry-run and resumable execution
3.  machine-readable error categories and step-level logs

### Phase 4: Method Expansion

Deliverables:

1.  migrate/add LDSC, coloc, MR, mBAT-combo, others
2.  ensure all methods emit standardized manifests
3.  integration tests across multi-method pipelines

## Future-Proofing Requirements

The abstractions above should explicitly support:

1.  multiple ancestries and genome builds
2.  multiple trait datasets in one analysis plan
3.  reference mirroring and offline HPC environments
4.  resumability after partial failures
5.  deterministic reruns years later
6.  incremental addition of new methods with minimal plumbing changes

## Apptainer + Filepaths Plan (Critical Path)

This is the most critical subsystem because every method depends on it.

### Current State (Summary)

1.  Reference/container relative paths are shipped in package
    `inst/extdata/params.yml`.
2.  Local machine-specific settings are stored in user config
    (`~/.config/downstreamGWAS/config.yml`).
3.  Methods compose host/container paths from both files.

This split is directionally correct, but it needs stricter contracts and
versioning.

### Recommendation on Shipping Filepaths in the R Package

Keep shipping **defaults** in the R package, but do not treat them as
the only source of truth.

Use a two-layer model:

1.  **Package defaults (read-only):**
    - canonical IDs for methods, references, containers
    - default relative paths
    - default runtime assumptions
2.  **Local/site overrides (read-write):**
    - actual storage locations
    - HPC/container runtime differences
    - local mirror paths and site-specific naming

Rationale:

1.  Shipping defaults gives reproducible bootstrap behavior.
2.  Local overrides are mandatory for real HPC environments.
3.  It prevents hardcoding site-specific assumptions into package
    releases.

### Filepath Contract

All method code should only use resolved paths from one resolver API.

Required resolver outputs:

1.  `host_workdir`
2.  `host_reference_root`
3.  `host_container_path`
4.  `container_workdir` (default `/mnt`)
5.  `container_reference_root` (default `/src`)
6.  `resolved_reference_files` (per method)
7.  `resolved_output_dir`

No method should manually concatenate path strings after this resolution
step.

### Runtime Contract (Apptainer/Singularity)

Define one runtime adapter that emits execution commands.

Adapter responsibilities:

1.  choose runtime binary from config (`apptainer` or `singularity`)
2.  emit bind mounts from resolved paths
3.  support env vars (`OMP_NUM_THREADS`, etc.)
4.  support both command and `R -e` execution safely
5.  return rendered command lines for manifests/tests

Method wrappers should never write raw `apptainer exec` lines directly.

Batch scheduler focus:

1.  initial batch scheduler target is **SLURM** (`sbatch`)
2.  scheduler API should stay modular so additional backends
    (e.g. PBS/LSF) can be added without changing method-level pipeline
    code
3.  pipelines should accept a `schedule` object (default `NULL`) instead
    of embedding scheduler flags in every method signature

### Registry and Versioning

Create explicit registries with stable IDs:

1.  `containers.yml` (image IDs, default filenames, optional digest
    metadata)
2.  `references.yml` (reference IDs, versions, expected size, optional
    checksums, build/ancestry tags)
3.  `methods.yml` (method -\> required container IDs + reference IDs)

Package can ship defaults in `inst/extdata/`; local overrides can live
in config directory.

### Override + Merge Rules

Deterministic precedence:

1.  function arguments (highest)
2.  local/site registry overrides
3.  package defaults (lowest)

Every run manifest should record which layer provided each resolved
path.

### Validation Requirements

Before script creation:

1.  validate runtime binary availability
2.  validate container file exists and is readable
3.  validate required reference files exist (and optionally match
    expected size if configured)
4.  validate output dir is writable
5.  fail fast with machine-readable errors

Checksum verification should be an explicit on-demand operation
(`ref_verify()`), not part of default per-setup or per-run validation.

### Migration Plan from Current `params.yml` Setup

1.  Keep `params.yml` working for backward compatibility.
2.  Introduce new resolver API and internal adapters first.
3.  Move methods (`clumping`, `sbayesrc`, `sbayess`) to resolver-only
    path usage.
4.  Add deprecation warnings for direct access patterns that bypass
    resolver.
5.  Introduce `containers.yml` + `references.yml` once resolver is
    stable.

### Testing Plan for This Layer

1.  unit tests for path resolution and precedence rules
2.  unit tests for runtime command rendering (`apptainer` and
    `singularity`)
3.  snapshot tests of rendered scripts for core methods
4.  fixture tests for missing refs/containers with clear error messages

### Phase 0 Deliverables (Expanded)

1.  implement `resolve_runtime()` and `resolve_method_paths()`
2.  update
    [`with_container()`](http://arvidharder.com/downstreamGWAS/reference/with_container.md)
    to runtime-agnostic command generation
3.  remove hardcoded runtime calls from method wrappers
4.  enforce default/custom `output_dir` through shared resolver helper
5.  include resolved runtime/path block in each `run_manifest.json`

## Success Criteria

1.  Adding a new method requires only method-specific code and registry
    entries.
2.  All runs are reproducible from manifests without manual
    reconstruction.
3.  Analysts and agents can discover missing references and required
    setup programmatically.
4.  Core workflows (`clumping`, `sbayesrc`, `sbayess`) are stable and
    tested end-to-end at script generation level.
5.  All `pipeline_*` methods share the same concrete interface
    (`parent_dir`, `output_dir`, `write_script`, optional `execute`).
