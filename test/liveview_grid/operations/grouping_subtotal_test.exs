defmodule LiveViewGrid.Grouping.SubtotalTest do
  use ExUnit.Case, async: true

  alias LiveViewGrid.Grouping

  @data [
    %{id: 1, department: "개발", position: "시니어", salary: 80_000_000},
    %{id: 2, department: "개발", position: "시니어", salary: 70_000_000},
    %{id: 3, department: "개발", position: "주니어", salary: 50_000_000},
    %{id: 4, department: "마케팅", position: "시니어", salary: 60_000_000},
    %{id: 5, department: "마케팅", position: "주니어", salary: 45_000_000}
  ]

  @aggregates %{salary: :sum}

  describe "subtotals" do
    test "기본 그룹핑에 소계 행이 추가된다" do
      result = Grouping.group_data(@data, [:department], %{}, @aggregates, subtotals: true)

      subtotals = Enum.filter(result, &(Map.get(&1, :_row_type) == :subtotal))
      assert length(subtotals) == 2

      dev_sub = Enum.find(subtotals, &(&1._group_value == "개발 소계"))
      assert dev_sub._group_aggregates.salary == 200_000_000
      assert dev_sub._group_count == 3

      mkt_sub = Enum.find(subtotals, &(&1._group_value == "마케팅 소계"))
      assert mkt_sub._group_aggregates.salary == 105_000_000
      assert mkt_sub._group_count == 2
    end

    test "소계 행이 그룹 끝에 위치한다" do
      result = Grouping.group_data(@data, [:department], %{}, @aggregates, subtotals: true)

      # 개발 그룹: header, 3 data rows, subtotal
      dev_header_idx = Enum.find_index(result, &(Map.get(&1, :_row_type) == :group_header and &1._group_value == "개발"))
      dev_subtotal_idx = Enum.find_index(result, &(Map.get(&1, :_row_type) == :subtotal and &1._group_value == "개발 소계"))

      assert dev_subtotal_idx == dev_header_idx + 4  # header + 3 data rows
    end

    test "소계 옵션 off일 때 소계 행이 없다" do
      result = Grouping.group_data(@data, [:department], %{}, @aggregates)
      subtotals = Enum.filter(result, &(Map.get(&1, :_row_type) == :subtotal))
      assert subtotals == []
    end

    test "다단계 그룹에서 각 레벨별 소계가 생성된다" do
      result = Grouping.group_data(@data, [:department, :position], %{}, @aggregates, subtotals: true)

      subtotals = Enum.filter(result, &(Map.get(&1, :_row_type) == :subtotal))
      # 개발-시니어, 개발-주니어, 마케팅-시니어, 마케팅-주니어, 개발(상위), 마케팅(상위)
      assert length(subtotals) >= 4

      # 상위 그룹 소계
      dev_top_sub = Enum.find(subtotals, &(&1._group_value == "개발 소계" and &1._group_depth == 0))
      assert dev_top_sub != nil
      assert dev_top_sub._group_aggregates.salary == 200_000_000
    end

    test "접힌 그룹에는 소계가 표시되지 않는다" do
      expanded = %{"개발" => false}
      result = Grouping.group_data(@data, [:department], expanded, @aggregates, subtotals: true)

      dev_subtotals = Enum.filter(result, &(Map.get(&1, :_row_type) == :subtotal and &1._group_value == "개발 소계"))
      assert dev_subtotals == []
    end
  end

  describe "grand_total" do
    test "총계 행이 맨 마지막에 추가된다" do
      result = Grouping.group_data(@data, [:department], %{}, @aggregates, grand_total: true)

      last = List.last(result)
      assert last._row_type == :grand_total
      assert last._group_value == "총계"
      assert last._group_aggregates.salary == 305_000_000
      assert last._group_count == 5
    end

    test "총계 옵션 off일 때 총계 행이 없다" do
      result = Grouping.group_data(@data, [:department], %{}, @aggregates)
      grand = Enum.filter(result, &(Map.get(&1, :_row_type) == :grand_total))
      assert grand == []
    end

    test "소계 + 총계 동시 사용" do
      result = Grouping.group_data(@data, [:department], %{}, @aggregates, subtotals: true, grand_total: true)

      subtotals = Enum.filter(result, &(Map.get(&1, :_row_type) == :subtotal))
      grand = Enum.filter(result, &(Map.get(&1, :_row_type) == :grand_total))

      assert length(subtotals) == 2
      assert length(grand) == 1

      grand_row = hd(grand)
      assert grand_row._group_aggregates.salary == 305_000_000
    end

    test "집계 없으면 총계 행이 추가되지 않는다" do
      result = Grouping.group_data(@data, [:department], %{}, %{}, grand_total: true)
      grand = Enum.filter(result, &(Map.get(&1, :_row_type) == :grand_total))
      assert grand == []
    end
  end
end
