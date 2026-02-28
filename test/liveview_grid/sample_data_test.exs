defmodule LiveViewGrid.SampleDataTest do
  use ExUnit.Case, async: true

  alias LiveViewGrid.SampleData

  describe "generate/2" do
    test "generates correct number of rows" do
      columns = [%{field: :name, type: :string}]

      assert length(SampleData.generate(columns, 3)) == 3
      assert length(SampleData.generate(columns, 10)) == 10
    end

    test "default count is 5" do
      columns = [%{field: :name, type: :string}]
      assert length(SampleData.generate(columns)) == 5
    end

    test "each row has an :id field" do
      columns = [%{field: :name, type: :string}]
      rows = SampleData.generate(columns, 3)

      Enum.each(rows, fn row ->
        assert Map.has_key?(row, :id)
      end)

      assert Enum.map(rows, & &1.id) == [1, 2, 3]
    end

    test "generates string type values" do
      columns = [%{field: :title, type: :string}]
      [row | _] = SampleData.generate(columns, 1)

      assert is_binary(row.title)
    end

    test "generates integer type values" do
      columns = [%{field: :age, type: :integer}]
      [row | _] = SampleData.generate(columns, 1)

      assert is_integer(row.age)
    end

    test "generates float type values" do
      columns = [%{field: :price, type: :float}]
      [row | _] = SampleData.generate(columns, 1)

      assert is_float(row.price)
    end

    test "generates boolean type values" do
      columns = [%{field: :active, type: :boolean}]
      rows = SampleData.generate(columns, 2)

      Enum.each(rows, fn row ->
        assert is_boolean(row.active)
      end)
    end

    test "generates date type values" do
      columns = [%{field: :created, type: :date}]
      [row | _] = SampleData.generate(columns, 1)

      assert %Date{} = row.created
    end

    test "generates datetime type values" do
      columns = [%{field: :updated, type: :datetime}]
      [row | _] = SampleData.generate(columns, 1)

      assert %NaiveDateTime{} = row.updated
    end

    test "generates fallback value for unknown types" do
      columns = [%{field: :custom, type: :unknown}]
      [row | _] = SampleData.generate(columns, 1)

      assert is_binary(row.custom)
    end

    test "field-aware: name field generates realistic names" do
      columns = [%{field: :name, type: :string}]
      [row | _] = SampleData.generate(columns, 1)

      # Name should contain a space (First Last)
      assert String.contains?(row.name, " ")
    end

    test "field-aware: email field generates email format" do
      columns = [%{field: :email, type: :string}]
      [row | _] = SampleData.generate(columns, 1)

      assert String.contains?(row.email, "@")
      assert String.contains?(row.email, ".com")
    end

    test "field-aware: phone field generates phone format" do
      columns = [%{field: :phone, type: :string}]
      [row | _] = SampleData.generate(columns, 1)

      assert String.contains?(row.phone, "010-")
    end

    test "handles multiple columns" do
      columns = [
        %{field: :name, type: :string},
        %{field: :age, type: :integer},
        %{field: :active, type: :boolean}
      ]

      [row | _] = SampleData.generate(columns, 1)

      assert Map.has_key?(row, :name)
      assert Map.has_key?(row, :age)
      assert Map.has_key?(row, :active)
    end

    test "handles string field names" do
      columns = [%{field: "name", type: :string}]
      [row | _] = SampleData.generate(columns, 1)

      assert Map.has_key?(row, :name)
    end

    test "skips columns with empty field" do
      columns = [%{field: "", type: :string}, %{field: :name, type: :string}]
      [row | _] = SampleData.generate(columns, 1)

      assert Map.has_key?(row, :name)
      assert map_size(row) == 2  # :id + :name
    end
  end
end
