defmodule IdentityWeb.Router do
  use IdentityWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", IdentityWeb do
    pipe_through :api

    post "/identity", ContactController, :identity
  end
end
