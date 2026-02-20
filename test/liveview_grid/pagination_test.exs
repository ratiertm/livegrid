defmodule LiveViewGrid.PaginationTest do
  use ExUnit.Case, async: true

  alias LiveViewGrid.Pagination

  setup do
    data = Enum.map(1..50, fn i -> %{id: i, name: "User #{i}"} end)
    %{data: data}
  end

  test "returns first page (10 items)", %{data: data} do
    page_data = Pagination.paginate(data, 1, 10)

    assert length(page_data) == 10
    assert hd(page_data).id == 1
    assert List.last(page_data).id == 10
  end

  test "returns second page", %{data: data} do
    page_data = Pagination.paginate(data, 2, 10)

    assert length(page_data) == 10
    assert hd(page_data).id == 11
    assert List.last(page_data).id == 20
  end

  test "returns last page (partial)", %{data: data} do
    # 50개 / 10 = 5페이지
    page_data = Pagination.paginate(data, 5, 10)

    assert length(page_data) == 10
    assert List.last(page_data).id == 50
  end

  test "returns empty list for out of range page", %{data: data} do
    page_data = Pagination.paginate(data, 10, 10)

    assert page_data == []
  end

  test "returns all data when page_size > data length", %{data: data} do
    page_data = Pagination.paginate(data, 1, 1000)

    assert length(page_data) == 50
    assert hd(page_data).id == 1
    assert List.last(page_data).id == 50
  end

  test "page_size of 1 returns single items", %{data: data} do
    page1 = Pagination.paginate(data, 1, 1)
    page2 = Pagination.paginate(data, 2, 1)

    assert length(page1) == 1
    assert hd(page1).id == 1
    assert length(page2) == 1
    assert hd(page2).id == 2
  end

  describe "total_pages/2" do
    test "calculates total pages exactly" do
      assert Pagination.total_pages(100, 20) == 5
    end

    test "calculates total pages with remainder (rounds up)" do
      assert Pagination.total_pages(101, 20) == 6
      assert Pagination.total_pages(99, 20) == 5
    end

    test "returns 0 for empty data" do
      assert Pagination.total_pages(0, 20) == 0
    end

    test "total_pages with page_size of 1" do
      assert Pagination.total_pages(50, 1) == 50
    end
  end
end
