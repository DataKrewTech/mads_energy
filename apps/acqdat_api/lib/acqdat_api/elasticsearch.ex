defmodule AcqdatApi.ElasticSearch do
  import Tirexs.HTTP

  def create(type, params) do
    create_function = fn ->
      post("#{type}/_doc/#{params.id}",
        id: params.id,
        label: params.label,
        uuid: params.uuid,
        properties: params.properties,
        category: params.category
      )
    end

    retry(create_function)
  end

  def update(type, params) do
    update_function = fn ->
      post("#{type}/_update/#{params.id}",
        doc: [
          label: params.label,
          uuid: params.uuid,
          properties: params.properties,
          category: params.category
        ]
      )
    end

    retry(update_function)
  end

  def update_users(type, params, org) do
    update = fn ->
      put("#{type}/_doc/#{params.id}?routing=#{org.id}",
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

    retry(update)
  end

  def delete(type, params) do
    delete_function = fn ->
      delete("#{type}/_doc/#{params}")
    end

    retry(delete_function)
  end

  def search_widget(type, params) do
    case do_widget_search(type, params) do
      {:ok, _return_code, hits} ->
        {:ok, hits.hits}

      {:error, _return_code, hits} ->
        {:error, hits}

      :error ->
        {:error, "elasticsearch is not running"}
    end
  end

  def search_user(org_id, params) do
    case do_user_search(org_id, params) do
      {:ok, _return_code, hits} ->
        {:ok, hits.hits}

      {:error, _return_code, hits} ->
        {:error, hits}

      :error ->
        {:error, "elasticsearch is not running"}
    end
  end

  def search_assets(type, params) do
    case do_asset_search(type, params) do
      {:ok, _return_code, hits} ->
        {:ok, hits.hits}

      {:error, _return_code, hits} ->
        {:error, hits}

      :error ->
        {:error, "elasticsearch is not running"}
    end
  end

  defp do_widget_search(type, params) do
    query = create_query("label", params, type)
    Tirexs.Query.create_resource(query)
  end

  defp do_user_search(org_id, params) do
    query = create_user_search_query(org_id, params)
    Tirexs.Query.create_resource(query)
  end

  defp do_asset_search(type, params) do
    query = create_query("name", params, type)
    Tirexs.Query.create_resource(query)
  end

  def user_indexing(page) do
    page_size = String.to_integer(page)

    case get("/user/_search", size: page_size) do
      {:ok, _return_code, hits} -> {:ok, hits.hits}
      :error -> {:error, "elasticsearch is not running"}
    end
  end

  defp retry(function) do
    GenRetry.retry(function, retries: 3, delay: 10_000)
  end

  defp create_query(field, value, index) do
    [search: [query: [match: ["#{field}": [query: "#{value}", fuzziness: 1]]]], index: "#{index}"]
  end

  defp create_user_search_query(org_id, label) do
    [
      search: [
        query: [
          bool: [
            must: [[parent_id: [type: "user", id: org_id]]],
            filter: [term: ["first_name.keyword": "#{label}"]]
          ]
        ]
      ],
      index: "organisation"
    ]
  end

  # [ "#{field}": [query: "#{value}", fuzziness: 1]
  def create_user(type, params, org) do
    post("#{type}/_doc/#{params.id}?routing=#{org.id}",
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
