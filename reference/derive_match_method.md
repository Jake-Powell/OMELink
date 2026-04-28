# Derive Human-Readable Match Method Labels

Converts combined first-name and last-name matching signals into a
simple text label describing the strongest observed matching mechanism.

## Usage

``` r
derive_match_method(df, fuzzy_only_threshold = 0.9)
```

## Arguments

- df:

  Data frame produced by
  [`score_name_matches()`](https://jake-powell.github.io/OMELink/reference/score_name_matches.md).

- fuzzy_only_threshold:

  Numeric threshold used to classify a candidate as `"FUZZY"` or
  `"INITIAL + FUZZY"` when no stronger signal is present.

## Value

Character vector of method labels, one per row.

## Examples

``` r
people = data.frame(
  FN = c("MATTHEW", "MATT"),
  LN = c("JONES", "JONES"),
  stringsAsFactors = FALSE
)

x = matching_breakdown("Matt", "Jones", people, "FN", "LN")
x = score_name_matches(x)
derive_match_method(x)
#> [1] "PARTIAL START" "PARTIAL START"
```
