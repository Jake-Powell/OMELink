# Clean names

Clean names

## Usage

``` r
clean_name(x, rm_whit = F)
```

## Arguments

- x:

  name to clean

- rm_whit:

  Flag (TRUE/FALSE) for whether whitespace wants to be removed from the
  names

## Value

cleaned name

## Details

"Cleans" name by changing to lower case and translating to Latin-ASCII
(i.e removing accents, etc). Can also remove whitespace by setting
rm_whit = T.

## Examples

``` r
 clean_name('John Leonard Knapp')
#> [1] "john leonard knapp"
 clean_name('Pierre-Joseph Redouté')
#> [1] "pierre-joseph redoute"
```
