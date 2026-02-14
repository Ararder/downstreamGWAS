utils::globalVariables(c("N", "P", "SNP", "POS", "tmp", "chr", "start", "end"))

#' Setup downstreamGWAS config
#'
#' @param storage_root Long-term storage root for references and containers.
#' @param sumstats_folder Optional default folder containing tidyGWAS datasets.
#' @param container_dependency Optional shell command to load runtime dependencies
#'   on HPC (e.g. `"ml apptainer"`).
#' @param force Overwrite existing config file?
#'
#' @return Path to written config file.
#' @export
setup_dsg <- function(
    storage_root,
    sumstats_folder = NULL,
    container_dependency = "",
    force = FALSE
) {
  rlang::check_required(storage_root)
  stopifnot(
    is.character(storage_root),
    length(storage_root) == 1,
    is.character(container_dependency),
    length(container_dependency) == 1,
    rlang::is_bool(force)
  )

  cfg_path <- fs::path(Sys.getenv("HOME"), ".config", "downstreamGWAS", "config.yml")
  if (fs::file_exists(cfg_path) && !isTRUE(force)) {
    stop("Config already exists. Re-run with force = TRUE to overwrite.")
  }

  reference_dir <- fs::path(storage_root, "reference")
  container_dir <- fs::path(storage_root, "containers")

  fs::dir_create(fs::path_dir(cfg_path), recurse = TRUE)
  fs::dir_create(storage_root, recurse = TRUE)
  fs::dir_create(reference_dir, recurse = TRUE)
  fs::dir_create(container_dir, recurse = TRUE)

  cfg <- list(
    storage_root = storage_root,
    reference_dir = reference_dir,
    container_dir = container_dir,
    container_software = "apptainer",
    sumstats_folder = sumstats_folder %||% "",
    container_dependency = container_dependency,
    # compatibility keys
    downstreamGWAS_folder = storage_root,
    container_dependency_legacy = container_dependency
  )

  yaml::write_yaml(cfg, cfg_path)
  cfg_path
}


#' Resolve downstreamGWAS pipeline output directory
#'
#' @param parent_dir Path to `tidyGWAS::tidyGWAS()` output directory.
#' @param method_name Method identifier, e.g. `clumping`.
#' @param output_dir Optional custom output directory.
#'
#' @return Absolute path to the output directory.
#' @export
dsg_method_output_dir <- function(parent_dir, method_name, output_dir = NULL) {
  rlang::check_required(parent_dir)
  rlang::check_required(method_name)

  out <- output_dir %||% fs::path(parent_dir, "analysis", method_name)
  fs::path_abs(out)
}


dsg_get_config <- function() {
  cfg <- parse_config()

  storage_root <- cfg$storage_root %||% cfg$downstreamGWAS_folder
  reference_dir <- cfg$reference_dir %||% fs::path(storage_root, "reference")
  container_dir <- cfg$container_dir %||% fs::path(storage_root, "containers")

  list(
    storage_root = storage_root,
    reference_dir = reference_dir,
    container_dir = container_dir,
    container_software = "apptainer",
    sumstats_folder = cfg$sumstats_folder,
    container_dependency = cfg$container_dependency %||% cfg$container_dependency_legacy %||% ""
  )
}


dsg_build_apptainer_exec <- function(command, workdir, reference_dir, container, env = NULL) {
  rlang::check_required(command)
  rlang::check_required(workdir)
  rlang::check_required(reference_dir)
  rlang::check_required(container)

  env_flag <- if (is.null(env)) "" else glue::glue("--env {shQuote(env)} ")

  glue::glue(
    "apptainer exec --cleanenv {env_flag}",
    "--bind {shQuote(glue::glue('{workdir}:/mnt'))},{shQuote(glue::glue('{reference_dir}:/src'))} ",
    "{shQuote(container)} {command}"
  )
}


dsg_write_script <- function(script_lines, output_dir, script_name) {
  fs::dir_create(output_dir, recurse = TRUE)
  script_path <- fs::path(output_dir, script_name)
  writeLines(script_lines, script_path)
  script_path
}


dsg_run_return <- function(script, script_path, output_dir, executed = FALSE, exit_code = NULL) {
  list(
    output_dir = output_dir,
    script_path = script_path,
    script = script,
    executed = executed,
    exit_code = exit_code,
    job_id = NULL,
    submit_output = NULL
  )
}

