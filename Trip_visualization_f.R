############################################################################
############################################################################


# packages   <- c('shiny', 'shinydashboard', 'leaflet', 'data.table', "htmltools", "shinyWidgets"
#                 ,'leaflet.extras', 'rsconnect')
# 
# ### Install the packages ###
# if(length(setdiff(packages,rownames(installed.packages())))>0){
#   install.packages(setdiff(packages,rownames(installed.packages())), dependencies = T)
# }
# 
# ### Load the packages in R ###
# sapply(packages, require, character.only =T)



library(shiny)
library(shinydashboard)
library(leaflet)
library(data.table)
library(htmltools)
library(shinyWidgets)
library(rsconnect)


countries_data      <- fread("worldcities.csv")


### For handling error on Shiny app ###
options(shiny.sanitize.errors=TRUE)

############################################################################
#####################           Read the data         ######################


UI                  <- 
  
  fluidPage(
    
    #Add a title to your Page
    titlePanel( h2("Map cities for your Next Vacation")),
    br(),
    br(),
    sidebarLayout(
      sidebarPanel(h4("Enter details of your Trip"),
                   tags$hr(),
                   
                   uiOutput("country.select"),
                   tags$hr(),
                   uiOutput("city.select"),
                   tags$hr(),
                   tags$style(type="text/css",
                              ".shiny-output-error { visibility: hidden; }",
                              ".shiny-output-error:before { visibility: hidden; }"),
                   actionBttn(
                     inputId = "MAPS",
                     label = "Show Map", 
                     style = "gradient",
                     color = "primary",
                     icon = icon("thumbs-up")
                   ), width = 4),
      mainPanel(
        tabsetPanel(
          tabPanel("Vacation mode is on!",
                   leafletOutput("myleaflet")),
          tabPanel("About",
                   br(),
                   tags$h4("Planning your vacation!"),
                   p("This simple Shiny App is the web app to visualize the cities, a traveller wants to explore in a country"),
                   p("I will add more functionalities to the App in future! Watch me!")
          )))
      
      
    )
  )


server <- function(input, output, session){
  
  #####################################################
  ###      Create Dropdown for Country              ###
  

  
  
  name.countries     <- reactive({
    countries        <- sort(unique(countries_data$country))
    return(countries)
  })
  
   output$country.select    <- renderUI({
     selectInput("name.country", "Select a country you want to visit:", choices = name.countries(), multiple = F)
   })
  
  
  ######################################################
  ###       Select filter for selecting cities       ###
  
  country.city         <- reactive({
    req(input$name.country)
    
    filter_data        <- countries_data[country==input$name.country]
    
    cities             <- sort(unique(filter_data$city_ascii))
    return(cities)
    
  })
  
  ### Filter for cities
  output$city.select    <- renderUI({
    selectInput("name.city", "Select your Cities in the order you want to visit:", choices = as.factor(country.city()), multiple = T)
  })
  
  
  ### Select the Latitude and Longitude of the cities in order
  lat_long              <- eventReactive(input$MAPS,{
    cities_filter       <<- countries_data[country == input$name.country & city_ascii %in% input$name.city, c( 'city_ascii','lat', 'lng'), with=F]
    list.cities         <- input$name.city
    
    ### Order the Data table with the specific list order & remove Duplicates
    cities_filter       <<- cities_filter[ , Ordered.city := factor(city_ascii, levels =list.cities )]
    setorder(cities_filter, Ordered.city)
    cities_filter       <<- unique(cities_filter, by="city_ascii")
    
    
    cities_filter       <<- cities_filter[ ,-4, with =F]
    
    tot_rows            <<- nrow(cities_filter)
    
    #new_first           <- matrix(data=NA, nrow = tot_rows, ncol = 5)
    print(input$name.city)
    for(i in 1:tot_rows){
      first_name            <<- cities_filter[i]
      
      if(i<tot_rows){
        second_name           <<- cities_filter[i+1]
        second_name[[1]]      <<- first_name[[1]]
        
      }else if(i==tot_rows){
        second_name          <<- first_name
      }
      new_first            <<- rbind(first_name,second_name)
      if(i==1){
        final_loc       <<- new_first
      } else {
        final_loc       <<- rbind(final_loc, new_first)
      }
      
    }
    
    return(final_loc)
  })
  
  
  #Rendering the Output for leaflet
  output$myleaflet      <- renderLeaflet({
    
    leaflet(lat_long()) %>% 
      addTiles()%>%
      addEasyButton(easyButton(
        icon="fa-globe", title="Zoom to Level 1",
        onClick=JS("function(btn, map){ map.setZoom(1); }"))) %>%
      addEasyButton(easyButton(
        icon="fa-crosshairs", title="Locate Me",
        onClick=JS("function(btn, map){ map.locate({setView: true}); }")))%>%
      addPolylines(data = lat_long(), lng = ~lng, lat = ~lat, group = ~city_ascii)%>%
      addMarkers(cities_filter, lat = ~lat,lng = ~lng, labelOptions = ~city_ascii, 
                 icon = icon("fas fa-map-marker-alt"))%>%
      addCircles(cities_filter, lat = ~lat,lng = ~lng, radius = 3,stroke = FALSE,
                 fillColor = "black", fillOpacity = 5)
    # fitBounds(19.1104,74.75,26.4500,74.64)%>%
    # addMeasure()
    
  })
}

shinyApp(UI, server)


