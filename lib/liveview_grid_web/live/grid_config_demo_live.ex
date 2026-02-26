defmodule LiveviewGridWeb.GridConfigDemoLive do
  @moduledoc """
  Grid Configuration Modal Demo

  Grid Configuration 기능을 테스트하는 간단한 데모 페이지.
  - Grid 설정 모달 열기/닫기
  - 컬럼 속성 변경 (Tab 1, 2, 3)
  - 컬럼 표시/숨김
  - Grid Settings 변경 (Tab 4: Phase 2)
  """

  use Phoenix.LiveView
  alias LiveViewGrid.Grid

  @impl true
  def mount(_params, _session, socket) do
    sample_data = [
      %{id: 1, name: "Alice", email: "alice@example.com", salary: 5000, department: "Engineering"},
      %{id: 2, name: "Bob", email: "bob@example.com", salary: 4500, department: "Sales"},
      %{id: 3, name: "Charlie", email: "charlie@example.com", salary: 6000, department: "Engineering"},
      %{id: 4, name: "Diana", email: "diana@example.com", salary: 5500, department: "HR"},
      %{id: 5, name: "Eve", email: "eve@example.com", salary: 4800, department: "Marketing"}
    ]

    columns = [
      %{field: :name, label: "이름", width: 120, align: :left, sortable: true, editable: true},
      %{field: :email, label: "이메일", width: 180, align: :left, sortable: false},
      %{field: :salary, label: "급여", width: 100, align: :right, sortable: true},
      %{field: :department, label: "부서", width: 120, align: :left, sortable: true}
    ]

    grid = Grid.new(
      data: sample_data,
      columns: columns,
      options: %{
        page_size: 10,
        theme: "light",
        virtual_scroll: false,
        row_height: 40,
        frozen_columns: 0,
        show_row_number: true,
        show_header: true,
        show_footer: false
      }
    )

    {:ok,
     socket
     |> assign(:grid, grid)
     |> assign(:config_applied_count, 0)
     |> assign(:last_config_changes, nil)
     |> assign(:current_options, grid.options)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div style="padding: 40px; background: #f5f5f5; min-height: 100vh; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;">
      <div style="max-width: 1400px; margin: 0 auto;">
        <!-- Header -->
        <div style="margin-bottom: 30px;">
          <h1 style="margin: 0 0 10px 0; font-size: 32px; color: #333;">
            ⚙️ Grid Configuration Modal Demo
          </h1>
          <p style="margin: 0; font-size: 14px; color: #666;">
            Grid Configuration 기능을 테스트합니다. "⚙ 설정" 버튼을 클릭해서 설정 모달을 열어보세요.
          </p>
        </div>

        <!-- Status Info -->
        <div style="margin-bottom: 20px; padding: 15px; background: white; border-left: 4px solid #2196f3; border-radius: 4px; box-shadow: 0 1px 3px rgba(0,0,0,0.1);">
          <div style="display: flex; gap: 30px; flex-wrap: wrap;">
            <div>
              <span style="font-size: 12px; color: #666; text-transform: uppercase; font-weight: 600;">
                총 컬럼 수
              </span>
              <div style="font-size: 24px; font-weight: bold; color: #2196f3;">
                <%= length(@grid.columns) %>
              </div>
            </div>
            <div>
              <span style="font-size: 12px; color: #666; text-transform: uppercase; font-weight: 600;">
                총 데이터 행
              </span>
              <div style="font-size: 24px; font-weight: bold; color: #4caf50;">
                <%= length(@grid.data) %>
              </div>
            </div>
            <div>
              <span style="font-size: 12px; color: #666; text-transform: uppercase; font-weight: 600;">
                설정 적용 횟수
              </span>
              <div style="font-size: 24px; font-weight: bold; color: #ff9800;">
                <%= @config_applied_count %>
              </div>
            </div>
          </div>
        </div>

        <!-- Current Grid Settings (Phase 2) -->
        <div style="margin-bottom: 20px; padding: 20px; background: white; border-radius: 4px; box-shadow: 0 1px 3px rgba(0,0,0,0.1); border-left: 4px solid #9c27b0;">
          <h2 style="margin: 0 0 15px 0; font-size: 18px; color: #333;">Grid Settings (Phase 2)</h2>
          <div style="display: grid; grid-template-columns: repeat(auto-fill, minmax(180px, 1fr)); gap: 10px;">
            <div style="padding: 10px; background: #f9f9f9; border: 1px solid #e0e0e0; border-radius: 4px; font-size: 13px;">
              <div style="color: #666; font-size: 11px; text-transform: uppercase; font-weight: 600; margin-bottom: 4px;">Page Size</div>
              <div style="font-size: 18px; font-weight: bold; color: #9c27b0;"><%= @current_options.page_size %> rows</div>
            </div>
            <div style="padding: 10px; background: #f9f9f9; border: 1px solid #e0e0e0; border-radius: 4px; font-size: 13px;">
              <div style="color: #666; font-size: 11px; text-transform: uppercase; font-weight: 600; margin-bottom: 4px;">Theme</div>
              <div style="font-size: 18px; font-weight: bold; color: #9c27b0;"><%= @current_options.theme %></div>
            </div>
            <div style="padding: 10px; background: #f9f9f9; border: 1px solid #e0e0e0; border-radius: 4px; font-size: 13px;">
              <div style="color: #666; font-size: 11px; text-transform: uppercase; font-weight: 600; margin-bottom: 4px;">Row Height</div>
              <div style="font-size: 18px; font-weight: bold; color: #9c27b0;"><%= @current_options.row_height %>px</div>
            </div>
            <div style="padding: 10px; background: #f9f9f9; border: 1px solid #e0e0e0; border-radius: 4px; font-size: 13px;">
              <div style="color: #666; font-size: 11px; text-transform: uppercase; font-weight: 600; margin-bottom: 4px;">Virtual Scroll</div>
              <div style="font-size: 14px; font-weight: bold; color: #9c27b0;">
                <%= if @current_options.virtual_scroll, do: "On", else: "Off" %>
              </div>
            </div>
            <div style="padding: 10px; background: #f9f9f9; border: 1px solid #e0e0e0; border-radius: 4px; font-size: 13px;">
              <div style="color: #666; font-size: 11px; text-transform: uppercase; font-weight: 600; margin-bottom: 4px;">Frozen Columns</div>
              <div style="font-size: 18px; font-weight: bold; color: #9c27b0;"><%= @current_options.frozen_columns %></div>
            </div>
            <div style="padding: 10px; background: #f9f9f9; border: 1px solid #e0e0e0; border-radius: 4px; font-size: 13px;">
              <div style="color: #666; font-size: 11px; text-transform: uppercase; font-weight: 600; margin-bottom: 4px;">Show Row #</div>
              <div style="font-size: 14px; font-weight: bold; color: #9c27b0;">
                <%= if @current_options.show_row_number, do: "Yes", else: "No" %>
              </div>
            </div>
            <div style="padding: 10px; background: #f9f9f9; border: 1px solid #e0e0e0; border-radius: 4px; font-size: 13px;">
              <div style="color: #666; font-size: 11px; text-transform: uppercase; font-weight: 600; margin-bottom: 4px;">Show Header</div>
              <div style="font-size: 14px; font-weight: bold; color: #9c27b0;">
                <%= if @current_options.show_header, do: "Yes", else: "No" %>
              </div>
            </div>
            <div style="padding: 10px; background: #f9f9f9; border: 1px solid #e0e0e0; border-radius: 4px; font-size: 13px;">
              <div style="color: #666; font-size: 11px; text-transform: uppercase; font-weight: 600; margin-bottom: 4px;">Show Footer</div>
              <div style="font-size: 14px; font-weight: bold; color: #9c27b0;">
                <%= if @current_options.show_footer, do: "Yes", else: "No" %>
              </div>
            </div>
          </div>
        </div>

        <!-- Current Column Configuration -->
        <div style="margin-bottom: 20px; padding: 20px; background: white; border-radius: 4px; box-shadow: 0 1px 3px rgba(0,0,0,0.1);">
          <h2 style="margin: 0 0 15px 0; font-size: 18px; color: #333;">Current Column Configuration</h2>
          <div style="display: grid; grid-template-columns: repeat(auto-fill, minmax(250px, 1fr)); gap: 10px;">
            <%= for col <- @grid.columns do %>
              <div style="padding: 12px; background: #f9f9f9; border: 1px solid #e0e0e0; border-radius: 4px; font-size: 13px;">
                <div style="margin-bottom: 8px;">
                  <strong style="color: #333;"><%= col.field %></strong>
                  <span style="float: right; color: #999; font-size: 11px;">
                    w: <%= col.width %>px
                  </span>
                </div>
                <div style="color: #666; margin-bottom: 4px;">
                  Label: <strong><%= col.label %></strong>
                </div>
                <div style="color: #666; margin-bottom: 4px;">
                  Align: <strong><%= col.align %></strong>
                </div>
                <div style="display: flex; gap: 8px; font-size: 11px;">
                  <%= if col.sortable do %>
                    <span style="background: #4caf50; color: white; padding: 2px 6px; border-radius: 2px;">Sortable</span>
                  <% end %>
                  <%= if col.filterable do %>
                    <span style="background: #2196f3; color: white; padding: 2px 6px; border-radius: 2px;">Filterable</span>
                  <% end %>
                  <%= if col.editable do %>
                    <span style="background: #ff9800; color: white; padding: 2px 6px; border-radius: 2px;">Editable</span>
                  <% end %>
                </div>
              </div>
            <% end %>
          </div>
        </div>

        <!-- Grid Component -->
        <div style="background: white; border-radius: 4px; box-shadow: 0 2px 8px rgba(0,0,0,0.1); overflow: hidden;">
          <.live_component
            module={LiveViewGridWeb.GridComponent}
            id="demo_grid"
            grid={@grid}
            data={@grid.data}
            columns={@grid.columns}
            options={@grid.options}
          />
        </div>

        <!-- Instructions -->
        <div style="margin-top: 30px; padding: 20px; background: #e8f5e9; border-left: 4px solid #4caf50; border-radius: 4px;">
          <h3 style="margin: 0 0 10px 0; color: #2e7d32;">📘 사용 방법</h3>
          <ul style="margin: 0; padding-left: 20px; color: #333; font-size: 14px; line-height: 1.8;">
            <li>그리드 위의 <strong>"⚙ 설정"</strong> 버튼을 클릭합니다</li>
            <li>설정 모달에서 다음을 구성할 수 있습니다:
              <ul style="margin-top: 8px;">
                <li><strong>Tab 1: Column Visibility & Order</strong> - 컬럼 표시/숨김 및 순서 변경</li>
                <li><strong>Tab 2: Column Properties</strong> - 컬럼 속성 편집 (라벨, 너비, 정렬 등)</li>
                <li><strong>Tab 3: Formatters & Validators</strong> - 포매터 및 검증자 설정</li>
                <li><strong>Tab 4: Grid Settings</strong> - 페이지 크기, 테마, 행 높이, 가상 스크롤, 고정 컬럼 등</li>
              </ul>
            </li>
            <li><strong>"Apply"</strong> 버튼을 클릭하면 설정이 즉시 적용됩니다</li>
            <li><strong>"Reset"</strong> 버튼으로 원래 설정으로 복원할 수 있습니다</li>
            <li><strong>"Cancel"</strong> 버튼으로 변경사항 없이 모달을 닫을 수 있습니다</li>
          </ul>
        </div>
      </div>
    </div>
    """
  end

  # Handle events if needed
  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info(:modal_close, socket) do
    {:noreply, socket}
  end
end
