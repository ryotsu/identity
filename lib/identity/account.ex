defmodule Identity.Account do
  @moduledoc """
  The Account context.
  """

  import Ecto.Query, warn: false
  alias Ecto.Query
  alias Identity.Repo

  alias Identity.Contact

  @doc """
  Checks if either phone or email is present and returns an error otherwise.
  If either of them is present, checks for the primary contact associated with them.

  If it can't find any associated primary contact, inserts the new contact as primary.
  If one primary is already present, inserts the new contact if it has new info.
  If two primaries are found, one linked to email and one to phone, it updates the newer
  primary and all its secondaries to link to the older primary.

  Returns an list of tuple containing ids, phones, and emails.
  """
  @spec query_contact(map()) ::
          {:ok, [{number(), String.t(), String.t()}]} | {:error, Ecto.Changeset}
  def query_contact(%{"phoneNumber" => phone, "email" => email})
      when phone != nil or email != nil do
    phone = if is_number(phone), do: to_string(phone), else: phone

    Repo.transaction(fn ->
      {:ok, primary} = get_primary(phone, email)

      query =
        from c in Contact, select: {c.id, c.phone, c.email}, where: [linked: ^primary.id]

      [{primary.id, primary.phone, primary.email} | Repo.all(query)]
    end)
  end

  def query_contact(attrs) do
    %Contact{}
    |> Contact.changeset(attrs)
    |> Repo.insert()
  end

  @spec get_primary(String.t(), String.t()) :: {:ok, Contact.t()}
  defp get_primary(phone, email) do
    # Finds the primary contact for the given combination of phone and email.
    # Inserts new contact and modifies already existing contacts as necessary.
    attrs = %{"phone" => phone, "email" => email}

    case get_related_contacts(phone, email) do
      {nil, nil} ->
        # No associated contacts, insert a new primary contact
        insert_primary(attrs)

      {nil, contact} ->
        # A linked primary contact found, along with new info, insert the new info
        insert_secondary(attrs, contact)
        {:ok, contact}

      {:ok, primary} ->
        # A linked primary contact found, but no new info
        {:ok, primary}

      {contact, contact} ->
        # Email an phone link to the same primary contact
        {:ok, contact}

      {one, two} ->
        # Email and phone link to different primary contacts. Join the two contacts.
        join_partition(one, two)
    end
  end

  @type maybe_string :: nil | String.t()
  @spec get_related_contacts(maybe_string, maybe_string) ::
          {:ok | nil | Contact.t(), nil | Contact.t()}
  defp get_related_contacts(phone, email)

  defp get_related_contacts(nil, email) do
    # Returns the primary contact linked with this email
    contact = where_field_query(:email, email) |> Repo.one() |> Repo.preload(:primary)

    case contact do
      nil -> {nil, nil}
      contact when contact.is_primary -> {:ok, contact}
      contact -> {:ok, contact.primary}
    end
  end

  defp get_related_contacts(phone, nil) do
    # Returns the primary contact linked with this phone
    contact = where_field_query(:phone, phone) |> Repo.one() |> Repo.preload(:primary)

    case contact do
      nil -> {nil, nil}
      contact when contact.is_primary -> {:ok, contact}
      contact -> {:ok, contact.primary}
    end
  end

  defp get_related_contacts(phone, email) do
    # Returns the primary contacts linked with the phone and email
    phone = where_field_query(:phone, phone) |> Repo.one() |> Repo.preload(:primary)
    email = where_field_query(:email, email) |> Repo.one() |> Repo.preload(:primary)

    case {phone, email} do
      {nil, nil} ->
        {nil, nil}

      {nil, email} ->
        {nil, primary(email)}

      {phone, nil} ->
        {nil, primary(phone)}

      {phone, email} ->
        {primary(phone), primary(email)}
    end
  end

  @spec insert_primary(map) :: {:ok, Contact.t()} | {:error, Ecto.Changeset.t()}
  defp insert_primary(attrs) do
    %Contact{}
    |> Contact.changeset(attrs |> Map.put_new("is_primary", true))
    |> Repo.insert()
  end

  @spec insert_secondary(map, Contact.t()) :: {:ok, Contact.t()} | {:error, Ecto.Changeset.t()}
  defp insert_secondary(attrs, %Contact{} = contact) do
    %Contact{}
    |> Contact.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:primary, contact)
    |> Repo.insert()
  end

  @spec update_secondary(Contact.t(), map, Contact.t()) ::
          {:ok, Contact.t()} | {:error, Ecto.Changeset.t()}
  defp update_secondary(%Contact{} = contact, attrs, primary) do
    contact
    |> Contact.changeset(attrs |> Map.put_new("is_primary", false))
    |> Ecto.Changeset.put_assoc(:primary, primary)
    |> Repo.update()
  end

  @spec join_partition(Contact.t(), Contact.t()) :: {:ok, Contact.t()}
  defp join_partition(one, two) do
    # Link contacts which link to the old primary contact to the new primary contact.
    {primary, secondary} = set_primary_secondary(one, two)

    from(Contact)
    |> where(linked: ^secondary.id)
    |> update(set: [linked: ^primary.id])
    |> Repo.update_all([])

    # Link old primary contact to the new primary contact
    update_secondary(secondary, %{}, primary)
    {:ok, primary}
  end

  @spec set_primary_secondary(Contact.t(), Contact.t()) :: {Contact.t(), Contact.t()}
  defp set_primary_secondary(one, two) do
    if one.inserted_at <= two.inserted_at, do: {one, two}, else: {two, one}
  end

  @spec primary(Contact.t()) :: Contact.t()
  defp primary(contact) do
    if contact.is_primary, do: contact, else: contact.primary |> Repo.preload(:primary)
  end

  @spec where_field_query(atom(), String.t()) :: Query.t()
  defp where_field_query(field_name, value) do
    from c in Contact, select: c, where: field(c, ^field_name) == ^value, limit: 1
  end
end
