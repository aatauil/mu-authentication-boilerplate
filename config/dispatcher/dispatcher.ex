defmodule Dispatcher do
  use Matcher

  define_accept_types [
    json: [ "application/json", "application/vnd.api+json" ],
    html: [ "text/html", "application/xhtml+html" ],
    sparql: [ "application/sparql-results+json" ],
    any: [ "*/*" ]
  ]

  define_layers [ :static, :sparql, :api_services, :frontend_fallback, :resources, :not_found ]

  options "/*path", _ do
    conn
    |> Plug.Conn.put_resp_header( "access-control-allow-headers", "content-type,accept" )
    |> Plug.Conn.put_resp_header( "access-control-allow-methods", "*" )
    |> send_resp( 200, "{ \"message\": \"ok\" }" )
  end


  ###############
  # STATIC
  ###############
  # frontend
  match "/assets/*path", %{ layer: :static } do
    forward conn, path, "http://frontend/assets/"
  end

  match "/index.html", %{ layer: :static } do
    forward conn, [], "http://frontend/index.html"
  end

  match "/favicon.ico", %{ layer: :static } do
    send_resp( conn, 404, "" )
  end


  ###############
  # SPARQL
  ###############
  match "/sparql", %{ layer: :sparql, accept: %{ sparql: true } } do
    forward conn, [], "http://database:8890/sparql"
  end


  ###############
  # API SERVICES
  ###############
  post "/accounts/*path", %{ layer: :api_services, accept: %{ json: true } } do
    Proxy.forward conn, path, "http://authentication/accounts/" 
  end

  delete "/accounts/current/*path", %{ layer: :api_services, accept: %{ json: true } } do
    Proxy.forward conn, path, "http://authentication/accounts/current/" 
  end

  patch "/accounts/current/changePassword/*path", %{ layer: :api_services, accept: %{ json: true } } do
    Proxy.forward conn, path, "http://authentication/accounts/current/changePassword/" 
  end

  match "/sessions/*path", %{ layer: :api_services, accept: %{ json: true } } do
    Proxy.forward conn, path, "http://authentication/sessions/" 
  end


  ###############
  # RESOURCES
  ###############
  get "/accounts/*path", %{ layer: :resources, accept: %{ json: true } }  do
    Proxy.forward conn, path, "http://resource/accounts/" 
  end

  #################
  # NOT FOUND
  #################
  match "/*_path", %{ layer: :not_found } do
    send_resp( conn, 404, "Route not found.  See config/dispatcher.ex" )
  end

end
