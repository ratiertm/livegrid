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
end
