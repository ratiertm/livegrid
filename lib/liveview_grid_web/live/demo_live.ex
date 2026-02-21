defmodule LiveviewGridWeb.DemoLive do
  @moduledoc """
  LiveView Grid 데모 페이지
  
  프로토타입 v0.1-alpha
  """
  
  use Phoenix.LiveView

  @impl true
  def mount(_params, _session, socket) do
    all_users = generate_sample_data(50)
    {:ok, assign(socket,
      all_users: all_users,
      saved_users: all_users,
      filtered_users: all_users,
      visible_users: Enum.take(all_users, 100),
      data_count: 50,
      search_query: "",
      page_size: 10,
      loaded_count: min(100, length(all_users)),
      virtual_scroll: false,
      theme: "light"
    )}
  end

  @impl true
  def handle_event("change_data_count", %{"count" => count}, socket) do
    count_num = String.to_integer(count)
    current_users = socket.assigns.all_users
    current_count = length(current_users)

    all_users = cond do
      count_num == current_count ->
        # 개수 동일 → 변경 없음
        current_users

      count_num < current_count ->
        # 줄이기 → 기존 데이터에서 앞쪽만 유지
        Enum.take(current_users, count_num)

      true ->
        # 늘리기 → 기존 데이터 유지 + 부족분만 새로 생성하여 추가
        additional = generate_sample_data(count_num - current_count, current_count + 1)
        current_users ++ additional
    end

    filtered = filter_users(all_users, socket.assigns.search_query)
    visible = Enum.take(filtered, 100)

    socket = assign(socket,
      all_users: all_users,
      saved_users: all_users,
      filtered_users: filtered,
      visible_users: visible,
      data_count: count_num,
      loaded_count: min(100, length(filtered))
    )

    # 스크롤 상태 리셋 (새로운 데이터니까 다시 로드 가능)
    {:noreply, push_event(socket, "reset_scroll", %{})}
  end

  @impl true
  def handle_event("search", %{"value" => query}, socket) do
    filtered = filter_users(socket.assigns.all_users, query)
    visible = Enum.take(filtered, 100)
    
    socket = assign(socket, 
      filtered_users: filtered,
      visible_users: visible,
      search_query: query,
      loaded_count: min(100, length(filtered))
    )
    
    # 스크롤 상태 리셋
    {:noreply, push_event(socket, "reset_scroll", %{})}
  end

  @impl true
  def handle_event("clear_search", _params, socket) do
    {:noreply, assign(socket, 
      filtered_users: socket.assigns.all_users,
      search_query: ""
    )}
  end

  @impl true
  def handle_event("change_page_size", %{"size" => size}, socket) do
    {:noreply, assign(socket, page_size: String.to_integer(size))}
  end

  @impl true
  def handle_event("load_more", _params, socket) do
    current_loaded = socket.assigns.loaded_count
    total = length(socket.assigns.filtered_users)
    
    require Logger
    Logger.info("📥 load_more 이벤트 수신: #{current_loaded}/#{total}")
    
    # 이미 모두 로드했으면 무시
    if current_loaded >= total do
      Logger.info("⛔ 이미 모든 데이터 로드됨 - no_more_data 전송")
      # JavaScript에 더 이상 데이터 없음을 알림
      {:noreply, push_event(socket, "no_more_data", %{})}
    else
      # 다음 100개 추가 로드
      new_loaded = min(current_loaded + 100, total)
      visible = Enum.take(socket.assigns.filtered_users, new_loaded)
      
      Logger.info("✅ 데이터 추가 로드: #{current_loaded} → #{new_loaded} (visible_users: #{length(visible)}개)")
      
      socket = assign(socket, 
        visible_users: visible,
        loaded_count: new_loaded
      )
      
      # 모두 로드되었으면 알림
      if new_loaded >= total do
        Logger.info("🎉 모든 데이터 로드 완료 - no_more_data 전송")
        {:noreply, push_event(socket, "no_more_data", %{})}
      else
        Logger.info("🔄 아직 더 로드 가능 (남은: #{total - new_loaded}개)")
        {:noreply, socket}
      end
    end
  end

  @impl true
  def handle_event("toggle_virtual_scroll", _params, socket) do
    {:noreply, assign(socket, virtual_scroll: !socket.assigns.virtual_scroll)}
  end

  @impl true
  def handle_event("toggle_theme", %{"theme" => theme}, socket) do
    {:noreply, assign(socket, theme: theme)}
  end

  # CSV/Excel Export: GridComponent → 부모 LiveView → push_event → JS 다운로드 (F-510)
  @impl true
  def handle_info({:grid_download_file, payload}, socket) do
    {:noreply, push_event(socket, "download_file", payload)}
  end

  @impl true
  def handle_info({:grid_cell_updated, row_id, field, value}, socket) do
    # GridComponent에서 셀 편집 완료 시 원본 데이터 업데이트
    updated_users = Enum.map(socket.assigns.all_users, fn user ->
      if user.id == row_id, do: Map.put(user, field, value), else: user
    end)

    updated_filtered = Enum.map(socket.assigns.filtered_users, fn user ->
      if user.id == row_id, do: Map.put(user, field, value), else: user
    end)

    updated_visible = Enum.map(socket.assigns.visible_users, fn user ->
      if user.id == row_id, do: Map.put(user, field, value), else: user
    end)

    {:noreply, assign(socket,
      all_users: updated_users,
      filtered_users: updated_filtered,
      visible_users: updated_visible
    )}
  end

  @impl true
  def handle_info({:grid_save_blocked, error_count}, socket) do
    {:noreply, put_flash(socket, :error, "검증 오류 #{error_count}건이 있어 저장할 수 없습니다. 오류를 수정해주세요.")}
  end

  @impl true
  def handle_info({:grid_save_requested, changed_rows}, socket) do
    # 실제 프로젝트에서는 여기서 DB에 저장
    # 예: Repo.update_all(changed_rows)
    require Logger
    Logger.info("💾 저장 요청: #{length(changed_rows)}건")
    for %{row: row, status: status} <- changed_rows do
      Logger.info("  - [#{status}] ID=#{row.id} #{inspect(row)}")
    end

    # 데모에서는 이미 메모리에 반영되어 있으므로 saved_users를 현재 상태로 갱신
    {:noreply, socket
      |> assign(saved_users: socket.assigns.all_users)
      |> put_flash(:info, "#{length(changed_rows)}건 저장 완료")}
  end

  @impl true
  def handle_info({:grid_row_added, new_row}, socket) do
    # 새 행을 부모 데이터에도 추가
    updated_all = [new_row | socket.assigns.all_users]
    updated_filtered = [new_row | socket.assigns.filtered_users]
    updated_visible = [new_row | socket.assigns.visible_users]

    {:noreply, assign(socket,
      all_users: updated_all,
      filtered_users: updated_filtered,
      visible_users: updated_visible,
      loaded_count: socket.assigns.loaded_count + 1
    )}
  end

  @impl true
  def handle_info({:grid_rows_deleted, row_ids}, socket) do
    require Logger
    Logger.info("🗑️ 행 삭제 요청: #{inspect(row_ids)}")

    # :new 행(음수 ID)은 부모 데이터에서도 제거
    new_ids = Enum.filter(row_ids, fn id -> id < 0 end)

    remove_fn = fn users ->
      Enum.reject(users, fn user -> user.id in new_ids end)
    end

    updated_all = remove_fn.(socket.assigns.all_users)
    updated_filtered = remove_fn.(socket.assigns.filtered_users)
    updated_visible = remove_fn.(socket.assigns.visible_users)

    {:noreply, assign(socket,
      all_users: updated_all,
      filtered_users: updated_filtered,
      visible_users: updated_visible,
      loaded_count: length(updated_visible)
    )}
  end

  @impl true
  def handle_info(:grid_discard_requested, socket) do
    # 마지막 저장 시점의 데이터로 복원
    all_users = socket.assigns.saved_users
    filtered = filter_users(all_users, socket.assigns.search_query)
    visible = Enum.take(filtered, socket.assigns.loaded_count)

    {:noreply, assign(socket,
      all_users: all_users,
      filtered_users: filtered,
      visible_users: visible
    )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div style="padding: 20px;">
      <h1>LiveView Grid 프로토타입 v0.1-alpha</h1>
      <p>기본 기능: 정렬 + 페이징 + Virtual Scrolling</p>
      
      <!-- 데이터 상태 표시 -->
      <div style="margin: 10px 0; padding: 10px; background: #e1f5fe; border-left: 4px solid #03a9f4; border-radius: 4px;">
        <strong>📊 현재 데이터:</strong> 
        전체 <span style="color: #03a9f4; font-weight: 600; font-size: 18px;"><%= length(@all_users) %>개</span>
        <%= if @search_query != "" do %>
          / 검색 결과 <span style="color: #ff9800; font-weight: 600; font-size: 18px;"><%= length(@filtered_users) %>개</span>
        <% end %>
        <span style="margin-left: 20px; padding: 5px 10px; background: #4caf50; color: white; border-radius: 3px; font-size: 12px;">
          로드됨: <%= @loaded_count %>개 / <%= length(@filtered_users) %>개
        </span>
      </div>
      
      <!-- 검색 기능 -->
      <div style="margin: 20px 0; padding: 15px; background: #e3f2fd; border-radius: 4px; border-left: 4px solid #2196f3;">
        <form phx-submit="search" style="display: flex; align-items: center; gap: 10px;">
          <label style="font-weight: 600;">🔍 전체 검색:</label>
          <input 
            type="text" 
            name="value"
            value={@search_query}
            placeholder="이름, 이메일, 도시로 검색..."
            style="flex: 1; padding: 10px 15px; border: 2px solid #2196f3; border-radius: 4px; font-size: 14px;"
          />
          <button 
            type="submit"
            style="padding: 10px 24px; background: #2196f3; color: white; border: none; border-radius: 4px; cursor: pointer; font-weight: 600; font-size: 14px;"
          >
            검색
          </button>
          <%= if @search_query != "" do %>
            <button 
              type="button"
              phx-click="clear_search"
              style="padding: 10px 20px; background: #f44336; color: white; border: none; border-radius: 4px; cursor: pointer; font-weight: 600;"
            >
              ✕ 초기화
            </button>
          <% end %>
        </form>
        <div style="margin-top: 10px; font-size: 13px; color: #666;">
          <%= if @search_query != "" do %>
            <strong style="color: #2196f3;"><%= length(@filtered_users) %>개</strong> 검색됨 
            (전체 <%= length(@all_users) %>개 중)
          <% else %>
            전체 <strong><%= length(@all_users) %>개</strong> 표시 중
          <% end %>
        </div>
      </div>
      
      <!-- Export: Grid 하단 footer에서 Excel/CSV 버튼으로 내보내기 -->
      
      <!-- Virtual Scroll 토글 -->
      <div style="margin: 20px 0; padding: 15px; background: #fff3e0; border-radius: 4px; border-left: 4px solid #ff9800;">
        <div style="display: flex; align-items: center; justify-content: space-between;">
          <div>
            <label style="font-weight: 600;">Virtual Scrolling:</label>
            <span style="margin-left: 10px; color: #666; font-size: 13px;">
              <%= if @virtual_scroll do %>
                ON - 보이는 행만 렌더링 (대용량 최적화)
              <% else %>
                OFF - 무한 스크롤 모드 (100개씩 추가 로드)
              <% end %>
            </span>
          </div>
          <button
            phx-click="toggle_virtual_scroll"
            style={"padding: 10px 24px; border: none; border-radius: 4px; cursor: pointer; font-weight: 600; #{if @virtual_scroll, do: "background: #ff9800; color: white;", else: "background: #e0e0e0; color: #666;"}"}
          >
            <%= if @virtual_scroll, do: "ON", else: "OFF" %>
          </button>
        </div>
      </div>
      
      <!-- 테마 토글 (F-200) -->
      <div style="margin: 20px 0; padding: 15px; background: #f3e5f5; border-radius: 4px; border-left: 4px solid #9c27b0;">
        <div style="display: flex; align-items: center; gap: 15px;">
          <label style="font-weight: 600;">🌗 테마:</label>
          <button
            phx-click="toggle_theme"
            phx-value-theme="light"
            style={"padding: 8px 20px; border: 2px solid #9c27b0; border-radius: 4px; cursor: pointer; font-weight: 600; #{if @theme == "light", do: "background: #9c27b0; color: white;", else: "background: white; color: #666;"}"}
          >
            ☀️ Light
          </button>
          <button
            phx-click="toggle_theme"
            phx-value-theme="dark"
            style={"padding: 8px 20px; border: 2px solid #9c27b0; border-radius: 4px; cursor: pointer; font-weight: 600; #{if @theme == "dark", do: "background: #9c27b0; color: white;", else: "background: white; color: #666;"}"}
          >
            🌙 Dark
          </button>
        </div>
      </div>

      <div style="margin: 20px 0; padding: 15px; background: #f5f5f5; border-radius: 4px;">
        <label style="margin-right: 10px; font-weight: 600;">데이터 개수:</label>
        <button phx-click="change_data_count" phx-value-count="50" style={"padding: 8px 16px; margin: 0 5px; border: 1px solid #ddd; border-radius: 4px; cursor: pointer; #{if @data_count == 50, do: "background: #2196f3; color: white;", else: "background: white;"}"}>
          50개
        </button>
        <button phx-click="change_data_count" phx-value-count="100" style={"padding: 8px 16px; margin: 0 5px; border: 1px solid #ddd; border-radius: 4px; cursor: pointer; #{if @data_count == 100, do: "background: #2196f3; color: white;", else: "background: white;"}"}>
          100개
        </button>
        <button phx-click="change_data_count" phx-value-count="200" style={"padding: 8px 16px; margin: 0 5px; border: 1px solid #ddd; border-radius: 4px; cursor: pointer; #{if @data_count == 200, do: "background: #2196f3; color: white;", else: "background: white;"}"}>
          200개
        </button>
        <button phx-click="change_data_count" phx-value-count="500" style={"padding: 8px 16px; margin: 0 5px; border: 1px solid #ddd; border-radius: 4px; cursor: pointer; #{if @data_count == 500, do: "background: #2196f3; color: white;", else: "background: white;"}"}>
          500개
        </button>
        <button phx-click="change_data_count" phx-value-count="1000" style={"padding: 8px 16px; margin: 0 5px; border: 1px solid #ddd; border-radius: 4px; cursor: pointer; #{if @data_count == 1000, do: "background: #2196f3; color: white;", else: "background: white;"}"}>
          1000개
        </button>
        <span style="margin-left: 15px; color: #666;">현재: <%= @data_count %>개</span>
      </div>
      
      <div style="position: relative;">
        <.live_component
          module={LiveviewGridWeb.GridComponent}
          id="users-grid"
          data={if @virtual_scroll, do: @filtered_users, else: @visible_users}
          columns={[
            %{field: :id, label: "ID", width: 80, sortable: true},
            %{field: :name, label: "이름", width: 150, sortable: true, filterable: true, filter_type: :text, editable: true,
              validators: [{:required, "이름은 필수입니다"}]},
            %{field: :email, label: "이메일", width: 250, sortable: true, filterable: true, filter_type: :text, editable: true,
              validators: [{:required, "이메일은 필수입니다"}, {:pattern, ~r/@/, "이메일 형식이 올바르지 않습니다"}],
              renderer: LiveViewGrid.Renderers.link(prefix: "mailto:")},
            %{field: :age, label: "나이", width: 100, sortable: true, filterable: true, filter_type: :number, editable: true, editor_type: :number,
              validators: [{:required, "나이는 필수입니다"}, {:min, 1, "1 이상이어야 합니다"}, {:max, 150, "150 이하이어야 합니다"}],
              renderer: LiveViewGrid.Renderers.progress(max: 60, color: "green")},
            %{field: :city, label: "도시", width: 120, sortable: true, filterable: true, filter_type: :text, editable: true, editor_type: :select,
              renderer: LiveViewGrid.Renderers.badge(
                colors: %{"서울" => "blue", "부산" => "green", "대구" => "red",
                          "인천" => "purple", "광주" => "yellow", "대전" => "gray",
                          "울산" => "blue", "수원" => "green", "창원" => "red", "고양" => "purple"}),
              editor_options: [
                {"서울", "서울"}, {"부산", "부산"}, {"대구", "대구"},
                {"인천", "인천"}, {"광주", "광주"}, {"대전", "대전"},
                {"울산", "울산"}, {"수원", "수원"}, {"창원", "창원"}, {"고양", "고양"}
              ]}
          ]}
          options={%{
            page_size: if(@virtual_scroll, do: 20, else: 99999),
            virtual_scroll: @virtual_scroll,
            row_height: 40,
            show_footer: !@virtual_scroll,
            frozen_columns: 1,
            debug: true,
            theme: @theme
          }}
        />
        
        <!-- 상세 디버깅 정보 (Grid 하단) - 개발 모드에서만 표시 -->
        <%= if Mix.env() == :dev do %>
          <div style="position: absolute; bottom: 20px; right: 20px; padding: 12px; background: rgba(0, 0, 0, 0.8); color: white; border-radius: 8px; font-size: 11px; box-shadow: 0 2px 8px rgba(0,0,0,0.3); max-width: 300px;">
            <div style="font-weight: 600; margin-bottom: 5px; color: #4caf50;">🔍 실시간 디버깅</div>
            <div>전체: <%= length(@filtered_users) %>개</div>
            <div>로드됨: <strong style="color: #2196f3;"><%= @loaded_count %>개</strong></div>
            <div>visible_users: <strong style="color: #ff9800;"><%= length(@visible_users) %>개</strong></div>
            <%= if @loaded_count < length(@filtered_users) do %>
              <div style="margin-top: 5px; padding: 5px; background: rgba(33, 150, 243, 0.3); border-radius: 3px;">
                ⏳ 더 로드 가능 (남은: <%= length(@filtered_users) - @loaded_count %>개)
              </div>
            <% else %>
              <div style="margin-top: 5px; padding: 5px; background: rgba(76, 175, 80, 0.3); border-radius: 3px;">
                ✅ 모두 로드됨
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
      
      <!-- 완료 메시지 -->
      <%= if @loaded_count >= length(@filtered_users) && length(@filtered_users) > 100 do %>
        <div style="text-align: center; padding: 15px; color: #666; font-size: 13px; background: #e8f5e9; border-radius: 4px; margin: 10px 0;">
          ✅ 모든 데이터를 표시했습니다 (<%= @loaded_count %>개)
        </div>
      <% end %>
    </div>
    """
  end

  # 검색 필터링
  defp filter_users(users, ""), do: users
  defp filter_users(users, query) do
    query_lower = String.downcase(query)
    
    Enum.filter(users, fn user ->
      String.contains?(String.downcase(user.name), query_lower) or
      String.contains?(String.downcase(user.email), query_lower) or
      String.contains?(String.downcase(user.city), query_lower) or
      String.contains?(to_string(user.age), query_lower)
    end)
  end

  # 샘플 데이터 생성 (동적 개수, start_id로 ID 시작값 지정 가능)
  defp generate_sample_data(count, start_id \\ 1) do
    first_names = ["Alice", "Bob", "Charlie", "David", "Eve", "Frank", "Grace", "Henry", "Iris", "Jack"]
    last_names = ["Kim", "Lee", "Park", "Choi", "Jung", "Kang", "Cho", "Yoon", "Jang", "Lim"]
    cities = ["서울", "부산", "대구", "인천", "광주", "대전", "울산", "수원", "창원", "고양"]

    for i <- start_id..(start_id + count - 1) do
      first = Enum.random(first_names)
      last = Enum.random(last_names)

      %{
        id: i,
        name: "#{first} #{last}",
        email: "#{String.downcase(first)}.#{String.downcase(last)}@example.com",
        age: Enum.random(20..60),
        city: Enum.random(cities)
      }
    end
  end
end
