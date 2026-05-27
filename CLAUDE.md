# downstreamGWAS

## tidyGWAS Output Structure (the "parent_dir")

All `pipeline_*()` functions expect a `parent_dir` — the output of `tidyGWAS::tidyGWAS()`:

```
<parent_dir>/
├── tidyGWAS_hivestyle/        # Arrow dataset, hive-partitioned by CHR
│   ├── CHR=1/
│   ├── CHR=2/
│   └── ...
├── metadata.yaml              # Build info, row counts, QC params, md5
├── raw/*.parquet              # Original input (unmodified)
├── pipeline_info/*.parquet    # Removed variants per QC step (with rowid)
├── tidyGWAS_logfile.txt       # Optional execution log
└── ancestry_estimates.tsv     # Optional ancestry composition
```

### Hivestyle schema (key columns)

| Column | Type | Notes |
|--------|------|-------|
| CHR | chr | Partition key |
| POS_37, POS_38 | int | Dual-build coordinates |
| RSID | chr | dbSNP ID |
| EffectAllele, OtherAllele | chr | Standardized alleles |
| B | dbl | Beta |
| SE | dbl | Standard error |
| P | dbl | P-value |
| Z | dbl | Z-score (optional) |
| EAF | dbl | Effect allele frequency (optional) |
| N | int | Sample size |
| CaseN, ControlN | int | Case/control (optional) |
| EffectiveN | int | Effective N (optional) |
| INFO | dbl | Imputation quality (optional) |
| multi_allelic | lgl | Multi-allelic flag |
| indel | lgl | Indel flag |
| rowid | int | Maps back to raw input |

Not all columns present in every dataset — depends on input.

### Important data caveats

- **EffectiveN vs N**: `EffectiveN` only exists for binary (case/control) traits. For quantitative traits, only `N` is present. `to_ma()` can compute effective N from CaseN/ControlN via `use_effective_n = TRUE`.
- **EAF and INFO can be missing**: Not all input GWAS provide allele frequencies or imputation quality scores. Downstream methods that require EAF (e.g. SBayesRC) will fail if it's absent.
- **Alleles are NOT harmonised to reference**: EffectAllele/OtherAllele retain the orientation from the original GWAS. They are not aligned to REF_37 or REF_38. Some downstream methods may need alleles flipped to match a reference panel — this must be handled explicitly.

### What downstreamGWAS reads

- `to_ma()`: RSID, EffectAllele, OtherAllele, EAF, B, SE, P, N (+ CaseN/ControlN for effective N)
- `to_clumping()`: RSID, P
- `to_ldsc()`: RSID, EffectAllele, OtherAllele, B (or Z), SE, P, N, EAF, INFO

### CHR type safety

Arrow infers the CHR partition column type from directory names. If all chromosomes are numeric (1-22), it may infer CHR as integer, which breaks `dplyr::filter(CHR == "7")` silently (zero rows). Always use `open_tidygwas(parent_dir)` instead of `arrow::open_dataset()` — it forces CHR to character.

## Project conventions

- Naming: `pipeline_*()` for HPC batch jobs (SLURM/containers), `run_*()` for quick R functions (coloc, MR)
- Chromosome argument: always use `chrom` (not `chr`)

- Pipeline contract: `pipeline_*(parent_dir, output_dir, write_script, execute, schedule, prepare_inputs, check_paths)`
- Output goes to `<parent_dir>/analysis/<method>/` by default
- Input prep runs inside the bash script (on compute node), not in the calling R session
- `dsg_finalize_pipeline()` handles script write/execute/return for all pipelines
- Config lives at `~/.config/downstreamGWAS/config.yml`, created by `setup_dsg()`
- Reference data mounted at `/src`, workdir at `/mnt` inside containers
