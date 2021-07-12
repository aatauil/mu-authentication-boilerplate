defmodule Dispatcher do
  use Matcher

  define_accept_types [
    json: [ "application/json", "application/vnd.api+json" ],
  ]

  @any %{}
  @json %{ accept: %{ json: true } }
  @html %{ accept: %{ html: true } }

  match "/accounts/*path", %{ accept: %{ json: true } } do
    Proxy.forward conn, path, "http://authentication/accounts/" 
  end

  match "/sessions/*path", %{ accept: %{ json: true } } do
    Proxy.forward conn, path, "http://authentication/sessions/" 
  end

  match "_", %{ last_call: true } do
    send_resp( conn, 404, "Route not found.  See config/dispatcher.ex" )
  end

end
