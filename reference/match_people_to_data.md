# Match Multiple People to Grouped Data

Matches a set of individuals (first and last names in a data frame) to a
target dataset, optionally within groupings such as teams, departments,
or expeditions. This is a batch version of
\`match_person_to_grouped_data()\`.

## Usage

``` r
match_people_to_data(
  to_match,
  data,
  FN_column = "FN",
  LN_column = "LN",
  UPI_column = "UPI",
  group_column = NULL,
  group_value = NULL,
  max_dist = 2,
  method = "osa",
  show_all_fuzzy = FALSE,
  to_match_FN_column = FN_column,
  to_match_LN_column = LN_column,
  to_match_group_column = group_column,
  include_non_matched = FALSE,
  verbose = T,
  ...
)
```

## Arguments

- to_match:

  A data frame of people to match, with at least first and last name
  columns.

- data:

  A data frame containing the reference data to match against (must
  contain names, UPI, and optional group column).

- FN_column:

  Column name for first names in \`data\` (default: \`"FN"\`).

- LN_column:

  Column name for last names in \`data\` (default: \`"LN"\`).

- UPI_column:

  Column name for Unique Person Identifier in \`data\` (default:
  \`"UPI"\`).

- group_column:

  Optional. Column name in \`data\` representing a grouping (e.g.,
  Department, Team).

- group_value:

  Optional. If specified, filters \`data\` to just this group before
  matching.

- max_dist:

  Maximum allowed string distance for fuzzy matching (default: \`2\`).

- method:

  Method used for computing string distance. Passed to
  \`stringdist::stringdist()\` (default: \`"osa"\`).

- show_all_fuzzy:

  Logical; if \`TRUE\`, shows all fuzzy matches instead of just the best
  (default: \`FALSE\`).

- to_match_FN_column:

  Column name for first names in the \`to_match\` data frame (default:
  same as \`FN_column\`).

- to_match_LN_column:

  Column name for last names in \`to_match\` (default: same as
  \`LN_column\`).

- to_match_group_column:

  Column name in \`to_match\` that specifies the group (if applicable).
  Used only when \`group_column\` is also specified.

- include_non_matched:

  Logical; if \`TRUE\`, includes rows from \`to_match\` even if no match
  is found (default: \`FALSE\`).

- verbose:

  Logical; if \`TRUE\`, include console messaging.

- ...:

  Additional arguments passed to \`clean_name()\` or internal matching
  functions.

## Value

A data frame of matched people. Includes input first and last names as
\`inputFN\` and \`inputLN\`. If \`include_non_matched = TRUE\`, rows
with no match will still be returned (likely with NAs).

## Examples

``` r
## ---- Basic matching ----

to_match <- data.frame(
  FN = c("Karl", "Janet"),
  LN = c("Linnaeus", "Brown"),
  stringsAsFactors = FALSE
)

botanist_db <- data.frame(
  UPI = c("CL001", "JB002", "AH003", "AA004", "JB003", "GB004"),
  FN = c("Carl---Karl", "Joseph", "Alexander---Alex", "Agnes", "Janet", "George"),
  LN = c("Linnaeus---Linnaeus",
   "Banks",
    "von Humboldt---von Humboldt",
     "Arber",
      "Browne",
       "Bentham"),
  Expedition = c("Sweden", "Endeavour", "South America", "UK", "UK", "Australia"),
  stringsAsFactors = FALSE
)

result <- match_people_to_data(
  to_match = to_match,
  data = botanist_db
)

result
#>        FN       LN  Method NameDB_UPI NameDB_FN NameDB_LN NameDB_Expedition
#> 1.1  Karl Linnaeus   EXACT      CL001      karl  linnaeus            Sweden
#> 5   Janet    Brown FN only      JB003     janet    browne                UK

## ---- Grouped matching ----

to_match_grouped <- data.frame(
  FN = c("Janet", "Alexander"),
  LN = c("Brown", "von Humboldt"),
  Expedition = c("UK", "South America"),
  stringsAsFactors = FALSE
)

grouped_result <- match_people_to_data(
  to_match = to_match_grouped,
  data = botanist_db,
  group_column = "Expedition",
  to_match_group_column = "Expedition"
)

grouped_result
#>          FN           LN    Expedition  Method NameDB_UPI NameDB_FN
#> 5     Janet        Brown            UK FN only      JB003     janet
#> 3 Alexander von Humboldt South America   EXACT      AH003 alexander
#>      NameDB_LN NameDB_Expedition
#> 5       browne                UK
#> 3 von humboldt     South America
```
