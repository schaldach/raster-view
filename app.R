if(!require(pacman)) {
    install.packages("pacman", dependencies = TRUE);
}
library(pacman)
p_load(shiny, bslib, ggplot2, terra, leaflet, viridis)

fileInputCustom <- function(inputId, label, value = 0) {
  tags$div(
    class = "form-group shiny-input-container",
    tags$label(label, `for` = inputId),
    tags$input(id = inputId, type = "file", class = "form-control", value = value)
  )
}

# Define UI
ui <- page_sidebar(
  title = "Raster View",
  tags$head(
    tags$style(HTML("
      /* Disable padding on leaflet output */
      /* .main  { 
        padding: 0 !important; 
        margin: 0 !important; 
      } */
      
      /* Shrink table font size */
      #names table {
        font-size: 12px;
      }
    "))
  ),
  sidebar = sidebar(
    fileInput("upload", "Select a File: "),
    tableOutput("names"),
    width = 325,
    padding = 8
  ),
  leafletOutput("rastermap")
)

# Define server
server <- function(input, output, session) {
  observe({
    req(input$upload)
    print(input$upload)
  })
  
  output$rastermap <- renderLeaflet({
    req(input$upload)
    terra_raster <- terra::rast(input$upload$datapath)[[1]] # apenas primeira camada
    terra_raster[terra_raster > 10000] <- NA

    pal <- colorNumeric(palette = "viridis", domain = values(terra_raster), na.color = NA)
    
    leaflet() %>%
      addProviderTiles("OpenStreetMap") %>%
      addRasterImage(terra_raster, colors = pal, opacity = 0.8) %>%
      addLegend(pal = pal, values = values(terra_raster), title = "Raster Values") %>%
      addControl("Raster Values", position = "bottomright") # %>%
      # setMaxBounds(-180, -90, 180, 90)
  })
  
  output$names <- renderTable({
    req(input$upload)
    terra_raster <- terra::rast(input$upload$datapath)
    
    # Extract time values and convert to day-month-year format
    time_values <- time(terra_raster)
    formatted_time <- format(as.POSIXct(time_values, origin = "1970-01-01"), "%d/%m/%Y")

    raster_info <- cbind(names(terra_raster), formatted_time, varnames(terra_raster), units(terra_raster))
    colnames(raster_info) <- c("Layer", "Time", "Variable", "Unit")
    raster_info
  })
}

options(shiny.maxRequestSize = 500 * 1024^2)

# Create a Shiny app object
shinyApp(ui = ui, server = server)