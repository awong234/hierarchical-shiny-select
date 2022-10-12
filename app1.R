library(shiny)
library(logger)
library(dplyr)
library(RSQLite)
library(DBI)

local(source("create_data.R", local = TRUE))

logger::log_threshold(DEBUG)

con = dbConnect(
    RSQLite::SQLite(),
    'data.db'
)

df = tbl(con, 'table')

ui <- fluidPage(
    shiny::sidebarPanel(
        shiny::selectInput('colA', 'colA', choices = df |> distinct(colA) |> collect() |> pull(), multiple = FALSE),
        shiny::selectInput('colB', 'colB', choices = NULL, multiple = FALSE),
        shiny::selectInput('colC', 'colC', choices = NULL, multiple = FALSE),
        shiny::selectInput('colD', 'colD', choices = NULL, multiple = FALSE),
        shiny::selectInput('colE', 'colE', choices = NULL, multiple = FALSE)
    ),
    shiny::mainPanel(
        shiny::h1("Data qualities."),
        shiny::h2("Structure (first 6 rows)"),
        shiny::verbatimTextOutput('str_df'),
        shiny::textOutput('total_rows'),
        shiny::br(),
        shiny::h2("Characteristics"),
        shiny::fluidRow(
            shiny::column(3,
                          shiny::p("Class A1 lacks B1."),
                          shiny::p("Class A2 lacks C2."),
                          shiny::p("Class A3 lacks D3."),
                          shiny::p("Class A4 lacks E4.")
                          ),
            shiny::column(3,
                          shiny::p("Class B1 lacks C1."),
                          shiny::p("Class B2 lacks D2."),
                          shiny::p("Class B3 lacks E3.")
                          ),
            shiny::column(3,
                          shiny::p("Class C1 lacks D1."),
                          shiny::p("Class C2 lacks E2.")
                          ),
            shiny::column(3, shiny::p("Class D1 lacks E1."))
        ),
        shiny::p("Data are structured this way so that most selectors must update something on each input.")

    )
)

server <- function(input, output, session) {
    output$str_df = renderPrint({
        df |> head() |> collect() |> str()
    })
    output$total_rows = renderText({
        nrows = df |> count() |> collect() |> pull(n)
        size = fs::dir_info(glob = "data.db")[['size']]
        paste0("Dataset has ", nrows, " rows (", size, " on disk)")
    })
    # Reactive to obtain data at A level
    A_lvl = reactive({
        log_debug("Filtering colA")
        df |> filter(colA == !!input$colA)
    })
    # Set choices for B
    observeEvent(A_lvl(), {
        log_debug("Getting unique colB")
        choices = A_lvl() |> distinct(colB) |> collect() |> pull() |> sort()
        updateSelectInput(session, 'colB', choices = choices)
    })
    # Reactive to obtain data at A-B level
    B_lvl = reactive({
        log_debug("Filtering colB")
        A_lvl() |> filter(colB == !!input$colB)
    })
    # Set choices for C
    observeEvent(B_lvl(), {
        log_debug("Getting unique colC")
        choices = B_lvl() |> distinct(colC) |> collect() |> pull() |> sort()
        updateSelectInput(session, 'colC', choices = choices)
    })
    # Reactive to obtain data at A-B-C level
    C_lvl = reactive({
        log_debug("Filtering colC")
        B_lvl() |> filter(colC == !!input$colC)
    })
    # Set choices for D
    observeEvent(C_lvl(), {
        log_debug("Getting unique colD")
        choices = C_lvl() |> distinct(colD) |> collect() |> pull() |> sort()
        updateSelectInput(session, 'colD', choices = choices)
    })
    # Reactive to obtain data at A-B-C-D level
    D_lvl = reactive({
        log_debug("Filtering colD")
        C_lvl() |> filter(colD == !!input$colD)
    })
    # Set choices for E
    observeEvent(D_lvl(), {
        log_debug("Getting unique colE")
        choices = D_lvl() |> distinct(colE) |> collect() |> pull() |> sort()
        updateSelectInput(session, 'colE', choices = choices)
    })


}

shinyApp(ui, server)
