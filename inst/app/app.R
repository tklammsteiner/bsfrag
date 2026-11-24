library(shiny)
library(shinychat)

store <- ragnar::ragnar_store_connect(
  getOption("bsfrag.store_path", "bsf.duckdb"), read_only = TRUE
)

ui <- bslib::page_fillable(
  h3("BSF-RAG: ask the black soldier fly literature"),
  chat_ui("chat")
)

server <- function(input, output, session) {
  chat <- ellmer::chat_anthropic(system_prompt = bsfrag::system_prompt())
  ragnar::ragnar_register_tool_retrieve(chat, store, top_k = 8)
  chat_server("chat", chat)
}

shinyApp(ui, server)
