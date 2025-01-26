if(!require(pacman)) {
    install.packages("pacman", dependencies = TRUE);
}
library(pacman)
p_load(shiny, bslib, ggplot2, terra, leaflet, viridis, DT)

fileInputCustom <- function(inputId, label, value = 0) {
  tags$div(
    class = "form-group shiny-input-container",
    tags$label(label, `for` = inputId),
    tags$input(id = inputId, type = "file", class = "form-control", value = value)
  )
}

activeLayerIndex <- 1

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
    DTOutput("names"),
    width = 325,
    padding = 8
  ),
  htmlOutput("text"),
  leafletOutput("rastermap")
)

# Define server
server <- function(input, output, session) {
  observe({
    req(input$upload)
    print(input$upload)
  })
  
  # div para não sofrer a estilização "flex column" e HTML para renderizar o texto em negrito
  output$text <- renderUI({ 
    HTML("Select a NetCDF file to visualize a layer")
  })
# pelo visto nao da pra ter 2 renders no mesmo output. como seria feito? depois farei tudo dentro de um observe imagino,
  # sera que funcionaria?
  output$text <- renderUI({ 
    req(input$upload)
    terra_raster <- terra::rast(input$upload$datapath)
    layer_name <- names(terra_raster)[[activeLayerIndex]]
    
    tags$div(HTML(paste0("Plotting layer <b>", layer_name, "</b>")))
  })
  
  output$rastermap <- renderLeaflet({
    req(input$upload)
    terra_raster <- terra::rast(input$upload$datapath)[[activeLayerIndex]] # apenas primeira camada
    terra_raster[terra_raster > 10000] <- NA

    pal <- colorNumeric(palette = "viridis", domain = values(terra_raster), na.color = NA)
    
    leaflet() %>%
      addProviderTiles("OpenStreetMap") %>%
      addRasterImage(terra_raster, colors = pal, opacity = 0.8) %>%
      addLegend(pal = pal, values = values(terra_raster), title = "Raster Values") %>%
      addControl("Raster Values", position = "bottomright") # %>%
      # setMaxBounds(-180, -90, 180, 90)
  })
  
  output$names <- renderDT({
    req(input$upload)
    terra_raster <- terra::rast(input$upload$datapath)
    
    # Extract time values and convert to day-month-year format
    time_values <- time(terra_raster)
    formatted_time <- format(as.POSIXct(time_values, origin = "1970-01-01"), "%d/%m/%Y")

    raster_info <- cbind(names(terra_raster), formatted_time, varnames(terra_raster), units(terra_raster))
    colnames(raster_info) <- c("Layer", "Time", "Variable", "Unit")

    datatable(
      raster_info,
      selection = list(mode="single", selected = 1),
      options = list(dom = 't')
    )
  })
}

options(shiny.maxRequestSize = 500 * 1024^2)

# Create a Shiny app object
shinyApp(ui = ui, server = server)