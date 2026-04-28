# Compute Token-Based Jaro-Winkler Name Similarity

Computes a similarity score between two names using token-level
Jaro-Winkler similarity. Names are first standardised to upper case,
punctuation is removed, and the strings are split into tokens. A
similarity matrix is then formed between tokens in each name, and for
each token in the longer name the best match in the shorter name is
taken. The final score is the mean of these best matches.

## Usage

``` r
name_similarity_jw(x, y)
```

## Arguments

- x:

  Character string. First name string to compare.

- y:

  Character string. Second name string to compare.

## Value

Numeric scalar between `0` and `1`, or `NA_real_` if either name has no
valid tokens after cleaning.

## Details

This returns a value between `0` and `1`, where:

- `1` indicates an exact token-level match

- values closer to `0` indicate weaker similarity

## Examples

``` r
name_similarity_jw("Matthew", "Matt")
#> [1] 0.8571429
name_similarity_jw("Janet Brown", "Janet Browne")
#> [1] 0.9722222
```
