defmodule LiveViewGrid.SchemaRegistry do
  @moduledoc """
  Registry of available Ecto schemas for Grid Builder.

  Reads the schema list from application config `:schema_registry`
  and introspects each module for field metadata.

  ## Config

      config :liveview_grid, :schema_registry, [
        LiveviewGrid.DemoUser,
        LiveviewGrid.ApiKey
      ]
  """

  @doc """
  Lists all registered schemas with metadata.

  Returns a list of maps with module, table name, and field info.
  """
  @spec list_schemas() :: [map()]
  def list_schemas do
    Application.get_env(:liveview_grid, :schema_registry, [])
    |> Enum.filter(&Code.ensure_loaded?/1)
    |> Enum.map(&schema_info/1)
    |> Enum.reject(&is_nil/1)
  end

  @doc """
  Returns metadata for a single schema module.
  """
  @spec schema_info(module()) :: map() | nil
  def schema_info(module) do
    if function_exported?(module, :__schema__, 1) do
      fields = module.__schema__(:fields)
      table = module.__schema__(:source)

      field_infos =
        Enum.map(fields, fn field ->
          ecto_type = module.__schema__(:type, field)

          %{
            name: field,
            type: ecto_type_to_grid_type(ecto_type),
            ecto_type: ecto_type
          }
        end)

      %{
        module: module,
        table: table,
        label: module |> Module.split() |> List.last(),
        fields: field_infos
      }
    else
      nil
    end
  end

  @doc """
  Converts schema fields to grid-compatible column definitions.

  Returns column maps ready for the Grid Builder column list.
  """
  @spec schema_columns(module()) :: [map()]
  def schema_columns(module) do
    case schema_info(module) do
      nil ->
        []

      %{fields: fields} ->
        Enum.map(fields, fn %{name: name, type: type} ->
          %{
            field: Atom.to_string(name),
            label: name |> Atom.to_string() |> String.capitalize(),
            type: type,
            sortable: true,
            filterable: true,
            filter_type: filter_type_for(type),
            editable: name != :id,
            editor_type: editor_type_for(type)
          }
        end)
    end
  end

  # ── Private ──

  @spec ecto_type_to_grid_type(atom() | tuple()) :: atom()
  defp ecto_type_to_grid_type(:string), do: :string
  defp ecto_type_to_grid_type(:integer), do: :integer
  defp ecto_type_to_grid_type(:float), do: :float
  defp ecto_type_to_grid_type(:boolean), do: :boolean
  defp ecto_type_to_grid_type(:date), do: :date
  defp ecto_type_to_grid_type(:naive_datetime), do: :datetime
  defp ecto_type_to_grid_type(:utc_datetime), do: :datetime
  defp ecto_type_to_grid_type(:id), do: :integer
  defp ecto_type_to_grid_type(_), do: :string

  defp editor_type_for(:integer), do: :number
  defp editor_type_for(:float), do: :number
  defp editor_type_for(:boolean), do: :checkbox
  defp editor_type_for(:date), do: :date
  defp editor_type_for(:datetime), do: :date
  defp editor_type_for(_), do: :text

  defp filter_type_for(:integer), do: :number
  defp filter_type_for(:float), do: :number
  defp filter_type_for(:date), do: :date
  defp filter_type_for(:datetime), do: :date
  defp filter_type_for(_), do: :text
end
