defmodule IdentityWeb.ContactJSON do
  def show_contact(%{contact: [{id, phone, email} | rest] = contact}) do
    phones =
      case contact |> Enum.map(&elem(&1, 1)) |> Enum.uniq() do
        [^phone | _] = phones -> phones
        phones -> [phone | phones]
      end

    emails =
      case contact |> Enum.map(&elem(&1, 2)) |> Enum.uniq() do
        [^email | _] = emails -> emails
        emails -> [email | emails]
      end

    contact = %{
      primaryContactId: id,
      emails: emails,
      phoneNumbers: phones,
      secondaryContactIds: rest |> Enum.map(&elem(&1, 0))
    }

    %{contact: contact}
  end
end
