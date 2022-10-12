# Sample shiny app for hierarchical input selection

The book "Mastering Shiny" has a section on hierarchical select boxes, for the
purpose of drilling down into a dataset across multiple categories. This is
described
[here](https://mastering-shiny.org/action-dynamic.html#hierarchical-select).

The structure here reproduces that strategy, but with a larger dataset, with
both more rows and more columns than shown in the example.

In addition, logging is added to each reactive context, to identify when and
how often each item runs.

## My issue with the strategy

With larger data, this strategy is fairly slow. 

On launch, the app needs to set a value for colA, and in so doing, discover what values are valid for colB. The order of events _ought_ to be like so:

```
Initialize value for colA.
Find valid values for colB given colA; set value for selectInput.
Find valid values for colC given colB; set value for selectInput.
Find valid values for colD given colC; set value for selectInput.
Find valid values for colE given colD; set value for selectInput.
End.
```

But instead, the output looks like this on startup:

```
DEBUG [2022-10-11 23:53:41] Filtering colA
DEBUG [2022-10-11 23:53:41] Getting unique colB
DEBUG [2022-10-11 23:53:41] Filtering colB
DEBUG [2022-10-11 23:53:41] Getting unique colC
DEBUG [2022-10-11 23:53:41] Filtering colC
DEBUG [2022-10-11 23:53:41] Getting unique colD
DEBUG [2022-10-11 23:53:41] Filtering colD
DEBUG [2022-10-11 23:53:41] Getting unique colE
DEBUG [2022-10-11 23:53:42] Filtering colB
DEBUG [2022-10-11 23:53:42] Getting unique colC
DEBUG [2022-10-11 23:53:42] Filtering colC
DEBUG [2022-10-11 23:53:42] Getting unique colD
DEBUG [2022-10-11 23:53:42] Filtering colD
DEBUG [2022-10-11 23:53:42] Getting unique colE
DEBUG [2022-10-11 23:53:42] Filtering colC
DEBUG [2022-10-11 23:53:42] Getting unique colD
DEBUG [2022-10-11 23:53:42] Filtering colD
DEBUG [2022-10-11 23:53:42] Getting unique colE
DEBUG [2022-10-11 23:53:42] Filtering colD
DEBUG [2022-10-11 23:53:42] Getting unique colE
```

Each input triggers refresh of the inputs below it in the hierarchy, such that
colE (which is last in the hierarchy) ends up getting refreshed four times (and
the data are filtered on the value in colD 4 times).

**Is there a better scheme that minimizes how many inputs need to be refreshed in
the hierarchy?**

I've attempted instead to use a combination of `renderUI` and `uiOutput`, and on
each `renderUI` instance, setting `bindEvent` to the category above it in the
hierarchy (to be displayed in `app2.R` when ready). This solution is faster, but
has its own problems; if a value is valid for, say colB, when colA is changed,
anything dependent on colB further down the hierarchy will not refresh and we
end up with potentially invalid levels for C, D, and E.


## Running the app

The project dependencies are defined by renv; use `renv::restore()` to install
all relevant packages.

The app is contained in the `app1.R` file; source this file to run. `app1.R`
itself will source the script to create the data before launching the shiny
app. A file `data.db` will be generated, about 600MB in size.
