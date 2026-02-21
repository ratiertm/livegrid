defmodule LiveviewGridWeb.MockApiController do
  @moduledoc """
  Mock REST API for demonstrating the REST DataSource adapter.

  Provides a fully functional JSON API backed by SQLite (DemoUser table)
  with support for pagination, sorting, filtering, and CRUD operations.

  ## Endpoints

      GET    /api/users          - List users (paginated, sortable, filterable)
      GET    /api/users/:id      - Get single user
      POST   /api/users          - Create user
      PUT    /api/users/:id      - Update user (full replacement)
      PATCH  /api/users/:id      - Partial update user (specific fields only)
      DELETE /api/users/:id      - Delete user

  ## Query Parameters

      page       - Page number (default: 1)
      page_size  - Items per page (default: 20)
      sort       - Sort field (e.g., "name", "age")
      order      - Sort direction ("asc" or "desc")
      q          - Global search term
      filters    - JSON-encoded filter map (e.g., {"name":"Kim","age":">30"})
  """

  use LiveviewGridWeb, :controller

  alias LiveviewGrid.{Repo, DemoUser}
  import Ecto.Query

  def index(conn, params) do
    start_time = System.monotonic_time(:millisecond)

    page = parse_int(params["page"], 1)
    page_size = parse_int(params["page_size"], 20) |> min(500)
    sort_field = parse_sort_field(params["sort"])
    sort_dir = parse_sort_dir(params["order"])
    search = params["q"]
    filters = parse_filters(params["filters"])

    # Base query
    query = from(u in DemoUser)

    # Total count (unfiltered)
    total = Repo.aggregate(query, :count)

    # Apply global search
    query = apply_search(query, search)

    # Apply column filters
    query = apply_filters(query, filters)

    # Filtered count
    filtered = Repo.aggregate(query, :count)

    # Apply sorting
    query = apply_sort(query, sort_field, sort_dir)

    # Apply pagination
    offset = (page - 1) * page_size
    query = from(u in query, limit: ^page_size, offset: ^offset)

    # Execute
    rows = Repo.all(query) |> Enum.map(&row_to_map/1)

    elapsed = System.monotonic_time(:millisecond) - start_time

    json(conn, %{
      data: rows,
      total: total,
      filtered: filtered,
      page: page,
      page_size: page_size,
      total_pages: ceil(filtered / max(page_size, 1)),
      query_time_ms: elapsed
    })
  end

  def show(conn, %{"id" => id}) do
    case Repo.get(DemoUser, id) do
      nil -> conn |> put_status(:not_found) |> json(%{error: "Not found"})
      user -> json(conn, %{data: row_to_map(user)})
    end
  end

  def create(conn, params) do
    attrs = %{
      name: params["name"] || "New User",
      email: params["email"] || "new@example.com",
      department: params["department"] || "개발",
      age: parse_int(params["age"], 25),
      salary: parse_int(params["salary"], 35_000_000),
      status: params["status"] || "재직",
      join_date: params["join_date"] || Date.utc_today() |> Date.to_string()
    }

    case %DemoUser{} |> DemoUser.changeset(attrs) |> Repo.insert() do
      {:ok, user} ->
        conn |> put_status(:created) |> json(%{data: row_to_map(user)})

      {:error, changeset} ->
        errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, _} -> msg end)
        conn |> put_status(:unprocessable_entity) |> json(%{error: errors})
    end
  end

  def update(conn, %{"id" => id} = params) do
    case Repo.get(DemoUser, id) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "Not found"})

      user ->
        changes =
          params
          |> Map.take(~w(name email department age salary status join_date))
          |> Enum.reduce(%{}, fn
            {"age", v}, acc -> Map.put(acc, :age, parse_int(v, user.age))
            {"salary", v}, acc -> Map.put(acc, :salary, parse_int(v, user.salary))
            {k, v}, acc -> Map.put(acc, String.to_atom(k), v)
          end)

        case DemoUser.changeset(user, changes) |> Repo.update() do
          {:ok, updated} ->
            json(conn, %{data: row_to_map(updated)})

          {:error, changeset} ->
            errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, _} -> msg end)
            conn |> put_status(:unprocessable_entity) |> json(%{error: errors})
        end
    end
  end

  def patch(conn, %{"id" => id} = params) do
    case Repo.get(DemoUser, id) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "Not found"})

      user ->
        # PATCH: only update fields that are explicitly provided
        allowed = ~w(name email department age salary status join_date)
        provided = Map.take(params, allowed)

        if map_size(provided) == 0 do
          conn |> put_status(:bad_request) |> json(%{error: "No fields to update"})
        else
          changes =
            Enum.reduce(provided, %{}, fn
              {"age", v}, acc -> Map.put(acc, :age, parse_int(v, user.age))
              {"salary", v}, acc -> Map.put(acc, :salary, parse_int(v, user.salary))
              {k, v}, acc -> Map.put(acc, String.to_atom(k), v)
            end)

          case DemoUser.changeset(user, changes) |> Repo.update() do
            {:ok, updated} ->
              json(conn, %{data: row_to_map(updated), patched_fields: Map.keys(provided)})

            {:error, changeset} ->
              errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, _} -> msg end)
              conn |> put_status(:unprocessable_entity) |> json(%{error: errors})
          end
        end
    end
  end

  def delete(conn, %{"id" => id}) do
    case Repo.get(DemoUser, id) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "Not found"})

      user ->
        case Repo.delete(user) do
          {:ok, _} -> json(conn, %{message: "Deleted successfully"})
          {:error, _} -> conn |> put_status(:internal_server_error) |> json(%{error: "Delete failed"})
        end
    end
  end

  # ── Private helpers ──

  defp row_to_map(%DemoUser{} = user) do
    %{
      id: user.id,
      name: user.name,
      email: user.email,
      department: user.department,
      age: user.age,
      salary: user.salary,
      status: user.status,
      join_date: user.join_date
    }
  end

  defp apply_search(query, nil), do: query
  defp apply_search(query, ""), do: query
  defp apply_search(query, term) do
    pattern = "%#{escape_like(term)}%"
    from(u in query,
      where: like(fragment("CAST(? AS TEXT)", u.name), ^pattern)
          or like(fragment("CAST(? AS TEXT)", u.email), ^pattern)
          or like(fragment("CAST(? AS TEXT)", u.department), ^pattern)
          or like(fragment("CAST(? AS TEXT)", u.status), ^pattern)
    )
  end

  defp apply_filters(query, filters) when map_size(filters) == 0, do: query
  defp apply_filters(query, filters) do
    Enum.reduce(filters, query, fn {field, value}, q ->
      apply_single_filter(q, field, value)
    end)
  end

  defp apply_single_filter(query, field, value) when field in ~w(name email department status join_date) do
    field_atom = String.to_existing_atom(field)
    pattern = "%#{escape_like(value)}%"
    from(u in query, where: like(fragment("CAST(? AS TEXT)", field(u, ^field_atom)), ^pattern))
  end

  defp apply_single_filter(query, field, value) when field in ~w(age salary) do
    field_atom = String.to_existing_atom(field)
    case parse_number_filter(value) do
      {:gt, num} -> from(u in query, where: field(u, ^field_atom) > ^num)
      {:lt, num} -> from(u in query, where: field(u, ^field_atom) < ^num)
      {:gte, num} -> from(u in query, where: field(u, ^field_atom) >= ^num)
      {:lte, num} -> from(u in query, where: field(u, ^field_atom) <= ^num)
      {:eq, num} -> from(u in query, where: field(u, ^field_atom) == ^num)
      _ -> query
    end
  end

  defp apply_single_filter(query, _field, _value), do: query

  defp apply_sort(query, nil, _dir), do: from(u in query, order_by: [asc: u.id])
  defp apply_sort(query, field, :asc), do: from(u in query, order_by: [asc: field(u, ^field)])
  defp apply_sort(query, field, :desc), do: from(u in query, order_by: [desc: field(u, ^field)])

  defp parse_int(nil, default), do: default
  defp parse_int(val, default) when is_binary(val) do
    case Integer.parse(val) do
      {num, _} -> num
      :error -> default
    end
  end
  defp parse_int(val, _default) when is_integer(val), do: val

  defp parse_sort_field(nil), do: nil
  defp parse_sort_field(field) when field in ~w(id name email department age salary status join_date) do
    String.to_existing_atom(field)
  end
  defp parse_sort_field(_), do: nil

  defp parse_sort_dir(nil), do: :asc
  defp parse_sort_dir("desc"), do: :desc
  defp parse_sort_dir(_), do: :asc

  defp parse_filters(nil), do: %{}
  defp parse_filters(""), do: %{}
  defp parse_filters(json) when is_binary(json) do
    case Jason.decode(json) do
      {:ok, map} when is_map(map) -> map
      _ -> %{}
    end
  end

  defp parse_number_filter(value) when is_binary(value) do
    cond do
      String.starts_with?(value, ">=") -> {:gte, parse_num(String.slice(value, 2..-1//1))}
      String.starts_with?(value, "<=") -> {:lte, parse_num(String.slice(value, 2..-1//1))}
      String.starts_with?(value, ">") -> {:gt, parse_num(String.slice(value, 1..-1//1))}
      String.starts_with?(value, "<") -> {:lt, parse_num(String.slice(value, 1..-1//1))}
      true -> {:eq, parse_num(value)}
    end
  end
  defp parse_number_filter(value) when is_integer(value), do: {:eq, value}
  defp parse_number_filter(_), do: nil

  defp parse_num(str) do
    case Integer.parse(String.trim(str)) do
      {num, _} -> num
      :error -> 0
    end
  end

  defp escape_like(term) do
    term
    |> String.replace("\\", "\\\\")
    |> String.replace("%", "\\%")
    |> String.replace("_", "\\_")
  end
end
