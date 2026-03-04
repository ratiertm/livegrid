defmodule LiveviewGridWeb.BuilderLive do
  @moduledoc """
  Grid Builder - 새 그리드를 정의하고 생성하는 독립 페이지
  """

  use Phoenix.LiveView

  alias LiveViewGrid.GridConfigSerializer

  @doc "마운트 시 Grid Builder 초기 상태를 설정한다."
  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket,
      builder_open: false,
      dynamic_grids: []
    )}
  end

  # ── Grid Builder 이벤트 ──

  @doc "Grid Builder 페이지의 이벤트를 처리한다. 모달 열기, 그리드 삭제 등을 지원한다."
  @impl true
  def handle_event("open_builder", _params, socket) do
    {:noreply, assign(socket, builder_open: true)}
  end

  @impl true
  def handle_event("remove_dynamic_grid", %{"id" => grid_id}, socket) do
    updated = Enum.reject(socket.assigns.dynamic_grids, &(&1.id == grid_id))
    {:noreply, assign(socket, dynamic_grids: updated)}
  end

  # ── Config Export/Import 이벤트 ──

  @impl true
  def handle_event("export_config", %{"id" => grid_id}, socket) do
    case Enum.find(socket.assigns.dynamic_grids, &(&1.id == grid_id)) do
      nil ->
        {:noreply, put_flash(socket, :error, "Grid not found: #{grid_id}")}

      grid_map ->
        case GridConfigSerializer.serialize(grid_map) do
          {:ok, json} ->
            payload = %{
              content: Base.encode64(json),
              filename: "#{grid_id}_config.json",
              mime_type: "application/json"
            }

            {:noreply, push_event(socket, "download_file", payload)}

          {:error, reason} ->
            {:noreply, put_flash(socket, :error, "Export failed: #{reason}")}
        end
    end
  end

  @impl true
  def handle_event("import_config", %{"json" => json_str}, socket) do
    case GridConfigSerializer.deserialize(json_str) do
      {:ok, params} ->
        # 중복 ID 방지: 같은 ID의 그리드가 이미 있으면 suffix 추가
        grid_id = ensure_unique_id(params.grid_id, socket.assigns.dynamic_grids)
        params = %{params | grid_id: grid_id}

        %{grid_name: name, columns: cols, options: opts} = params
        ds_type = Map.get(params, :data_source_type, "sample")
        new_grid = build_grid(grid_id, name, cols, opts, ds_type, params)
        grids = socket.assigns.dynamic_grids ++ [new_grid]

        {:noreply,
         socket
         |> assign(dynamic_grids: grids)
         |> put_flash(:info, "Grid '#{name}' imported! (#{length(cols)} columns)")}

      {:error, errors} when is_list(errors) ->
        msg = Enum.join(errors, ", ")
        {:noreply, put_flash(socket, :error, "Import failed: #{msg}")}

      {:error, msg} ->
        {:noreply, put_flash(socket, :error, "Import failed: #{msg}")}
    end
  end

  @impl true
  def handle_event("import_config_error", %{"error" => msg}, socket) do
    {:noreply, put_flash(socket, :error, msg)}
  end

  # GridComponent 이벤트가 부모로 전파될 경우 안전하게 무시
  def handle_event("clear_cell_range", _params, socket), do: {:noreply, socket}

  # ── Grid Builder handle_info ──

  @doc "Grid Builder 및 GridComponent에서 전달되는 메시지를 처리한다. 그리드 생성, 파일 다운로드, 편집 이벤트 등을 지원한다."
  @impl true
  def handle_info(:grid_builder_close, socket) do
    {:noreply, assign(socket, builder_open: false)}
  end

  @impl true
  def handle_info({:grid_builder_create, params}, socket) do
    %{grid_name: grid_name, grid_id: grid_id, columns: columns, options: options} = params
    ds_type = Map.get(params, :data_source_type, "sample")

    new_grid = build_grid(grid_id, grid_name, columns, options, ds_type, params)
    grids = socket.assigns.dynamic_grids ++ [new_grid]

    row_count = length(Map.get(new_grid, :data, []))
    source_label = case ds_type do
      "schema" -> "DB Schema"
      "table" -> "DB Table"
      _ -> "Sample"
    end

    {:noreply,
     socket
     |> assign(dynamic_grids: grids, builder_open: false)
     |> put_flash(:info, "Grid '#{grid_name}' created! [#{source_label}] (#{length(columns)} columns, #{row_count} rows)")}
  end

  @impl true
  def handle_info({:grid_download_file, payload}, socket) do
    {:noreply, push_event(socket, "download_file", payload)}
  end

  @impl true
  def handle_info({:grid_cell_updated, _row_id, _field, _value}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info({:grid_row_updated, _row_id, _changed_values}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info({:grid_undo, _summary}, socket), do: {:noreply, socket}

  @impl true
  def handle_info({:grid_redo, _summary}, socket), do: {:noreply, socket}

  @impl true
  def handle_info({:grid_save_blocked, error_count}, socket) do
    {:noreply, put_flash(socket, :error, "#{error_count} validation errors. Please fix them before saving.")}
  end

  @impl true
  def handle_info({:grid_save_requested, changed_rows}, socket) do
    {:noreply, put_flash(socket, :info, "#{length(changed_rows)} rows saved.")}
  end

  @impl true
  def handle_info({:grid_row_added, _new_row}, socket), do: {:noreply, socket}

  @impl true
  def handle_info({:grid_rows_deleted, _row_ids}, socket), do: {:noreply, socket}

  @impl true
  def handle_info(:grid_discard_requested, socket), do: {:noreply, socket}

  @impl true
  def handle_info(:modal_close, socket), do: {:noreply, socket}

  # ── Helpers ──

  defp ensure_unique_id(id, grids) do
    existing_ids = MapSet.new(grids, & &1.id)

    if MapSet.member?(existing_ids, id) do
      find_unique_id(id, existing_ids, 2)
    else
      id
    end
  end

  defp find_unique_id(base_id, existing_ids, n) do
    candidate = "#{base_id}_#{n}"

    if MapSet.member?(existing_ids, candidate),
      do: find_unique_id(base_id, existing_ids, n + 1),
      else: candidate
  end

  # ── Build grid by data source type ──

  defp build_grid(grid_id, grid_name, columns, options, "schema", params) do
    schema_str = Map.get(params, :selected_schema)
    module = String.to_existing_atom(schema_str)

    %{
      id: grid_id,
      name: grid_name,
      columns: columns,
      options: Map.put(options, :show_footer, true),
      data: [],
      data_source: {LiveViewGrid.DataSource.Ecto, %{repo: LiveviewGrid.Repo, schema: module}},
      source_type: "schema"
    }
  end

  defp build_grid(grid_id, grid_name, columns, options, "table", params) do
    table = Map.get(params, :selected_table)

    %{
      id: grid_id,
      name: grid_name,
      columns: columns,
      options: Map.put(options, :show_footer, true),
      data: [],
      data_source: {LiveViewGrid.DataSource.RawTable, %{repo: LiveviewGrid.Repo, table: table, primary_key: "id"}},
      source_type: "table"
    }
  end

  defp build_grid(grid_id, grid_name, columns, options, _sample, _params) do
    sample_data = LiveViewGrid.SampleData.generate(columns, 10)

    %{
      id: grid_id,
      name: grid_name,
      columns: columns,
      options: Map.put(options, :show_footer, true),
      data: sample_data,
      source_type: "sample"
    }
  end

  @doc "Grid Builder 페이지를 렌더링한다."
  @impl true
  def render(assigns) do
    ~H"""
    <div style="padding: 30px; max-width: 1400px; margin: 0 auto;">
      <!-- Header -->
      <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 30px;">
        <div>
          <h1 style="margin: 0; font-size: 24px; color: #333; display: flex; align-items: center; gap: 10px;">
            <span style="font-size: 28px;">🏗️</span> Grid Builder
          </h1>
          <p style="margin: 5px 0 0 0; color: #888; font-size: 14px;">
            Define columns, validators, formatters and create new grids
          </p>
        </div>
        <div style="display: flex; gap: 10px; align-items: center;">
          <button
            id="config-import-btn"
            phx-hook="ConfigImport"
            style="padding: 12px 24px; background: #fff; color: #1976d2; border: 1px solid #1976d2; border-radius: 8px; cursor: pointer; font-weight: 600; font-size: 15px; display: flex; align-items: center; gap: 8px; transition: all 0.2s;"
          >
            <span style="font-size: 16px;">📥</span> Import Config
          </button>
          <button
            phx-click="open_builder"
            style="padding: 12px 24px; background: #4caf50; color: white; border: none; border-radius: 8px; cursor: pointer; font-weight: 600; font-size: 15px; display: flex; align-items: center; gap: 8px; box-shadow: 0 2px 8px rgba(76,175,80,0.3); transition: all 0.2s;"
          >
            <span style="font-size: 18px;">+</span> Create New Grid
          </button>
        </div>
      </div>

      <!-- Empty State -->
      <%= if @dynamic_grids == [] and not @builder_open do %>
        <div style="text-align: center; padding: 80px 40px; background: #fafafa; border: 2px dashed #e0e0e0; border-radius: 12px;">
          <div style="font-size: 64px; margin-bottom: 20px;">📋</div>
          <h2 style="margin: 0 0 10px 0; color: #555; font-size: 20px;">No grids created yet</h2>
          <p style="margin: 0 0 24px 0; color: #999; font-size: 14px; max-width: 400px; margin-left: auto; margin-right: auto;">
            Click "Create New Grid" to build from scratch, or "Import Config" to load a saved configuration.
          </p>
          <div style="display: flex; gap: 12px; justify-content: center;">
            <button
              id="config-import-btn-empty"
              phx-hook="ConfigImport"
              style="padding: 12px 28px; background: #fff; color: #1976d2; border: 1px solid #1976d2; border-radius: 8px; cursor: pointer; font-weight: 600; font-size: 15px;"
            >
              📥 Import Config
            </button>
            <button
              phx-click="open_builder"
              style="padding: 12px 28px; background: #4caf50; color: white; border: none; border-radius: 8px; cursor: pointer; font-weight: 600; font-size: 15px; box-shadow: 0 2px 8px rgba(76,175,80,0.3);"
            >
              + Create Your First Grid
            </button>
          </div>
        </div>
      <% end %>

      <!-- Created Grids Count -->
      <%= if @dynamic_grids != [] do %>
        <div style="margin-bottom: 20px; padding: 12px 16px; background: #e8f5e9; border-radius: 8px; display: flex; align-items: center; gap: 10px;">
          <span style="font-size: 18px;">📊</span>
          <span style="font-weight: 600; color: #2e7d32;">
            <%= length(@dynamic_grids) %> grid(s) created
          </span>
        </div>
      <% end %>

      <!-- Dynamic Grids -->
      <%= for dg <- @dynamic_grids do %>
        <div style="margin-bottom: 30px; background: white; border: 1px solid #e0e0e0; border-radius: 12px; overflow: hidden; box-shadow: 0 1px 4px rgba(0,0,0,0.06);">
          <div style="display: flex; align-items: center; justify-content: space-between; padding: 16px 20px; background: #f8f9fa; border-bottom: 1px solid #e0e0e0;">
            <h2 style="margin: 0; font-size: 17px; color: #333; display: flex; align-items: center; gap: 8px;">
              📊 <%= dg.name %>
              <span style="font-size: 12px; color: #999; font-weight: normal; padding: 2px 8px; background: #e8f5e9; border-radius: 10px;">
                Grid Builder
              </span>
              <%= if Map.get(dg, :source_type) in ["schema", "table"] do %>
                <span style="font-size: 11px; color: #1565c0; font-weight: 500; padding: 2px 8px; background: #e3f2fd; border-radius: 10px;">
                  🔗 DB
                </span>
              <% end %>
            </h2>
            <div style="display: flex; gap: 8px;">
              <button
                phx-click="export_config"
                phx-value-id={dg.id}
                style="padding: 6px 14px; background: #fff; color: #1976d2; border: 1px solid #1976d2; border-radius: 6px; cursor: pointer; font-size: 12px; font-weight: 500; transition: all 0.2s;"
              >
                📤 Export
              </button>
              <button
                phx-click="remove_dynamic_grid"
                phx-value-id={dg.id}
                style="padding: 6px 14px; background: #fff; color: #f44336; border: 1px solid #f44336; border-radius: 6px; cursor: pointer; font-size: 12px; font-weight: 500; transition: all 0.2s;"
              >
                Delete
              </button>
            </div>
          </div>
          <div style="padding: 0;">
            <.live_component
              module={LiveviewGridWeb.GridComponent}
              id={dg.id}
              data={Map.get(dg, :data, [])}
              columns={dg.columns}
              options={dg.options}
              data_source={Map.get(dg, :data_source)}
            />
          </div>
        </div>
      <% end %>

      <!-- Grid Builder Modal -->
      <%= if @builder_open do %>
        <.live_component
          module={LiveViewGridWeb.Components.GridBuilder.BuilderModal}
          id="grid-builder-modal"
        />
      <% end %>
    </div>
    """
  end
end