dsg_file_or_dir_exists <- function(path) {
  fs::file_exists(path) || fs::dir_exists(path)
}

dsg_assert <- function(ok, message) {
  if (!isTRUE(ok)) stop(message, call. = FALSE)
}

dsg_check_parent_dir <- function(parent_dir) {
  dsg_assert(fs::dir_exists(parent_dir), paste0("`parent_dir` does not exist: ", parent_dir))
  hive <- fs::path(parent_dir, "tidyGWAS_hivestyle")
  dsg_assert(fs::dir_exists(hive), paste0("Missing tidyGWAS dataset directory: ", hive))
}

dsg_check_writable_dir <- function(path) {
  fs::dir_create(path, recurse = TRUE)
  probe <- fs::path(path, ".dsg_write_test")
  ok <- tryCatch({
    writeLines("ok", probe)
    TRUE
  }, error = function(...) FALSE)
  if (fs::file_exists(probe)) fs::file_delete(probe)
  dsg_assert(ok, paste0("Output directory is not writable: ", path))
}

dsg_check_clumping_assets <- function(cfg, params) {
  container <- fs::path(cfg$container_dir, params$plink$container)
  base <- fs::path(cfg$reference_dir, params$genome_refs$deep_1kg)
  gene_ref <- fs::path(cfg$reference_dir, params$plink$gene_ref)

  dsg_assert(fs::file_exists(container), paste0("Missing PLINK container: ", container))
  dsg_assert(fs::file_exists(gene_ref), paste0("Missing PLINK clumping gene reference: ", gene_ref))
  dsg_assert(fs::file_exists(paste0(base, ".bed")), paste0("Missing PLINK .bed file: ", paste0(base, ".bed")))
  dsg_assert(fs::file_exists(paste0(base, ".bim")), paste0("Missing PLINK .bim file: ", paste0(base, ".bim")))
  dsg_assert(fs::file_exists(paste0(base, ".fam")), paste0("Missing PLINK .fam file: ", paste0(base, ".fam")))
}

dsg_check_sbayesrc_assets <- function(cfg, params) {
  container <- fs::path(cfg$container_dir, params$sbayesrc$container)
  ldm <- fs::path(cfg$reference_dir, params$sbayesrc$ldm)
  annot <- fs::path(cfg$reference_dir, params$sbayesrc$annot)

  dsg_assert(fs::file_exists(container), paste0("Missing SBayesRC container: ", container))
  dsg_assert(dsg_file_or_dir_exists(ldm), paste0("Missing SBayesRC LD matrix path: ", ldm))
  dsg_assert(fs::file_exists(annot), paste0("Missing SBayesRC annotation file: ", annot))
}

dsg_input_cmd_clumping <- function(parent_dir, outdir) {
  hivestyle <- fs::path(parent_dir, "tidyGWAS_hivestyle")
  glue::glue("R -e {shQuote(glue::glue(\"downstreamGWAS::to_clumping('{hivestyle}', '{outdir}')\"))}")
}

dsg_input_cmd_sbayesrc <- function(parent_dir, outdir, use_effective_n) {
  ma_out <- fs::path(outdir, "sumstats.ma")
  glue::glue("R -e {shQuote(glue::glue(\"downstreamGWAS::to_ma('{parent_dir}', out = '{ma_out}', use_effective_n = {use_effective_n})\"))}")
}

dsg_input_cmd_sbayess <- function(parent_dir, outdir, use_effective_n) {
  ma_out <- fs::path(outdir, "sumstats.ma")
  glue::glue("R -e {shQuote(glue::glue(\"downstreamGWAS::to_ma('{parent_dir}', out = '{ma_out}', use_effective_n = {use_effective_n})\"))}")
}

dsg_check_sbayess_assets <- function(cfg, params) {
  container <- fs::path(cfg$container_dir, params$gctb$container)
  ldm_info <- paste0(fs::path(cfg$reference_dir, params$gctb$ldm_s), ".info")
  ldm_bin <- paste0(fs::path(cfg$reference_dir, params$gctb$ldm_s), ".bin")

  dsg_assert(fs::file_exists(container), paste0("Missing GCTB container: ", container))
  dsg_assert(fs::file_exists(ldm_info), paste0("Missing sparse LDM .info file: ", ldm_info))
  dsg_assert(fs::file_exists(ldm_bin), paste0("Missing sparse LDM .bin file: ", ldm_bin))
}

