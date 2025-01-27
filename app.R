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
  leafletOutput("rastermap")
)

# activeLayerIndex <- 1

# Define server
server <- function(input, output, session) {
  observe({
    req(input$upload)
    print(input$upload)
  })
  
  # sera que eu poderia usar o mesmo raster como variável? Ou teria que ler o caminho do arquivo e carregá-lo novamente?
  # por enquanto vou fazer o jeito preguiçoso, mas considerar melhorar depois, pra usar o mesmo raster já
  observeEvent(input$names_rows_selected, {
    
    # if(activeLayerIndex==input$names_rows_selected)
    # se o cara fez isso o cara é burro, simples, mas considerar adicionar depois (por isso a variavel la em cima
    # ta comentada)
    
    # print(input$names_rows_selected)
    activeLayerIndex <- input$names_rows_selected
    
    output$rastermap <- renderLeaflet({
      req(input$upload)
      terra_raster <- terra::rast(input$upload$datapath)[[activeLayerIndex]] # apenas primeira camada
      terra_raster[terra_raster > 10000] <- NA
      
      pal <- colorNumeric(palette = "viridis", domain = values(terra_raster), na.color = NA)
      
      leaflet() %>%
        addProviderTiles("OpenStreetMap") %>%
        addRasterImage(terra_raster, colors = pal, opacity = 0.8) %>%
        addLegend(pal = pal, values = values(terra_raster), title = "Raster Values") %>%
        addControl(
          tags$div(
            # o raster passado para a tabela é o inteiro, mas aqui ele só tem 1 camada, já esta sendo cortado acima
            HTML(paste0('<h3> Plotting layer <b>', names(terra_raster)[[1]], '</b></h3>'))
          ), position = "bottomright")
    })
  })
  # acho que não é preciso o renderleaflet isolado quando todas as vezes que irei querer renderizar é quando
  # alguma linha na tabela é selecionada
  # da pra ver que isso deixa bem mais lento na 1 vez. mas por enquanto deixarei assim
  
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