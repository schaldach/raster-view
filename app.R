if(!require(pacman)) {
    install.packages("pacman", dependencies = TRUE);
}
library(pacman)
p_load(shiny, bslib, ggplot2, terra)

# Define UI
ui <- fluidPage(
  tags$head(
    tags$script(src = "customFileInput.js") # Include the JavaScript file
  ),
  fileInput("upload", "Select a File: "),
  imageOutput("files")
)

# Define server
server <- function(input, output, session) {
  observe({
    req(input$upload)
    print(input$upload)
  })
  
  output$files <- renderPlot({
    req(input$upload)
    terra_raster <- terra::rast(input$upload$datapath)
    terra_raster[terra_raster > 10000] <- NA
    terra::plot(terra_raster)
  })
}

# options(shiny.maxRequestSize = 500 * 1024^2)

# Create a Shiny app object
shinyApp(ui = ui, server = server)