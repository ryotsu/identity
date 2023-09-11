defmodule IdentityWeb.Router do
  use IdentityWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", IdentityWeb do
    pipe_through :api
  end
end
