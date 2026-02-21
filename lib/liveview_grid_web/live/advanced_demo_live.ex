defmodule LiveviewGridWeb.AdvancedDemoLive do
  @moduledoc """
  v0.7 Advanced Data Processing 데모
  - Grouping (다중 필드 그룹핑 + 집계)
  - Tree Grid (계층 데이터 + expand/collapse)
  - Pivot Table (행/열 차원 + 동적 컬럼)
  """

  use Phoenix.LiveView

  alias LiveViewGrid.Pivot

  @impl true
  def mount(_params, _session, socket) do
    employees = generate_employee_data()
    org_data = generate_org_data()

    {:ok, assign(socket,
      # Shared
      demo_mode: :grouping,
      # Grouping demo
      employees: employees,
      group_fields: "department",
      # Tree demo
      org_data: org_data,
      # Pivot demo
      pivot_data: employees,
      pivot_row_field: "department",
      pivot_col_field: "status",
      pivot_value_field: "salary",
      pivot_aggregate: "sum",
      pivot_columns: [],
      pivot_rows: []
    )}
  end

  @impl true
  def handle_event("switch_demo", %{"mode" => mode}, socket) do
    {:noreply, assign(socket, demo_mode: String.to_atom(mode))}
  end

  # ── Grouping 이벤트 ──

  @impl true
  def handle_event("set_group_fields", %{"fields" => fields}, socket) do
    {:noreply, assign(socket, group_fields: fields)}
  end

  # ── Pivot 이벤트 ──

  @impl true
  def handle_event("update_pivot", params, socket) do
    row_field = Map.get(params, "row_field", socket.assigns.pivot_row_field)
    col_field = Map.get(params, "col_field", socket.assigns.pivot_col_field)
    value_field = Map.get(params, "value_field", socket.assigns.pivot_value_field)
    aggregate = Map.get(params, "aggregate", socket.assigns.pivot_aggregate)

    config = %{
      row_fields: [String.to_atom(row_field)],
      col_field: String.to_atom(col_field),
      value_field: String.to_atom(value_field),
      aggregate: String.to_atom(aggregate)
    }

    {columns, rows} = Pivot.transform(socket.assigns.pivot_data, config)

    {:noreply, assign(socket,
      pivot_row_field: row_field,
      pivot_col_field: col_field,
      pivot_value_field: value_field,
      pivot_aggregate: aggregate,
      pivot_columns: columns,
      pivot_rows: rows
    )}
  end

  # ── Grid 이벤트 핸들러 (부모 LiveView로 전달되는 메시지) ──

  @impl true
  def handle_info({:grid_download_file, payload}, socket) do
    {:noreply, push_event(socket, "download_file", payload)}
  end

  @impl true
  def handle_info({:grid_cell_updated, _row_id, _field, _value}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info({:grid_save_requested, _changed_rows}, socket) do
    {:noreply, put_flash(socket, :info, "저장 완료 (데모)")}
  end

  @impl true
  def handle_info({:grid_save_blocked, count}, socket) do
    {:noreply, put_flash(socket, :error, "검증 오류 #{count}건")}
  end

  @impl true
  def handle_info({:grid_row_added, _row}, socket), do: {:noreply, socket}

  @impl true
  def handle_info({:grid_rows_deleted, _ids}, socket), do: {:noreply, socket}

  @impl true
  def handle_info(:grid_discard_requested, socket), do: {:noreply, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <div style="padding: 20px;">
      <h1>v0.7 Advanced Data Processing</h1>
      <p style="color: #666; margin-bottom: 20px;">Grouping, Tree Grid, Pivot Table</p>

      <!-- Mode Tabs -->
      <div style="display: flex; gap: 8px; margin-bottom: 24px;">
        <button
          phx-click="switch_demo"
          phx-value-mode="grouping"
          style={"padding: 10px 24px; border: 2px solid #2196f3; border-radius: 6px; cursor: pointer; font-weight: 600; #{if @demo_mode == :grouping, do: "background: #2196f3; color: white;", else: "background: white; color: #2196f3;"}"}
        >
          Grouping
        </button>
        <button
          phx-click="switch_demo"
          phx-value-mode="tree"
          style={"padding: 10px 24px; border: 2px solid #4caf50; border-radius: 6px; cursor: pointer; font-weight: 600; #{if @demo_mode == :tree, do: "background: #4caf50; color: white;", else: "background: white; color: #4caf50;"}"}
        >
          Tree Grid
        </button>
        <button
          phx-click="switch_demo"
          phx-value-mode="pivot"
          style={"padding: 10px 24px; border: 2px solid #ff9800; border-radius: 6px; cursor: pointer; font-weight: 600; #{if @demo_mode == :pivot, do: "background: #ff9800; color: white;", else: "background: white; color: #ff9800;"}"}
        >
          Pivot Table
        </button>
      </div>

      <%= case @demo_mode do %>
        <% :grouping -> %>
          <%= render_grouping_demo(assigns) %>
        <% :tree -> %>
          <%= render_tree_demo(assigns) %>
        <% :pivot -> %>
          <%= render_pivot_demo(assigns) %>
      <% end %>
    </div>
    """
  end

  defp render_grouping_demo(assigns) do
    ~H"""
    <div>
      <div style="margin-bottom: 16px; padding: 12px; background: #e3f2fd; border-radius: 6px; border-left: 4px solid #2196f3;">
        <strong>Grouping 데모</strong> - 부서/직급별 그룹핑 + 급여 집계
        <div style="margin-top: 8px; display: flex; gap: 8px; align-items: center;">
          <label>Group by:</label>
          <button phx-click="set_group_fields" phx-value-fields="department"
            style={"padding: 4px 12px; border-radius: 4px; cursor: pointer; #{if @group_fields == "department", do: "background: #2196f3; color: white; border: none;", else: "background: white; border: 1px solid #ddd;"}"}>
            부서
          </button>
          <button phx-click="set_group_fields" phx-value-fields="status"
            style={"padding: 4px 12px; border-radius: 4px; cursor: pointer; #{if @group_fields == "status", do: "background: #2196f3; color: white; border: none;", else: "background: white; border: 1px solid #ddd;"}"}>
            상태
          </button>
          <button phx-click="set_group_fields" phx-value-fields="department,position"
            style={"padding: 4px 12px; border-radius: 4px; cursor: pointer; #{if @group_fields == "department,position", do: "background: #2196f3; color: white; border: none;", else: "background: white; border: 1px solid #ddd;"}"}>
            부서 + 직급
          </button>
          <button phx-click="set_group_fields" phx-value-fields=""
            style={"padding: 4px 12px; border-radius: 4px; cursor: pointer; #{if @group_fields == "", do: "background: #f44336; color: white; border: none;", else: "background: white; border: 1px solid #ddd;"}"}>
            그룹 해제
          </button>
        </div>
      </div>

      <% group_by_atoms = @group_fields |> String.split(",", trim: true) |> Enum.map(&String.to_atom/1) %>

      <.live_component
        module={LiveviewGridWeb.GridComponent}
        id="grouping-grid"
        data={@employees}
        columns={employee_columns()}
        options={%{
          page_size: 100,
          show_footer: true,
          debug: false,
          group_by: group_by_atoms,
          group_aggregates: %{salary: :sum}
        }}
      />
    </div>
    """
  end

  defp render_tree_demo(assigns) do
    ~H"""
    <div>
      <div style="margin-bottom: 16px; padding: 12px; background: #e8f5e9; border-radius: 6px; border-left: 4px solid #4caf50;">
        <strong>Tree Grid 데모</strong> - 조직도 (parent_id 기반 계층)
      </div>

      <.live_component
        module={LiveviewGridWeb.GridComponent}
        id="tree-grid"
        data={@org_data}
        columns={org_columns()}
        options={%{
          page_size: 100,
          show_footer: true,
          debug: false,
          tree_mode: true,
          tree_parent_field: :parent_id
        }}
      />
    </div>
    """
  end

  defp render_pivot_demo(assigns) do
    ~H"""
    <div>
      <div style="margin-bottom: 16px; padding: 12px; background: #fff3e0; border-radius: 6px; border-left: 4px solid #ff9800;">
        <strong>Pivot Table 데모</strong> - 행/열 차원별 급여 집계
        <form phx-change="update_pivot" style="margin-top: 8px; display: flex; gap: 12px; align-items: center; flex-wrap: wrap;">
          <div>
            <label style="font-size: 12px; color: #666;">Row:</label>
            <select name="row_field" style="padding: 4px 8px; border: 1px solid #ddd; border-radius: 4px;">
              <option value="department" selected={@pivot_row_field == "department"}>부서</option>
              <option value="position" selected={@pivot_row_field == "position"}>직급</option>
              <option value="status" selected={@pivot_row_field == "status"}>상태</option>
            </select>
          </div>
          <div>
            <label style="font-size: 12px; color: #666;">Column:</label>
            <select name="col_field" style="padding: 4px 8px; border: 1px solid #ddd; border-radius: 4px;">
              <option value="status" selected={@pivot_col_field == "status"}>상태</option>
              <option value="department" selected={@pivot_col_field == "department"}>부서</option>
              <option value="position" selected={@pivot_col_field == "position"}>직급</option>
            </select>
          </div>
          <div>
            <label style="font-size: 12px; color: #666;">Value:</label>
            <select name="value_field" style="padding: 4px 8px; border: 1px solid #ddd; border-radius: 4px;">
              <option value="salary" selected={@pivot_value_field == "salary"}>급여</option>
              <option value="age" selected={@pivot_value_field == "age"}>나이</option>
            </select>
          </div>
          <div>
            <label style="font-size: 12px; color: #666;">Aggregate:</label>
            <select name="aggregate" style="padding: 4px 8px; border: 1px solid #ddd; border-radius: 4px;">
              <option value="sum" selected={@pivot_aggregate == "sum"}>합계</option>
              <option value="avg" selected={@pivot_aggregate == "avg"}>평균</option>
              <option value="count" selected={@pivot_aggregate == "count"}>건수</option>
              <option value="min" selected={@pivot_aggregate == "min"}>최소</option>
              <option value="max" selected={@pivot_aggregate == "max"}>최대</option>
            </select>
          </div>
        </form>
      </div>

      <!-- Pivot Table 결과 -->
      <%= if @pivot_columns != [] do %>
        <div class="lv-grid" style="max-width: 100%;">
          <div class="lv-grid__header">
            <%= for col <- @pivot_columns do %>
              <div class="lv-grid__header-cell" style={"width: #{col.width}px; flex: 0 0 #{col.width}px; #{if Map.get(col, :align) == :right, do: "justify-content: flex-end;", else: ""}"}>
                <%= col.label %>
              </div>
            <% end %>
          </div>
          <div class="lv-grid__body">
            <%= for row <- @pivot_rows do %>
              <div class="lv-grid__row">
                <%= for col <- @pivot_columns do %>
                  <div class={"lv-grid__cell #{if col.field == :_total, do: "lv-grid__pivot-total"}"} style={"width: #{col.width}px; flex: 0 0 #{col.width}px; #{if Map.get(col, :align) == :right, do: "justify-content: flex-end;", else: ""}"}>
                    <%= format_pivot_value(Map.get(row, col.field), col) %>
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>
        </div>
      <% else %>
        <div style="padding: 40px; text-align: center; color: #999; background: #fafafa; border-radius: 8px;">
          위 설정을 변경하면 피벗 테이블이 자동으로 생성됩니다.
        </div>
      <% end %>
    </div>
    """
  end

  defp format_pivot_value(nil, _col), do: "-"
  defp format_pivot_value(value, _col) when is_float(value) do
    :erlang.float_to_binary(value, decimals: 0)
  end
  defp format_pivot_value(value, _col) when is_integer(value) do
    Integer.to_string(value)
  end
  defp format_pivot_value(value, _col), do: to_string(value)

  # ── 컬럼 정의 ──

  defp employee_columns do
    [
      %{field: :id, label: "ID", width: 60, sortable: true},
      %{field: :name, label: "이름", width: 120, sortable: true, filterable: true},
      %{field: :department, label: "부서", width: 100, sortable: true, filterable: true},
      %{field: :position, label: "직급", width: 100, sortable: true, filterable: true},
      %{field: :status, label: "상태", width: 80, sortable: true, filterable: true},
      %{field: :salary, label: "급여", width: 120, sortable: true, filterable: true, filter_type: :number, align: :right},
      %{field: :age, label: "나이", width: 80, sortable: true, filterable: true, filter_type: :number}
    ]
  end

  defp org_columns do
    [
      %{field: :name, label: "이름/부서명", width: 200, sortable: true},
      %{field: :role, label: "역할", width: 120, sortable: true},
      %{field: :team, label: "팀", width: 120, sortable: true},
      %{field: :level, label: "레벨", width: 80, sortable: true}
    ]
  end

  # ── 샘플 데이터 ──

  defp generate_employee_data do
    departments = ["개발", "마케팅", "영업", "인사", "재무"]
    positions = ["사원", "대리", "과장", "차장", "부장"]
    statuses = ["재직", "휴직", "퇴직"]
    first_names = ["김철수", "이영희", "박지민", "최수진", "정민호", "강서연", "조현우", "윤하나", "장태양", "임지수"]
    last_names = ["A", "B", "C", "D", "E"]

    for i <- 1..30 do
      %{
        id: i,
        name: Enum.random(first_names) <> Enum.random(last_names),
        department: Enum.random(departments),
        position: Enum.random(positions),
        status: Enum.at(statuses, rem(i, 10) |> min(2)),
        salary: Enum.random(30..80) * 1_000_000,
        age: Enum.random(25..55)
      }
    end
  end

  defp generate_org_data do
    [
      %{id: 1, parent_id: nil, name: "CEO", role: "대표이사", team: "-", level: "C-Level"},
      %{id: 2, parent_id: 1, name: "개발본부", role: "본부장", team: "개발", level: "본부"},
      %{id: 3, parent_id: 1, name: "경영지원본부", role: "본부장", team: "경영", level: "본부"},
      %{id: 4, parent_id: 2, name: "백엔드팀", role: "팀장", team: "개발", level: "팀"},
      %{id: 5, parent_id: 2, name: "프론트엔드팀", role: "팀장", team: "개발", level: "팀"},
      %{id: 6, parent_id: 2, name: "인프라팀", role: "팀장", team: "개발", level: "팀"},
      %{id: 7, parent_id: 3, name: "인사팀", role: "팀장", team: "경영", level: "팀"},
      %{id: 8, parent_id: 3, name: "재무팀", role: "팀장", team: "경영", level: "팀"},
      %{id: 9, parent_id: 4, name: "김개발", role: "시니어", team: "백엔드", level: "팀원"},
      %{id: 10, parent_id: 4, name: "이서버", role: "주니어", team: "백엔드", level: "팀원"},
      %{id: 11, parent_id: 5, name: "박프론", role: "시니어", team: "프론트", level: "팀원"},
      %{id: 12, parent_id: 5, name: "최리액", role: "주니어", team: "프론트", level: "팀원"},
      %{id: 13, parent_id: 6, name: "정데옵", role: "시니어", team: "인프라", level: "팀원"},
      %{id: 14, parent_id: 7, name: "강인사", role: "매니저", team: "인사", level: "팀원"},
      %{id: 15, parent_id: 8, name: "조재무", role: "매니저", team: "재무", level: "팀원"}
    ]
  end
end