dsg_finalize_pipeline <- function(script, outdir, script_name, write_script, execute, schedule) {
  script_path <- NULL
  if (isTRUE(write_script) || isTRUE(execute)) {
    script_path <- dsg_write_script(script, outdir, script_name)
  }

  exit_code <- NULL
  job_id <- NULL
  submit_output <- NULL
  if (isTRUE(execute)) {
    ex <- dsg_execute_script(script_path, schedule = schedule)
    exit_code <- ex$exit_code
    job_id <- ex$job_id
    submit_output <- ex$submit_output
  }

  res <- dsg_run_return(
    script = script,
    script_path = script_path,
    output_dir = outdir,
    executed = execute,
    exit_code = exit_code
  )
  res$job_id <- job_id
  res$submit_output <- submit_output
  res
}

dsg_slurm_header <- function(slurm_args = list(), default_output = NULL) {
  stopifnot(is.list(slurm_args))

  defaults <- list(
    time = "24:00:00",
    mem = "8gb",
    cpus_per_task = NULL,
    account = NULL,
    partition = NULL,
    output = default_output
  )
  x <- utils::modifyList(defaults, slurm_args)

  header <- c(
    glue::glue("#SBATCH --mem={x$mem}"),
    glue::glue("#SBATCH --time={x$time}")
  )
  if (!is.null(x$cpus_per_task)) header <- c(header, glue::glue("#SBATCH --cpus-per-task={x$cpus_per_task}"))
  if (!is.null(x$account)) header <- c(header, glue::glue("#SBATCH --account={x$account}"))
  if (!is.null(x$partition)) header <- c(header, glue::glue("#SBATCH --partition={x$partition}"))
  if (!is.null(x$output)) header <- c(header, glue::glue("#SBATCH --output={x$output}"))
  header
}

dsg_is_slurm_schedule <- function(schedule) {
  is.list(schedule) && identical(schedule$type, "slurm")
}

#' Construct a SLURM schedule object
#'
#' @param time SLURM time limit.
#' @param mem SLURM memory request.
#' @param cpus_per_task SLURM CPUs per task.
#' @param account Optional SLURM account.
#' @param partition Optional SLURM partition.
#'
#' @return A schedule object that can be passed to `pipeline_*()` functions.
#' @export
schedule_slurm <- function(
    time = "24:00:00",
    mem = "8gb",
    cpus_per_task = NULL,
    account = NULL,
    partition = NULL
) {
  list(
    type = "slurm",
    args = list(
      time = time,
      mem = mem,
      cpus_per_task = cpus_per_task,
      account = account,
      partition = partition
    )
  )
}

dsg_script_preamble <- function(cfg, schedule = NULL, default_slurm_output = NULL) {
  dep <- cfg$container_dependency %||% ""
  dep <- trimws(dep)

  preamble <- c("#!/usr/bin/env bash")
  if (!is.null(schedule)) {
    if (!dsg_is_slurm_schedule(schedule)) {
      stop("Unsupported schedule object. Use schedule_slurm(...) or NULL.")
    }
    slurm_args <- schedule$args %||% list()
    slurm_args$output <- default_slurm_output
    preamble <- c(preamble, dsg_slurm_header(slurm_args = slurm_args, default_output = default_slurm_output))
  }
  preamble <- c(preamble, "set -euo pipefail")
  if (nzchar(dep)) preamble <- c(preamble, dep)
  preamble
}

dsg_execute_script <- function(script_path, schedule = NULL) {
  if (!is.null(schedule)) {
    if (!dsg_is_slurm_schedule(schedule)) {
      stop("Unsupported schedule object. Use schedule_slurm(...) or NULL.")
    }
    out <- system2("sbatch", args = script_path, stdout = TRUE, stderr = TRUE)
    status <- attr(out, "status", exact = TRUE) %||% 0L
    if (status != 0L) {
      stop(paste(c("sbatch failed:", out), collapse = "\n"), call. = FALSE)
    }
    job_id <- stringr::str_extract(paste(out, collapse = " "), "\\b[0-9]+\\b")
    return(list(exit_code = status, job_id = job_id, submit_output = out))
  }
  out <- system2("bash", args = script_path, stdout = TRUE, stderr = TRUE)
  status <- attr(out, "status", exact = TRUE) %||% 0L
  if (status != 0L) {
    stop(paste(c("Script execution failed:", out), collapse = "\n"), call. = FALSE)
  }
  list(exit_code = status, job_id = NULL, submit_output = out)
}


