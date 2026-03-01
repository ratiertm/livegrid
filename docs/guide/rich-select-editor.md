# Rich Select Editor (리치 셀렉트 에디터)

검색 가능한 커스텀 드롭다운 에디터입니다. 기본 `<select>` 대신 검색 입력, 키보드 네비게이션, 스크롤 옵션 목록을 제공합니다.

## Overview

Rich Select는 옵션이 많은 경우 기존 `editor_type: :select`보다 사용성이 뛰어납니다:

| Feature | :select | :rich_select |
|---------|---------|-------------|
| UI | 네이티브 `<select>` | 커스텀 드롭다운 |
| 검색 | 불가 | 실시간 검색 |
| 키보드 | 기본 | ArrowUp/Down + Enter |
| 스크롤 | OS 기본 | 커스텀 (max 200px) |

## 사용법

### 컬럼 정의

```elixir
%{
  field: :department,
  label: "부서",
  width: 150,
  editable: true,
  editor_type: :rich_select,
  editor_options: [
    %{value: "engineering", label: "Engineering"},
    %{value: "design", label: "Design"},
    %{value: "marketing", label: "Marketing"},
    %{value: "sales", label: "Sales"},
    %{value: "hr", label: "Human Resources"},
    %{value: "finance", label: "Finance"}
  ]
}
```

### editor_options 형식

옵션은 `%{value: string, label: string}` 맵 리스트:

```elixir
editor_options: [
  %{value: "v1", label: "옵션 1"},
  %{value: "v2", label: "옵션 2"}
]
```

- `value`: 저장되는 실제 값
- `label`: 사용자에게 표시되는 텍스트

## 키보드 네비게이션

| 키 | 동작 |
|----|------|
| `ArrowDown` | 다음 옵션 하이라이트 |
| `ArrowUp` | 이전 옵션 하이라이트 |
| `Enter` | 하이라이트된 옵션 선택 |
| `Escape` | 편집 취소 |
| `Tab` | 하이라이트된 옵션 선택 (또는 취소) |
| 문자 입력 | 옵션 실시간 검색 |

## 검색 동작

- 입력 시 label과 value 모두에서 검색
- 대소문자 무시
- 부분 일치 (includes)
- 검색 결과 없으면 빈 목록 표시

## CSS 커스터마이징

```css
/* 컨테이너 */
.lv-grid__rich-select { ... }

/* 검색 입력 */
.lv-grid__rich-select-search { ... }

/* 옵션 목록 (스크롤) */
.lv-grid__rich-select-options {
  max-height: 200px;
  overflow-y: auto;
}

/* 개별 옵션 */
.lv-grid__rich-select-option { ... }

/* 하이라이트 (키보드 포커스) */
.lv-grid__rich-select-option--highlighted { ... }

/* 현재 선택됨 */
.lv-grid__rich-select-option--selected { ... }
```

## Related

- [Cell Editing](./cell-editing.md) -- 기본 셀 편집
- [Column Definitions](./column-definitions.md) -- 컬럼 속성 (editor_type, editor_options)
