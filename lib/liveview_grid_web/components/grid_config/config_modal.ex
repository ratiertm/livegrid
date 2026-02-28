defmodule LiveViewGridWeb.Components.GridConfig.ConfigModal do
  use Phoenix.LiveComponent

  @moduledoc """
  Grid Configuration Modal Component

  사용자가 그리드 설정을 동적으로 변경할 수 있는 모달 다이얼로그입니다.

  ## 기능
  - Tab 1: Column Visibility & Order (컬럼 표시/숨김 및 순서 변경)
  - Tab 2: Column Properties (컬럼 속성: label, width, align, etc.)
  - Tab 3: Formatters & Validators (포매터 및 검증자 설정)
  - Tab 4: Grid Settings (페이지 크기, 테마, 행 높이 등 그리드 옵션)

  ## 사용법

      <.config_modal id="grid_config" grid={@grid} on_apply={...} />
  """

  @doc "Grid Configuration Modal의 전체 UI를 렌더링한다. 탭 네비게이션과 설정 패널을 포함한다."
  @impl true
  def render(assigns) do
    ~H"""
    <div class="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-50">
      <div class="bg-white rounded-lg shadow-xl w-full max-w-4xl max-h-[90vh] flex flex-col">
        <!-- Modal Header -->
        <div class="flex items-center justify-between px-6 py-4 border-b border-gray-200">
          <h2 class="text-xl font-semibold text-gray-800">Grid Configuration</h2>
          <button phx-click="close" phx-target={@myself} class="text-gray-400 hover:text-gray-600">
            <span class="text-2xl">x</span>
          </button>
        </div>

        <!-- Tabs Navigation -->
        <div class="flex border-b border-gray-200 bg-gray-50 px-6">
          <%= for {tab_name, tab_label} <- [
            {"visibility", "Column Visibility & Order"},
            {"properties", "Column Properties"},
            {"formatters", "Formatters & Validators"},
            {"grid_settings", "Grid Settings"}
          ] do %>
            <button
              phx-click="select_tab"
              phx-value-tab={tab_name}
              phx-target={@myself}
              class={[
                "px-4 py-3 font-medium border-b-2 transition-colors",
                if @active_tab == tab_name do
                  "border-blue-500 text-blue-600"
                else
                  "border-transparent text-gray-600 hover:text-gray-800"
                end
              ]}
            >
              <%= tab_label %>
            </button>
          <% end %>
        </div>

        <!-- Tab Content -->
        <div class="flex-1 overflow-y-auto px-6 py-4">
          <%= case @active_tab do %>
            <% "visibility" -> %>
              <.column_visibility_tab
                myself={@myself}
                column_order={@column_order}
                columns_visible={@columns_visible}
                grid={@grid}
              />
            <% "properties" -> %>
              <.column_properties_tab
                myself={@myself}
                column_order={@column_order}
                column_configs={@column_configs}
                selected_column={@selected_column}
              />
            <% "formatters" -> %>
              <.formatters_tab
                myself={@myself}
                column_order={@column_order}
                column_configs={@column_configs}
                selected_formatter_column={@selected_formatter_column}
                validators={@validators}
              />
            <% "grid_settings" -> %>
              <.grid_settings_tab
                myself={@myself}
                grid_options={@grid_options}
              />
          <% end %>
        </div>

        <!-- Change Summary Panel (Phase 3) -->
        <%= if @changes.total > 0 do %>
          <div class="px-6 py-3 bg-amber-50 border-t border-amber-200">
            <div class="flex items-center gap-2 mb-2">
              <span class="text-amber-600 font-semibold text-sm">
                Changes: <%= @changes.total %>
              </span>
            </div>
            <ul class="text-xs text-gray-600 space-y-1 max-h-24 overflow-y-auto">
              <%= for diff <- @changes.columns do %>
                <li>
                  <code class="bg-gray-100 px-1 rounded"><%= diff.field %></code>
                  <%= diff.property %>: "<%= diff.from %>" -> "<%= diff.to %>"
                </li>
              <% end %>
              <%= for diff <- @changes.hidden do %>
                <li>
                  <code class="bg-gray-100 px-1 rounded"><%= diff.field %></code>
                  <%= if diff.action == :show, do: "show (restore)", else: "hidden" %>
                </li>
              <% end %>
              <%= for diff <- @changes.options do %>
                <li><%= diff.key %>: "<%= diff.from %>" -> "<%= diff.to %>"</li>
              <% end %>
              <%= for _diff <- Map.get(@changes, :order, []) do %>
                <li>Column order changed</li>
              <% end %>
            </ul>
          </div>
        <% end %>

        <!-- Modal Footer -->
        <div class="flex items-center justify-end gap-3 px-6 py-4 border-t border-gray-200 bg-gray-50">
          <button
            phx-click="reset"
            phx-target={@myself}
            class="px-4 py-2 text-gray-700 bg-white border border-gray-300 rounded hover:bg-gray-50"
          >
            Reset
          </button>
          <button
            phx-click="close_config_modal"
            phx-target={@parent_target}
            class="px-4 py-2 text-gray-700 bg-white border border-gray-300 rounded hover:bg-gray-50"
          >
            Cancel
          </button>
          <button
            phx-click="apply_grid_config"
            phx-target={@parent_target}
            phx-value-config={build_config_json(@column_configs, @column_order, @columns_visible, @grid_options, @validators)}
            class={[
              "px-4 py-2 rounded transition-colors",
              if @changes.total > 0 do
                "text-white bg-blue-600 hover:bg-blue-700"
              else
                "text-gray-400 bg-gray-200 cursor-not-allowed"
              end
            ]}
            disabled={@changes.total == 0}
          >
            Apply (<%= @changes.total %>)
          </button>
        </div>
      </div>
    </div>
    """
  end

  @doc "마운트 시 탭 상태, 컬럼 설정, 그리드 옵션 등 초기 상태를 설정한다."
  @impl true
  def mount(socket) do
    default_options = %{
      page_size: 20,
      theme: "light",
      virtual_scroll: false,
      row_height: 40,
      frozen_columns: 0,
      show_row_number: false,
      show_header: true,
      show_footer: true
    }

    {:ok,
     socket
     |> assign(:active_tab, "visibility")
     |> assign(:column_order, [])
     |> assign(:column_configs, %{})
     |> assign(:columns_visible, %{})
     |> assign(:selected_column, nil)
     |> assign(:selected_formatter_column, nil)
     |> assign(:validators, %{})
     |> assign(:parent_target, nil)
     |> assign(:grid_options, default_options)
     |> assign(:options_backup, default_options)
     |> assign(:changes, %{columns: [], hidden: [], options: [], total: 0})}
  end

  @doc "부모에서 전달된 Grid 정보로 컬럼/옵션 상태를 초기화한다. 최초 마운트 시에만 실행된다."
  @impl true
  def update(assigns, socket) do
    socket = assign(socket, assigns)

    # 최초 마운트 시에만 column/options state 초기화
    # (부모 재렌더링 시 사용자 편집 내용이 리셋되는 것을 방지)
    socket =
      if socket.assigns[:initialized] do
        socket
      else
        socket
        |> init_column_state()
        |> init_grid_options_state()
        |> assign(:initialized, true)
      end

    {:ok, compute_changes(socket)}
  end

  # Phase 2: Grid options 상태 초기화
  defp init_grid_options_state(socket) do
    grid = socket.assigns.grid
    options = grid.options || %{}

    # 기존 grid options를 그리드에서 읽어와서 초기화
    grid_options = %{
      page_size: Map.get(options, :page_size, 20),
      theme: Map.get(options, :theme, "light"),
      virtual_scroll: Map.get(options, :virtual_scroll, false),
      row_height: Map.get(options, :row_height, 40),
      frozen_columns: Map.get(options, :frozen_columns, 0),
      show_row_number: Map.get(options, :show_row_number, false),
      show_header: Map.get(options, :show_header, true),
      show_footer: Map.get(options, :show_footer, true)
    }

    socket
    |> assign(:grid_options, grid_options)
    |> assign(:options_backup, grid_options)
  end

  # 초기 컬럼 상태 설정
  defp init_column_state(socket) do
    grid = socket.assigns.grid

    # runtime 변경을 우선 사용, 없으면 definition 원본 (하위 호환)
    all_columns =
      cond do
        grid.state[:all_columns] -> grid.state[:all_columns]
        grid.definition -> grid.definition.columns
        true -> grid.columns
      end

    column_order =
      case grid.state[:column_order] do
        nil -> Enum.map(all_columns, & &1.field)
        order -> order
      end

    column_configs =
      Enum.reduce(all_columns, %{}, fn col, acc ->
        Map.put(acc, col.field, %{
          label: col.label,
          width: col.width,
          align: col.align,
          sortable: col.sortable,
          filterable: col.filterable,
          editable: col.editable,
          formatter: col.formatter,
          formatter_options: col.formatter_options,
          validators: col.validators
        })
      end)

    # 모든 컬럼을 기본적으로 visible로 설정
    columns_visible =
      Enum.reduce(all_columns, %{}, fn col, acc ->
        Map.put(acc, col.field, true)
      end)

    # 기존 hidden_columns 반영
    hidden = Map.get(grid.state, :hidden_columns, [])

    columns_visible =
      Enum.reduce(hidden, columns_visible, fn field, acc ->
        Map.put(acc, field, false)
      end)

    # 컬럼별 validators 맵 구성 (tuple → map 변환)
    validators =
      Enum.reduce(all_columns, %{}, fn col, acc ->
        converted = Enum.map(col.validators || [], &tuple_to_validator_map/1)
        Map.put(acc, col.field, converted)
      end)

    socket
    |> assign(:column_order, column_order)
    |> assign(:column_configs, column_configs)
    |> assign(:columns_visible, columns_visible)
    |> assign(:selected_column, nil)
    |> assign(:selected_formatter_column, nil)
    |> assign(:validators, validators)
  end

  # ============================================================================
  # Event Handlers
  # ============================================================================

  @doc "Config Modal의 이벤트를 처리한다. 탭 전환, 컬럼 속성 변경, 포매터/검증자 설정, 그리드 옵션 변경 등을 지원한다."
  @impl true
  def handle_event("select_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :active_tab, tab)}
  end

  def handle_event("reset", _params, socket) do
    grid = socket.assigns.grid

    # definition.options가 있으면 grid_options도 원본으로
    original_options =
      if grid.definition do
        Map.merge(
          LiveViewGrid.Grid.default_options(),
          grid.definition.options
        )
        |> Map.take([:page_size, :theme, :virtual_scroll, :row_height,
                     :frozen_columns, :show_row_number, :show_header, :show_footer])
      else
        socket.assigns.options_backup
      end

    socket =
      socket
      |> assign(:grid_options, original_options)
      |> init_column_state()
      |> compute_changes()

    {:noreply, socket}
  end

  # Phase 2: Grid settings form update
  def handle_event("update_grid_option", %{"option" => option_key, "value" => value}, socket) do
    coerced_value = coerce_option_value(option_key, value)
    key_atom = String.to_atom(option_key)
    new_options = Map.put(socket.assigns.grid_options, key_atom, coerced_value)
    {:noreply, socket |> assign(:grid_options, new_options) |> compute_changes()}
  end

  # Phase 2: Handle checkbox for grid settings (checkboxes send phx-click, not phx-change)
  def handle_event("toggle_grid_option", %{"option" => option_key}, socket) do
    key_atom = String.to_atom(option_key)
    current_value = Map.get(socket.assigns.grid_options, key_atom, false)
    new_options = Map.put(socket.assigns.grid_options, key_atom, !current_value)
    {:noreply, socket |> assign(:grid_options, new_options) |> compute_changes()}
  end

  def handle_event("close", _params, socket) do
    send(self(), :modal_close)
    {:noreply, socket}
  end

  # Tab 1: Toggle column visibility
  # Tab 1: Drag to reorder columns
  def handle_event("reorder_columns", %{"order" => order}, socket) do
    new_order =
      Enum.map(order, fn field_str ->
        String.to_existing_atom(field_str)
      end)

    {:noreply, socket |> assign(:column_order, new_order) |> compute_changes()}
  end

  def handle_event("toggle_column_visibility", %{"field" => field_str}, socket) do
    field = String.to_existing_atom(field_str)
    columns_visible = socket.assigns.columns_visible
    current = Map.get(columns_visible, field, true)
    updated = Map.put(columns_visible, field, !current)
    {:noreply, socket |> assign(:columns_visible, updated) |> compute_changes()}
  end

  # Tab 2: Select a column to edit
  def handle_event("select_column", %{"column" => field_str}, socket) do
    field =
      case field_str do
        "" -> nil
        f -> String.to_existing_atom(f)
      end

    {:noreply, assign(socket, :selected_column, field)}
  end

  # Tab 2: Update a column property
  def handle_event("update_property", %{"field" => field_str, "key" => key_str} = params, socket) do
    value = params["value"] || params["val"]
    field = String.to_existing_atom(field_str)
    key = String.to_atom(key_str)
    column_configs = socket.assigns.column_configs
    current = Map.get(column_configs, field, %{})

    coerced_value =
      case {key, value} do
        {:width, v} ->
          case Integer.parse(v) do
            {int, _} -> int
            :error -> current[:width]
          end

        {:sortable, v} -> v == "true"
        {:filterable, v} -> v == "true"
        {:editable, v} -> v == "true"
        {:align, v} -> String.to_atom(v)
        {_k, v} -> v
      end

    updated_config = Map.put(current, key, coerced_value)
    updated_configs = Map.put(column_configs, field, updated_config)
    {:noreply, socket |> assign(:column_configs, updated_configs) |> compute_changes()}
  end

  # Tab 3: Select column for formatter
  def handle_event("select_formatter_column", %{"column" => field_str}, socket) do
    field =
      case field_str do
        "" -> nil
        f -> String.to_existing_atom(f)
      end

    {:noreply, assign(socket, :selected_formatter_column, field)}
  end

  # Tab 3: Select formatter for a column
  def handle_event("select_formatter", %{"field" => field_str, "formatter" => fmt_str}, socket) do
    field = String.to_existing_atom(field_str)
    formatter = if fmt_str == "", do: nil, else: String.to_atom(fmt_str)
    column_configs = socket.assigns.column_configs
    current = Map.get(column_configs, field, %{})
    updated = Map.put(current, :formatter, formatter)
    updated_configs = Map.put(column_configs, field, updated)
    {:noreply, socket |> assign(:column_configs, updated_configs) |> compute_changes()}
  end

  # Tab 3: Add a validator placeholder
  def handle_event("add_validator", %{"field" => field_str}, socket) do
    field = String.to_existing_atom(field_str)
    validators = socket.assigns.validators
    current = Map.get(validators, field, [])
    new_validator = %{type: "required", message: "This field is required", enabled: true}
    updated = Map.put(validators, field, current ++ [new_validator])
    {:noreply, socket |> assign(:validators, updated) |> compute_changes()}
  end

  # Tab 3: Remove a validator by index
  def handle_event("remove_validator", %{"field" => field_str, "index" => idx_str}, socket) do
    field = String.to_existing_atom(field_str)
    index = String.to_integer(idx_str)
    validators = socket.assigns.validators
    current = Map.get(validators, field, [])
    updated_list = List.delete_at(current, index)
    updated = Map.put(validators, field, updated_list)
    {:noreply, socket |> assign(:validators, updated) |> compute_changes()}
  end

  # Tab 3: Toggle validator enabled/disabled
  def handle_event("toggle_validator", %{"field" => field_str, "index" => idx_str}, socket) do
    field = String.to_existing_atom(field_str)
    index = String.to_integer(idx_str)
    validators = socket.assigns.validators
    current = Map.get(validators, field, [])

    updated_list =
      List.update_at(current, index, fn v ->
        Map.update(v, :enabled, true, &(!&1))
      end)

    updated = Map.put(validators, field, updated_list)
    {:noreply, assign(socket, :validators, updated)}
  end

  # ============================================================================
  # Change Tracking (Phase 3: Preview & Apply)
  # ============================================================================

  defp compute_changes(socket) do
    grid = socket.assigns.grid

    original_columns =
      cond do
        grid.definition -> grid.definition.columns
        grid.state[:all_columns] -> grid.state[:all_columns]
        true -> grid.columns
      end

    current_configs = socket.assigns.column_configs
    current_options = socket.assigns.grid_options

    original_options =
      if grid.definition do
        Map.merge(LiveViewGrid.Grid.default_options(), grid.definition.options)
      else
        grid.options
      end

    column_diffs =
      Enum.flat_map(current_configs, fn {field, config} ->
        original = Enum.find(original_columns, &(&1.field == field)) || %{}
        diff_column(field, original, config)
      end)

    # hidden columns diff: grid에 적용된 상태 vs 모달에서 변경된 상태 비교
    applied_hidden = MapSet.new(Map.get(grid.state, :hidden_columns, []))
    current_hidden =
      socket.assigns.columns_visible
      |> Enum.filter(fn {_, v} -> !v end)
      |> Enum.map(fn {f, _} -> f end)
      |> MapSet.new()

    # 새로 숨긴 컬럼 (기존엔 보였는데 이제 숨김)
    newly_hidden =
      MapSet.difference(current_hidden, applied_hidden)
      |> Enum.map(fn f -> %{type: :hidden, field: f, action: :hide} end)

    # 다시 보이게 한 컬럼 (기존엔 숨겨졌는데 이제 보임)
    newly_visible =
      MapSet.difference(applied_hidden, current_hidden)
      |> Enum.map(fn f -> %{type: :hidden, field: f, action: :show} end)

    hidden_diffs = newly_hidden ++ newly_visible

    option_diffs = diff_options(original_options, current_options)

    # Validator 변경 감지: @validators vs 원본 validators 비교
    validator_diffs =
      Enum.flat_map(socket.assigns.validators, fn {field, current_vals} ->
        original_col = Enum.find(original_columns, &(&1.field == field)) || %{}
        original_vals = original_col[:validators] || []
        if length(current_vals) != length(original_vals) do
          [%{type: :validator, field: field, from: length(original_vals), to: length(current_vals)}]
        else
          []
        end
      end)

    # Column order diff: 현재 순서 vs 원본 순서 비교
    original_order = Enum.map(original_columns, & &1.field)
    current_order = socket.assigns.column_order
    order_diffs =
      if current_order != original_order do
        [%{type: :order, from: original_order, to: current_order}]
      else
        []
      end

    changes = %{
      columns: column_diffs,
      hidden: hidden_diffs,
      options: option_diffs,
      validators: validator_diffs,
      order: order_diffs,
      total: length(column_diffs) + length(hidden_diffs) + length(option_diffs) + length(validator_diffs) + length(order_diffs)
    }

    assign(socket, :changes, changes)
  end

  defp diff_column(field, original, current) do
    [:label, :width, :align, :sortable, :filterable, :editable, :formatter]
    |> Enum.filter(fn key ->
      Map.get(original, key) != Map.get(current, key)
    end)
    |> Enum.map(fn key ->
      %{
        type: :column,
        field: field,
        property: key,
        from: Map.get(original, key),
        to: Map.get(current, key)
      }
    end)
  end

  defp diff_options(original, current) do
    tracked_keys = [:page_size, :theme, :virtual_scroll, :row_height,
                    :frozen_columns, :show_row_number, :show_header, :show_footer]

    Enum.filter(tracked_keys, fn k ->
      Map.get(original, k) != Map.get(current, k)
    end)
    |> Enum.map(fn k ->
      %{type: :option, key: k, from: Map.get(original, k), to: Map.get(current, k)}
    end)
  end

  # ============================================================================
  # Helpers
  # ============================================================================

  # Build JSON payload for Apply button (Phase 1 + Phase 2)
  defp build_config_json(column_configs, column_order, columns_visible, grid_options, validators) do
    hidden_columns =
      columns_visible
      |> Enum.filter(fn {_field, visible} -> !visible end)
      |> Enum.map(fn {field, _} -> Atom.to_string(field) end)

    columns_payload = build_column_changes(column_configs, validators)

    # Phase 2: convert atom keys to string keys for JSON
    options_payload =
      Map.new(grid_options, fn {k, v} ->
        key = if is_atom(k), do: Atom.to_string(k), else: k
        {key, v}
      end)

    Jason.encode!(%{
      "columns" => columns_payload,
      "column_order" => Enum.map(column_order, &Atom.to_string/1),
      "hidden_columns" => hidden_columns,
      "options" => options_payload
    })
  end

  # Phase 2: Type coercion for grid option values from form string inputs
  defp coerce_option_value(key, value) when is_binary(value) do
    case key do
      "page_size" -> String.to_integer(value)
      "row_height" -> String.to_integer(value)
      "frozen_columns" -> String.to_integer(value)
      "virtual_scroll" -> value == "true"
      "show_row_number" -> value == "true"
      "show_header" -> value == "true"
      "show_footer" -> value == "true"
      "debug_mode" -> value == "true"
      "theme" -> value
      _ -> value
    end
  end

  defp build_column_changes(column_configs, validators) do
    Enum.map(column_configs, fn {field, config} ->
      # @validators에서 최신 validator 목록 사용 (Tab 3에서 추가/삭제된 것 반영)
      field_validators = Map.get(validators, field, config.validators || [])

      %{
        "field" => Atom.to_string(field),
        "label" => config.label,
        "width" => config.width,
        "align" => to_string(config.align),
        "sortable" => config.sortable,
        "filterable" => config.filterable,
        "editable" => config.editable,
        "formatter" => if(config.formatter, do: to_string(config.formatter), else: nil),
        "formatter_options" => config.formatter_options,
        "validators" => Enum.map(field_validators, &serialize_validator/1)
      }
    end)
  end

  defp serialize_validator({:required, msg}), do: %{"type" => "required", "message" => msg}
  defp serialize_validator({:min, val, msg}), do: %{"type" => "min", "value" => val, "message" => msg}
  defp serialize_validator({:max, val, msg}), do: %{"type" => "max", "value" => val, "message" => msg}
  defp serialize_validator({:pattern, _regex, msg}), do: %{"type" => "pattern", "message" => msg}
  defp serialize_validator(other) when is_map(other) do
    other
    |> Map.drop([:enabled])
    |> Map.new(fn
      {k, v} when is_atom(k) -> {Atom.to_string(k), v}
      {k, v} -> {k, v}
    end)
  end
  defp serialize_validator(_), do: %{"type" => "unknown"}

  # tuple 형태 validator를 Tab 3 UI용 map 형태로 변환
  defp tuple_to_validator_map({:required, msg}), do: %{type: "required", message: msg, enabled: true}
  defp tuple_to_validator_map({:min, val, msg}), do: %{type: "min", value: val, message: msg, enabled: true}
  defp tuple_to_validator_map({:max, val, msg}), do: %{type: "max", value: val, message: msg, enabled: true}
  defp tuple_to_validator_map({:pattern, _regex, msg}), do: %{type: "pattern", message: msg, enabled: true}
  defp tuple_to_validator_map(%{} = map), do: Map.put_new(map, :enabled, true)
  defp tuple_to_validator_map(_), do: %{type: "unknown", message: "", enabled: true}

  # ============================================================================
  # Tab 1: Column Visibility & Order
  # ============================================================================

  defp column_visibility_tab(assigns) do
    ~H"""
    <div class="py-4">
      <h3 class="text-lg font-semibold text-gray-800 mb-4">Show/Hide & Reorder Columns</h3>
      <p class="text-gray-600 text-sm mb-4">
        Check to show columns, uncheck to hide. Drag to reorder.
      </p>

      <div id="config-sortable-list" phx-hook="ConfigSortable" phx-target={@myself}
           class="space-y-2 border border-gray-200 rounded p-3 bg-gray-50">
        <%= for field <- @column_order do %>
          <% visible = Map.get(@columns_visible, field, true) %>
          <div data-sortable-item data-field={field} class={[
            "flex items-center p-2 rounded border transition-colors cursor-grab active:cursor-grabbing",
            if visible do
              "bg-white border-gray-200 hover:bg-blue-50"
            else
              "bg-gray-100 border-gray-200 opacity-60"
            end
          ]}>
            <span class="mr-2 text-gray-400 select-none">::</span>
            <input
              type="checkbox"
              checked={visible}
              phx-click="toggle_column_visibility"
              phx-value-field={field}
              phx-target={@myself}
              class="w-4 h-4 text-blue-600 cursor-pointer"
            />
            <span class={[
              "ml-3 font-medium select-none",
              (if visible, do: "text-gray-700", else: "text-gray-400 line-through")
            ]}>
              <%= field %>
            </span>
            <span class="ml-2 text-xs text-gray-400 select-none">
              (<%= if visible, do: "visible", else: "hidden" %>)
            </span>
          </div>
        <% end %>
      </div>

      <p class="text-xs text-gray-500 mt-3 italic">
        Tip: Hidden columns can be re-shown by checking the checkbox.
      </p>
    </div>
    """
  end

  # ============================================================================
  # Tab 2: Column Properties
  # ============================================================================

  defp column_properties_tab(assigns) do
    ~H"""
    <div class="py-4">
      <div class="grid grid-cols-3 gap-6">
        <!-- Column Selector -->
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-2">Select Column</label>
          <form phx-change="select_column" phx-target={@myself}>
            <select
              id="column_selector"
              class="w-full px-3 py-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
              name="column"
            >
              <option value="">-- Select a column --</option>
              <%= for field <- @column_order do %>
                <% cfg = Map.get(@column_configs, field, %{}) %>
                <option value={field} selected={@selected_column == field}>
                  <%= cfg[:label] || field %>
                </option>
              <% end %>
            </select>
          </form>

          <%= if @selected_column do %>
            <div class="mt-4 space-y-2 text-xs text-gray-500">
              <p class="font-semibold text-gray-600">Quick Info:</p>
              <p>Field: <code class="bg-gray-100 px-1 rounded"><%= @selected_column %></code></p>
              <% cfg = Map.get(@column_configs, @selected_column, %{}) %>
              <p>Width: <%= cfg[:width] || "auto" %>px</p>
              <p>Align: <%= cfg[:align] || "left" %></p>
            </div>
          <% end %>
        </div>

        <!-- Properties Form or Empty State -->
        <div class="col-span-2">
          <%= if @selected_column do %>
            <% cfg = Map.get(@column_configs, @selected_column, %{}) %>
            <div class="space-y-4">
              <!-- Label -->
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Label</label>
                <form phx-change="update_property" phx-target={@myself}>
                  <input type="hidden" name="field" value={@selected_column} />
                  <input type="hidden" name="key" value="label" />
                  <input
                    type="text"
                    value={cfg[:label]}
                    name="value"
                    class="w-full px-3 py-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
                    placeholder="Column label"
                  />
                </form>
              </div>

              <!-- Width -->
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Width (px)</label>
                <form phx-change="update_property" phx-target={@myself}>
                  <input type="hidden" name="field" value={@selected_column} />
                  <input type="hidden" name="key" value="width" />
                  <input
                    type="number"
                    value={if is_integer(cfg[:width]), do: cfg[:width], else: 100}
                    min="50"
                    max="500"
                    name="value"
                    class="w-full px-3 py-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </form>
              </div>

              <!-- Alignment -->
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Alignment</label>
                <form phx-change="update_property" phx-target={@myself}>
                  <input type="hidden" name="field" value={@selected_column} />
                  <input type="hidden" name="key" value="align" />
                  <select
                    name="value"
                    class="w-full px-3 py-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
                  >
                    <option value="left" selected={cfg[:align] == :left || cfg[:align] == "left"}>Left</option>
                    <option value="center" selected={cfg[:align] == :center || cfg[:align] == "center"}>Center</option>
                    <option value="right" selected={cfg[:align] == :right || cfg[:align] == "right"}>Right</option>
                  </select>
                </form>
              </div>

              <!-- Boolean Flags -->
              <div class="grid grid-cols-3 gap-4">
                <label class="flex items-center gap-2">
                  <input
                    type="checkbox"
                    checked={cfg[:sortable]}
                    phx-click="update_property"
                    phx-target={@myself}
                    phx-value-field={@selected_column}
                    phx-value-key="sortable"
                    phx-value-val={if cfg[:sortable], do: "false", else: "true"}
                    class="w-4 h-4 text-blue-600 cursor-pointer"
                  />
                  <span class="text-sm text-gray-700">Sortable</span>
                </label>
                <label class="flex items-center gap-2">
                  <input
                    type="checkbox"
                    checked={cfg[:filterable]}
                    phx-click="update_property"
                    phx-target={@myself}
                    phx-value-field={@selected_column}
                    phx-value-key="filterable"
                    phx-value-val={if cfg[:filterable], do: "false", else: "true"}
                    class="w-4 h-4 text-blue-600 cursor-pointer"
                  />
                  <span class="text-sm text-gray-700">Filterable</span>
                </label>
                <label class="flex items-center gap-2">
                  <input
                    type="checkbox"
                    checked={cfg[:editable]}
                    phx-click="update_property"
                    phx-target={@myself}
                    phx-value-field={@selected_column}
                    phx-value-key="editable"
                    phx-value-val={if cfg[:editable], do: "false", else: "true"}
                    class="w-4 h-4 text-blue-600 cursor-pointer"
                  />
                  <span class="text-sm text-gray-700">Editable</span>
                </label>
              </div>
            </div>
          <% else %>
            <div class="flex items-center justify-center h-full text-gray-400">
              <p>Select a column to edit its properties</p>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  # ============================================================================
  # Tab 4: Grid Settings (Phase 2)
  # ============================================================================

  defp grid_settings_tab(assigns) do
    ~H"""
    <div class="grid-settings-tab py-4">
      <!-- Section 1: Pagination Settings -->
      <div class="form-section mb-6 pb-6 border-b border-gray-200">
        <h3 class="text-base font-semibold text-gray-800 mb-4">Pagination Settings</h3>

        <div class="form-group mb-4">
          <label class="block text-sm font-medium text-gray-700 mb-1" for="page_size">
            Page Size
          </label>
          <form phx-change="update_grid_option" phx-target={@myself}>
            <input type="hidden" name="option" value="page_size" />
            <select
              id="page_size"
              name="value"
              class="w-full px-3 py-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="10" selected={@grid_options[:page_size] == 10}>10 rows per page</option>
              <option value="25" selected={@grid_options[:page_size] == 25}>25 rows per page</option>
              <option value="50" selected={@grid_options[:page_size] == 50}>50 rows per page</option>
              <option value="100" selected={@grid_options[:page_size] == 100}>100 rows per page</option>
              <%= if @grid_options[:page_size] not in [10, 25, 50, 100] do %>
                <option value={@grid_options[:page_size]} selected={true}>
                  <%= @grid_options[:page_size] %> rows per page (custom)
                </option>
              <% end %>
            </select>
          </form>
          <p class="help-text text-xs text-gray-500 mt-1">Number of rows to display per page</p>
        </div>
      </div>

      <!-- Section 2: Display Settings -->
      <div class="form-section mb-6 pb-6 border-b border-gray-200">
        <h3 class="text-base font-semibold text-gray-800 mb-4">Display Settings</h3>

        <div class="flex items-center gap-3 p-3 mb-3 bg-gray-50 rounded border border-gray-200">
          <input
            type="checkbox"
            id="show_row_number"
            checked={@grid_options[:show_row_number]}
            phx-click="toggle_grid_option"
            phx-value-option="show_row_number"
            phx-target={@myself}
            class="w-4 h-4 text-blue-600 cursor-pointer"
          />
          <div>
            <label for="show_row_number" class="text-sm font-medium text-gray-700 cursor-pointer">
              Show Row Numbers
            </label>
            <p class="text-xs text-gray-500 mt-0.5">Display sequential row numbers in the left margin</p>
          </div>
        </div>

        <div class="flex items-center gap-3 p-3 mb-3 bg-gray-50 rounded border border-gray-200">
          <input
            type="checkbox"
            id="show_header"
            checked={@grid_options[:show_header]}
            phx-click="toggle_grid_option"
            phx-value-option="show_header"
            phx-target={@myself}
            class="w-4 h-4 text-blue-600 cursor-pointer"
          />
          <div>
            <label for="show_header" class="text-sm font-medium text-gray-700 cursor-pointer">
              Show Header Row
            </label>
            <p class="text-xs text-gray-500 mt-0.5">Display column headers at the top of the grid</p>
          </div>
        </div>

        <div class="flex items-center gap-3 p-3 mb-3 bg-gray-50 rounded border border-gray-200">
          <input
            type="checkbox"
            id="show_footer"
            checked={@grid_options[:show_footer]}
            phx-click="toggle_grid_option"
            phx-value-option="show_footer"
            phx-target={@myself}
            class="w-4 h-4 text-blue-600 cursor-pointer"
          />
          <div>
            <label for="show_footer" class="text-sm font-medium text-gray-700 cursor-pointer">
              Show Footer Row
            </label>
            <p class="text-xs text-gray-500 mt-0.5">Display aggregation/summary footer at the bottom</p>
          </div>
        </div>
      </div>

      <!-- Section 3: Theme Settings -->
      <div class="form-section mb-6 pb-6 border-b border-gray-200">
        <h3 class="text-base font-semibold text-gray-800 mb-4">Theme Settings</h3>

        <div class="form-group mb-4">
          <label class="block text-sm font-medium text-gray-700 mb-1" for="theme">Theme</label>
          <form phx-change="update_grid_option" phx-target={@myself}>
            <input type="hidden" name="option" value="theme" />
            <select
              id="theme"
              name="value"
              class="w-full px-3 py-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="light" selected={@grid_options[:theme] == "light"}>Light (Default)</option>
              <option value="dark" selected={@grid_options[:theme] == "dark"}>Dark</option>
              <option value="custom" selected={@grid_options[:theme] == "custom"}>Custom</option>
            </select>
          </form>
          <p class="text-xs text-gray-500 mt-1">Choose color scheme for the grid</p>

          <!-- Theme Preview -->
          <div class="mt-3">
            <div class={[
              "w-full p-4 rounded text-center font-medium transition-all",
              case @grid_options[:theme] do
                "dark" -> "bg-gray-800 border border-gray-600 text-white"
                "custom" -> "bg-gray-100 border border-gray-400 text-gray-700"
                _ -> "bg-white border border-gray-300 text-gray-700"
              end
            ]}>
              Theme Preview: <%= @grid_options[:theme] || "light" %>
            </div>
          </div>
        </div>
      </div>

      <!-- Section 4: Scroll & Row Settings -->
      <div class="form-section mb-6 pb-6 border-b border-gray-200">
        <h3 class="text-base font-semibold text-gray-800 mb-4">Scroll & Row Settings</h3>

        <div class="flex items-center gap-3 p-3 mb-4 bg-gray-50 rounded border border-gray-200">
          <input
            type="checkbox"
            id="virtual_scroll"
            checked={@grid_options[:virtual_scroll]}
            phx-click="toggle_grid_option"
            phx-value-option="virtual_scroll"
            phx-target={@myself}
            class="w-4 h-4 text-blue-600 cursor-pointer"
          />
          <div>
            <label for="virtual_scroll" class="text-sm font-medium text-gray-700 cursor-pointer">
              Enable Virtual Scrolling
            </label>
            <p class="text-xs text-gray-500 mt-0.5">
              For large datasets (1000+ rows), render only visible rows for performance
            </p>
          </div>
        </div>

        <div class="form-group">
          <label class="block text-sm font-medium text-gray-700 mb-1">
            Row Height:
            <span class="font-mono bg-gray-100 px-1.5 py-0.5 rounded text-sm ml-1">
              <%= @grid_options[:row_height] %> px
            </span>
          </label>
          <form phx-change="update_grid_option" phx-target={@myself}>
            <input type="hidden" name="option" value="row_height" />
            <input
              type="range"
              id="row_height"
              name="value"
              min="32"
              max="80"
              value={@grid_options[:row_height]}
              class="w-full h-2 bg-gray-200 rounded-lg appearance-none cursor-pointer accent-blue-600"
            />
          </form>
          <div class="flex justify-between text-xs text-gray-500 mt-1">
            <span>32px (Compact)</span>
            <span>80px (Spacious)</span>
          </div>
          <p class="text-xs text-gray-500 mt-1">Height of each row in pixels (affects vertical spacing)</p>
        </div>
      </div>

      <!-- Section 5: Column Freezing -->
      <div class="form-section">
        <h3 class="text-base font-semibold text-gray-800 mb-4">Column Freezing</h3>

        <div class="form-group">
          <label class="block text-sm font-medium text-gray-700 mb-1" for="frozen_columns">
            Frozen Columns
          </label>
          <form phx-change="update_grid_option" phx-target={@myself}>
            <input type="hidden" name="option" value="frozen_columns" />
            <input
              type="number"
              id="frozen_columns"
              name="value"
              min="0"
              max="10"
              value={@grid_options[:frozen_columns]}
              class="w-32 px-3 py-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </form>
          <p class="text-xs text-gray-500 mt-1">
            Number of leftmost columns to keep visible when horizontal scrolling (0 = no frozen columns)
          </p>
        </div>
      </div>
    </div>
    """
  end

  # ============================================================================
  # Tab 3: Formatters & Validators
  # ============================================================================

  defp formatters_tab(assigns) do
    ~H"""
    <div class="py-4">
      <div class="grid grid-cols-3 gap-6">
        <!-- Column Selector -->
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-2">Select Column</label>
          <form phx-change="select_formatter_column" phx-target={@myself}>
            <select
              id="formatter_column_selector"
              class="w-full px-3 py-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
              name="column"
            >
              <option value="">-- Select a column --</option>
              <%= for field <- @column_order do %>
                <% cfg = Map.get(@column_configs, field, %{}) %>
                <option value={field} selected={@selected_formatter_column == field}>
                  <%= cfg[:label] || field %>
                </option>
              <% end %>
            </select>
          </form>
        </div>

        <!-- Right panel -->
        <div class="col-span-2">
          <%= if @selected_formatter_column do %>
            <% cfg = Map.get(@column_configs, @selected_formatter_column, %{}) %>
            <% col_validators = Map.get(@validators, @selected_formatter_column, []) %>

            <!-- Formatter Section -->
            <div class="mb-6">
              <h4 class="text-sm font-semibold text-gray-700 mb-3">Formatter</h4>
              <form phx-change="select_formatter" phx-target={@myself}>
                <input type="hidden" name="field" value={@selected_formatter_column} />
                <select
                  name="formatter"
                  class="w-full px-3 py-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
                >
                  <option value="" selected={is_nil(cfg[:formatter])}>-- No Formatter --</option>
                  <option value="currency" selected={cfg[:formatter] == :currency}>Currency</option>
                  <option value="number" selected={cfg[:formatter] == :number}>Number</option>
                  <option value="date" selected={cfg[:formatter] == :date}>Date</option>
                  <option value="percent" selected={cfg[:formatter] == :percent}>Percent</option>
                  <option value="badge" selected={cfg[:formatter] == :badge}>Badge</option>
                </select>
              </form>

              <!-- Formatter-specific preview -->
              <%= if cfg[:formatter] do %>
                <div class="mt-3 p-3 bg-gray-50 rounded border border-gray-200 text-sm text-gray-600">
                  <span class="font-medium">Active formatter:</span>
                  <code class="ml-2 bg-gray-200 px-1 rounded"><%= cfg[:formatter] %></code>
                </div>
              <% end %>
            </div>

            <!-- Validators Section -->
            <div>
              <div class="flex items-center justify-between mb-3">
                <h4 class="text-sm font-semibold text-gray-700">Validators</h4>
                <button
                  type="button"
                  phx-click="add_validator"
                  phx-value-field={@selected_formatter_column}
                  phx-target={@myself}
                  class="px-3 py-1 text-sm text-white bg-blue-600 rounded hover:bg-blue-700"
                >
                  + Add Validator
                </button>
              </div>

              <div class="space-y-3">
                <%= if Enum.empty?(col_validators) do %>
                  <p class="text-sm text-gray-400 italic">No validators configured for this column.</p>
                <% else %>
                  <%= for {validator, index} <- Enum.with_index(col_validators) do %>
                    <div class={[
                      "flex items-center gap-3 p-3 rounded border",
                      if Map.get(validator, :enabled, true) do
                        "bg-white border-gray-200"
                      else
                        "bg-gray-50 border-gray-200 opacity-60"
                      end
                    ]}>
                      <input
                        type="checkbox"
                        checked={Map.get(validator, :enabled, true)}
                        phx-click="toggle_validator"
                        phx-value-field={@selected_formatter_column}
                        phx-value-index={index}
                        phx-target={@myself}
                        class="w-4 h-4 text-blue-600 cursor-pointer"
                      />
                      <span class="text-sm font-medium text-gray-700 flex-1">
                        <%= Map.get(validator, :type, "unknown") %>
                      </span>
                      <span class="text-xs text-gray-500">
                        <%= Map.get(validator, :message, "") %>
                      </span>
                      <button
                        type="button"
                        phx-click="remove_validator"
                        phx-value-field={@selected_formatter_column}
                        phx-value-index={index}
                        phx-target={@myself}
                        class="text-red-400 hover:text-red-600 text-sm"
                      >
                        Remove
                      </button>
                    </div>
                  <% end %>
                <% end %>
              </div>

              <p class="text-xs text-gray-500 mt-3 italic">
                Validators will be applied when the grid updates.
              </p>
            </div>
          <% else %>
            <div class="flex items-center justify-center h-full text-gray-400">
              <p>Select a column to configure formatter and validators</p>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
