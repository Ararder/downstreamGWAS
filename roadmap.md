# downstreamGWAS Roadmap

## Goal

Make downstream GWAS analysis reproducible and low-friction by
standardizing input contracts, containerized execution, reference data
management, and HPC scheduling.

## Design Principles

1.  **One canonical input**: tidyGWAS format is the only accepted input.
2.  **Consistent pipeline contract**: every `pipeline_*()` function
    follows the same interface.
3.  **Script-first**: generate inspectable bash scripts; execution is
    opt-in.
4.  **HPC-first**: SLURM scheduling and Apptainer containers are
    first-class.
5.  **Preflight validation**: fail fast with clear errors before wasting
    compute.

## What’s Implemented

### Pipeline contract (done)

All `pipeline_*()` functions share:

``` r
pipeline_<method>(
  parent_dir,
  output_dir = NULL,        # defaults to <parent_dir>/analysis/<method>
  write_script = TRUE,
  execute = FALSE,
  schedule = NULL,           # schedule_slurm(...) for SLURM submission
  prepare_inputs = execute,  # include data conversion step in script
  check_paths = TRUE,        # validate assets before execution
  ...                        # method-specific parameters
)
```

Implemented pipelines:
[`pipeline_clumping()`](http://arvidharder.com/downstreamGWAS/reference/pipeline_clumping.md),
[`pipeline_sbayesrc()`](http://arvidharder.com/downstreamGWAS/reference/pipeline_sbayesrc.md),
[`pipeline_sbayess()`](http://arvidharder.com/downstreamGWAS/reference/pipeline_sbayess.md).

### Infrastructure helpers (done)

- [`setup_dsg()`](http://arvidharder.com/downstreamGWAS/reference/setup_dsg.md)
  — one-time config setup, creates `~/.config/downstreamGWAS/config.yml`
- `dsg_get_config()` — reads merged config (package defaults + user
  overrides)
- `dsg_build_apptainer_exec()` — single function for container command
  generation
- `dsg_script_preamble()` — bash header with optional SLURM directives
- `dsg_finalize_pipeline()` — shared write/execute/return logic
- [`schedule_slurm()`](http://arvidharder.com/downstreamGWAS/reference/schedule_slurm.md)
  — typed schedule object
- Preflight checks: `dsg_check_parent_dir()`,
  `dsg_check_writable_dir()`, `dsg_check_*_assets()`

### Config architecture (done)

Two-layer model:

1.  **Package defaults** (`inst/extdata/params.yml`): container
    filenames, reference relative paths, mount points
2.  **User config** (`~/.config/downstreamGWAS/config.yml`):
    `storage_root`, `reference_dir`, `container_dir`,
    `container_dependency`

### Testing (done)

Unit tests for script generation — validates correct commands, SLURM
headers, container dependency injection, output paths, and
prepare_inputs toggling. No mocking of apptainer or SLURM; tests verify
the generated bash, not execution.

### Other working features

- `run_coloc()` /
  [`format_coloc()`](http://arvidharder.com/downstreamGWAS/reference/format_coloc.md)
  — colocalisation via
  [`coloc::coloc.abf()`](https://rdrr.io/pkg/coloc/man/coloc.abf.html)
- [`mr_on_tidyGWAS()`](http://arvidharder.com/downstreamGWAS/reference/mr_on_tidyGWAS.md)
  — two-sample MR via TwoSampleMR
- Export functions:
  [`to_ma()`](http://arvidharder.com/downstreamGWAS/reference/to_ma.md),
  [`to_clumping()`](http://arvidharder.com/downstreamGWAS/reference/to_clumping.md),
  [`to_ldsc()`](http://arvidharder.com/downstreamGWAS/reference/to_ldsc.md)

------------------------------------------------------------------------

## What’s Next

### Phase 1: Reference data integrity

**Problem**: Reference files are large (10-100GB), hosted across Zenodo
and external sources, and nothing verifies that what’s on disk is
correct. A truncated download, wrong version, or misnamed directory
silently produces wrong results.

**Deliverables**:

1.  `inst/extdata/references.yml` — manifest mapping each method to its
    required files with expected checksums (sha256), file sizes, source
    URLs, and build/ancestry tags.

2.  `dsg_verify_references(method = NULL)` — checks files on disk
    against the manifest. Reports missing, truncated (size mismatch), or
    wrong (checksum mismatch) files. Runs on-demand, not on every
    pipeline call.

3.  `dsg_reference_status()` — summary of what’s present and what’s
    missing, for all methods or a specific one.

4.  Document download instructions per method. For self-hosted files
    (Zenodo), provide direct URLs. For externally-hosted files, document
    the exact version and source. Accept that this is a mixed model —
    pin what we can, document what we can’t.

**Not in scope**: automated download functions for multi-GB files. A
documented `wget` or `curl` command is more practical than doing this in
R.

### Phase 2: Container versioning

**Problem**: `params.yml` uses `_latest` container tags. There’s no
record of what’s inside each container, and upstream changes can
silently break things.

**Deliverables**:

1.  Move Dockerfiles into `inst/docker/` so the repo records exactly
    what each container contains.

2.  Tag containers with dates or version numbers instead of `_latest`
    (e.g. `sbayesrc_2024-06.sif`). Update `params.yml` accordingly.

3.  Add a CI job (or documented manual step) that builds containers and
    runs a smoke test
    (e.g. `apptainer exec image.sif R -e "library(SBayesRC)"`).

### Phase 3: Migrate remaining methods

Migrate old `run_*()` wrappers to the `pipeline_*()` contract:

- `pipeline_ldsc()` — LD score regression (h2, rg)
- `pipeline_sldsc()` — stratified LDSC / cell-type analysis
- `pipeline_mbat_combo()` — mBAT-combo gene test
- `pipeline_coloc()` — wrap `run_coloc()` with script generation for
  batch use

Each migration follows the same pattern: extract the container command
construction, use `dsg_build_apptainer_exec()`, add preflight checks,
use `dsg_finalize_pipeline()`.

### Phase 4: Integration testing

**Problem**: Unit tests verify script generation but not actual
execution. The gap between “script looks correct” and “script runs
correctly” is where most real failures happen.

**Deliverables**:

1.  A small test dataset (subset of tidyGWAS output, ~1000 variants)
    committed to `inst/testdata/` or hosted on Zenodo.

2.  An integration test script (not in `testthat` — meant to run
    manually on HPC) that exercises the full path:
    [`setup_dsg()`](http://arvidharder.com/downstreamGWAS/reference/setup_dsg.md)
    →
    [`pipeline_sbayesrc()`](http://arvidharder.com/downstreamGWAS/reference/pipeline_sbayesrc.md)
    → verify output file exists and is non-empty.

3.  Document expected resource requirements and runtime for the
    integration test.

### Phase 5: Run manifests (optional)

Each pipeline run writes a `run_manifest.json` alongside results,
recording: parameters used, container path, reference versions,
generated script, and timestamps. This is valuable for reproducibility
but not blocking — the generated `.sh` script already captures most of
this information.

------------------------------------------------------------------------

## Decided against (and why)

- **Dataset abstraction** (`dataset_open()`, `dataset_validate()`): the
  tidyGWAS directory *is* the dataset. Adding a wrapper object doesn’t
  buy much over `dsg_check_parent_dir()`.

- **Method spec contract** (`method_prepare_*`, `method_run_*`,
  `method_parse_*`): over-engineering for 5-10 methods maintained by one
  person. The `pipeline_*()` contract is concrete and sufficient.

- **Runtime adapter abstraction** (apptainer vs singularity):
  `dsg_build_apptainer_exec()` handles this. Singularity is effectively
  dead; abstracting over both runtimes adds complexity for no practical
  benefit.

- **Orchestration layer** (`plan_analysis()`, DAG execution): premature.
  The current pattern of calling `pipeline_*()` in a loop or script is
  adequate. Revisit if/when there are 20+ methods with complex
  dependencies.

- **Automated reference downloads in R**: multi-GB downloads are better
  handled by shell commands. R’s download facilities are unreliable for
  large files.

## Success Criteria

1.  A new user can go from `install_github()` to running SBayesRC on
    their cluster in under 30 minutes (including reference data
    download).
2.  `dsg_verify_references()` catches wrong/missing/truncated files
    before they cause silent failures.
3.  Adding a new pipeline method requires only method-specific code — no
    plumbing changes.
4.  Generated scripts are self-contained and runnable without R.
