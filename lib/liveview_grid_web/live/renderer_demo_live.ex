defmodule LiveviewGridWeb.RendererDemoLive do
  @moduledoc """
  렌더러 쇼케이스 데모 페이지

  모든 내장 렌더러(badge, link, progress)의 다양한 옵션을
  한눈에 확인할 수 있는 페이지
  """

  use Phoenix.LiveView

  alias LiveViewGrid.Renderers

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, data: generate_showcase_data())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div style="padding: 20px; max-width: 1400px; margin: 0 auto;">
      <h1 style="margin-bottom: 5px;">🎨 커스텀 셀 렌더러 쇼케이스</h1>
      <p style="color: #666; margin-bottom: 30px;">
        모든 내장 렌더러를 한눈에 확인하세요.
      </p>

      <!-- =============================== -->
      <!-- 1. Badge 렌더러 -->
      <!-- =============================== -->
      <div style="margin-bottom: 40px;">
        <h2 style="color: #1565c0; border-bottom: 2px solid #1565c0; padding-bottom: 8px;">
          🏷️ Badge 렌더러
        </h2>
        <p style="color: #666; margin-bottom: 15px;">
          값을 색상 뱃지로 표시합니다. 상태, 카테고리, 지역 등에 적합합니다.
        </p>

        <.live_component
          module={LiveviewGridWeb.GridComponent}
          id="badge-grid"
          data={@data}
          columns={[
            %{field: :id, label: "ID", width: 60},
            %{field: :name, label: "이름", width: 120},
            %{field: :status, label: "상태 (Badge)", width: 120,
              renderer: Renderers.badge(
                colors: %{
                  "활성" => "green",
                  "비활성" => "red",
                  "대기" => "yellow",
                  "점검중" => "gray"
                }
              )},
            %{field: :grade, label: "등급 (Badge)", width: 120,
              renderer: Renderers.badge(
                colors: %{
                  "VIP" => "purple",
                  "Gold" => "yellow",
                  "Silver" => "gray",
                  "Bronze" => "red"
                },
                default_color: "blue"
              )},
            %{field: :city, label: "도시 (Badge)", width: 120,
              renderer: Renderers.badge(
                colors: %{
                  "서울" => "blue",
                  "부산" => "green",
                  "대구" => "red",
                  "인천" => "purple",
                  "광주" => "yellow"
                }
              )},
            %{field: :department, label: "부서 (Badge)", width: 130,
              renderer: Renderers.badge(
                colors: %{
                  "개발팀" => "blue",
                  "디자인팀" => "purple",
                  "마케팅팀" => "green",
                  "영업팀" => "yellow",
                  "인사팀" => "gray"
                }
              )}
          ]}
          options={%{page_size: 99999, show_footer: false}}
        />

        <div style="margin-top: 12px; padding: 12px; background: #f5f5f5; border-radius: 6px; font-size: 13px;">
          <strong>사용 가능한 색상:</strong>
          <span style="display: inline-flex; gap: 8px; margin-left: 10px;">
            <span style="background: #e3f2fd; color: #1565c0; padding: 2px 8px; border-radius: 12px; font-size: 12px; font-weight: 600;">blue</span>
            <span style="background: #e8f5e9; color: #2e7d32; padding: 2px 8px; border-radius: 12px; font-size: 12px; font-weight: 600;">green</span>
            <span style="background: #ffebee; color: #c62828; padding: 2px 8px; border-radius: 12px; font-size: 12px; font-weight: 600;">red</span>
            <span style="background: #fff8e1; color: #f57f17; padding: 2px 8px; border-radius: 12px; font-size: 12px; font-weight: 600;">yellow</span>
            <span style="background: #f5f5f5; color: #616161; padding: 2px 8px; border-radius: 12px; font-size: 12px; font-weight: 600;">gray</span>
            <span style="background: #f3e5f5; color: #6a1b9a; padding: 2px 8px; border-radius: 12px; font-size: 12px; font-weight: 600;">purple</span>
          </span>
        </div>

        <details style="margin-top: 10px;">
          <summary style="cursor: pointer; font-weight: 600; color: #1565c0;">코드 보기</summary>
          <pre style="background: #263238; color: #eeffff; padding: 16px; border-radius: 6px; overflow-x: auto; font-size: 13px; margin-top: 8px;">
          %{field: :status, label: "상태",
            renderer: LiveViewGrid.Renderers.badge(
              colors: %{"활성" => "green", "비활성" => "red", "대기" => "yellow"},
              default_color: "gray"
            )}
          </pre>
        </details>
      </div>

      <!-- =============================== -->
      <!-- 2. Link 렌더러 -->
      <!-- =============================== -->
      <div style="margin-bottom: 40px;">
        <h2 style="color: #1565c0; border-bottom: 2px solid #1565c0; padding-bottom: 8px;">
          🔗 Link 렌더러
        </h2>
        <p style="color: #666; margin-bottom: 15px;">
          값을 클릭 가능한 링크로 표시합니다. 이메일, 전화번호, URL 등에 적합합니다.
        </p>

        <.live_component
          module={LiveviewGridWeb.GridComponent}
          id="link-grid"
          data={@data}
          columns={[
            %{field: :id, label: "ID", width: 60},
            %{field: :name, label: "이름", width: 120},
            %{field: :email, label: "이메일 (mailto:)", width: 250,
              renderer: Renderers.link(prefix: "mailto:")},
            %{field: :phone, label: "전화 (tel:)", width: 150,
              renderer: Renderers.link(prefix: "tel:")},
            %{field: :website, label: "웹사이트 (새탭)", width: 200,
              renderer: Renderers.link(target: "_blank")},
            %{field: :name, label: "프로필 (커스텀URL)", width: 150,
              renderer: Renderers.link(
                href: fn row, _col -> "/profile/#{row.id}" end
              )}
          ]}
          options={%{page_size: 99999, show_footer: false}}
        />

        <details style="margin-top: 10px;">
          <summary style="cursor: pointer; font-weight: 600; color: #1565c0;">코드 보기</summary>
          <pre style="background: #263238; color: #eeffff; padding: 16px; border-radius: 6px; overflow-x: auto; font-size: 13px; margin-top: 8px;">
          # 이메일 링크
          %{field: :email, renderer: Renderers.link(prefix: "mailto:")}
          # 전화 링크
          %{field: :phone, renderer: Renderers.link(prefix: "tel:")}
          # 새 탭에서 열기
          %{field: :website, renderer: Renderers.link(target: "_blank")}
          # 커스텀 URL 함수
          %{field: :name, renderer: Renderers.link(href: fn row, _col -> "/profile/#{row.id}" end)}
          </pre>
        </details>
      </div>

      <!-- =============================== -->
      <!-- 3. Progress 렌더러 -->
      <!-- =============================== -->
      <div style="margin-bottom: 40px;">
        <h2 style="color: #1565c0; border-bottom: 2px solid #1565c0; padding-bottom: 8px;">
          📊 Progress 렌더러
        </h2>
        <p style="color: #666; margin-bottom: 15px;">
          숫자 값을 프로그레스바로 표시합니다. 점수, 완료율, 수치 등에 적합합니다.
        </p>

        <.live_component
          module={LiveviewGridWeb.GridComponent}
          id="progress-grid"
          data={@data}
          columns={[
            %{field: :id, label: "ID", width: 60},
            %{field: :name, label: "이름", width: 120},
            %{field: :score, label: "점수 (blue, max:100)", width: 180,
              renderer: Renderers.progress(max: 100, color: "blue")},
            %{field: :age, label: "나이 (green, max:60)", width: 180,
              renderer: Renderers.progress(max: 60, color: "green")},
            %{field: :completion, label: "완료율 (red)", width: 180,
              renderer: Renderers.progress(max: 100, color: "red")},
            %{field: :rating, label: "평점 (yellow, max:5)", width: 180,
              renderer: Renderers.progress(max: 5, color: "yellow")},
            %{field: :score, label: "바만 표시", width: 140,
              renderer: Renderers.progress(max: 100, color: "blue", show_value: false)}
          ]}
          options={%{page_size: 99999, show_footer: false}}
        />

        <div style="margin-top: 12px; padding: 12px; background: #f5f5f5; border-radius: 6px; font-size: 13px;">
          <strong>사용 가능한 색상:</strong>
          <span style="display: inline-flex; gap: 12px; margin-left: 10px; align-items: center;">
            <span style="display: flex; align-items: center; gap: 4px;">
              <span style="display: inline-block; width: 40px; height: 8px; background: #1976d2; border-radius: 4px;"></span> blue
            </span>
            <span style="display: flex; align-items: center; gap: 4px;">
              <span style="display: inline-block; width: 40px; height: 8px; background: #2e7d32; border-radius: 4px;"></span> green
            </span>
            <span style="display: flex; align-items: center; gap: 4px;">
              <span style="display: inline-block; width: 40px; height: 8px; background: #c62828; border-radius: 4px;"></span> red
            </span>
            <span style="display: flex; align-items: center; gap: 4px;">
              <span style="display: inline-block; width: 40px; height: 8px; background: #f57f17; border-radius: 4px;"></span> yellow
            </span>
          </span>
        </div>

        <details style="margin-top: 10px;">
          <summary style="cursor: pointer; font-weight: 600; color: #1565c0;">코드 보기</summary>
          <pre style="background: #263238; color: #eeffff; padding: 16px; border-radius: 6px; overflow-x: auto; font-size: 13px; margin-top: 8px;">
          # 점수 (파란색, 최대 100)
          %{field: :score, renderer: Renderers.progress(max: 100, color: "blue")}
          # 나이 (초록색, 최대 60)
          %{field: :age, renderer: Renderers.progress(max: 60, color: "green")}
          # 숫자 텍스트 숨기기
          %{field: :score, renderer: Renderers.progress(max: 100, color: "blue", show_value: false)}
          </pre>
        </details>
      </div>

      <!-- =============================== -->
      <!-- 4. 커스텀 렌더러 (직접 만들기) -->
      <!-- =============================== -->
      <div style="margin-bottom: 40px;">
        <h2 style="color: #1565c0; border-bottom: 2px solid #1565c0; padding-bottom: 8px;">
          ✏️ 커스텀 렌더러 (직접 만들기)
        </h2>
        <p style="color: #666; margin-bottom: 15px;">
          내장 프리셋 외에 직접 함수를 작성하여 어떤 형태로든 렌더링할 수 있습니다.
        </p>

        <.live_component
          module={LiveviewGridWeb.GridComponent}
          id="custom-grid"
          data={@data}
          columns={[
            %{field: :id, label: "ID", width: 60},
            %{field: :name, label: "이름 (Bold)", width: 150,
              renderer: fn row, column, _assigns ->
                value = Map.get(row, column.field)
                Phoenix.HTML.raw("<strong style=\"color: #1565c0;\">#{Phoenix.HTML.html_escape(value) |> Phoenix.HTML.safe_to_string()}</strong>")
              end},
            %{field: :is_active, label: "활성여부 (O/X)", width: 120,
              renderer: fn row, column, _assigns ->
                value = Map.get(row, column.field)
                if value do
                  Phoenix.HTML.raw("<span style=\"color: #4caf50; font-weight: bold; font-size: 16px;\">O</span>")
                else
                  Phoenix.HTML.raw("<span style=\"color: #f44336; font-weight: bold; font-size: 16px;\">X</span>")
                end
              end},
            %{field: :score, label: "점수 (별점)", width: 150,
              renderer: fn row, column, _assigns ->
                value = Map.get(row, column.field) || 0
                stars = div(value, 20)
                empty = 5 - stars
                filled = String.duplicate("★", stars)
                unfilled = String.duplicate("☆", empty)
                Phoenix.HTML.raw("<span style=\"color: #ff9800; font-size: 16px; letter-spacing: 2px;\">#{filled}#{unfilled}</span>")
              end},
            %{field: :age, label: "나이 (색상코딩)", width: 120,
              renderer: fn row, column, _assigns ->
                value = Map.get(row, column.field) || 0
                {color, label} = cond do
                  value < 30 -> {"#4caf50", "청년"}
                  value < 50 -> {"#ff9800", "중년"}
                  true -> {"#f44336", "장년"}
                end
                Phoenix.HTML.raw("<span style=\"color: #{color}; font-weight: 600;\">#{value}세</span> <span style=\"font-size: 10px; color: #999; margin-left: 4px;\">#{label}</span>")
              end},
            %{field: :priority, label: "우선순위 (아이콘)", width: 130,
              renderer: fn row, column, _assigns ->
                value = Map.get(row, column.field)
                {icon, color} = case value do
                  "높음" -> {"🔴", "#c62828"}
                  "중간" -> {"🟡", "#f57f17"}
                  "낮음" -> {"🟢", "#2e7d32"}
                  _ -> {"⚪", "#999"}
                end
                Phoenix.HTML.raw("<span style=\"color: #{color};\">#{icon} #{value}</span>")
              end}
          ]}
          options={%{page_size: 99999, show_footer: false}}
        />

        <details style="margin-top: 10px;">
          <summary style="cursor: pointer; font-weight: 600; color: #1565c0;">코드 보기</summary>
          <pre style="background: #263238; color: #eeffff; padding: 16px; border-radius: 6px; overflow-x: auto; font-size: 13px; margin-top: 8px;">
          # 활성여부 (O/X)
          renderer: fn row, col, _ -&gt;
            if Map.get(row, col.field), do: raw("O"), else: raw("X")
          end

          # 별점 렌더러 (100점 만점 -&gt; 5단계)
          renderer: fn row, col, _ -&gt;
            stars = div(Map.get(row, col.field, 0), 20)
            raw(String.duplicate("★", stars) &lt;&gt; String.duplicate("☆", 5 - stars))
          end
          </pre>
        </details>
      </div>

      <!-- =============================== -->
      <!-- 5. 종합: 모든 렌더러 한 그리드에 -->
      <!-- =============================== -->
      <div style="margin-bottom: 40px;">
        <h2 style="color: #1565c0; border-bottom: 2px solid #1565c0; padding-bottom: 8px;">
          🌈 종합 (모든 렌더러를 한 그리드에)
        </h2>
        <p style="color: #666; margin-bottom: 15px;">
          실제 프로젝트에서 여러 렌더러를 조합하여 사용하는 예시입니다.
        </p>

        <.live_component
          module={LiveviewGridWeb.GridComponent}
          id="combined-grid"
          data={@data}
          columns={[
            %{field: :id, label: "ID", width: 60, sortable: true},
            %{field: :name, label: "이름", width: 130, sortable: true},
            %{field: :status, label: "상태", width: 100, sortable: true,
              renderer: Renderers.badge(
                colors: %{"활성" => "green", "비활성" => "red", "대기" => "yellow", "점검중" => "gray"})},
            %{field: :email, label: "이메일", width: 220,
              renderer: Renderers.link(prefix: "mailto:")},
            %{field: :score, label: "점수", width: 150, sortable: true,
              renderer: Renderers.progress(max: 100, color: "blue")},
            %{field: :completion, label: "완료율", width: 140,
              renderer: Renderers.progress(max: 100, color: "green")},
            %{field: :grade, label: "등급", width: 100,
              renderer: Renderers.badge(
                colors: %{"VIP" => "purple", "Gold" => "yellow", "Silver" => "gray", "Bronze" => "red"})},
            %{field: :priority, label: "우선순위", width: 110,
              renderer: fn row, column, _assigns ->
                value = Map.get(row, column.field)
                {icon, _} = case value do
                  "높음" -> {"🔴", nil}
                  "중간" -> {"🟡", nil}
                  "낮음" -> {"🟢", nil}
                  _ -> {"⚪", nil}
                end
                Phoenix.HTML.raw("<span>#{icon} #{value}</span>")
              end}
          ]}
          options={%{page_size: 10, show_footer: true, frozen_columns: 1}}
        />
      </div>
    </div>
    """
  end

  # ── 쇼케이스용 샘플 데이터 ──

  defp generate_showcase_data do
    names = ["김민수", "이지은", "박서준", "최유리", "정하늘", "강도윤", "조은서", "윤민호", "장서영", "임태양",
             "한소라", "오준혁", "배수진", "류지훈", "권나영"]
    cities = ["서울", "부산", "대구", "인천", "광주"]
    statuses = ["활성", "비활성", "대기", "점검중"]
    grades = ["VIP", "Gold", "Silver", "Bronze"]
    departments = ["개발팀", "디자인팀", "마케팅팀", "영업팀", "인사팀"]
    priorities = ["높음", "중간", "낮음"]

    for i <- 1..5 do
      name = Enum.at(names, i - 1)
      %{
        id: i,
        name: name,
        email: "user#{i}@example.com",
        phone: "010-#{String.pad_leading(to_string(Enum.random(1000..9999)), 4, "0")}-#{String.pad_leading(to_string(Enum.random(1000..9999)), 4, "0")}",
        website: "https://example.com/user/#{i}",
        age: Enum.random(22..58),
        city: Enum.at(cities, rem(i - 1, 5)),
        status: Enum.at(statuses, rem(i - 1, 4)),
        grade: Enum.at(grades, rem(i - 1, 4)),
        department: Enum.at(departments, rem(i - 1, 5)),
        score: Enum.random(10..100),
        completion: Enum.random(0..100),
        rating: Enum.random(1..5),
        is_active: rem(i, 3) != 0,
        priority: Enum.at(priorities, rem(i - 1, 3))
      }
    end
  end
end
