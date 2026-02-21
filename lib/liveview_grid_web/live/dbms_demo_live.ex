defmodule LiveviewGridWeb.DbmsDemoLive do
  @moduledoc """
  DBMS 연동 데모 페이지

  v0.3: Ecto DataSource adapter를 사용하여 SQLite DB에서
  정렬/필터/페이지네이션을 SQL 레벨로 수행하는 데모
  """

  use Phoenix.LiveView

  alias LiveviewGrid.{Repo, DemoUser}

  @impl true
  def mount(_params, _session, socket) do
    # DB에 데이터가 있는지 확인, 없으면 시드 실행
    total = Repo.aggregate(DemoUser, :count)
    if total == 0, do: seed_demo_data()

    total = Repo.aggregate(DemoUser, :count)

    {:ok, assign(socket,
      total_db_count: total,
      query_time_ms: 0,
      last_action: "초기 로드",
      save_result: nil
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
    row_id = if is_binary(row_id), do: String.to_integer(row_id), else: row_id
    field_atom = String.to_existing_atom(field)

    # DB에 직접 업데이트
    start_time = System.monotonic_time(:millisecond)

    case Repo.get(DemoUser, row_id) do
      nil ->
        {:noreply, assign(socket, save_result: {:error, "행을 찾을 수 없음 (ID: #{row_id})"})}

      user ->
        # 타입 변환
        typed_value = cast_value(field_atom, value)
        changes = %{field_atom => typed_value}

        case DemoUser.changeset(user, changes) |> Repo.update() do
          {:ok, _updated} ->
            elapsed = System.monotonic_time(:millisecond) - start_time
            {:noreply, assign(socket,
              query_time_ms: elapsed,
              last_action: "셀 편집: #{field} (ID: #{row_id})",
              save_result: {:ok, "#{field} 업데이트 완료"}
            )}

          {:error, changeset} ->
            errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, _} -> msg end)
            {:noreply, assign(socket, save_result: {:error, inspect(errors)})}
        end
    end
  end

  @impl true
  def handle_event("add_row", _params, socket) do
    start_time = System.monotonic_time(:millisecond)
    next_id = Repo.aggregate(DemoUser, :count) + 1

    attrs = %{
      name: "신규사원",
      email: "new_user#{next_id}@example.com",
      department: "개발",
      age: 25,
      salary: 35_000_000,
      status: "재직",
      join_date: Date.utc_today() |> Date.to_string()
    }

    case %DemoUser{} |> DemoUser.changeset(attrs) |> Repo.insert() do
      {:ok, _user} ->
        elapsed = System.monotonic_time(:millisecond) - start_time
        total = Repo.aggregate(DemoUser, :count)
        {:noreply, assign(socket,
          total_db_count: total,
          query_time_ms: elapsed,
          last_action: "행 추가",
          save_result: {:ok, "새 행 추가 완료"}
        )}

      {:error, changeset} ->
        errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, _} -> msg end)
        {:noreply, assign(socket, save_result: {:error, inspect(errors)})}
    end
  end

  @impl true
  def handle_event("delete_selected", %{"row_ids" => row_ids_str}, socket) do
    start_time = System.monotonic_time(:millisecond)

    row_ids =
      row_ids_str
      |> String.split(",")
      |> Enum.map(&String.trim/1)
      |> Enum.filter(&(&1 != ""))
      |> Enum.map(&String.to_integer/1)

    deleted_count =
      Enum.count(row_ids, fn id ->
        case Repo.get(DemoUser, id) do
          nil -> false
          user -> match?({:ok, _}, Repo.delete(user))
        end
      end)

    elapsed = System.monotonic_time(:millisecond) - start_time
    total = Repo.aggregate(DemoUser, :count)

    {:noreply, assign(socket,
      total_db_count: total,
      query_time_ms: elapsed,
      last_action: "#{deleted_count}건 삭제",
      save_result: {:ok, "#{deleted_count}건 삭제 완료"}
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
      query_time_ms: elapsed,
      last_action: "데이터 리셋 (1000건)",
      save_result: {:ok, "1000건 시드 데이터 재생성 완료"}
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
            🗄️ DBMS 연동 데모
          </h1>
          <p style="margin: 5px 0 0; color: #666; font-size: 14px;">
            SQLite + Ecto DataSource adapter - SQL 레벨 정렬/필터/페이지네이션
          </p>
        </div>
        <div style="display: flex; gap: 10px; align-items: center;">
          <a href="/demo" style="padding: 8px 16px; background: #f5f5f5; border: 1px solid #ddd; border-radius: 6px; text-decoration: none; color: #333; font-size: 13px;">
            ← InMemory 데모
          </a>
          <a href="/api-demo" style="padding: 8px 16px; background: #f5f5f5; border: 1px solid #ddd; border-radius: 6px; text-decoration: none; color: #333; font-size: 13px;">
            🌐 API 데모
          </a>
        </div>
      </div>

      <!-- 상태 패널 -->
      <div style="display: flex; gap: 15px; margin-bottom: 20px; flex-wrap: wrap;">
        <!-- DB 상태 -->
        <div style="flex: 1; min-width: 200px; padding: 15px; background: #e3f2fd; border-radius: 8px; border: 1px solid #90caf9;">
          <div style="font-size: 12px; color: #1565c0; font-weight: 600; margin-bottom: 5px;">📊 DB 통계</div>
          <div style="font-size: 20px; font-weight: 700; color: #0d47a1;"><%= @total_db_count %>건</div>
          <div style="font-size: 11px; color: #42a5f5;">SQLite · demo_users 테이블</div>
        </div>

        <!-- 쿼리 성능 -->
        <div style="flex: 1; min-width: 200px; padding: 15px; background: #e8f5e9; border-radius: 8px; border: 1px solid #a5d6a7;">
          <div style="font-size: 12px; color: #2e7d32; font-weight: 600; margin-bottom: 5px;">⚡ 마지막 쿼리</div>
          <div style="font-size: 20px; font-weight: 700; color: #1b5e20;"><%= @query_time_ms %>ms</div>
          <div style="font-size: 11px; color: #66bb6a;"><%= @last_action %></div>
        </div>

        <!-- 동작 결과 -->
        <div style={"flex: 1; min-width: 200px; padding: 15px; border-radius: 8px; border: 1px solid #{result_border_color(@save_result)}; background: #{result_bg_color(@save_result)};"}>
          <div style={"font-size: 12px; font-weight: 600; margin-bottom: 5px; color: #{result_text_color(@save_result)};"}>
            <%= result_icon(@save_result) %> 결과
          </div>
          <div style={"font-size: 14px; font-weight: 600; color: #{result_text_color(@save_result)};"}>
            <%= result_message(@save_result) %>
          </div>
        </div>
      </div>

      <!-- 액션 버튼 -->
      <div style="display: flex; gap: 10px; margin-bottom: 15px; flex-wrap: wrap;">
        <button phx-click="add_row" style="padding: 8px 16px; background: #4caf50; color: white; border: none; border-radius: 6px; cursor: pointer; font-size: 13px; font-weight: 500;">
          ➕ 행 추가 (DB INSERT)
        </button>
        <button phx-click="reseed_data" style="padding: 8px 16px; background: #ff9800; color: white; border: none; border-radius: 6px; cursor: pointer; font-size: 13px; font-weight: 500;"
                data-confirm="모든 데이터를 삭제하고 1000건을 재생성합니다. 계속하시겠습니까?">
          🔄 데이터 리셋 (1000건)
        </button>
      </div>

      <!-- Grid (Ecto DataSource) -->
      <.live_component
        module={LiveviewGridWeb.GridComponent}
        id="dbms-grid"
        data={[]}
        columns={[
          %{field: :id, label: "ID", width: 70, sortable: true},
          %{field: :name, label: "이름", width: 120, sortable: true, filterable: true, filter_type: :text, editable: true,
            validators: [{:required, "이름은 필수입니다"}]},
          %{field: :email, label: "이메일", width: 220, sortable: true, filterable: true, filter_type: :text, editable: true,
            validators: [{:required, "이메일은 필수입니다"}, {:pattern, ~r/@/, "이메일 형식 오류"}]},
          %{field: :department, label: "부서", width: 100, sortable: true, filterable: true, filter_type: :text, editable: true, editor_type: :select,
            editor_options: [
              {"개발", "개발"}, {"디자인", "디자인"}, {"마케팅", "마케팅"}, {"영업", "영업"},
              {"인사", "인사"}, {"재무", "재무"}, {"기획", "기획"}, {"CS", "CS"}
            ],
            renderer: LiveViewGrid.Renderers.badge(
              colors: %{"개발" => "blue", "디자인" => "purple", "마케팅" => "green",
                        "영업" => "red", "인사" => "yellow", "재무" => "gray",
                        "기획" => "blue", "CS" => "green"})},
          %{field: :age, label: "나이", width: 80, sortable: true, filterable: true, filter_type: :number, editable: true, editor_type: :number,
            validators: [{:min, 1, "1 이상"}, {:max, 150, "150 이하"}]},
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
        data_source={{LiveViewGrid.DataSource.Ecto, %{
          repo: LiveviewGrid.Repo,
          schema: LiveviewGrid.DemoUser
        }}}
      />

      <!-- 기술 설명 -->
      <div style="margin-top: 20px; padding: 15px; background: #fafafa; border-radius: 8px; border: 1px solid #eee;">
        <h3 style="margin: 0 0 10px; font-size: 14px; font-weight: 600; color: #333;">
          🔧 기술 스택
        </h3>
        <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 10px; font-size: 13px;">
          <div>
            <strong style="color: #1565c0;">DataSource</strong><br/>
            <code style="font-size: 12px; background: #e3f2fd; padding: 2px 6px; border-radius: 3px;">
              LiveViewGrid.DataSource.Ecto
            </code>
          </div>
          <div>
            <strong style="color: #2e7d32;">Database</strong><br/>
            <code style="font-size: 12px; background: #e8f5e9; padding: 2px 6px; border-radius: 3px;">
              SQLite3 (ecto_sqlite3)
            </code>
          </div>
          <div>
            <strong style="color: #e65100;">쿼리 빌더</strong><br/>
            <code style="font-size: 12px; background: #fff3e0; padding: 2px 6px; border-radius: 3px;">
              Ecto.Query (서버사이드)
            </code>
          </div>
          <div>
            <strong style="color: #6a1b9a;">기능</strong><br/>
            <span style="font-size: 12px;">정렬 · 필터 · 검색 · 페이지네이션 · CRUD</span>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # ── Private helpers ──

  defp cast_value(:age, value) when is_binary(value), do: String.to_integer(value)
  defp cast_value(:salary, value) when is_binary(value), do: String.to_integer(value)
  defp cast_value(_field, value), do: value

  defp result_icon(nil), do: "💤"
  defp result_icon({:ok, _}), do: "✅"
  defp result_icon({:error, _}), do: "❌"

  defp result_message(nil), do: "대기중"
  defp result_message({:ok, msg}), do: msg
  defp result_message({:error, msg}), do: msg

  defp result_bg_color(nil), do: "#f5f5f5"
  defp result_bg_color({:ok, _}), do: "#e8f5e9"
  defp result_bg_color({:error, _}), do: "#ffebee"

  defp result_border_color(nil), do: "#e0e0e0"
  defp result_border_color({:ok, _}), do: "#a5d6a7"
  defp result_border_color({:error, _}), do: "#ef9a9a"

  defp result_text_color(nil), do: "#757575"
  defp result_text_color({:ok, _}), do: "#2e7d32"
  defp result_text_color({:error, _}), do: "#c62828"

  defp seed_demo_data do
    departments = ["개발", "디자인", "마케팅", "영업", "인사", "재무", "기획", "CS"]
    statuses = ["재직", "휴직", "퇴직"]
    names = [
      "김민수", "이영희", "박철수", "정미영", "최준호",
      "강서연", "조현우", "윤하나", "임동현", "한지은",
      "오승민", "서예진", "장태윤", "송민지", "류현석",
      "권나영", "배성훈", "홍수진", "문재원", "이다은",
      "김태호", "박소영", "정현기", "최유리", "강지훈",
      "조은서", "윤석민", "임수빈", "한승우", "오다연",
      "서진우", "장하영", "송현준", "류미선", "권도현",
      "배서희", "홍태양", "문지영", "신동욱", "이서윤",
      "김하준", "박지민", "정수아", "최민호", "강예린",
      "조태현", "윤서영", "임정훈", "한미래", "오건우"
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
