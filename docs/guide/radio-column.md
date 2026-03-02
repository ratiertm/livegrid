# Radio Column

셀 내에 라디오 버튼 그룹을 표시합니다. 단일 선택이 필요한 상태 필드에 유용합니다.

## Column Configuration

```elixir
%{
  field: :priority,
  label: "우선순위",
  renderer: LiveviewGrid.Renderers.radio(
    options: [{"high", "High"}, {"medium", "Med"}, {"low", "Low"}]
  )
}
```

## Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `options` | `[{value, label}]` | 라디오 버튼 옵션 목록 (값, 표시 텍스트) |

## Examples

```elixir
# 우선순위 선택
%{field: :priority, label: "우선순위",
  renderer: LiveviewGrid.Renderers.radio(
    options: [{"high", "높음"}, {"medium", "중간"}, {"low", "낮음"}]
  )}

# 승인 상태
%{field: :approval, label: "승인",
  renderer: LiveviewGrid.Renderers.radio(
    options: [{"approved", "승인"}, {"rejected", "반려"}, {"pending", "대기"}]
  )}

# 등급 선택
%{field: :grade, label: "등급",
  renderer: LiveviewGrid.Renderers.radio(
    options: [{"A", "A"}, {"B", "B"}, {"C", "C"}, {"D", "D"}]
  )}
```

## CSS Classes

```css
.lv-grid__radio-group   /* 라디오 그룹 컨테이너 (flex, gap: 8px) */
.lv-grid__radio-label   /* 개별 라디오 레이블 (flex, gap: 4px) */
.lv-grid__radio-input   /* 라디오 input 요소 (14x14px) */
```

## Behavior

- 각 행마다 독립적인 라디오 그룹 (name: `radio_{row_id}_{field}`)
- 현재 값과 일치하는 옵션이 자동으로 checked
- 값 비교는 문자열로 변환 후 비교 (`to_string/1`)
