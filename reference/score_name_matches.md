# Score Combined First-Name and Last-Name Matches

Combines separate first-name and last-name matching signals into a
single composite score and a scaled confidence measure between `0` and
`1`.

## Usage

``` r
score_name_matches(
  partial_matching,
  w_exact_both = 5,
  w_exact_token_both = 3,
  w_partial_start_both = 2,
  w_partial_anywhere_both = 1,
  w_initial_both = 0.5,
  w_fuzzy_mean = 3
)
```

## Arguments

- partial_matching:

  Data frame returned by
  [`matching_breakdown()`](https://jake-powell.github.io/OMELink/reference/matching_breakdown.md).

- w_exact_both:

  Numeric weight applied when both first and last names exactly match.

- w_exact_token_both:

  Numeric weight applied when both first and last names have exact token
  matches.

- w_partial_start_both:

  Numeric weight applied when both first and last names partially match
  at the start of a token.

- w_partial_anywhere_both:

  Numeric weight applied when both first and last names partially match
  anywhere within a token.

- w_initial_both:

  Numeric weight applied when both first and last names share token
  initials.

- w_fuzzy_mean:

  Numeric weight applied to the mean first-name and last-name fuzzy
  similarity.

## Value

The input data frame with additional columns:

- mean_fuzzy:

  Mean of `FN_fuzzy` and `LN_fuzzy`.

- match_score:

  Composite matching score.

- match_confidence:

  Scaled confidence between `0` and `1`.

## Details

The score is heuristic rather than probabilistic. It is intended to rank
candidate matches and provide an interpretable confidence-like measure.

## Examples

``` r
people = data.frame(
  FN = c("MATTHEW", "MATT"),
  LN = c("JONES", "JONES"),
  stringsAsFactors = FALSE
)

x = matching_breakdown("Matt", "Jones", people, "FN", "LN")
score_name_matches(x)
#>              FN    LN FN_given_name FN_data_name FN_exact FN_exact_token
#> MATTHEW MATTHEW JONES          Matt      MATTHEW    FALSE          FALSE
#> MATT       MATT JONES          Matt         MATT    FALSE          FALSE
#>         FN_partial_start FN_partial_anywhere FN_initial_token  FN_fuzzy
#> MATTHEW             TRUE                TRUE             TRUE 0.8571429
#> MATT                TRUE                TRUE             TRUE 1.0000000
#>         LN_given_name LN_data_name LN_exact LN_exact_token LN_partial_start
#> MATTHEW         Jones        JONES    FALSE          FALSE             TRUE
#> MATT            Jones        JONES    FALSE          FALSE             TRUE
#>         LN_partial_anywhere LN_initial_token LN_fuzzy mean_fuzzy match_score
#> MATTHEW                TRUE             TRUE        1  0.9285714    6.285714
#> MATT                   TRUE             TRUE        1  1.0000000    6.500000
#>         match_confidence
#> MATTHEW        0.4334975
#> MATT           0.4482759
```