#' Pipeline clumping
#'
#' @param parent_dir Path to `tidyGWAS::tidyGWAS()` output directory.
#' @param output_dir Optional custom output directory. Defaults to
#'   `<parent_dir>/analysis/clumping`.
#' @param write_script Should script be written to disk?
#' @param execute Should generated script be executed via `system2("bash", ...)`?
#' @param p1 Passed to PLINK `--clump-p1`.
#' @param p2 Passed to PLINK `--clump-p2`.
#' @param r2 Passed to PLINK `--clump-r2`.
#' @param kb Passed to PLINK `--clump-kb`.
#' @param schedule Optional schedule object (e.g. from `schedule_slurm()`).
#'   If `NULL`, no scheduler header is written and local bash execution is used.
#' @param prepare_inputs Should an input preparation step (e.g. `to_ma()`,
#'   `to_clumping()`) be included in the generated script? Defaults to `execute`.
#' @param check_paths Should required files and directories be validated before
#'   execution/submission? Defaults to `TRUE`.
#'
#' @return A list with script metadata.
#' @export
pipeline_clumping <- function(
    parent_dir,
    output_dir = NULL,
    write_script = TRUE,
    execute = FALSE,
    p1 = "5e-08",
    p2 = "5e-06",
    r2 = 0.1,
    kb = 3000,
    schedule = NULL,
    prepare_inputs = execute,
    check_paths = TRUE
){
  stopifnot(
    rlang::is_bool(write_script),
    rlang::is_bool(execute),
    rlang::is_bool(prepare_inputs),
    rlang::is_bool(check_paths)
  )

  cfg <- dsg_get_config()
  params <- parse_params()
  outdir <- dsg_method_output_dir(parent_dir, "clumping", output_dir)
  dsg_check_parent_dir(parent_dir)
  dsg_check_writable_dir(outdir)

  if (isTRUE(check_paths) && isTRUE(execute)) {
    dsg_check_clumping_assets(cfg, params)
  }

  container <- fs::path(cfg$container_dir, params$plink$container)
  bfile <- fs::path("/src", params$genome_refs$deep_1kg)
  gene_ref <- fs::path("/src", params$plink$gene_ref)
  sumstat <- fs::path("/mnt", "sumstats.tsv")

  clump_cmd <- glue::glue(
    "plink --bfile {bfile} ",
    "--clump {sumstat} ",
    "--out /mnt/clumps ",
    "--clump-p1 {p1} ",
    "--clump-p2 {p2} ",
    "--clump-r2 {r2} ",
    "--clump-kb {kb} ",
    "--clump-snp-field RSID ",
    "--clump-field P ",
    "--clump-range {gene_ref}"
  )

  clump <- dsg_build_apptainer_exec(
    command = clump_cmd,
    workdir = outdir,
    reference_dir = cfg$reference_dir,
    container = container
  )

  to_bed <- glue::glue(
    "R -e {shQuote(glue::glue(\"downstreamGWAS::ranges_to_bed('{outdir}')\"))}"
  )

  merge_cmd <- dsg_build_apptainer_exec(
    command = "/bin/bash -c \"bedtools merge -d 50000 -i /mnt/clumps.bed -c 4,5,6 -o sum,collapse,collapse > /mnt/merged_loci.bed\"",
    workdir = outdir,
    reference_dir = cfg$reference_dir,
    container = container
  )

  cleanup <- glue::glue("rm -f {shQuote(fs::path(outdir, 'sumstats.tsv'))}")

  munge <- if (isTRUE(prepare_inputs)) dsg_input_cmd_clumping(parent_dir, outdir) else NULL
  script <- c(
    dsg_script_preamble(
      cfg = cfg,
      schedule = schedule,
      default_slurm_output = fs::path(outdir, "slurm-%j.out")
    ),
    munge, clump, to_bed, merge_cmd, cleanup
  )

  dsg_finalize_pipeline(script, outdir, "pipeline_clumping.sh", write_script, execute, schedule)
}


