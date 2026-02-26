defmodule LiveViewGridWeb.Components.GridConfig.Tabs.GridSettingsTab do
  @moduledoc """
  Grid Settings Tab Component (Phase 2)

  ConfigModal의 Tab 4: Grid Settings 탭의 내용을 렌더링하는
  함수형 컴포넌트입니다.

  5개의 섹션으로 구성됩니다:
  1. Pagination Settings (page_size)
  2. Display Settings (show_row_number, show_header, show_footer)
  3. Theme Settings (theme with preview)
  4. Scroll & Row Settings (virtual_scroll, row_height slider)
  5. Column Freezing (frozen_columns)
  """

  use Phoenix.Component

  attr :options, :map, required: true
  attr :form_state, :map, default: %{}
  attr :target, :any, default: nil

  @doc """
  Grid Settings 탭의 전체 폼을 렌더링합니다.
  """
  def render(assigns) do
    ~H"""
    <div class="grid-settings-tab py-4">
      <!-- Section 1: Pagination Settings -->
      <div class="form-section mb-6 pb-6 border-b border-gray-200">
        <h3 class="text-base font-semibold text-gray-800 mb-4">Pagination Settings</h3>

        <div class="form-group mb-4">
          <label class="block text-sm font-medium text-gray-700 mb-1" for="gs_page_size">
            Page Size
          </label>
          <select
            id="gs_page_size"
            name="value"
            phx-change="update_grid_option"
            phx-value-option="page_size"
            phx-target={@target}
            class="w-full px-3 py-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="10" selected={option_value(@options, :page_size) == 10}>10 rows per page</option>
            <option value="25" selected={option_value(@options, :page_size) == 25}>25 rows per page</option>
            <option value="50" selected={option_value(@options, :page_size) == 50}>50 rows per page</option>
            <option value="100" selected={option_value(@options, :page_size) == 100}>100 rows per page</option>
            <%= if option_value(@options, :page_size) not in [10, 25, 50, 100] do %>
              <option value={option_value(@options, :page_size)} selected={true}>
                <%= option_value(@options, :page_size) %> rows per page (custom)
              </option>
            <% end %>
          </select>
          <p class="text-xs text-gray-500 mt-1">Number of rows to display per page</p>
        </div>
      </div>

      <!-- Section 2: Display Settings -->
      <div class="form-section mb-6 pb-6 border-b border-gray-200">
        <h3 class="text-base font-semibold text-gray-800 mb-4">Display Settings</h3>

        <div class="flex items-center gap-3 p-3 mb-3 bg-gray-50 rounded border border-gray-200">
          <input
            type="checkbox"
            id="gs_show_row_number"
            checked={option_value(@options, :show_row_number)}
            phx-click="toggle_grid_option"
            phx-value-option="show_row_number"
            phx-target={@target}
            class="w-4 h-4 text-blue-600 cursor-pointer"
          />
          <div>
            <label for="gs_show_row_number" class="text-sm font-medium text-gray-700 cursor-pointer">
              Show Row Numbers
            </label>
            <p class="text-xs text-gray-500 mt-0.5">Display sequential row numbers in the left margin</p>
          </div>
        </div>

        <div class="flex items-center gap-3 p-3 mb-3 bg-gray-50 rounded border border-gray-200">
          <input
            type="checkbox"
            id="gs_show_header"
            checked={option_value(@options, :show_header)}
            phx-click="toggle_grid_option"
            phx-value-option="show_header"
            phx-target={@target}
            class="w-4 h-4 text-blue-600 cursor-pointer"
          />
          <div>
            <label for="gs_show_header" class="text-sm font-medium text-gray-700 cursor-pointer">
              Show Header Row
            </label>
            <p class="text-xs text-gray-500 mt-0.5">Display column headers at the top of the grid</p>
          </div>
        </div>

        <div class="flex items-center gap-3 p-3 mb-3 bg-gray-50 rounded border border-gray-200">
          <input
            type="checkbox"
            id="gs_show_footer"
            checked={option_value(@options, :show_footer)}
            phx-click="toggle_grid_option"
            phx-value-option="show_footer"
            phx-target={@target}
            class="w-4 h-4 text-blue-600 cursor-pointer"
          />
          <div>
            <label for="gs_show_footer" class="text-sm font-medium text-gray-700 cursor-pointer">
              Show Footer Row
            </label>
            <p class="text-xs text-gray-500 mt-0.5">Display aggregation/summary footer at the bottom</p>
          </div>
        </div>
      </div>

      <!-- Section 3: Theme Settings -->
      <div class="form-section mb-6 pb-6 border-b border-gray-200">
        <h3 class="text-base font-semibold text-gray-800 mb-4">Theme Settings</h3>

        <div class="form-group mb-4">
          <label class="block text-sm font-medium text-gray-700 mb-1" for="gs_theme">Theme</label>
          <select
            id="gs_theme"
            name="value"
            phx-change="update_grid_option"
            phx-value-option="theme"
            phx-target={@target}
            class="w-full px-3 py-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="light" selected={option_value(@options, :theme) == "light"}>Light (Default)</option>
            <option value="dark" selected={option_value(@options, :theme) == "dark"}>Dark</option>
            <option value="custom" selected={option_value(@options, :theme) == "custom"}>Custom</option>
          </select>
          <p class="text-xs text-gray-500 mt-1">Choose color scheme for the grid</p>

          <!-- Theme Preview -->
          <div class="mt-3 theme-preview">
            <div class={[
              "preview-box w-full p-4 rounded text-center font-medium transition-all",
              theme_preview_class(option_value(@options, :theme))
            ]}>
              Theme Preview: <%= option_value(@options, :theme) || "light" %>
            </div>
          </div>
        </div>
      </div>

      <!-- Section 4: Scroll & Row Settings -->
      <div class="form-section mb-6 pb-6 border-b border-gray-200">
        <h3 class="text-base font-semibold text-gray-800 mb-4">Scroll & Row Settings</h3>

        <div class="flex items-center gap-3 p-3 mb-4 bg-gray-50 rounded border border-gray-200">
          <input
            type="checkbox"
            id="gs_virtual_scroll"
            checked={option_value(@options, :virtual_scroll)}
            phx-click="toggle_grid_option"
            phx-value-option="virtual_scroll"
            phx-target={@target}
            class="w-4 h-4 text-blue-600 cursor-pointer"
          />
          <div>
            <label for="gs_virtual_scroll" class="text-sm font-medium text-gray-700 cursor-pointer">
              Enable Virtual Scrolling
            </label>
            <p class="text-xs text-gray-500 mt-0.5">
              For large datasets (1000+ rows), render only visible rows for performance
            </p>
          </div>
        </div>

        <div class="form-group">
          <label class="block text-sm font-medium text-gray-700 mb-1">
            Row Height:
            <span class="value-display font-mono bg-gray-100 px-1.5 py-0.5 rounded text-sm ml-1">
              <%= option_value(@options, :row_height) %> px
            </span>
          </label>
          <input
            type="range"
            id="gs_row_height"
            name="value"
            min="32"
            max="80"
            value={option_value(@options, :row_height)}
            phx-change="update_grid_option"
            phx-value-option="row_height"
            phx-target={@target}
            class="form-slider w-full h-2 bg-gray-200 rounded-lg appearance-none cursor-pointer accent-blue-600"
          />
          <div class="slider-labels flex justify-between text-xs text-gray-500 mt-1">
            <span class="label-min">32px (Compact)</span>
            <span class="label-max">80px (Spacious)</span>
          </div>
          <p class="help-text text-xs text-gray-500 mt-1">Height of each row in pixels (affects vertical spacing)</p>
        </div>
      </div>

      <!-- Section 5: Column Freezing -->
      <div class="form-section">
        <h3 class="text-base font-semibold text-gray-800 mb-4">Column Freezing</h3>

        <div class="form-group">
          <label class="block text-sm font-medium text-gray-700 mb-1" for="gs_frozen_columns">
            Frozen Columns
          </label>
          <input
            type="number"
            id="gs_frozen_columns"
            name="value"
            min="0"
            max="10"
            value={option_value(@options, :frozen_columns)}
            phx-change="update_grid_option"
            phx-value-option="frozen_columns"
            phx-target={@target}
            class="w-32 px-3 py-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
          <p class="help-text text-xs text-gray-500 mt-1">
            Number of leftmost columns to keep visible when horizontal scrolling (0 = no frozen columns)
          </p>
        </div>
      </div>
    </div>
    """
  end

  # ============================================================================
  # Private helpers
  # ============================================================================

  # Retrieve option value supporting both atom and string keys
  defp option_value(options, key) when is_map(options) and is_atom(key) do
    Map.get(options, key) || Map.get(options, Atom.to_string(key))
  end

  defp option_value(_options, _key), do: nil

  # Return Tailwind class for theme preview box
  defp theme_preview_class("dark"), do: "bg-gray-800 border border-gray-600 text-white"
  defp theme_preview_class("custom"), do: "bg-gray-100 border border-gray-400 text-gray-700"
  defp theme_preview_class(_), do: "bg-white border border-gray-300 text-gray-700"
end
