defmodule LiveViewGrid.FilterTest do
  use ExUnit.Case, async: true

  alias LiveViewGrid.Filter

  @columns [
    %{field: :name, filter_type: :text},
    %{field: :email, filter_type: :text},
    %{field: :age, filter_type: :number},
    %{field: :city, filter_type: :text}
  ]

  @data [
    %{id: 1, name: "Alice Kim", email: "alice@example.com", age: 30, city: "서울"},
    %{id: 2, name: "Bob Lee", email: "bob@example.com", age: 25, city: "부산"},
    %{id: 3, name: "Charlie Park", email: "charlie@example.com", age: 35, city: "대전"},
    %{id: 4, name: "David Choi", email: "david@example.com", age: 28, city: "서울"},
    %{id: 5, name: "Eve Jung", email: "eve@example.com", age: 40, city: "인천"}
  ]

  describe "텍스트 필터" do
    test "이름 부분 일치" do
      result = Filter.apply(@data, %{name: "ali"}, @columns)
      assert length(result) == 1
      assert hd(result).name == "Alice Kim"
    end

    test "대소문자 무관" do
      result = Filter.apply(@data, %{name: "ALICE"}, @columns)
      assert length(result) == 1
      assert hd(result).name == "Alice Kim"
    end

    test "이메일 필터" do
      result = Filter.apply(@data, %{email: "bob"}, @columns)
      assert length(result) == 1
      assert hd(result).name == "Bob Lee"
    end

    test "도시 필터 (한글)" do
      result = Filter.apply(@data, %{city: "서울"}, @columns)
      assert length(result) == 2
      assert Enum.all?(result, fn row -> row.city == "서울" end)
    end

    test "빈 필터 → 전체 데이터" do
      result = Filter.apply(@data, %{name: ""}, @columns)
      assert length(result) == 5
    end

    test "일치 없음 → 빈 결과" do
      result = Filter.apply(@data, %{name: "xyz"}, @columns)
      assert result == []
    end

    test "nil 값 필터 무시" do
      result = Filter.apply(@data, %{name: nil}, @columns)
      assert length(result) == 5
    end
  end

  describe "숫자 필터" do
    test "등호 (=30)" do
      result = Filter.apply(@data, %{age: "=30"}, @columns)
      assert length(result) == 1
      assert hd(result).age == 30
    end

    test "연산자 없이 숫자만 (30)" do
      result = Filter.apply(@data, %{age: "30"}, @columns)
      assert length(result) == 1
      assert hd(result).age == 30
    end

    test "초과 (>30)" do
      result = Filter.apply(@data, %{age: ">30"}, @columns)
      assert length(result) == 2
      ages = Enum.map(result, & &1.age) |> Enum.sort()
      assert ages == [35, 40]
    end

    test "이상 (>=30)" do
      result = Filter.apply(@data, %{age: ">=30"}, @columns)
      assert length(result) == 3
    end

    test "미만 (<30)" do
      result = Filter.apply(@data, %{age: "<30"}, @columns)
      assert length(result) == 2
      ages = Enum.map(result, & &1.age) |> Enum.sort()
      assert ages == [25, 28]
    end

    test "이하 (<=30)" do
      result = Filter.apply(@data, %{age: "<=30"}, @columns)
      assert length(result) == 3
    end

    test "공백 포함 (> 30)" do
      result = Filter.apply(@data, %{age: "> 30"}, @columns)
      assert length(result) == 2
    end

    test "잘못된 숫자 → 빈 결과" do
      result = Filter.apply(@data, %{age: "abc"}, @columns)
      assert result == []
    end
  end

  describe "다중 필터 (AND 조건)" do
    test "이름 + 도시" do
      result = Filter.apply(@data, %{name: "d", city: "서울"}, @columns)
      assert length(result) == 1
      assert hd(result).name == "David Choi"
    end

    test "도시 + 나이" do
      result = Filter.apply(@data, %{city: "서울", age: ">29"}, @columns)
      assert length(result) == 1
      assert hd(result).name == "Alice Kim"
    end

    test "모든 필터 조합 (결과 없음)" do
      result = Filter.apply(@data, %{name: "alice", city: "부산"}, @columns)
      assert result == []
    end
  end

  describe "빈/빈 필터 맵" do
    test "빈 필터 맵 → 전체" do
      result = Filter.apply(@data, %{}, @columns)
      assert length(result) == 5
    end

    test "빈 데이터 → 빈 결과" do
      result = Filter.apply([], %{name: "alice"}, @columns)
      assert result == []
    end
  end

  describe "전체 검색 (global_search)" do
    test "이름으로 검색" do
      result = Filter.global_search(@data, "alice", @columns)
      assert length(result) == 1
      assert hd(result).name == "Alice Kim"
    end

    test "이메일로 검색" do
      result = Filter.global_search(@data, "bob@", @columns)
      assert length(result) == 1
      assert hd(result).name == "Bob Lee"
    end

    test "도시로 검색 (한글)" do
      result = Filter.global_search(@data, "서울", @columns)
      assert length(result) == 2
    end

    test "대소문자 무관" do
      result = Filter.global_search(@data, "CHARLIE", @columns)
      assert length(result) == 1
      assert hd(result).name == "Charlie Park"
    end

    test "빈 문자열 → 전체 데이터" do
      result = Filter.global_search(@data, "", @columns)
      assert length(result) == 5
    end

    test "공백만 → 전체 데이터" do
      result = Filter.global_search(@data, "   ", @columns)
      assert length(result) == 5
    end

    test "일치 없음 → 빈 결과" do
      result = Filter.global_search(@data, "zzzzz", @columns)
      assert result == []
    end

    test "숫자 컬럼에서도 검색" do
      result = Filter.global_search(@data, "30", @columns)
      assert length(result) == 1
      assert hd(result).age == 30
    end

    test "nil 값 포함 데이터에서 검색" do
      data_with_nil = [
        %{id: 1, name: nil, email: "a@b.com", age: 30, city: "서울"},
        %{id: 2, name: "Bob", email: "b@b.com", age: 25, city: "부산"}
      ]
      result = Filter.global_search(data_with_nil, "bob", @columns)
      assert length(result) == 1
      assert hd(result).name == "Bob"
    end
  end

  # ── 날짜 필터 (F-062) ──

  @date_columns [
    %{field: :name, filter_type: :text},
    %{field: :created_at, filter_type: :date}
  ]

  @date_data [
    %{id: 1, name: "Alice", created_at: ~D[2026-01-15]},
    %{id: 2, name: "Bob", created_at: ~D[2026-02-10]},
    %{id: 3, name: "Charlie", created_at: ~D[2026-03-20]},
    %{id: 4, name: "David", created_at: ~D[2026-04-05]},
    %{id: 5, name: "Eve", created_at: nil}
  ]

  describe "날짜 필터 (기본)" do
    test "범위 필터: from~to" do
      result = Filter.apply(@date_data, %{created_at: "2026-01-01~2026-02-28"}, @date_columns)
      assert length(result) == 2
      names = Enum.map(result, & &1.name) |> Enum.sort()
      assert names == ["Alice", "Bob"]
    end

    test "범위 필터: from만" do
      result = Filter.apply(@date_data, %{created_at: "2026-03-01~"}, @date_columns)
      assert length(result) == 2
      names = Enum.map(result, & &1.name) |> Enum.sort()
      assert names == ["Charlie", "David"]
    end

    test "범위 필터: to만" do
      result = Filter.apply(@date_data, %{created_at: "~2026-02-28"}, @date_columns)
      assert length(result) == 2
      names = Enum.map(result, & &1.name) |> Enum.sort()
      assert names == ["Alice", "Bob"]
    end

    test "단일 날짜 (정확히 일치)" do
      result = Filter.apply(@date_data, %{created_at: "2026-02-10"}, @date_columns)
      assert length(result) == 1
      assert hd(result).name == "Bob"
    end

    test "빈 필터 → 전체 데이터" do
      result = Filter.apply(@date_data, %{created_at: ""}, @date_columns)
      assert length(result) == 5
    end

    test "nil 날짜는 필터에서 제외" do
      result = Filter.apply(@date_data, %{created_at: "2026-01-01~2026-12-31"}, @date_columns)
      assert length(result) == 4
      refute Enum.any?(result, fn row -> row.name == "Eve" end)
    end

    test "DateTime 값도 Date로 비교" do
      data = [
        %{id: 1, name: "Alice", created_at: ~N[2026-02-10 14:30:00]},
        %{id: 2, name: "Bob", created_at: ~N[2026-03-15 09:00:00]}
      ]
      result = Filter.apply(data, %{created_at: "2026-02-01~2026-02-28"}, @date_columns)
      assert length(result) == 1
      assert hd(result).name == "Alice"
    end

    test "ISO8601 문자열 값도 처리" do
      data = [
        %{id: 1, name: "Alice", created_at: "2026-01-15"},
        %{id: 2, name: "Bob", created_at: "2026-03-20"}
      ]
      result = Filter.apply(data, %{created_at: "2026-01-01~2026-02-28"}, @date_columns)
      assert length(result) == 1
      assert hd(result).name == "Alice"
    end
  end

  describe "날짜 필터 (고급)" do
    test "eq: 같은 날" do
      conditions = [%{field: :created_at, operator: :eq, value: "2026-02-10"}]
      result = Filter.apply_advanced(@date_data, %{logic: :and, conditions: conditions}, @date_columns)
      assert length(result) == 1
      assert hd(result).name == "Bob"
    end

    test "before: 이전" do
      conditions = [%{field: :created_at, operator: :before, value: "2026-03-01"}]
      result = Filter.apply_advanced(@date_data, %{logic: :and, conditions: conditions}, @date_columns)
      assert length(result) == 2
      names = Enum.map(result, & &1.name) |> Enum.sort()
      assert names == ["Alice", "Bob"]
    end

    test "after: 이후" do
      conditions = [%{field: :created_at, operator: :after, value: "2026-03-01"}]
      result = Filter.apply_advanced(@date_data, %{logic: :and, conditions: conditions}, @date_columns)
      assert length(result) == 2
      names = Enum.map(result, & &1.name) |> Enum.sort()
      assert names == ["Charlie", "David"]
    end

    test "between: 사이" do
      conditions = [%{field: :created_at, operator: :between, value: "2026-02-01~2026-03-31"}]
      result = Filter.apply_advanced(@date_data, %{logic: :and, conditions: conditions}, @date_columns)
      assert length(result) == 2
      names = Enum.map(result, & &1.name) |> Enum.sort()
      assert names == ["Bob", "Charlie"]
    end

    test "is_empty: 비어있음" do
      conditions = [%{field: :created_at, operator: :is_empty, value: ""}]
      result = Filter.apply_advanced(@date_data, %{logic: :and, conditions: conditions}, @date_columns)
      assert length(result) == 1
      assert hd(result).name == "Eve"
    end

    test "is_not_empty: 비어있지않음" do
      conditions = [%{field: :created_at, operator: :is_not_empty, value: ""}]
      result = Filter.apply_advanced(@date_data, %{logic: :and, conditions: conditions}, @date_columns)
      assert length(result) == 4
      refute Enum.any?(result, fn row -> row.name == "Eve" end)
    end

    test "날짜 + 텍스트 다중 조건 (AND)" do
      conditions = [
        %{field: :created_at, operator: :after, value: "2026-02-01"},
        %{field: :name, operator: :contains, value: "Charlie"}
      ]
      result = Filter.apply_advanced(@date_data, %{logic: :and, conditions: conditions}, @date_columns)
      assert length(result) == 1
      assert hd(result).name == "Charlie"
    end

    test "날짜 다중 조건 (OR)" do
      conditions = [
        %{field: :created_at, operator: :eq, value: "2026-01-15"},
        %{field: :created_at, operator: :eq, value: "2026-04-05"}
      ]
      result = Filter.apply_advanced(@date_data, %{logic: :or, conditions: conditions}, @date_columns)
      assert length(result) == 2
      names = Enum.map(result, & &1.name) |> Enum.sort()
      assert names == ["Alice", "David"]
    end
  end

  describe "nil 값 포함 데이터" do
    test "nil 필드값은 텍스트 필터에서 제외" do
      data_with_nil = [
        %{id: 1, name: nil, email: "a@b.com", age: 30, city: "서울"},
        %{id: 2, name: "Bob", email: "b@b.com", age: 25, city: "부산"}
      ]
      result = Filter.apply(data_with_nil, %{name: "bob"}, @columns)
      assert length(result) == 1
      assert hd(result).name == "Bob"
    end

    test "nil 필드값은 숫자 필터에서 제외" do
      data_with_nil = [
        %{id: 1, name: "Alice", email: "a@b.com", age: nil, city: "서울"},
        %{id: 2, name: "Bob", email: "b@b.com", age: 25, city: "부산"}
      ]
      result = Filter.apply(data_with_nil, %{age: ">20"}, @columns)
      assert length(result) == 1
      assert hd(result).name == "Bob"
    end
  end

  # ── FA-003: Date Filter Enhancement (Date Preset) ──

  describe "FA-003: date_preset_range/1" do
    test ":today returns today's date range" do
      {from, to} = Filter.date_preset_range(:today)
      today = Date.utc_today()
      assert from == today
      assert to == today
    end

    test ":yesterday returns yesterday" do
      {from, to} = Filter.date_preset_range(:yesterday)
      yesterday = Date.add(Date.utc_today(), -1)
      assert from == yesterday
      assert to == yesterday
    end

    test ":this_week returns current week range" do
      {from, to} = Filter.date_preset_range(:this_week)
      today = Date.utc_today()
      assert Date.compare(from, today) in [:lt, :eq]
      assert Date.compare(to, today) in [:gt, :eq]
    end

    test ":last_week returns previous week range" do
      {from, to} = Filter.date_preset_range(:last_week)
      today = Date.utc_today()
      assert Date.compare(to, today) == :lt
      assert Date.diff(to, from) == 6
    end

    test ":this_month returns current month range" do
      {from, to} = Filter.date_preset_range(:this_month)
      today = Date.utc_today()
      assert from.day == 1
      assert from.month == today.month
      assert to.month == today.month
    end

    test ":last_month returns previous month range" do
      {from, to} = Filter.date_preset_range(:last_month)
      today = Date.utc_today()
      assert from.day == 1
      assert Date.compare(to, today) == :lt
    end

    test ":last_30_days returns 30-day range" do
      {from, to} = Filter.date_preset_range(:last_30_days)
      today = Date.utc_today()
      assert to == today
      assert Date.diff(to, from) == 30
    end

    test ":last_90_days returns 90-day range" do
      {from, to} = Filter.date_preset_range(:last_90_days)
      today = Date.utc_today()
      assert to == today
      assert Date.diff(to, from) == 90
    end
  end

  describe "FA-003: date_preset_to_filter/1" do
    test "returns ISO8601 date range string" do
      result = Filter.date_preset_to_filter(:today)
      today = Date.utc_today() |> Date.to_iso8601()
      assert result == "#{today}~#{today}"
    end

    test "range string format is from~to" do
      result = Filter.date_preset_to_filter(:last_30_days)
      assert String.contains?(result, "~")
      [from_str, to_str] = String.split(result, "~")
      {:ok, _} = Date.from_iso8601(from_str)
      {:ok, _} = Date.from_iso8601(to_str)
    end
  end

  # ── FA-012: Set Filter ──

  describe "FA-012: extract_unique_values/2" do
    test "extracts unique values from data" do
      values = Filter.extract_unique_values(@data, :city)
      assert Enum.sort(values) == Enum.sort(["서울", "부산", "대전", "인천"])
    end

    test "returns unique values without duplicates" do
      values = Filter.extract_unique_values(@data, :city)
      assert length(values) == length(Enum.uniq(values))
    end

    test "handles empty data" do
      values = Filter.extract_unique_values([], :city)
      assert values == []
    end
  end

  describe "FA-012: set filter matching" do
    @set_columns [
      %{field: :name, filter_type: :text},
      %{field: :city, filter_type: :set}
    ]

    test "set filter with list matches selected values" do
      # JSON-encoded list of selected values
      filter_val = Jason.encode!(["서울", "부산"])
      result = Filter.apply(@data, %{city: filter_val}, @set_columns)
      assert length(result) == 3
      assert Enum.all?(result, fn r -> r.city in ["서울", "부산"] end)
    end

    test "set filter with single value" do
      filter_val = Jason.encode!(["대전"])
      result = Filter.apply(@data, %{city: filter_val}, @set_columns)
      assert length(result) == 1
      assert hd(result).city == "대전"
    end

    test "set filter with all values returns all data" do
      all_cities = Filter.extract_unique_values(@data, :city)
      filter_val = Jason.encode!(all_cities)
      result = Filter.apply(@data, %{city: filter_val}, @set_columns)
      assert length(result) == length(@data)
    end

    test "set filter with empty list returns no data" do
      filter_val = Jason.encode!([])
      result = Filter.apply(@data, %{city: filter_val}, @set_columns)
      assert result == []
    end

    test "set filter combined with text filter" do
      set_columns = [
        %{field: :name, filter_type: :text},
        %{field: :city, filter_type: :set}
      ]
      filter_val = Jason.encode!(["서울"])
      result = Filter.apply(@data, %{city: filter_val, name: "alice"}, set_columns)
      assert length(result) == 1
      assert hd(result).name == "Alice Kim"
    end
  end
end
