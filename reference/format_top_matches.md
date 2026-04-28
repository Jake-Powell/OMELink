# Format Top Candidate Matches for Manual Review

Creates a single character string summarising the top candidate matches,
one per line, for manual review.

## Usage

``` r
format_top_matches(df, UPI_column, FN_column, LN_column, n = 5, digits = 3)
```

## Arguments

- df:

  Ranked candidate match data frame.

- UPI_column:

  Character scalar. Name of the unique identifier column.

- FN_column:

  Character scalar. Name of the first-name column.

- LN_column:

  Character scalar. Name of the last-name column.

- n:

  Integer. Number of top candidates to include.

- digits:

  Integer. Number of decimal places to display for confidence.

## Value

Character scalar containing top candidates separated by newline
characters, or `NA_character_` if `df` has no rows.

## Examples

``` r
df = data.frame(
  UPI = c("A", "B"),
  FN = c("MATTHEW", "MARK"),
  LN = c("JONES", "SMITH"),
  match_confidence = c(0.95, 0.62),
  stringsAsFactors = FALSE
)

format_top_matches(df, "UPI", "FN", "LN", n = 2)
#> [1] "A: MATTHEW JONES = 0.950\nB: MARK SMITH = 0.620"
```
