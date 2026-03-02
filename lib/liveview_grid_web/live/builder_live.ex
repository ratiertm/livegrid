defmodule LiveviewGridWeb.BuilderLive do
  @moduledoc """
  Grid Builder - 새 그리드를 정의하고 생성하는 독립 페이지
  """

  use Phoenix.LiveView

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

  @impl true
  def handle_event("export_dynamic_grid", %{"id" => grid_id}, socket) do
    case Enum.find(socket.assigns.dynamic_grids, &(&1.id == grid_id)) do
      nil ->
        {:noreply, socket}

      dg ->
        json = export_grid_to_json(dg)
        content = Base.encode64(json)
        name_slug = String.replace(dg.name, ~r/[^\w가-힣]+/u, "_") |> String.trim("_")
        filename = "grid_config_#{name_slug}_#{System.system_time(:second)}.json"

        {:noreply, push_event(socket, "download_file", %{
          content: content,
          filename: filename,
          mime_type: "application/json"
        })}
    end
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

  # ── Export helper ──

  defp export_grid_to_json(dg) do
    columns =
      Enum.map(dg.columns, fn col ->
        %{
          field: to_string(col.field),
          label: col.label,
          type: to_string(col.type),
          width: if(col[:width] == :auto or is_nil(col[:width]), do: "auto", else: col[:width]),
          align: to_string(col[:align] || :left),
          sortable: col[:sortable] == true,
          filterable: col[:filterable] == true,
          editable: col[:editable] == true,
          editor_type: to_string(col[:editor_type] || :text),
          formatter: if(col[:formatter], do: to_string(col[:formatter])),
          validators: col[:validators] || [],
          renderer: col[:renderer],
          renderer_options: col[:renderer_options] || %{}
        }
      end)

    Jason.encode!(%{
      version: "1.0",
      grid_name: dg.name,
      grid_id: dg.id,
      data_source_type: Map.get(dg, :source_type, "sample"),
      grid_options: dg.options,
      columns: columns
    }, pretty: true)
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
        <button
          phx-click="open_builder"
          style="padding: 12px 24px; background: #4caf50; color: white; border: none; border-radius: 8px; cursor: pointer; font-weight: 600; font-size: 15px; display: flex; align-items: center; gap: 8px; box-shadow: 0 2px 8px rgba(76,175,80,0.3); transition: all 0.2s;"
        >
          <span style="font-size: 18px;">+</span> Create New Grid
        </button>
      </div>

      <!-- Empty State -->
      <%= if @dynamic_grids == [] and not @builder_open do %>
        <div style="text-align: center; padding: 80px 40px; background: #fafafa; border: 2px dashed #e0e0e0; border-radius: 12px;">
          <div style="font-size: 64px; margin-bottom: 20px;">📋</div>
          <h2 style="margin: 0 0 10px 0; color: #555; font-size: 20px;">No grids created yet</h2>
          <p style="margin: 0 0 24px 0; color: #999; font-size: 14px; max-width: 400px; margin-left: auto; margin-right: auto;">
            Click the "Create New Grid" button to define columns, set up validators and formatters, and generate a new grid.
          </p>
          <button
            phx-click="open_builder"
            style="padding: 12px 28px; background: #4caf50; color: white; border: none; border-radius: 8px; cursor: pointer; font-weight: 600; font-size: 15px; box-shadow: 0 2px 8px rgba(76,175,80,0.3);"
          >
            + Create Your First Grid
          </button>
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
                phx-click="export_dynamic_grid"
                phx-value-id={dg.id}
                style="padding: 6px 14px; background: #fff; color: #1976d2; border: 1px solid #1976d2; border-radius: 6px; cursor: pointer; font-size: 12px; font-weight: 500; transition: all 0.2s;"
              >
                Export
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
