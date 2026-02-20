defmodule LiveViewGrid.SortingTest do
  use ExUnit.Case, async: true

  alias LiveViewGrid.Sorting

  setup do
    data = [
      %{id: 2, name: "Bob", age: 25},
      %{id: 1, name: "Alice", age: 30},
      %{id: 3, name: "Charlie", age: 20}
    ]

    %{data: data}
  end

  test "sorts by name ascending", %{data: data} do
    sorted = Sorting.sort(data, :name, :asc)

    assert length(sorted) == 3
    assert hd(sorted).name == "Alice"
    assert List.last(sorted).name == "Charlie"
  end

  test "sorts by name descending", %{data: data} do
    sorted = Sorting.sort(data, :name, :desc)

    assert hd(sorted).name == "Charlie"
    assert List.last(sorted).name == "Alice"
  end

  test "sorts by age ascending", %{data: data} do
    sorted = Sorting.sort(data, :age, :asc)

    assert hd(sorted).age == 20
    assert List.last(sorted).age == 30
  end

  test "handles nil values (nil last)" do
    data = [
      %{name: "Alice"},
      %{name: nil},
      %{name: "Bob"}
    ]

    sorted = Sorting.sort(data, :name, :asc)

    # nil은 마지막
    assert List.last(sorted).name == nil
  end

  test "sorts data with missing field (nil fallback)", %{data: data} do
    # :email 필드가 없는 행 정렬 시 nil로 처리
    sorted = Sorting.sort(data, :email, :asc)

    # 모든 값이 nil이므로 원래 순서 유지 (안정 정렬)
    assert length(sorted) == 3
  end

  test "stable sort preserves order of equal values" do
    data = [
      %{id: 1, name: "Alice", group: "A"},
      %{id: 2, name: "Bob", group: "A"},
      %{id: 3, name: "Charlie", group: "B"}
    ]

    sorted = Sorting.sort(data, :group, :asc)

    # group "A"인 Alice, Bob 순서 유지
    group_a = Enum.filter(sorted, &(&1.group == "A"))
    assert hd(group_a).id == 1
    assert List.last(group_a).id == 2
  end

  test "sorts mixed numeric values" do
    data = [
      %{id: 1, score: 100},
      %{id: 2, score: 5},
      %{id: 3, score: 50}
    ]

    sorted = Sorting.sort(data, :score, :asc)
    assert hd(sorted).score == 5
    assert List.last(sorted).score == 100
  end
end
