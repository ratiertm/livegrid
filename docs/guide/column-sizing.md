# Column Sizing

컬럼 너비를 수동 조절하거나 내용에 맞게 자동 조절합니다.

## Overview

Grid 컬럼은 고정 너비 또는 자동(flex) 너비로 설정할 수 있습니다. 사용자가 드래그로 너비를 조절하거나, 더블클릭으로 내용에 맞게 자동 조절(auto-fit)할 수 있습니다.

## Fixed Width

컬럼 정의에서 `width`를 px 단위로 지정합니다:

```elixir
columns = [
  %{field: :id, label: "ID", width: 80},
  %{field: :name, label: "이름", width: 150},
  %{field: :email, label: "이메일", width: 250}
]
```

## Auto Width

`width: :auto`로 설정하면 남은 공간을 균등 분배합니다:

```elixir
%{field: :description, label: "설명", width: :auto}
```

## Manual Resize (Drag)

컬럼 헤더 경계에 마우스를 올리면 리사이즈 커서가 나타납니다. 드래그하여 너비를 조절합니다:

- 최소 너비: 50px
- 조절된 너비는 서버에 자동 동기화됩니다
- `grid_column_resize` 이벤트로 `{field, width}`가 전송됩니다

## Auto-fit (Double Click)

리사이즈 핸들을 **더블클릭**하면 해당 컬럼의 너비가 내용에 맞게 자동 조절됩니다:

- 헤더 텍스트와 모든 데이터 셀의 텍스트 너비를 측정합니다
- 최대 텍스트 너비 + 패딩(40px)으로 컬럼 너비를 설정합니다
- 범위: 최소 50px ~ 최대 500px

### 동작 원리

1. Canvas API의 `measureText()`로 텍스트 너비 측정
2. 헤더 + 모든 데이터 셀 중 최대값 계산
3. 패딩(40px) 추가 후 50~500px 범위로 클램핑
4. 서버에 `grid_column_resize` 이벤트 전송

## Events

| 이벤트 | 파라미터 | 트리거 |
|--------|---------|--------|
| `grid_column_resize` | `%{field, width}` | 드래그 완료 또는 더블클릭 auto-fit |

## JS Hook

컬럼 리사이즈는 `ColumnResize` Phoenix LiveView Hook으로 구현됩니다. 리사이즈 핸들(`.lv-grid__resize-handle`)에 자동 부착됩니다.

## Related

- [Column Definitions](./column-definitions.md) — width 속성
- [Frozen Columns](./frozen-columns.md) — 고정 컬럼 너비
- [Grid Options](./grid-options.md) — 옵션 레퍼런스
