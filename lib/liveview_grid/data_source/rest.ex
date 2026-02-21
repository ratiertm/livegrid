defmodule LiveViewGrid.DataSource.Rest do
  @moduledoc """
  REST API DataSource adapter for LiveView Grid.

  Fetches data from external REST APIs with support for:
  - Server-side pagination (offset/cursor)
  - Server-side sorting
  - Server-side filtering
  - Authentication (Bearer token, API key, custom headers)
  - CRUD operations (POST/PUT/PATCH/DELETE)
  - Error handling & retry logic
  - Loading states

  ## Config

      %{
        base_url: "https://api.example.com",
        endpoint: "/users",
        headers: %{"Authorization" => "Bearer token123"},
        # Response mapping (API 응답 구조에 맞게 매핑)
        response_mapping: %{
          data_key: "data",           # rows가 담긴 키
          total_key: "total",         # 전체 건수 키
          filtered_key: "filtered"    # 필터된 건수 키 (없으면 total 사용)
        },
        # Query parameter mapping (API가 기대하는 파라미터명)
        query_mapping: %{
          page: "page",
          page_size: "page_size",
          sort_field: "sort",
          sort_direction: "order",
          search: "q",
          filters: "filters"
        },
        # 요청 옵션
        request_opts: %{
          timeout: 10_000,
          retry: 3,
          retry_delay: 1_000
        }
      }
  """

  @behaviour LiveViewGrid.DataSource

  require Logger

  @default_response_mapping %{
    data_key: "data",
    total_key: "total",
    filtered_key: "filtered"
  }

  @default_query_mapping %{
    page: "page",
    page_size: "page_size",
    sort_field: "sort",
    sort_direction: "order",
    search: "q",
    filters: "filters"
  }

  @default_request_opts %{
    timeout: 10_000,
    retry: 3,
    retry_delay: 1_000
  }

  @impl true
  def fetch_data(config, state, options, _columns) do
    url = build_url(config, state, options)
    headers = build_headers(config)
    request_opts = Map.merge(@default_request_opts, Map.get(config, :request_opts, %{}))
    response_mapping = Map.merge(@default_response_mapping, Map.get(config, :response_mapping, %{}))

    case do_request(:get, url, headers, nil, request_opts) do
      {:ok, body} when is_map(body) ->
        rows = extract_rows(body, response_mapping)
        total = extract_count(body, response_mapping.total_key, length(rows))
        filtered = extract_count(body, response_mapping.filtered_key, total)
        {rows, total, filtered}

      {:ok, body} when is_list(body) ->
        # 응답이 배열인 경우 (단순 API)
        {atomize_rows(body), length(body), length(body)}

      {:error, reason} ->
        Logger.error("[REST DataSource] fetch_data failed: #{inspect(reason)}")
        {[], 0, 0}
    end
  end

  @impl true
  def insert_row(config, row) do
    url = base_endpoint_url(config)
    headers = build_headers(config)
    request_opts = Map.merge(@default_request_opts, Map.get(config, :request_opts, %{}))
    body = Jason.encode!(stringify_keys(row))

    case do_request(:post, url, headers, body, request_opts) do
      {:ok, response_body} ->
        {:ok, atomize_keys(response_body)}

      {:error, reason} ->
        Logger.error("[REST DataSource] insert_row failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @impl true
  def update_row(config, row_id, changes) do
    url = "#{base_endpoint_url(config)}/#{row_id}"
    headers = build_headers(config)
    request_opts = Map.merge(@default_request_opts, Map.get(config, :request_opts, %{}))
    body = Jason.encode!(stringify_keys(changes))

    case do_request(:put, url, headers, body, request_opts) do
      {:ok, response_body} ->
        {:ok, atomize_keys(response_body)}

      {:error, reason} ->
        Logger.error("[REST DataSource] update_row failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @impl true
  def partial_update_row(config, row_id, changes) do
    url = "#{base_endpoint_url(config)}/#{row_id}"
    headers = build_headers(config)
    request_opts = Map.merge(@default_request_opts, Map.get(config, :request_opts, %{}))
    body = Jason.encode!(stringify_keys(changes))

    case do_request(:patch, url, headers, body, request_opts) do
      {:ok, response_body} ->
        {:ok, atomize_keys(response_body)}

      {:error, reason} ->
        Logger.error("[REST DataSource] partial_update_row failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @impl true
  def delete_row(config, row_id) do
    url = "#{base_endpoint_url(config)}/#{row_id}"
    headers = build_headers(config)
    request_opts = Map.merge(@default_request_opts, Map.get(config, :request_opts, %{}))

    case do_request(:delete, url, headers, nil, request_opts) do
      {:ok, _} -> :ok
      {:error, reason} ->
        Logger.error("[REST DataSource] delete_row failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # ── URL Building ──

  defp build_url(config, state, options) do
    base = base_endpoint_url(config)
    query_mapping = Map.merge(@default_query_mapping, Map.get(config, :query_mapping, %{}))

    params =
      %{}
      |> add_pagination_params(state, options, query_mapping)
      |> add_sort_params(state, query_mapping)
      |> add_search_params(state, query_mapping)
      |> add_filter_params(state, query_mapping)
      |> Map.merge(Map.get(config, :extra_params, %{}))
      |> Enum.reject(fn {_k, v} -> is_nil(v) or v == "" end)
      |> Enum.into(%{})

    if map_size(params) > 0 do
      query_string = URI.encode_query(params)
      "#{base}?#{query_string}"
    else
      base
    end
  end

  defp base_endpoint_url(config) do
    base_url = String.trim_trailing(config.base_url, "/")
    endpoint = String.trim_leading(Map.get(config, :endpoint, ""), "/")
    "#{base_url}/#{endpoint}"
  end

  defp add_pagination_params(params, state, options, qm) do
    page = get_in(state, [:pagination, :current_page]) || 1
    page_size = Map.get(options, :page_size, 20)

    params
    |> Map.put(qm.page, page)
    |> Map.put(qm.page_size, page_size)
  end

  defp add_sort_params(params, state, qm) do
    case state do
      %{sort: %{field: field, direction: dir}} when not is_nil(field) ->
        params
        |> Map.put(qm.sort_field, field)
        |> Map.put(qm.sort_direction, dir)

      _ ->
        params
    end
  end

  defp add_search_params(params, state, qm) do
    case Map.get(state, :global_search) do
      search when is_binary(search) and search != "" ->
        Map.put(params, qm.search, search)

      _ ->
        params
    end
  end

  defp add_filter_params(params, state, qm) do
    filters = Map.get(state, :filters, %{})

    active_filters =
      filters
      |> Enum.reject(fn {_k, v} -> is_nil(v) or v == "" end)
      |> Enum.into(%{})

    if map_size(active_filters) > 0 do
      Map.put(params, qm.filters, Jason.encode!(stringify_keys(active_filters)))
    else
      params
    end
  end

  # ── Headers ──

  defp build_headers(config) do
    base = %{"content-type" => "application/json", "accept" => "application/json"}
    custom = Map.get(config, :headers, %{})
    Map.merge(base, custom)
  end

  # ── HTTP Request with Retry ──

  defp do_request(method, url, headers, body, opts) do
    timeout = Map.get(opts, :timeout, 10_000)
    max_retries = Map.get(opts, :retry, 3)
    retry_delay = Map.get(opts, :retry_delay, 1_000)

    headers_list = Enum.map(headers, fn {k, v} -> {to_string(k), to_string(v)} end)

    do_request_with_retry(method, url, headers_list, body, timeout, max_retries, retry_delay, 0)
  end

  defp do_request_with_retry(method, url, headers, body, timeout, max_retries, retry_delay, attempt) do
    req_opts = [
      method: method,
      url: url,
      headers: headers,
      receive_timeout: timeout,
      retry: false
    ]

    req_opts = if body, do: Keyword.put(req_opts, :body, body), else: req_opts

    result =
      try do
        Req.request(req_opts)
      rescue
        e -> {:error, Exception.message(e)}
      catch
        :exit, reason -> {:error, "Connection failed: #{inspect(reason)}"}
      end

    case result do
      {:ok, %Req.Response{status: status, body: resp_body}} when status in 200..299 ->
        {:ok, resp_body}

      {:ok, %Req.Response{status: status, body: resp_body}} ->
        if attempt < max_retries and status in [408, 429, 500, 502, 503, 504] do
          Process.sleep(retry_delay * (attempt + 1))
          do_request_with_retry(method, url, headers, body, timeout, max_retries, retry_delay, attempt + 1)
        else
          {:error, "HTTP #{status}: #{inspect(resp_body)}"}
        end

      {:error, reason} ->
        if attempt < max_retries do
          Process.sleep(retry_delay * (attempt + 1))
          do_request_with_retry(method, url, headers, body, timeout, max_retries, retry_delay, attempt + 1)
        else
          {:error, "Request failed: #{inspect(reason)}"}
        end
    end
  end

  # ── Response Parsing ──

  defp extract_rows(body, mapping) do
    data_key = mapping.data_key

    case Map.get(body, data_key) do
      rows when is_list(rows) -> atomize_rows(rows)
      _ -> []
    end
  end

  defp extract_count(body, key, default) do
    case Map.get(body, key) do
      count when is_integer(count) -> count
      count when is_binary(count) -> String.to_integer(count)
      _ -> default
    end
  end

  defp atomize_rows(rows) when is_list(rows) do
    Enum.map(rows, &atomize_keys/1)
  end

  defp atomize_keys(map) when is_map(map) do
    Map.new(map, fn
      {k, v} when is_binary(k) -> {String.to_atom(k), v}
      {k, v} when is_atom(k) -> {k, v}
    end)
  end

  defp atomize_keys(other), do: other

  defp stringify_keys(map) when is_map(map) do
    Map.new(map, fn
      {k, v} when is_atom(k) -> {Atom.to_string(k), v}
      {k, v} -> {to_string(k), v}
    end)
  end
end
