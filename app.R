if(!require(pacman)) {
    install.packages("pacman", dependencies = TRUE);
}
library(pacman)
p_load(shiny, bslib, ggplot2, terra, ncdf4)

# Define UI
ui <- page_sidebar(
  title = "Raster View",
  sidebar = sidebar(
    fileInput("upload", "Select a File: "),
    tableOutput("names")
  ),
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
    terra::plot(terra_raster[[1]])
  })
  
  output$names <- renderTable({
    req(input$upload)
    terra_raster <- terra::rast(input$upload$datapath)
    names(terra_raster)
  })
}

# options(shiny.maxRequestSize = 500 * 1024^2)

# Create a Shiny app object
shinyApp(ui = ui, server = server)