defmodule LiveviewGridWeb.DemoLive do
  @moduledoc """
  LiveView Grid 데모 페이지
  
  프로토타입 v0.1-alpha
  """
  
  use Phoenix.LiveView

  @grid_id "users-grid"

  @doc "마운트 시 샘플 데이터 생성, PubSub 구독, Presence 등록 등 초기 상태를 설정한다."
  @impl true
  def mount(_params, _session, socket) do
    # F-500: 실시간 협업 - PubSub 구독 + Presence 등록
    if connected?(socket) do
      LiveViewGrid.PubSubBridge.subscribe(@grid_id)
      user_id = "user_#{:crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)}"
      LiveViewGrid.GridPresence.track_user(self(), @grid_id, user_id, %{name: user_id})
    end

    all_users = generate_sample_data(50)
    online_users = if connected?(socket), do: LiveViewGrid.GridPresence.user_count(@grid_id), else: 0

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
      pinned_top: [],
      pinned_bottom: [],
      theme: "light",
      online_users: online_users,
      # 테마 커스터마이저 상태
      customizer_open: false,
      custom_css_vars: %{},
      saved_presets: %{
        "Ocean Blue" => %{
          "--lv-grid-primary" => "#0288d1",
          "--lv-grid-primary-dark" => "#01579b",
          "--lv-grid-primary-light" => "#e1f5fe",
          "--lv-grid-bg" => "#ffffff",
          "--lv-grid-bg-secondary" => "#f0f7ff",
          "--lv-grid-text" => "#1a237e",
          "--lv-grid-border" => "#b3d4fc",
          "--lv-grid-hover" => "#e3f2fd",
          "--lv-grid-selected" => "#bbdefb"
        },
        "Forest Green" => %{
          "--lv-grid-primary" => "#2e7d32",
          "--lv-grid-primary-dark" => "#1b5e20",
          "--lv-grid-primary-light" => "#e8f5e9",
          "--lv-grid-bg" => "#ffffff",
          "--lv-grid-bg-secondary" => "#f1f8f1",
          "--lv-grid-text" => "#1b5e20",
          "--lv-grid-border" => "#a5d6a7",
          "--lv-grid-hover" => "#e8f5e9",
          "--lv-grid-selected" => "#c8e6c9"
        },
        "Sunset Orange" => %{
          "--lv-grid-primary" => "#e65100",
          "--lv-grid-primary-dark" => "#bf360c",
          "--lv-grid-primary-light" => "#fff3e0",
          "--lv-grid-bg" => "#fffaf5",
          "--lv-grid-bg-secondary" => "#fff8f0",
          "--lv-grid-text" => "#3e2723",
          "--lv-grid-border" => "#ffcc80",
          "--lv-grid-hover" => "#fff3e0",
          "--lv-grid-selected" => "#ffe0b2"
        },
        "Dark Purple" => %{
          "--lv-grid-primary" => "#bb86fc",
          "--lv-grid-primary-dark" => "#9c64fc",
          "--lv-grid-primary-light" => "#2d1b4e",
          "--lv-grid-bg" => "#121212",
          "--lv-grid-bg-secondary" => "#1e1e2e",
          "--lv-grid-text" => "#e0e0e0",
          "--lv-grid-border" => "#3a3a5c",
          "--lv-grid-hover" => "#2a2a3e",
          "--lv-grid-selected" => "#2d1b4e"
        }
      },
      preset_name_input: ""
    )}
  end

  @doc "데모 페이지의 UI 이벤트를 처리한다. 데이터 개수 변경, 검색, 테마 전환, 가상스크롤 등을 지원한다."
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

  # FA-001: Row Pinning 이벤트 핸들러
  @impl true
  def handle_event("pin_first_row_top", _params, socket) do
    first_row = List.first(socket.assigns.visible_users)
    if first_row do
      {:noreply, assign(socket, pinned_top: [first_row.id], pinned_bottom: socket.assigns[:pinned_bottom] || [])}
    else
      {:noreply, socket}
    end
  end

  def handle_event("pin_last_row_bottom", _params, socket) do
    last_row = List.last(socket.assigns.visible_users)
    if last_row do
      {:noreply, assign(socket, pinned_bottom: [last_row.id], pinned_top: socket.assigns[:pinned_top] || [])}
    else
      {:noreply, socket}
    end
  end

  def handle_event("unpin_all", _params, socket) do
    {:noreply, assign(socket, pinned_top: [], pinned_bottom: [])}
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
    {:noreply, assign(socket, theme: theme, custom_css_vars: %{})}
  end

  @impl true
  def handle_event("toggle_customizer", _params, socket) do
    {:noreply, assign(socket, customizer_open: !socket.assigns.customizer_open)}
  end

  @impl true
  def handle_event("update_css_var", %{"var" => var_name, "value" => value}, socket) do
    custom_vars = Map.put(socket.assigns.custom_css_vars, var_name, value)
    {:noreply, assign(socket, custom_css_vars: custom_vars, theme: "custom")}
  end

  @impl true
  def handle_event("apply_preset", %{"name" => name}, socket) do
    case Map.get(socket.assigns.saved_presets, name) do
      nil -> {:noreply, socket}
      vars -> {:noreply, assign(socket, custom_css_vars: vars, theme: "custom")}
    end
  end

  @impl true
  def handle_event("save_preset", %{"name" => name}, socket) do
    name = String.trim(name)
    if name == "" do
      {:noreply, put_flash(socket, :error, "프리셋 이름을 입력하세요")}
    else
      presets = Map.put(socket.assigns.saved_presets, name, socket.assigns.custom_css_vars)
      {:noreply, socket
        |> assign(saved_presets: presets, preset_name_input: "")
        |> put_flash(:info, "프리셋 '#{name}' 저장 완료")}
    end
  end

  @impl true
  def handle_event("delete_preset", %{"name" => name}, socket) do
    presets = Map.delete(socket.assigns.saved_presets, name)
    {:noreply, assign(socket, saved_presets: presets)}
  end

  @impl true
  def handle_event("reset_customizer", _params, socket) do
    {:noreply, assign(socket, custom_css_vars: %{}, theme: "light")}
  end

  @impl true
  def handle_event("update_preset_name", %{"value" => value}, socket) do
    {:noreply, assign(socket, preset_name_input: value)}
  end

  # GridComponent 이벤트가 부모로 전파될 경우 안전하게 무시
  def handle_event("clear_cell_range", _params, socket), do: {:noreply, socket}

  @doc "GridComponent 및 PubSub에서 전달되는 메시지를 처리한다. 셀/행 편집, Undo/Redo, 저장, 실시간 협업 이벤트 등을 지원한다."
  @impl true
  def handle_info({:grid_download_file, payload}, socket) do
    {:noreply, push_event(socket, "download_file", payload)}
  end

  @impl true
  def handle_info({:grid_cell_updated, row_id, field, value}, socket) do
    # F-500: 다른 사용자에게 브로드캐스트
    LiveViewGrid.PubSubBridge.broadcast_cell_update(@grid_id, row_id, field, value, self())

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
  def handle_info({:grid_row_updated, row_id, changed_values}, socket) do
    update_row = fn users ->
      Enum.map(users, fn user ->
        if user.id == row_id do
          Enum.reduce(changed_values, user, fn {field, value}, acc ->
            Map.put(acc, field, value)
          end)
        else
          user
        end
      end)
    end

    {:noreply, assign(socket,
      all_users: update_row.(socket.assigns.all_users),
      filtered_users: update_row.(socket.assigns.filtered_users),
      visible_users: update_row.(socket.assigns.visible_users)
    )}
  end

  @impl true
  def handle_info({:grid_undo, %{type: :cell, row_id: row_id, field: field, value: value}}, socket) do
    update_fn = fn users ->
      Enum.map(users, fn user ->
        if user.id == row_id, do: Map.put(user, field, value), else: user
      end)
    end

    {:noreply, assign(socket,
      all_users: update_fn.(socket.assigns.all_users),
      filtered_users: update_fn.(socket.assigns.filtered_users),
      visible_users: update_fn.(socket.assigns.visible_users)
    )}
  end

  @impl true
  def handle_info({:grid_undo, %{type: :row, row_id: row_id, values: values}}, socket) do
    update_fn = fn users ->
      Enum.map(users, fn user ->
        if user.id == row_id do
          Enum.reduce(values, user, fn {field, value}, acc -> Map.put(acc, field, value) end)
        else
          user
        end
      end)
    end

    {:noreply, assign(socket,
      all_users: update_fn.(socket.assigns.all_users),
      filtered_users: update_fn.(socket.assigns.filtered_users),
      visible_users: update_fn.(socket.assigns.visible_users)
    )}
  end

  @impl true
  def handle_info({:grid_redo, summary}, socket) do
    # Redo는 Undo와 동일한 구조 (값만 다름)
    handle_info({:grid_undo, summary}, socket)
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

    # F-500: 다른 사용자에게 저장 완료 브로드캐스트
    LiveViewGrid.PubSubBridge.broadcast_rows_saved(@grid_id, self())

    # :deleted 행은 부모 데이터에서도 제거
    deleted_ids = changed_rows
      |> Enum.filter(fn %{status: s} -> s == :deleted end)
      |> Enum.map(fn %{row: r} -> r.id end)
      |> MapSet.new()

    remove_deleted = fn users ->
      if MapSet.size(deleted_ids) > 0 do
        Enum.reject(users, fn user -> MapSet.member?(deleted_ids, user.id) end)
      else
        users
      end
    end

    updated_all = remove_deleted.(socket.assigns.all_users)
    updated_filtered = remove_deleted.(socket.assigns.filtered_users)
    updated_visible = remove_deleted.(socket.assigns.visible_users)

    {:noreply, socket
      |> assign(
        all_users: updated_all,
        filtered_users: updated_filtered,
        visible_users: updated_visible,
        saved_users: updated_all,
        loaded_count: length(updated_visible)
      )
      |> put_flash(:info, "#{length(changed_rows)}건 저장 완료")}
  end

  @impl true
  def handle_info({:grid_row_added, new_row}, socket) do
    # F-500: 다른 사용자에게 브로드캐스트
    LiveViewGrid.PubSubBridge.broadcast_row_added(@grid_id, new_row, self())

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
    # F-500: 다른 사용자에게 브로드캐스트
    LiveViewGrid.PubSubBridge.broadcast_rows_deleted(@grid_id, row_ids, self())

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

  # ── F-500: 실시간 협업 - PubSub 수신 ──

  @impl true
  def handle_info({:grid_event, %{type: :cell_updated, sender: sender} = event}, socket) do
    # 자기 자신이 보낸 이벤트는 무시 (이미 로컬에서 처리됨)
    if sender == self() do
      {:noreply, socket}
    else
      update_fn = fn users ->
        Enum.map(users, fn user ->
          if user.id == event.row_id, do: Map.put(user, event.field, event.value), else: user
        end)
      end

      {:noreply, assign(socket,
        all_users: update_fn.(socket.assigns.all_users),
        filtered_users: update_fn.(socket.assigns.filtered_users),
        visible_users: update_fn.(socket.assigns.visible_users)
      )}
    end
  end

  @impl true
  def handle_info({:grid_event, %{type: :row_added, sender: sender} = event}, socket) do
    if sender == self() do
      {:noreply, socket}
    else
      {:noreply, assign(socket,
        all_users: [event.row | socket.assigns.all_users],
        filtered_users: [event.row | socket.assigns.filtered_users],
        visible_users: [event.row | socket.assigns.visible_users]
      )}
    end
  end

  @impl true
  def handle_info({:grid_event, %{type: :rows_deleted, sender: sender} = event}, socket) do
    if sender == self() do
      {:noreply, socket}
    else
      remove_fn = fn users ->
        Enum.reject(users, fn user -> user.id in event.row_ids end)
      end

      {:noreply, assign(socket,
        all_users: remove_fn.(socket.assigns.all_users),
        filtered_users: remove_fn.(socket.assigns.filtered_users),
        visible_users: remove_fn.(socket.assigns.visible_users)
      )}
    end
  end

  @impl true
  def handle_info({:grid_event, %{type: :rows_saved, sender: sender}}, socket) do
    if sender == self() do
      {:noreply, socket}
    else
      {:noreply, assign(socket, saved_users: socket.assigns.all_users)}
    end
  end

  @impl true
  def handle_info({:grid_event, %{type: :user_editing}}, socket) do
    # 편집 위치 정보는 Presence로 처리 (향후 확장)
    {:noreply, socket}
  end

  @impl true
  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff"}, socket) do
    online_users = LiveViewGrid.GridPresence.user_count(@grid_id)
    {:noreply, assign(socket, online_users: online_users)}
  end

  @doc "데모 페이지를 렌더링한다. 데이터 컨트롤, 테마 커스터마이저, 그리드를 표시한다."
  @impl true
  def render(assigns) do
    ~H"""
    <div style="padding: 20px;">
      <div>
        <h1>LiveView Grid 프로토타입 v0.1-alpha</h1>
        <p>기본 기능: 정렬 + 페이징 + Virtual Scrolling</p>
        <%= if @online_users > 0 do %>
          <div style="display: inline-flex; align-items: center; gap: 6px; padding: 4px 12px; background: #e8f5e9; border-radius: 12px; font-size: 13px; color: #2e7d32;">
            <span style="display: inline-block; width: 8px; height: 8px; background: #4caf50; border-radius: 50%; animation: pulse 2s infinite;"></span>
            <strong><%= @online_users %></strong> 명 접속 중
          </div>
        <% end %>
      </div>
      
      <!-- 데모 컨트롤 (접기/펼치기) -->
      <details style="margin: 10px 0;">
        <summary style="cursor: pointer; padding: 8px 12px; background: #f5f5f5; border-radius: 4px; font-weight: 600; font-size: 13px; color: #666; user-select: none;">
          ⚙️ 데모 설정 (검색, 테마, 데이터 개수, Virtual Scroll)
        </summary>

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
      
      <!-- FA-001: Row Pinning 제어 -->
      <div style="margin: 20px 0; padding: 15px; background: #e8f5e9; border-radius: 4px; border-left: 4px solid #4caf50;">
        <label style="font-weight: 600;">📌 Row Pinning:</label>
        <button phx-click="pin_first_row_top" style="padding: 6px 14px; background: #4caf50; color: white; border: none; border-radius: 4px; cursor: pointer; font-weight: 600; margin-left: 8px;">
          첫 행 상단 고정
        </button>
        <button phx-click="pin_last_row_bottom" style="padding: 6px 14px; background: #2196f3; color: white; border: none; border-radius: 4px; cursor: pointer; font-weight: 600; margin-left: 8px;">
          마지막 행 하단 고정
        </button>
        <button phx-click="unpin_all" style="padding: 6px 14px; background: #f44336; color: white; border: none; border-radius: 4px; cursor: pointer; font-weight: 600; margin-left: 8px;">
          고정 해제
        </button>
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
      
      <!-- 테마 토글 + 커스터마이저 (F-200) -->
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
          <button
            phx-click="toggle_customizer"
            style={"padding: 8px 20px; border: 2px solid #9c27b0; border-radius: 4px; cursor: pointer; font-weight: 600; #{if @customizer_open, do: "background: #7b1fa2; color: white;", else: "background: white; color: #9c27b0;"}"}
          >
            🎨 커스터마이저
          </button>
          <%= if @theme == "custom" do %>
            <span style="padding: 4px 12px; background: #9c27b0; color: white; border-radius: 12px; font-size: 12px; font-weight: 600;">
              ✨ 커스텀 테마 적용중
            </span>
          <% end %>
        </div>

        <!-- 테마 커스터마이저 패널 -->
        <%= if @customizer_open do %>
          <div style="margin-top: 15px; padding: 20px; background: white; border: 2px solid #ce93d8; border-radius: 8px; box-shadow: 0 4px 12px rgba(156,39,176,0.15);">

            <!-- 프리셋 섹션 -->
            <div style="margin-bottom: 20px;">
              <h4 style="margin: 0 0 10px 0; color: #7b1fa2; font-size: 14px;">📦 프리셋 테마</h4>
              <div style="display: flex; flex-wrap: wrap; gap: 8px;">
                <%= for {name, vars} <- @saved_presets do %>
                  <div style="display: flex; align-items: center; gap: 4px;">
                    <button
                      phx-click="apply_preset"
                      phx-value-name={name}
                      style="padding: 6px 14px; border: 1px solid #ce93d8; border-radius: 16px; cursor: pointer; font-size: 12px; font-weight: 500; background: #fce4ec; color: #7b1fa2; transition: all 0.2s;"
                    >
                      <span style={"display: inline-block; width: 10px; height: 10px; border-radius: 50%; margin-right: 4px; background: #{Map.get(vars, "--lv-grid-primary", "#9c27b0")}; vertical-align: middle;"}></span>
                      <%= name %>
                    </button>
                    <button
                      phx-click="delete_preset"
                      phx-value-name={name}
                      style="padding: 2px 6px; border: none; background: none; cursor: pointer; color: #999; font-size: 14px;"
                      title="삭제"
                    >×</button>
                  </div>
                <% end %>
              </div>
            </div>

            <!-- 색상 조정 섹션 -->
            <div style="margin-bottom: 15px;">
              <h4 style="margin: 0 0 10px 0; color: #7b1fa2; font-size: 14px;">🎨 색상 조정</h4>
              <div style="display: grid; grid-template-columns: repeat(auto-fill, minmax(220px, 1fr)); gap: 10px;">

                <.color_picker_item var_name="--lv-grid-primary" label="기본 색상 (Primary)" current={Map.get(@custom_css_vars, "--lv-grid-primary", "#2196f3")} />
                <.color_picker_item var_name="--lv-grid-primary-dark" label="기본 색상 (진하게)" current={Map.get(@custom_css_vars, "--lv-grid-primary-dark", "#1976d2")} />
                <.color_picker_item var_name="--lv-grid-bg" label="배경색" current={Map.get(@custom_css_vars, "--lv-grid-bg", "#ffffff")} />
                <.color_picker_item var_name="--lv-grid-bg-secondary" label="보조 배경색" current={Map.get(@custom_css_vars, "--lv-grid-bg-secondary", "#fafafa")} />
                <.color_picker_item var_name="--lv-grid-text" label="텍스트 색상" current={Map.get(@custom_css_vars, "--lv-grid-text", "#333333")} />
                <.color_picker_item var_name="--lv-grid-text-secondary" label="보조 텍스트" current={Map.get(@custom_css_vars, "--lv-grid-text-secondary", "#555555")} />
                <.color_picker_item var_name="--lv-grid-border" label="테두리 색상" current={Map.get(@custom_css_vars, "--lv-grid-border", "#e0e0e0")} />
                <.color_picker_item var_name="--lv-grid-hover" label="호버 색상" current={Map.get(@custom_css_vars, "--lv-grid-hover", "#f5f5f5")} />
                <.color_picker_item var_name="--lv-grid-selected" label="선택 색상" current={Map.get(@custom_css_vars, "--lv-grid-selected", "#e3f2fd")} />
                <.color_picker_item var_name="--lv-grid-danger" label="위험 색상" current={Map.get(@custom_css_vars, "--lv-grid-danger", "#f44336")} />
                <.color_picker_item var_name="--lv-grid-success" label="성공 색상" current={Map.get(@custom_css_vars, "--lv-grid-success", "#4caf50")} />
                <.color_picker_item var_name="--lv-grid-warning" label="경고 색상" current={Map.get(@custom_css_vars, "--lv-grid-warning", "#ff9800")} />
              </div>
            </div>

            <!-- 저장/리셋 -->
            <div style="display: flex; align-items: center; gap: 10px; padding-top: 15px; border-top: 1px solid #e0e0e0;">
              <input
                type="text"
                value={@preset_name_input}
                phx-keyup="update_preset_name"
                placeholder="프리셋 이름 입력..."
                style="padding: 8px 12px; border: 1px solid #ce93d8; border-radius: 4px; font-size: 13px; width: 180px;"
              />
              <button
                phx-click="save_preset"
                phx-value-name={@preset_name_input}
                style="padding: 8px 16px; background: #9c27b0; color: white; border: none; border-radius: 4px; cursor: pointer; font-weight: 600; font-size: 13px;"
              >
                💾 프리셋 저장
              </button>
              <button
                phx-click="reset_customizer"
                style="padding: 8px 16px; background: #f5f5f5; color: #666; border: 1px solid #ddd; border-radius: 4px; cursor: pointer; font-weight: 600; font-size: 13px;"
              >
                🔄 초기화
              </button>
              <span style="margin-left: auto; font-size: 12px; color: #999;">
                현재 커스텀 변수: <%= map_size(@custom_css_vars) %>개
              </span>
            </div>
          </div>
        <% end %>
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
      </details>

      <div style="position: relative;">
        <.live_component
          module={LiveviewGridWeb.GridComponent}
          id="users-grid"
          data={if @virtual_scroll, do: @filtered_users, else: @visible_users}
          columns={[
            %{field: :id, label: "ID", width: 80, sortable: true, resizable: false},
            %{field: :name, label: "이름", width: 150, sortable: true, filterable: true, filter_type: :text, editable: true,
              header_group: "인적 정보",
              # input_pattern 제거: 국제 문자(한글, 중국어, 일본어, 이모지 등) 모두 허용
              validators: [{:required, "이름은 필수입니다"}]},
            %{field: :email, label: "이메일", width: 250, sortable: true, filterable: true, filter_type: :text, editable: true,
              header_group: "인적 정보", wordwrap: :word,
              validators: [{:required, "이메일은 필수입니다"}, {:pattern, ~r/@/, "이메일 형식이 올바르지 않습니다"}],
              renderer: LiveViewGrid.Renderers.link(prefix: "mailto:")},
            %{field: :age, label: "나이", width: 100, sortable: true, filterable: true, filter_type: :number, editable: true, editor_type: :number,
              header_group: "인적 정보", summary: :avg,
              validators: [{:required, "나이는 필수입니다"}, {:min, 1, "1 이상이어야 합니다"}, {:max, 150, "150 이하이어야 합니다"}],
              renderer: LiveViewGrid.Renderers.progress(max: 60, color: "green"),
              style_expr: fn row ->
                age = Map.get(row, :age)
                cond do
                  is_nil(age) -> nil
                  age >= 50 -> %{bg: "#ffebee", color: "#c62828"}
                  age < 30 -> %{bg: "#e3f2fd", color: "#1565c0"}
                  true -> nil
                end
              end},
            %{field: :active, label: "활성", width: 70, editable: true, editor_type: :checkbox, header_group: "부가 정보", summary: :count},
            %{field: :city, label: "도시", width: 120, sortable: true, filterable: true, filter_type: :text, editable: true, editor_type: :select,
              header_group: "부가 정보", suppress: true,
              renderer: LiveViewGrid.Renderers.badge(
                colors: %{"서울" => "blue", "부산" => "green", "대구" => "red",
                          "인천" => "purple", "광주" => "yellow", "대전" => "gray",
                          "울산" => "blue", "수원" => "green", "창원" => "red", "고양" => "purple"}),
              editor_options: [
                {"서울", "서울"}, {"부산", "부산"}, {"대구", "대구"},
                {"인천", "인천"}, {"광주", "광주"}, {"대전", "대전"},
                {"울산", "울산"}, {"수원", "수원"}, {"창원", "창원"}, {"고양", "고양"}
              ]},
            %{field: :created_at, label: "가입일", width: 160, sortable: true, filterable: true, filter_type: :date, editable: true, editor_type: :date, formatter: :date, header_group: "부가 정보"}
          ]}
          options={%{
            page_size: if(@virtual_scroll, do: 20, else: 99999),
            virtual_scroll: @virtual_scroll,
            row_height: 40,
            show_footer: !@virtual_scroll,
            frozen_columns: 1,
            frozen_right_columns: 1,
            show_row_number: true,
            debug: Mix.env() == :dev,
            theme: @theme,
            custom_css_vars: @custom_css_vars,
            row_reorder: true,
            merge_regions: [
              %{row_id: 1, col_field: :name, colspan: 2},
              %{row_id: 3, col_field: :age, rowspan: 2}
            ],
            chart_panel: true,
            text_selectable: true,
            pinned_top: @pinned_top,
            pinned_bottom: @pinned_bottom
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

  # 테마 커스터마이저: 색상 피커 아이템 컴포넌트
  defp color_picker_item(assigns) do
    ~H"""
    <div style="display: flex; align-items: center; gap: 8px; padding: 6px 10px; background: #fafafa; border-radius: 6px; border: 1px solid #eee;">
      <form phx-change="update_css_var" style="display: contents;">
        <input type="hidden" name="var" value={@var_name} />
        <input
          type="color"
          name="value"
          value={@current}
          style="width: 32px; height: 32px; border: 2px solid #ddd; border-radius: 4px; cursor: pointer; padding: 0;"
        />
      </form>
      <div style="flex: 1; min-width: 0;">
        <div style="font-size: 12px; font-weight: 600; color: #333; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;"><%= @label %></div>
        <div style="font-size: 11px; color: #999; font-family: monospace;"><%= @current %></div>
      </div>
    </div>
    """
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
        active: Enum.random([true, false]),
        city: Enum.random(cities),
        created_at: Date.new!(2025, Enum.random(1..12), Enum.random(1..28))
      }
    end
  end
end
