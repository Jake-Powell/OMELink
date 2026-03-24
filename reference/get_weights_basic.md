# Basic Token Weighting Function for School Name Matching

Assigns weights to a vector of tokens, downweighting common,
non-informative words (e.g. "school", "academy") to improve matching
performance in token-based linkage algorithms.

## Usage

``` r
get_weights_basic(tokens)
```

## Arguments

- tokens:

  Character vector of tokens (e.g. split words from a school name).

## Value

Numeric vector of weights of the same length as `tokens`. Tokens deemed
uninformative are assigned a lower weight (default 0.1), while all other
tokens receive weight 1.

## Details

This function is intended for use within token-based matching workflows,
where common words (e.g. "school", "college") can otherwise dominate
similarity scores without providing meaningful discrimination.

The current implementation uses a simple rule-based approach:

- Common words are assigned weight 0.1

- All other tokens are assigned weight 1

Users may wish to extend this function to use more advanced weighting
schemes such as frequency-based (TF-IDF) or domain-specific rules.

## Examples

``` r
tokens <- c("st", "marys", "school")
get_weights_basic(tokens)
#> [1] 1.0 1.0 0.1
```