#' Pipeline SBayesRC
#'
#' @param parent_dir Path to `tidyGWAS::tidyGWAS()` output directory.
#' @param output_dir Optional custom output directory. Defaults to
#'   `<parent_dir>/analysis/sbayesrc`.
#' @param write_script Should script be written to disk?
#' @param execute Should generated script be executed via `system2("bash", ...)`?
#' @param thread_rc Number of OMP threads for `SBayesRC::sbayesrc`.
#' @param thread_imp Number of OMP threads for `SBayesRC::impute`.
#' @param use_effective_n Passed to `to_ma()`.
#' @param schedule Optional schedule object (e.g. from `schedule_slurm()`).
#'   If `NULL`, no scheduler header is written and local bash execution is used.
#' @param prepare_inputs Should an input preparation step (e.g. `to_ma()`,
#'   `to_clumping()`) be included in the generated script? Defaults to `execute`.
#' @param check_paths Should required files and directories be validated before
#'   execution/submission? Defaults to `TRUE`.
#'
#' @return A list with script metadata.
#' @export
pipeline_sbayesrc <- function(
    parent_dir,
    output_dir = NULL,
    write_script = TRUE,
    execute = FALSE,
    thread_rc = 8,
    thread_imp = 4,
    use_effective_n = FALSE,
    schedule = NULL,
    prepare_inputs = execute,
    check_paths = TRUE
){
  stopifnot(
    rlang::is_bool(write_script),
    rlang::is_bool(execute),
    rlang::is_bool(prepare_inputs),
    rlang::is_bool(check_paths)
  )

  cfg <- dsg_get_config()
  params <- parse_params()
  outdir <- dsg_method_output_dir(parent_dir, "sbayesrc", output_dir)
  dsg_check_parent_dir(parent_dir)
  dsg_check_writable_dir(outdir)

  if (isTRUE(check_paths) && isTRUE(execute)) {
    dsg_check_sbayesrc_assets(cfg, params)
  }

  container <- fs::path(cfg$container_dir, params$sbayesrc$container)
  ma_file <- "/mnt/sumstats.ma"
  ldm <- fs::path("/src", params$sbayesrc$ldm)
  annot <- fs::path("/src", params$sbayesrc$annot)
  out_prefix <- "/mnt/sbrc"

  tidy_cmd <- dsg_build_apptainer_exec(
    command = glue::glue("R -e {shQuote(glue::glue(\"SBayesRC::tidy('{ma_file}',LDdir='{ldm}',output='{ma_file}')\"))}"),
    workdir = outdir,
    reference_dir = cfg$reference_dir,
    container = container
  )

  impute_cmd <- dsg_build_apptainer_exec(
    command = glue::glue("R -e {shQuote(glue::glue(\"SBayesRC::impute('{ma_file}',LDdir='{ldm}',output='{ma_file}')\"))}"),
    workdir = outdir,
    reference_dir = cfg$reference_dir,
    container = container,
    env = glue::glue("OMP_NUM_THREADS={thread_imp}")
  )

  rc_cmd <- dsg_build_apptainer_exec(
    command = glue::glue("R -e {shQuote(glue::glue(\"SBayesRC::sbayesrc('{ma_file}',LDdir='{ldm}',outPrefix='{out_prefix}', annot='{annot}')\"))}"),
    workdir = outdir,
    reference_dir = cfg$reference_dir,
    container = container,
    env = glue::glue("OMP_NUM_THREADS={thread_rc}")
  )

  gzip_cmd <- glue::glue("gzip -f {shQuote(fs::path(outdir, 'sbrc.txt'))}")
  cleanup <- c(
    glue::glue("rm -f {shQuote(outdir)}/*.rds"),
    glue::glue("rm -f {shQuote(outdir)}/sumstats.ma*"),
    glue::glue("rm -f {shQuote(outdir)}/sbrc_tune*"),
    glue::glue("rm -f {shQuote(outdir)}/sbrc.mcmcsamples*")
  )

  munge <- if (isTRUE(prepare_inputs)) dsg_input_cmd_sbayesrc(parent_dir, outdir, use_effective_n) else NULL
  script <- c(
    dsg_script_preamble(
      cfg = cfg,
      schedule = schedule,
      default_slurm_output = fs::path(outdir, "slurm-%j.out")
    ),
    munge, tidy_cmd, impute_cmd, rc_cmd, gzip_cmd, cleanup
  )

  dsg_finalize_pipeline(script, outdir, "pipeline_sbayesrc.sh", write_script, execute, schedule)
}


