# Link School Names to an Establishment List

Matches school names from an input dataset to a reference establishment
list using a combination of exact and token-based matching methods.

## Usage

``` r
link_establishment(
  data,
  establishment_list,
  school_name_column,
  ID_column = "EstablishmentID",
  token_match = "exact",
  get_token_weights = function(tokens) rep(1, length(tokens))
)
```

## Arguments

- data:

  Data frame containing school names to be matched.

- establishment_list:

  Data frame of known establishments. Must contain columns
  `EstablishmentName` and the specified `ID_column`.

- school_name_column:

  Character string. Name of the column in `data` containing school
  names.

- ID_column:

  Character string. Name of the column in `establishment_list`
  containing the establishment identifier. Default is
  `"EstablishmentID"`.

- token_match:

  Character string specifying the token matching method. One of
  `"exact"`, `"partial"`, or `"fuzzy"`.

- get_token_weights:

  Function that takes a character vector of tokens and returns a numeric
  vector of weights of the same length. Defaults to equal weighting for
  all tokens.

## Value

A data frame with the following columns:

- `match_index` Index of the matched establishment in
  `establishment_list`. Set to `NA` when multiple matches exist, and
  `-1` when no valid school name is provided.

- `original_name` Original input school name.

- `match_name` Matched establishment name(s) formatted as `"ID: Name"`.
  Multiple matches are separated by newline characters.

- `establishment_ID` Matched establishment ID when a single match
  exists, otherwise `NA`.

- `match_method` Method used for matching (e.g. `"exact"`,
  `"token_exact"`, `"token_partial"`, `"token_fuzzy"`, or
  `"NO SCHOOL NAME PROVIDED"`).

- `match_score` Matching score (token-based methods only; exact matches
  are assigned `Inf`).

- `n_matches` Number of matched establishments.

## Details

The matching process proceeds in stages:

- School names are cleaned using
  [`clean_school_name`](https://jake-powell.github.io/OMELink/reference/clean_school_name.md).

- Missing or empty names are flagged and not matched.

- Exact matching is attempted first on cleaned names.

- Remaining records are matched using token-based methods.

Token matching compares words (tokens) in the input name against those
in establishment names. Matching can be:

- Exact token matching

- Partial matching using
  [`stringr::str_detect()`](https://stringr.tidyverse.org/reference/str_detect.html)

- Fuzzy matching using
  [`stringdist::stringdist()`](https://rdrr.io/pkg/stringdist/man/stringdist.html)

Token weights can be customised via `get_token_weights`, allowing common
or uninformative words (e.g. "school", "academy") to be downweighted.

When multiple establishments achieve the same best score, all are
returned in `match_name`, and `establishment_ID` is set to `NA`.

## Examples

``` r
df <- data.frame(School = c("St Inga's Primary School", "Ilex aquifolium Centre", NA))

establishments <- data.frame(
  EstablishmentName = c("St. Inga's Primary School",
   "Ilex aquifolium Academy",
   "The DS Maths School"),
  EstablishmentID = c(A, 1, 'I')
)
#> Error: object 'A' not found

link_establishment(
  data = df,
  establishment_list = establishments,
  school_name_column = "School"
)
#> Error: object 'establishments' not found
```
