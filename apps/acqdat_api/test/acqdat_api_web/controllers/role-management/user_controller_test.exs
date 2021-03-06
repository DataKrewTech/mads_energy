defmodule AcqdatApiWeb.RoleManagement.UserControllerTest do
  use ExUnit.Case, async: true
  use AcqdatApiWeb.ConnCase
  use AcqdatCore.DataCase
  alias AcqdatCore.Schema.RoleManagement.User
  alias AcqdatCore.Model.RoleManagement.User, as: UModel
  alias AcqdatCore.Repo
  import AcqdatCore.Support.Factory

  describe "show/2" do
    setup :setup_conn

    test "fails if authorization header not found", %{conn: conn, org: org} do
      bad_access_token = "avcbd123489u"

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{bad_access_token}")

      conn = get(conn, Routes.user_path(conn, :show, org.id, 1))
      result = conn |> json_response(403)
      assert result == %{"errors" => %{"message" => "Unauthorized"}}
    end

    test "user with invalid organisation id", %{conn: conn, user: _user, org: org} do
      conn = get(conn, Routes.user_path(conn, :show, org.id, -1))
      result = conn |> json_response(404)
      assert result == %{"errors" => %{"message" => "Resource Not Found"}}
    end

    test "user with valid id", %{conn: conn, user: user} do
      conn = get(conn, Routes.user_path(conn, :show, user.org_id, user.id))
      result = conn |> json_response(200)

      assert result["id"] == user.id
    end
  end

  describe "delete/2" do
    setup :setup_conn

    test "fails if authorization header not found", %{conn: conn, org: org} do
      bad_access_token = "avcbd123489u"

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{bad_access_token}")

      conn = delete(conn, Routes.user_path(conn, :delete, org.id, 1))
      result = conn |> json_response(403)
      assert result == %{"errors" => %{"message" => "Unauthorized"}}
    end

    test "user with invalid organisation id", %{conn: conn, user: _user, org: org} do
      conn = delete(conn, Routes.user_path(conn, :delete, -1, 1))
      result = conn |> json_response(404)
      assert result == %{"errors" => %{"message" => "Resource Not Found"}}
    end

    test "user with valid id", %{conn: conn, user: user} do
      conn = delete(conn, Routes.user_path(conn, :delete, user.org_id, user.id))
      result = conn |> json_response(200)
      result = Repo.get(User, user.id)
      assert result.is_deleted == true
    end
  end

  describe "assets/2" do
    setup :setup_conn

    setup do
      org = insert(:organisation)
      project = insert(:project, org: org)
      asset = insert(:asset, org: org, project: project)
      user = insert(:user)

      [user: user, asset: asset, org: org, project: project]
    end

    test "fails if authorization header not found", context do
      %{user: user, conn: conn, org: org} = context

      bad_access_token = "avcbd123489u"

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{bad_access_token}")

      data = %{}
      conn = put(conn, Routes.user_assets_path(conn, :assets, org.id, user.id), data)
      result = conn |> json_response(403)
      assert result == %{"errors" => %{"message" => "Unauthorized"}}
    end

    test "fails if assets params are not present", context do
      %{user: user, conn: conn, org: org} = context

      params = %{}

      conn = put(conn, Routes.user_assets_path(conn, :assets, org.id, user.id), params)
      response = conn |> json_response(400)
      assert response == %{"errors" => %{"message" => %{"assets" => ["can't be blank"]}}}
    end

    test "update user's assets", context do
      %{user: user, asset: asset, conn: conn, org: org} = context

      params = %{
        assets: [
          %{
            id: asset.id,
            name: asset.name
          }
        ]
      }

      conn = put(conn, Routes.user_assets_path(conn, :assets, org.id, user.id), params)
      response = conn |> json_response(200)
      assert Map.has_key?(response, "assets")
    end
  end

  describe "apps/2" do
    setup :setup_conn

    setup do
      org = insert(:organisation)
      app = insert(:app)
      user = insert(:user)

      [user: user, app: app, org: org]
    end

    test "fails if authorization header not found", context do
      %{user: user, conn: conn, org: org} = context

      bad_access_token = "avcbd123489u"

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{bad_access_token}")

      data = %{}
      conn = put(conn, Routes.user_apps_path(conn, :apps, org.id, user.id), data)
      result = conn |> json_response(403)
      assert result == %{"errors" => %{"message" => "Unauthorized"}}
    end

    test "fails if assets params are not present", context do
      %{user: user, conn: conn, org: org} = context

      params = %{}

      conn = put(conn, Routes.user_apps_path(conn, :apps, org.id, user.id), params)
      response = conn |> json_response(400)
      assert response == %{"errors" => %{"message" => %{"apps" => ["can't be blank"]}}}
    end

    test "update user's apps", context do
      %{user: user, app: app, conn: conn, org: org} = context

      params = %{
        apps: [
          %{
            id: app.id,
            name: app.name
          }
        ]
      }

      conn = put(conn, Routes.user_apps_path(conn, :apps, org.id, user.id), params)
      response = conn |> json_response(200)
      assert Map.has_key?(response, "apps")
    end
  end

  describe "create/2" do
    setup :setup_conn

    setup do
      org = insert(:organisation)
      invitation = insert(:invitation)
      [org: org, invitation: invitation]
    end

    test "fails if invitation-token header not found", context do
      %{org: org, conn: conn} = context

      bad_invitation_token = "avcbd123489u"

      conn =
        conn
        |> put_req_header("invitation-token", bad_invitation_token)

      data = %{
        user: %{
          password: "test123@!%$",
          password_confirmation: "test123@!%$",
          first_name: "Demo Name"
        }
      }

      conn = post(conn, Routes.user_path(conn, :create, org.id), data)
      result = conn |> json_response(400)

      assert result["errors"] == %{"message" => %{"error" => "Invitation is Invalid"}}
    end

    test "user created when valid token is provided", context do
      %{org: org, conn: conn} = context
      salt = "test user_salt"
      token = Phoenix.Token.sign(AcqdatApiWeb.Endpoint, salt, %{email: "test@test.com"})
      invitation = insert(:invitation, token: token, salt: salt, email: "test@test.com")

      assert token == invitation.token
      assert salt == invitation.salt

      data = %{
        user: %{
          password: "test123@!%$",
          password_confirmation: "test123@!%$",
          first_name: "Demo Name"
        }
      }

      conn =
        conn
        |> put_req_header("invitation-token", invitation.token)

      conn = post(conn, Routes.user_path(conn, :create, org.id), data)

      response = conn |> json_response(200)
      assert Map.has_key?(response, "is_invited")
      assert response["is_invited"]
      assert response["first_name"] == "Demo Name"
    end

    test "user creation fails in case of invalid token", context do
      %{org: org, invitation: invitation, conn: conn} = context

      data = %{
        user: %{
          password: "test123@!%$",
          password_confirmation: "test123@!%$",
          first_name: "Demo Name"
        }
      }

      conn =
        conn
        |> put_req_header("invitation-token", invitation.token)

      conn = post(conn, Routes.user_path(conn, :create, org.id), data)

      response = conn |> json_response(400)
      assert response["errors"] == %{"message" => %{"error" => "Invalid Invitation Token"}}
    end

    test "existing user created when valid token is provided", context do
      %{org: org, conn: conn} = context
      salt = "test user_salt"

      user = insert(:user)
      token = Phoenix.Token.sign(AcqdatApiWeb.Endpoint, salt, %{email: user.email})
      invitation = insert(:invitation, token: token, salt: salt, email: user.email)

      assert token == invitation.token
      assert salt == invitation.salt

      {:ok, result} = UModel.delete(user)
      result = Repo.get(User, user.id)

      data = %{
        user: %{
          password: "test123@!%$",
          password_confirmation: "test123@!%$",
          first_name: "Demo Name"
        }
      }

      conn =
        conn
        |> put_req_header("invitation-token", invitation.token)

      assert result.is_deleted == true
      conn = post(conn, Routes.user_path(conn, :create, org.id), data)
      response = conn |> json_response(200)
      result = Repo.get(User, response["id"])
      assert result.is_deleted == false
    end
  end

  describe "search_users/2" do
    setup :setup_conn

    test "fails if authorization header not found", %{conn: conn, user: user, org: org} do
      setup_index(%{user: user, org: org})
      bad_access_token = "avcbd123489u"
      org = insert(:organisation)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{bad_access_token}")

      conn =
        get(conn, Routes.user_path(conn, :search_users, org.id), %{
          "label" => "Chandu"
        })

      result = conn |> json_response(403)
      assert result == %{"errors" => %{"message" => "Unauthorized"}}
    end

    test "search with valid params", %{conn: conn, user: user, org: org} do
      setup_index(%{user: user, org: org})

      conn =
        get(conn, Routes.user_path(conn, :search_users, user.org_id), %{
          "label" => user.first_name
        })

      result = conn |> json_response(200)

      role = %{
        "description" => user.role.description,
        "id" => user.role.id,
        "name" => user.role.name
      }

      organisation = %{"id" => user.org.id, "name" => user.org.name, "type" => "Organisation"}

      assert result == %{
               "users" => [
                 %{
                   "email" => user.email,
                   "first_name" => user.first_name,
                   "id" => user.id,
                   "last_name" => user.last_name,
                   "org_id" => user.org_id,
                   "role_id" => user.role_id,
                   "org" => organisation,
                   "role" => role
                 }
               ]
             }
    end

    test "search with no hits ", %{conn: conn, user: user, org: org} do
      setup_index(%{user: user, org: org})
      org = insert(:organisation)

      conn =
        get(conn, Routes.user_path(conn, :search_users, org.id), %{
          "label" => "Datakrew"
        })

      result = conn |> json_response(200)

      assert result == %{
               "users" => []
             }
    end
  end

  def setup_index(%{user: user, org: org}) do
    create_organisation("organisation", org)
    create_user("organisation", user, org)
    :timer.sleep(1500)
  end

  def create_organisation(type, params) do
    Tirexs.HTTP.put("/organisation", %{
      mappings: %{properties: %{join_field: %{type: "join", relations: %{organisation: "user"}}}}
    })

    Tirexs.HTTP.post("#{type}/_doc/#{params.id}",
      id: params.id,
      name: params.name,
      uuid: params.uuid,
      join_field: "organisation"
    )
  end

  def create_user(type, params, org) do
    Tirexs.HTTP.post("#{type}/_doc/#{params.id}?routing=#{org.id}",
      id: params.id,
      email: params.email,
      first_name: params.first_name,
      last_name: params.last_name,
      org_id: params.org_id,
      is_invited: params.is_invited,
      role_id: params.role_id,
      join_field: %{name: "user", parent: org.id}
    )
  end
end
