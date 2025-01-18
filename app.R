if(!require(pacman)) {
    install.packages("pacman", dependencies = TRUE);
}
library(pacman)
p_load(shiny, bslib, ggplot2, terra)

# Get the data

file <- "https://github.com/rstudio-education/shiny-course/raw/main/movies.RData"
destfile <- "movies.RData"

download.file(file, destfile)

# Load data

load("movies.RData")


fileInputCustom <- function(inputId, label) {
  tags$div(
    class = "form-group shiny-input-container",
    tags$label(label, `for` = inputId),
    tags$input(id = inputId, type = "file", class = "form-control")
  )
}


# Define UI

ui <- fluidPage(
  fileInput("upload", "Upload a file"),
  fileInputCustom("myFileInput", "Select a File: "),
  tableOutput("files"),
  tableOutput("files2")
)

# Define server

server <- function(input, output, session) {
  output$files <- renderTable(input$upload)
  
  rasterData <- reactive({
    req(input$myFileInput) # Ensure a file is uploaded before proceeding
    
    # Read the raster file using terra::rast
    print(input$myFileInput)
    #filePath <- input$myFileInput$datapath
    #terra::rast(filePath)
  })
  
  #terra_raster <- terra::rast(input$myFileInput$)
  #output$files2 <- terra::plot(terra_raster)
}

# Create a Shiny app object
options(shiny.maxRequestSize = 500 * 1024^2)

shinyApp(ui = ui, server = server)