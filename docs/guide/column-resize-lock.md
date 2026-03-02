# Column Resize Lock

특정 컬럼의 너비 변경을 잠급니다. 고정 너비가 필요한 상태/체크박스/아이콘 컬럼에 유용합니다.

## Column Configuration

```elixir
%{
  field: :status,
  label: "상태",
  width: "80px",
  resizable: false    # 리사이즈 잠금
}
```

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `resizable` | boolean | `true` | 컬럼 리사이즈 허용 여부 |

## Behavior

- `resizable: true` (기본값): 헤더 우측에 리사이즈 핸들 표시, 드래그로 너비 변경 가능
- `resizable: false`: 리사이즈 핸들이 렌더링되지 않음, 너비 변경 불가

## Examples

```elixir
columns = [
  # 체크박스 컬럼 - 고정 너비
  %{field: :select, label: "", width: "40px", resizable: false},

  # 상태 컬럼 - 고정 너비
  %{field: :status, label: "상태", width: "80px", resizable: false},

  # 이름 컬럼 - 리사이즈 가능 (기본값)
  %{field: :name, label: "이름", width: "150px"},

  # 설명 컬럼 - 리사이즈 가능
  %{field: :description, label: "설명", resizable: true}
]
```

## Resize Handle

`resizable: true`일 때 헤더 셀에 표시되는 리사이즈 핸들:
- 위치: 헤더 셀 우측 가장자리
- 너비: 6px
- 호버 시 파란색 표시
- 더블클릭: 내용에 맞게 자동 조절 (autofit)
- 드래그: 최소 너비 50px 이상으로 조절

## CSS Classes

```css
.lv-grid__resize-handle          /* 리사이즈 핸들 */
.lv-grid__resize-handle:hover    /* 호버 시 시각적 피드백 */
```
