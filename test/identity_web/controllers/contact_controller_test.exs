defmodule IdentityWeb.ContactControllerTest do
  use IdentityWeb.ConnCase

  @valid_contact_1 %{
    phoneNumber: "123456",
    email: "lorraine@hillvalley.edu"
  }

  @valid_contact_2 %{
    phoneNumber: "1234567",
    email: "mcfly@hillvalley.edu"
  }

  @linked_to_contact_1_and_2 %{
    phoneNumber: "123456",
    email: "mcfly@hillvalley.edu"
  }

  @invalid_attrs %{phoneNumber: nil, email: nil}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "identify" do
    test "blank contact details", %{conn: conn} do
      conn = post(conn, ~p"/identify", @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end

    test "primary contact", %{conn: conn} do
      conn = post(conn, ~p"/identify", @valid_contact_1)

      assert %{
               "primaryContactId" => _id,
               "emails" => ["lorraine@hillvalley.edu"],
               "phoneNumbers" => ["123456"],
               "secondaryContactIds" => []
             } = json_response(conn, 200)["contact"]
    end

    test "primary and secondary contacts", %{conn: conn} do
      conn = post(conn, ~p"/identify", @valid_contact_1)
      assert %{"primaryContactId" => id} = json_response(conn, 200)["contact"]

      conn = post(conn, ~p"/identify", @linked_to_contact_1_and_2)

      assert %{
               "primaryContactId" => ^id,
               "emails" => ["lorraine@hillvalley.edu", "mcfly@hillvalley.edu"],
               "phoneNumbers" => ["123456"],
               "secondaryContactIds" => _secondary
             } = json_response(conn, 200)["contact"]
    end

    test "no new info", %{conn: conn} do
      conn = post(conn, ~p"/identify", @valid_contact_1)
      assert %{"primaryContactId" => _id} = json_response(conn, 200)["contact"]

      conn = post(conn, ~p"/identify", @linked_to_contact_1_and_2)
      assert contact = json_response(conn, 200)["contact"]

      conn = post(conn, ~p"/identify", %{phoneNumber: "123456"})
      assert ^contact = json_response(conn, 200)["contact"]

      conn = post(conn, ~p"/identify", %{email: "lorraine@hillvalley.edu"})
      assert ^contact = json_response(conn, 200)["contact"]

      conn = post(conn, ~p"/identify", %{email: "mcfly@hillvalley.edu"})
      assert ^contact = json_response(conn, 200)["contact"]
    end

    test "two primary contacts", %{conn: conn} do
      conn = post(conn, ~p"/identify", @valid_contact_1)
      assert %{"primaryContactId" => id_1} = json_response(conn, 200)["contact"]

      conn = post(conn, ~p"/identify", @valid_contact_2)
      assert %{"primaryContactId" => id_2} = json_response(conn, 200)["contact"]

      assert id_1 != id_2
    end

    test "join two partitions", %{conn: conn} do
      conn = post(conn, ~p"/identify", @valid_contact_1)
      assert %{"primaryContactId" => id_1} = json_response(conn, 200)["contact"]

      conn = post(conn, ~p"/identify", @valid_contact_2)
      assert %{"primaryContactId" => id_2} = json_response(conn, 200)["contact"]

      assert id_1 != id_2

      conn = post(conn, ~p"/identify", @linked_to_contact_1_and_2)
      assert %{"primaryContactId" => ^id_1} = json_response(conn, 200)["contact"]

      conn = post(conn, ~p"/identify", @linked_to_contact_1_and_2)
      assert %{"primaryContactId" => ^id_1} = json_response(conn, 200)["contact"]
    end
  end
end
