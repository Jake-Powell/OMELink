# Compute Partial and Fuzzy Matching Signals for a Single Name

Compares a single input name to a vector of candidate names and returns
several matching signals. These include exact string match, token
overlap, prefix matching, substring matching, initial matching, and
token-based Jaro-Winkler fuzzy similarity.

## Usage

``` r
partial_fuzzy_match(name, all_names, do_clean_name = FALSE)
```

## Arguments

- name:

  Character scalar. A single name to match.

- all_names:

  Character vector of candidate names to compare against.

- do_clean_name:

  Logical; if `TRUE`, applies
  [`clean_name()`](https://jake-powell.github.io/OMELink/reference/clean_name.md)
  to `name` and `all_names` before matching.

## Value

A data frame with one row per element of `all_names` and the following
columns:

- given_name:

  The input `name`.

- data_name:

  The candidate name from `all_names`.

- exact:

  Logical; exact full-string match.

- exact_token:

  Logical; at least one token matches exactly.

- partial_start:

  Logical; at least one token matches at the start of a token in either
  direction.

- partial_anywhere:

  Logical; at least one token matches anywhere within a token in either
  direction.

- initial_token:

  Logical; at least one token shares an initial.

- fuzzy:

  Numeric token-based Jaro-Winkler similarity between `0` and `1`.

## Details

This function is designed to support downstream person linkage workflows
where first and last names are scored separately and then combined.

## Examples

``` r
all_names = c("MATTHEW", "MATT", "MARK", "JANET")
partial_fuzzy_match("Matt", all_names)
#>         given_name data_name exact exact_token partial_start partial_anywhere
#> MATTHEW       Matt   MATTHEW FALSE       FALSE          TRUE             TRUE
#> MATT          Matt      MATT FALSE       FALSE          TRUE             TRUE
#> MARK          Matt      MARK FALSE       FALSE         FALSE            FALSE
#> JANET         Matt     JANET FALSE       FALSE         FALSE            FALSE
#>         initial_token     fuzzy
#> MATTHEW          TRUE 0.8571429
#> MATT             TRUE 1.0000000
#> MARK             TRUE 0.6666667
#> JANET           FALSE 0.6333333
```
