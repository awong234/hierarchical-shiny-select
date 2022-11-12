library(duckdb)
library(DBI)
library(dplyr)

con = dbConnect(
    duckdb::duckdb(),
    'data_duck.db'
)

df = list(
    'colA' = character(0),
    'colB' = character(0),
    'colC' = character(0),
    'colD' = character(0),
    'colE' = character(0)
)
for (i in 1:5) {
    letter = LETTERS[i]
    df[[paste0("col", letter)]] = paste0(letter, 1:5)
}

df = expand.grid(df)
df = df |>
    filter(! (colA == "A1" & colB == "B1"),
           ! (colA == "A2" & colC == "C2"),
           ! (colA == "A3" & colD == "D3"),
           ! (colA == "A4" & colD == "E4"),
           ! (colB == "B1" & colC == "C1"),
           ! (colB == "B2" & colD == "D2"),
           ! (colB == "B3" & colE == "E3"),
           ! (colC == "C1" & colD == "D1"),
           ! (colC == "C2" & colE == "E2"),
           ! (colD == "D1" & colE == "E1")
           )
attr(df, 'out.attrs') = NULL
df_dup = replicate(n = 100000, df, simplify = FALSE)
df = bind_rows(df_dup)
dbWriteTable(con, "table", df, overwrite = TRUE)
dbDisconnect(con, shutdown = TRUE)
