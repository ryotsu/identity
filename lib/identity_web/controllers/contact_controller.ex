defmodule IdentityWeb.ContactController do
  use IdentityWeb, :controller

  alias Identity.Account

  action_fallback IdentityWeb.FallbackController

  def identify(conn, contact_params) do
    contact_params =
      contact_params
      |> Map.update("phoneNumber", nil, fn x -> if x == "", do: nil, else: x end)
      |> Map.update("email", nil, fn x -> if x == "", do: nil, else: x end)

    with {:ok, contact} <- Account.query_contact(contact_params) do
      render(conn, :show_contact, contact: contact)
    end
  end
end
