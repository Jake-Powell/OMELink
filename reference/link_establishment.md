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
  token_method = "fuzzy",
  fuzzy_threshold = 0.5,
  get_token_weights = OMELink::get_weights_basic,
  keep_top_n = 3,
  min_score = 0.5
)
```

## Arguments

- data:

  Data frame containing school names to be matched.

- establishment_list:

  Data frame of known establishments. Must contain `EstablishmentName`
  and `ID_column`.

- school_name_column:

  Character string. Column in `data`.

- ID_column:

  Character string. ID column in establishment list.

- token_method:

  One of `"exact"`, `"partial"`, `"fuzzy"`.

- fuzzy_threshold:

  Numeric in \[0,1\] for fuzzy similarity cutoff.

- get_token_weights:

  Function returning weights per token.

- keep_top_n:

  Integer. Number of matches stored in `top_n_matches`.

- min_score:

  Numeric. Minimum score required to accept a match.

## Value

Data frame with match results and diagnostics.
