defmodule LiveViewGrid.DataSource do
  @moduledoc """
  DataSource behaviour for Grid data backends.

  Defines a contract for pluggable data sources (InMemory, Ecto, etc.).
  Grid delegates data fetching and CRUD operations to the configured adapter.

  ## Usage

      # InMemory (default - backward compatible)
      Grid.new(data: rows, columns: cols)

      # Ecto adapter
      Grid.new(
        columns: cols,
        data_source: {LiveViewGrid.DataSource.Ecto, %{
          repo: MyApp.Repo,
          schema: MyApp.User
        }}
      )
  """

  @type config :: map()
  @type state :: map()
  @type options :: map()
  @type columns :: list(map())
  @type row :: map()
  @type row_id :: any()

  @doc """
  Fetch visible data based on current grid state (filters, sort, pagination).

  Returns `{rows, total_count, filtered_count}` where:
  - `rows` - list of row maps for the current page
  - `total_count` - total number of rows (unfiltered)
  - `filtered_count` - number of rows after filtering
  """
  @callback fetch_data(config(), state(), options(), columns()) ::
              {list(row()), non_neg_integer(), non_neg_integer()}

  @doc """
  Insert a new row and return the persisted row with its ID.
  """
  @callback insert_row(config(), row()) :: {:ok, row()} | {:error, any()}

  @doc """
  Update a row by ID with the given changes map.
  """
  @callback update_row(config(), row_id(), map()) :: {:ok, row()} | {:error, any()}

  @doc """
  Delete a row by ID.
  """
  @callback delete_row(config(), row_id()) :: :ok | {:error, any()}
end
