# Localization (i18n)

그리드 UI 텍스트를 다국어로 표시합니다. 한국어(ko), 영어(en), 일본어(ja) 3개 언어를 지원합니다.

## Basic Usage

```elixir
# 한국어 (기본값)
LiveviewGrid.Locale.t(:search_placeholder)
# => "전체 검색..."

# 영어
LiveviewGrid.Locale.t(:search_placeholder, :en)
# => "Search..."

# 일본어
LiveviewGrid.Locale.t(:search_placeholder, :ja)
# => "検索..."
```

## Grid Option

```elixir
options = %{
  locale: :en  # :ko (기본값), :en, :ja
}
```

## Supported Locales

```elixir
LiveviewGrid.Locale.supported_locales()
# => [:ko, :en, :ja]
```

## Translation Keys

| Key | KO | EN |
|-----|----|----|
| `:search_placeholder` | "전체 검색..." | "Search..." |
| `:add_row` | "+ 추가" | "+ Add" |
| `:save` | "저장" | "Save" |
| `:cancel` | "취소" | "Cancel" |
| `:delete` | "삭제" | "Delete" |
| `:no_data` | "데이터가 없습니다" | "No data" |
| `:loading` | "로딩 중..." | "Loading..." |
| `:filter_placeholder` | "필터..." | "Filter..." |

## Custom Overrides

특정 키만 커스터마이징:

```elixir
LiveviewGrid.Locale.t(:save, :ko, %{save: "변경사항 저장"})
# => "변경사항 저장"
```

## Template Helper

```elixir
# render_helpers.ex에서 사용
grid_t(:search_placeholder, assigns.locale)
```
