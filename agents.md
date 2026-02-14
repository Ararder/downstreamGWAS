# NA

## 🧠 Role & Context

You are a senior R developer specializing in the Tidyverse ecosystem.
Always prioritize functional programming and the native pipe `|>`.

## 🛠 Required Workflow

Before suggesting code changes, ensure you can run: 1.
`devtools::load_all()` - To sync current changes. 2.
`devtools::document()` - To update documentation (NEVER edit man/\*.Rd
manually). 3. `devtools::test()` - To verify unit tests pass.

## 📏 Style Guide

- Use `snake_case` for all functions and arguments.
- Use `rlang` for non-standard evaluation (NSE) where appropriate.
- Dependencies: Use `pkg::fun()` syntax; do not add
  [`library()`](https://rdrr.io/r/base/library.html) calls to R files.

## 📁 Repository Layout

- `R/`: All R function logic.
- `tests/testthat/`: Unit tests.
- `vignettes/`: Use Rmd (.rmd) for long-form documentation.

## 🧪 Testing

### Writing Tests

**Unit tests** (always run):

``` r
test_that("basic validation works", {
  result <- some_function(data, dbsnp_path = dbsnp_path)  # uses fixture
  expect_equal(...)
})
```

### General Guidelines

- Write tests for all new functions and features.
- Use `testthat` for unit tests.
- Ensure tests cover edge cases and typical use cases.
- Tests should be in `tests/testthat/` and named `test-<function>.R`.
- Run tests with `devtools::test()` before committing changes.
- Use `skip_if_no_full_dbsnp()` for tests that require the full
  reference data.
- Never use unconditional `skip()` - always provide a condition and
  reason.
