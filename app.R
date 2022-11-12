library(shiny)
library(logger)
library(dplyr)
library(RSQLite)
library(DBI)

# local(source("create_data.R", local = TRUE))

logger::log_threshold(DEBUG)

con = dbConnect(
    duckdb::duckdb(),
    'data_duck.db'
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
        shiny::p("Data are structured this way so that most selectors must update something on each input."),
        shiny::verbatimTextOutput('stack')

    )
)

server <- function(input, output, session) {
    output$str_df = renderPrint({
        df |> head() |> collect() |> str()
    })
    output$total_rows = renderText({
        nrows = df |> count() |> collect() |> pull(n)
        size = fs::dir_info(glob = "data_duck.db")[['size']]
        paste0("Dataset has ", format(nrows, big.mark = ","), " rows (", size, " on disk)")
    })
    output$stack = renderText({
        paste0("Order of events\n", paste0("Update ", stack(), collapse = "\n"))
    })
    stack = reactiveVal('start')
    push = function(stack, add) {
        c(stack(), add)
    }
    log_event = function(letter, stack) {
        last_stack = tail(stack(), 1)
        log_debug("Getting unique col{letter} to set selectInput choices: coming from {last_stack}")
    }
    valid_sel = function(value, valid_values) {
        value_valid = value %in% valid_values
        if (isTRUE(value_valid)) {
            selection = value
        } else {
            selection = valid_values[1]
        }
        return(selection)
    }

    # Reactive to obtain data at A level
    A_lvl = reactive({
        log_trace("Filtering colA")
        df |> filter(colA == !!input$colA)
    })
    # Reactive to obtain data at A-B level
    B_lvl = reactive({
        log_trace("Filtering colB")
        A_lvl() |> filter(colB == !!input$colB)
    })
    # Reactive to obtain data at A-B-C level
    C_lvl = reactive({
        log_trace("Filtering colC")
        B_lvl() |> filter(colC == !!input$colC)
    })
    # Reactive to obtain data at A-B-C-D level
    D_lvl = reactive({
        log_trace("Filtering colD")
        C_lvl() |> filter(colD == !!input$colD)
    })

    update_defaults = function() {
        log_debug("UPDATING DEFAULTS")
        updateSelectInput(session, 'colA', choices = paste0("A", 1:5), selected = "A1")
        updateSelectInput(session, 'colB', choices = paste0("B", 1:5), selected = "B2")
        updateSelectInput(session, 'colC', choices = paste0("C", 1:5), selected = "C3")
        updateSelectInput(session, 'colD', choices = paste0("D", 1:5), selected = "D4")
        updateSelectInput(session, 'colE', choices = paste0("E", 1:5), selected = "E5")
    }

    update_defaults()

    # Set choices for B
    observeEvent(A_lvl(), {
        log_event("B", stack)
        stack(push(stack, "B"))
        validate(need(input$colB, label = "colB"))
        value = input$colB
        choices = A_lvl() |> distinct(colB) |> collect() |> pull() |> sort()
        selection = valid_sel(value, choices)
        updateSelectInput(session, 'colB', choices = choices, selected = selection)
    })
    # Set choices for C
    observeEvent(B_lvl(), {
        log_event("C", stack)
        stack(push(stack, "C"))
        validate(need(input$colC, label = "colB"))
        value = input$colC
        choices = B_lvl() |> distinct(colC) |> collect() |> pull() |> sort()
        selection = valid_sel(value, choices)
        updateSelectInput(session, 'colC', choices = choices, selected = selection)
    })
    # Set choices for D
    observeEvent(C_lvl(), {
        log_event("D", stack)
        stack(push(stack, "D"))
        validate(need(input$colB, label = "colB"))
        value = input$colB
        choices = C_lvl() |> distinct(colD) |> collect() |> pull() |> sort()
        selection = valid_sel(value, choices)
        updateSelectInput(session, 'colD', choices = choices, selected = selection)
    })
    # Set choices for E
    observeEvent(D_lvl(), {
        log_event("E", stack)
        stack(push(stack, "E"))
        validate(need(input$colB, label = "colB"))
        value = input$colB
        choices = D_lvl() |> distinct(colE) |> collect() |> pull() |> sort()
        selection = valid_sel(value, choices)
        updateSelectInput(session, 'colE', choices = choices, selected = selection)
    })


}

shinyApp(ui, server)
