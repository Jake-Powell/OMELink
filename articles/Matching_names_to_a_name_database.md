# Case Study: Matching names to a name database

``` r
library(OMELink)
```

**In this document we will provide a run through of how to match names
to a name database and perform some checks.**

The setup of this example is we have a list of individuals we want to
match to our name database and either extract a unique reference to an
individual or add them to the database.

``` r
to_match = data.frame(FN = c('Karl', 'Janet'),
                      LN = c('Linnaeus', 'Brown'))

botanist_db =  data.frame(
  UPI = c("CL001", "JB002", "AH003", "AA004", "JB003", "GB004"),
  FN = c("Carl---Karl", "Joseph", "Alexander---Alex", "Agnes", "Janet", "George"),
  LN = c("Linnaeus---Linnaeus", "Banks", "von Humboldt---von Humboldt", "Arber", "Browne", "Bentham"),
  Expedition = c("Sweden", "Endeavour", "South America", "UK", "UK", "Australia"),
  
  stringsAsFactors = FALSE
)

# Show data
to_match |> DT::datatable(rownames = F)
```

``` r
botanist_db |> DT::datatable(rownames = F)
```

## TL:DR - matching all names

First we want to attempt matching all names in `to_match` to
`botanist_db` we can do this with the
[`match_people_to_data()`](https://jake-powell.github.io/OMELink/reference/match_people_to_data.md)
function by the following

``` r
result = match_people_to_data(to_match = to_match, data = botanist_db)
 
# Show outcome
result |> DT::datatable(rownames = F)
```

We see that the output is the names provided in `to_match` appended with
the match method and all columns from botanist_db. From this we can use
the method variable to check the confidence of matches. Note that for
names with multiple options only the name used in the matching is
reported in the output.

## 
