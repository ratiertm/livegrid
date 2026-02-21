defmodule LiveviewGridWeb.ApiDemoLive do
  @moduledoc """
  REST API 연동 데모 페이지

  v0.5: REST DataSource adapter를 사용하여 외부 API(Mock)에서
  데이터를 가져와 그리드에 표시하는 데모
  """

  use Phoenix.LiveView

  alias LiveviewGrid.{Repo, DemoUser}

  @api_base_url "http://localhost:5001"

  @impl true
  def mount(_params, _session, socket) do
    # DB에 데이터가 있는지 확인, 없으면 시드 실행
    total = Repo.aggregate(DemoUser, :count)
    if total == 0, do: seed_demo_data()

    total = Repo.aggregate(DemoUser, :count)

    {:ok, assign(socket,
      total_db_count: total,
      api_url: "#{@api_base_url}/api/users",
      last_action: "초기 로드",
      last_status: nil,
      response_time_ms: 0
    )}
  end

  @impl true
  def handle_event("grid_updated", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("export_data", params, socket) do
    {:noreply, push_event(socket, "download", params)}
  end

  @impl true
  def handle_event("cell_edited", %{"row_id" => row_id, "field" => field, "value" => value}, socket) do
    start_time = System.monotonic_time(:millisecond)

    # REST API를 통한 업데이트
    url = "#{@api_base_url}/api/users/#{row_id}"
    body = Jason.encode!(%{field => value})

    case Req.put(url, body: body, headers: [{"content-type", "application/json"}]) do
      {:ok, %{status: status}} when status in 200..299 ->
        elapsed = System.monotonic_time(:millisecond) - start_time
        {:noreply, assign(socket,
          response_time_ms: elapsed,
          last_action: "PUT /api/users/#{row_id} (#{field}=#{value})",
          last_status: {:ok, "#{status} OK - #{field} 업데이트 완료"}
        )}

      {:ok, %{status: status, body: body}} ->
        {:noreply, assign(socket, last_status: {:error, "#{status}: #{inspect(body)}"})}

      {:error, reason} ->
        {:noreply, assign(socket, last_status: {:error, inspect(reason)})}
    end
  end

  @impl true
  def handle_event("api_add_row", _params, socket) do
    start_time = System.monotonic_time(:millisecond)

    body = Jason.encode!(%{
      name: "API 신규사원",
      email: "api_new_#{System.unique_integer([:positive])}@example.com",
      department: "개발",
      age: 25,
      salary: 35_000_000,
      status: "재직",
      join_date: Date.utc_today() |> Date.to_string()
    })

    case Req.post("#{@api_base_url}/api/users", body: body, headers: [{"content-type", "application/json"}]) do
      {:ok, %{status: status}} when status in 200..299 ->
        elapsed = System.monotonic_time(:millisecond) - start_time
        total = Repo.aggregate(DemoUser, :count)
        {:noreply, assign(socket,
          total_db_count: total,
          response_time_ms: elapsed,
          last_action: "POST /api/users",
          last_status: {:ok, "#{status} Created - 행 추가 완료"}
        )}

      {:ok, %{status: status, body: body}} ->
        {:noreply, assign(socket, last_status: {:error, "#{status}: #{inspect(body)}"})}

      {:error, reason} ->
        {:noreply, assign(socket, last_status: {:error, inspect(reason)})}
    end
  end

  @impl true
  def handle_event("api_delete_selected", %{"row_ids" => row_ids_str}, socket) do
    start_time = System.monotonic_time(:millisecond)

    row_ids =
      row_ids_str
      |> String.split(",")
      |> Enum.map(&String.trim/1)
      |> Enum.filter(&(&1 != ""))

    results =
      Enum.map(row_ids, fn id ->
        case Req.delete("#{@api_base_url}/api/users/#{id}") do
          {:ok, %{status: status}} when status in 200..299 -> :ok
          _ -> :error
        end
      end)

    deleted = Enum.count(results, &(&1 == :ok))
    elapsed = System.monotonic_time(:millisecond) - start_time
    total = Repo.aggregate(DemoUser, :count)

    {:noreply, assign(socket,
      total_db_count: total,
      response_time_ms: elapsed,
      last_action: "DELETE /api/users (#{deleted}건)",
      last_status: {:ok, "#{deleted}건 삭제 완료"}
    )}
  end

  @impl true
  def handle_event("reseed_data", _params, socket) do
    start_time = System.monotonic_time(:millisecond)

    Repo.delete_all(DemoUser)
    seed_demo_data()

    elapsed = System.monotonic_time(:millisecond) - start_time
    total = Repo.aggregate(DemoUser, :count)

    {:noreply, assign(socket,
      total_db_count: total,
      response_time_ms: elapsed,
      last_action: "데이터 리셋 (1000건)",
      last_status: {:ok, "1000건 시드 데이터 재생성 완료"}
    )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div style="padding: 20px; max-width: 1400px; margin: 0 auto; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;">
      <!-- 헤더 -->
      <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px;">
        <div>
          <h1 style="margin: 0; font-size: 24px; font-weight: 600;">
            🌐 REST API 연동 데모
          </h1>
          <p style="margin: 5px 0 0; color: #666; font-size: 14px;">
            REST DataSource adapter - HTTP API 기반 정렬/필터/페이지네이션/CRUD
          </p>
        </div>
        <div></div>
      </div>

      <!-- API 엔드포인트 정보 -->
      <div style="padding: 12px 16px; background: #f0f4ff; border: 1px solid #c5cae9; border-radius: 8px; margin-bottom: 20px;">
        <div style="font-size: 12px; color: #3949ab; font-weight: 600; margin-bottom: 4px;">📡 API Endpoint</div>
        <code style="font-size: 14px; color: #1a237e; font-weight: 500;"><%= @api_url %></code>
        <span style="font-size: 11px; color: #7986cb; margin-left: 10px;">
          GET (목록) · POST (추가) · PUT (수정) · DELETE (삭제)
        </span>
      </div>

      <!-- 상태 패널 -->
      <div style="display: flex; gap: 15px; margin-bottom: 20px; flex-wrap: wrap;">
        <!-- API 데이터 -->
        <div style="flex: 1; min-width: 200px; padding: 15px; background: #e8eaf6; border-radius: 8px; border: 1px solid #9fa8da;">
          <div style="font-size: 12px; color: #283593; font-weight: 600; margin-bottom: 5px;">📊 API 데이터</div>
          <div style="font-size: 20px; font-weight: 700; color: #1a237e;"><%= @total_db_count %>건</div>
          <div style="font-size: 11px; color: #5c6bc0;">Mock API · SQLite 백엔드</div>
        </div>

        <!-- 응답 시간 -->
        <div style="flex: 1; min-width: 200px; padding: 15px; background: #e0f2f1; border-radius: 8px; border: 1px solid #80cbc4;">
          <div style="font-size: 12px; color: #00695c; font-weight: 600; margin-bottom: 5px;">⚡ 응답 시간</div>
          <div style="font-size: 20px; font-weight: 700; color: #004d40;"><%= @response_time_ms %>ms</div>
          <div style="font-size: 11px; color: #26a69a;"><%= @last_action %></div>
        </div>

        <!-- 결과 -->
        <div style={"flex: 1; min-width: 200px; padding: 15px; border-radius: 8px; border: 1px solid #{status_border(@last_status)}; background: #{status_bg(@last_status)};"}>
          <div style={"font-size: 12px; font-weight: 600; margin-bottom: 5px; color: #{status_color(@last_status)};"}>
            <%= status_icon(@last_status) %> HTTP 결과
          </div>
          <div style={"font-size: 14px; font-weight: 600; color: #{status_color(@last_status)};"}>
            <%= status_message(@last_status) %>
          </div>
        </div>
      </div>

      <!-- 액션 버튼 -->
      <div style="display: flex; gap: 10px; margin-bottom: 15px; flex-wrap: wrap;">
        <button phx-click="api_add_row" style="padding: 8px 16px; background: #3949ab; color: white; border: none; border-radius: 6px; cursor: pointer; font-size: 13px; font-weight: 500;">
          ➕ 행 추가 (POST /api/users)
        </button>
        <button phx-click="reseed_data" style="padding: 8px 16px; background: #ff9800; color: white; border: none; border-radius: 6px; cursor: pointer; font-size: 13px; font-weight: 500;"
                data-confirm="모든 데이터를 삭제하고 1000건을 재생성합니다. 계속하시겠습니까?">
          🔄 데이터 리셋 (1000건)
        </button>
      </div>

      <!-- Grid (REST DataSource) -->
      <.live_component
        module={LiveviewGridWeb.GridComponent}
        id="api-grid"
        data={[]}
        columns={[
          %{field: :id, label: "ID", width: 70, sortable: true},
          %{field: :name, label: "이름", width: 120, sortable: true, filterable: true, filter_type: :text, editable: true},
          %{field: :email, label: "이메일", width: 220, sortable: true, filterable: true, filter_type: :text, editable: true},
          %{field: :department, label: "부서", width: 100, sortable: true, filterable: true, filter_type: :text, editable: true, editor_type: :select,
            editor_options: [
              {"개발", "개발"}, {"디자인", "디자인"}, {"마케팅", "마케팅"}, {"영업", "영업"},
              {"인사", "인사"}, {"재무", "재무"}, {"기획", "기획"}, {"CS", "CS"}
            ],
            renderer: LiveViewGrid.Renderers.badge(
              colors: %{"개발" => "blue", "디자인" => "purple", "마케팅" => "green",
                        "영업" => "red", "인사" => "yellow", "재무" => "gray",
                        "기획" => "blue", "CS" => "green"})},
          %{field: :age, label: "나이", width: 80, sortable: true, filterable: true, filter_type: :number, editable: true, editor_type: :number},
          %{field: :salary, label: "연봉", width: 130, sortable: true, filterable: true, filter_type: :number, editable: true, editor_type: :number},
          %{field: :status, label: "상태", width: 80, sortable: true, filterable: true, filter_type: :text,
            renderer: LiveViewGrid.Renderers.badge(
              colors: %{"재직" => "green", "휴직" => "yellow", "퇴직" => "red"})},
          %{field: :join_date, label: "입사일", width: 120, sortable: true, filterable: true, filter_type: :text}
        ]}
        options={%{
          page_size: 50,
          show_footer: true,
          frozen_columns: 1,
          debug: true,
          theme: "light"
        }}
        data_source={{LiveViewGrid.DataSource.Rest, %{
          base_url: "http://localhost:5001",
          endpoint: "/api/users",
          headers: %{},
          response_mapping: %{
            data_key: "data",
            total_key: "total",
            filtered_key: "filtered"
          },
          query_mapping: %{
            page: "page",
            page_size: "page_size",
            sort_field: "sort",
            sort_direction: "order",
            search: "q",
            filters: "filters"
          },
          request_opts: %{
            timeout: 10_000,
            retry: 2,
            retry_delay: 500
          }
        }}}
      />

      <!-- API 명세 -->
      <div style="margin-top: 20px; padding: 15px; background: #fafafa; border-radius: 8px; border: 1px solid #eee;">
        <h3 style="margin: 0 0 10px; font-size: 14px; font-weight: 600; color: #333;">
          📋 API 명세
        </h3>
        <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 10px; font-size: 13px;">
          <div>
            <strong style="color: #283593;">Endpoints</strong><br/>
            <code style="font-size: 11px; background: #e8eaf6; padding: 2px 6px; border-radius: 3px; display: inline-block; margin: 2px 0;">
              GET /api/users?page=1&page_size=50
            </code><br/>
            <code style="font-size: 11px; background: #e8eaf6; padding: 2px 6px; border-radius: 3px; display: inline-block; margin: 2px 0;">
              POST /api/users
            </code><br/>
            <code style="font-size: 11px; background: #e8eaf6; padding: 2px 6px; border-radius: 3px; display: inline-block; margin: 2px 0;">
              PUT /api/users/:id
            </code><br/>
            <code style="font-size: 11px; background: #e8eaf6; padding: 2px 6px; border-radius: 3px; display: inline-block; margin: 2px 0;">
              DELETE /api/users/:id
            </code>
          </div>
          <div>
            <strong style="color: #00695c;">Query Parameters</strong><br/>
            <span style="font-size: 12px;">
              <code>sort</code>=name · <code>order</code>=asc/desc<br/>
              <code>q</code>=검색어 · <code>page</code>=페이지<br/>
              <code>filters</code>={"name":"Kim","age":">30"}<br/>
              <code>page_size</code>=50/100/200/300/400/500
            </span>
          </div>
          <div>
            <strong style="color: #e65100;">Response Format</strong><br/>
            <code style="font-size: 11px; background: #fff3e0; padding: 2px 6px; border-radius: 3px; display: inline-block;">
              {"data": [...], "total": N, "filtered": N, "page": 1}
            </code>
          </div>
          <div>
            <strong style="color: #6a1b9a;">DataSource</strong><br/>
            <code style="font-size: 12px; background: #f3e5f5; padding: 2px 6px; border-radius: 3px;">
              LiveViewGrid.DataSource.Rest
            </code><br/>
            <span style="font-size: 11px;">Req HTTP Client · Auto Retry · JSON Parsing</span>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # ── Private helpers ──

  defp status_icon(nil), do: "💤"
  defp status_icon({:ok, _}), do: "✅"
  defp status_icon({:error, _}), do: "❌"

  defp status_message(nil), do: "대기중"
  defp status_message({:ok, msg}), do: msg
  defp status_message({:error, msg}), do: msg

  defp status_bg(nil), do: "#f5f5f5"
  defp status_bg({:ok, _}), do: "#e8f5e9"
  defp status_bg({:error, _}), do: "#ffebee"

  defp status_border(nil), do: "#e0e0e0"
  defp status_border({:ok, _}), do: "#a5d6a7"
  defp status_border({:error, _}), do: "#ef9a9a"

  defp status_color(nil), do: "#757575"
  defp status_color({:ok, _}), do: "#2e7d32"
  defp status_color({:error, _}), do: "#c62828"

  defp seed_demo_data do
    departments = ["개발", "디자인", "마케팅", "영업", "인사", "재무", "기획", "CS"]
    statuses = ["재직", "휴직", "퇴직"]
    names = [
      "김민수", "이영희", "박철수", "정미영", "최준호",
      "강서연", "조현우", "윤하나", "임동현", "한지은",
      "오승민", "서예진", "장태윤", "송민지", "류현석",
      "권나영", "배성훈", "홍수진", "문재원", "이다은",
      "김태호", "박소영", "정현기", "최유리", "강지훈",
      "조은서", "윤석민", "임수빈", "한승우", "오다연"
    ]

    now = DateTime.utc_now() |> DateTime.truncate(:second)

    users =
      for i <- 1..1000 do
        status = if :rand.uniform(100) <= 85, do: "재직", else: Enum.random(statuses)
        year = 2015 + :rand.uniform(10)
        month = :rand.uniform(12) |> Integer.to_string() |> String.pad_leading(2, "0")
        day = :rand.uniform(28) |> Integer.to_string() |> String.pad_leading(2, "0")

        %{
          name: Enum.random(names),
          email: "user#{i}@example.com",
          department: Enum.random(departments),
          age: 22 + :rand.uniform(40),
          salary: (3000 + :rand.uniform(7000)) * 10000,
          status: status,
          join_date: "#{year}-#{month}-#{day}",
          inserted_at: now,
          updated_at: now
        }
      end

    users
    |> Enum.chunk_every(100)
    |> Enum.each(&Repo.insert_all(DemoUser, &1))
  end
end
