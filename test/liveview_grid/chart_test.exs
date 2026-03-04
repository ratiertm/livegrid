defmodule LiveviewGrid.ChartTest do
  use ExUnit.Case, async: true

  alias LiveviewGrid.Chart

  @sample_data [
    %{id: 1, name: "Alice", department: "개발", age: 30, salary: 5000},
    %{id: 2, name: "Bob", department: "개발", age: 25, salary: 4500},
    %{id: 3, name: "Carol", department: "영업", age: 35, salary: 5500},
    %{id: 4, name: "Dave", department: "영업", age: 28, salary: 4800},
    %{id: 5, name: "Eve", department: "기획", age: 32, salary: 5200}
  ]

  @config %{
    chart_type: :bar,
    category_field: :department,
    value_fields: [:salary],
    aggregation: :sum
  }

  describe "prepare_data/2" do
    test "카테고리별 집계 데이터 생성" do
      result = Chart.prepare_data(@sample_data, @config)

      assert result != nil
      assert length(result.points) == 3
      assert result.max_value > 0
    end

    test "다중 value_fields 집계" do
      config = %{@config | value_fields: [:salary, :age]}
      result = Chart.prepare_data(@sample_data, config)

      first_point = hd(result.points)
      assert Map.has_key?(first_point.values, :salary)
      assert Map.has_key?(first_point.values, :age)
    end

    test "category_field가 nil이면 nil 반환" do
      assert Chart.prepare_data(@sample_data, %{@config | category_field: nil}) == nil
    end

    test "value_fields가 빈 리스트이면 nil 반환" do
      assert Chart.prepare_data(@sample_data, %{@config | value_fields: []}) == nil
    end

    test "빈 데이터이면 nil 반환" do
      assert Chart.prepare_data([], @config) == nil
    end

    test "색상이 할당됨" do
      result = Chart.prepare_data(@sample_data, @config)

      for point <- result.points do
        assert point.color != nil
        assert String.starts_with?(point.color, "#")
      end
    end

    test "카테고리별로 정렬됨" do
      result = Chart.prepare_data(@sample_data, @config)
      categories = Enum.map(result.points, & &1.category)
      assert categories == Enum.sort(categories)
    end
  end

  describe "aggregate/2" do
    test "sum" do
      assert Chart.aggregate([10, 20, 30], :sum) == 60
    end

    test "avg" do
      assert Chart.aggregate([10, 20, 30], :avg) == 20.0
    end

    test "count" do
      assert Chart.aggregate([10, 20, 30], :count) == 3
    end

    test "min" do
      assert Chart.aggregate([10, 20, 30], :min) == 10
    end

    test "max" do
      assert Chart.aggregate([10, 20, 30], :max) == 30
    end

    test "빈 리스트는 0 반환" do
      assert Chart.aggregate([], :sum) == 0
    end
  end

  describe "to_number/1" do
    test "정수" do
      assert Chart.to_number(42) == 42
    end

    test "실수" do
      assert Chart.to_number(3.14) == 3.14
    end

    test "문자열 숫자" do
      assert Chart.to_number("100") == 100.0
    end

    test "비숫자 문자열" do
      assert Chart.to_number("abc") == 0
    end

    test "nil" do
      assert Chart.to_number(nil) == 0
    end
  end

  describe "format_number/1" do
    test "천 단위 구분자" do
      assert Chart.format_number(12345) == "12,345"
    end

    test "소수점" do
      assert Chart.format_number(3.14) == "3.1"
    end

    test "정수형 실수" do
      assert Chart.format_number(5.0) == "5"
    end

    test "일반 정수" do
      assert Chart.format_number(42) == "42"
    end
  end

  describe "palette/0" do
    test "8색 팔레트 반환" do
      assert length(Chart.palette()) == 8
    end
  end
end