#' Pipeline SBayesS
#'
#' @param parent_dir Path to `tidyGWAS::tidyGWAS()` output directory.
#' @param output_dir Optional custom output directory. Defaults to
#'   `<parent_dir>/analysis/sbayess`.
#' @param write_script Should script be written to disk?
#' @param execute Should generated script be executed via `system2("bash", ...)`?
#' @param pi Passed to GCTB `--pi`.
#' @param hsq Passed to GCTB `--hsq`.
#' @param num_chains Passed to GCTB `--num-chains`.
#' @param chain_length Passed to GCTB `--chain-length`.
#' @param burn_in Passed to GCTB `--burn-in`.
#' @param seed Passed to GCTB `--seed`.
#' @param thread Passed to GCTB `--thread`.
#' @param use_effective_n Passed to `to_ma()`.
#' @param schedule Optional schedule object (e.g. from `schedule_slurm()`).
#'   If `NULL`, no scheduler header is written and local bash execution is used.
#' @param prepare_inputs Should an input preparation step (e.g. `to_ma()`,
#'   `to_clumping()`) be included in the generated script? Defaults to `execute`.
#' @param check_paths Should required files and directories be validated before
#'   execution/submission? Defaults to `TRUE`.
#'
#' @return A list with script metadata.
#' @export
pipeline_sbayess <- function(
    parent_dir,
    output_dir = NULL,
    write_script = TRUE,
    execute = FALSE,
    pi = "0.01",
    hsq = "0.5",
    num_chains = "4",
    chain_length = "25000",
    burn_in = "5000",
    seed = "2023",
    thread = "8",
    use_effective_n = FALSE,
    schedule = NULL,
    prepare_inputs = execute,
    check_paths = TRUE
){
  stopifnot(
    rlang::is_bool(write_script),
    rlang::is_bool(execute),
    rlang::is_bool(prepare_inputs),
    rlang::is_bool(check_paths)
  )

  cfg <- dsg_get_config()
  params <- parse_params()
  outdir <- dsg_method_output_dir(parent_dir, "sbayess", output_dir)
  dsg_check_parent_dir(parent_dir)
  dsg_check_writable_dir(outdir)

  if (isTRUE(check_paths) && isTRUE(execute)) {
    dsg_check_sbayess_assets(cfg, params)
  }

  container <- fs::path(cfg$container_dir, params$gctb$container)
  ldm <- fs::path("/src", params$gctb$ldm_s)
  ma_file <- "/mnt/sumstats.ma"
  out_prefix <- "/mnt/SbayesS"

  gctb_cmd <- glue::glue(
    "gctb --sbayes S ",
    "--gwas-summary {ma_file} ",
    "--ldm {ldm} ",
    "--out {out_prefix} ",
    "--pi {pi} ",
    "--num-chains {num_chains} ",
    "--hsq {hsq} ",
    "--chain-length {chain_length} ",
    "--burn-in {burn_in} ",
    "--seed {seed} ",
    "--thread {thread} ",
    "--no-mcmc-bin"
  )

  sbayes <- dsg_build_apptainer_exec(
    command = gctb_cmd,
    workdir = outdir,
    reference_dir = cfg$reference_dir,
    container = container
  )

  munge <- if (isTRUE(prepare_inputs)) dsg_input_cmd_sbayess(parent_dir, outdir, use_effective_n) else NULL
  script <- c(
    dsg_script_preamble(
      cfg = cfg,
      schedule = schedule,
      default_slurm_output = fs::path(outdir, "slurm-%j.out")
    ),
    munge, sbayes
  )

  dsg_finalize_pipeline(script, outdir, "pipeline_sbayess.sh", write_script, execute, schedule)
}
