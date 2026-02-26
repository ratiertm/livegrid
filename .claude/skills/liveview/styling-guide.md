# 스타일 가이드 (HEEx + TailwindCSS)

## MUST (반드시)
- TailwindCSS 유틸리티 클래스 우선 사용
- 반응형: 모바일 퍼스트 (sm → md → lg 순서)
- 동적 클래스는 리스트 형태로 — Phoenix의 class 병합 활용
- 색상/간격은 Tailwind 설정값만 사용 (하드코딩 금지)

## NEVER (금지)
- 인라인 style 속성 금지
- HEEx 안에서 복잡한 클래스 조건 분기 금지 → 헬퍼 함수로 분리
- `!important` 금지
- 전역 CSS 셀렉터 최소화

## 패턴

### ✅ 동적 클래스 — 좋은 예
```heex
<div class={[
  "rounded-lg p-4 border",
  @status == :active && "bg-green-50 border-green-200",
  @status == :inactive && "bg-gray-50 border-gray-200"
]}>
  <%= @content %>
</div>
```

### ✅ 헬퍼 함수 분리 — 좋은 예
```elixir
defp status_class(:active), do: "bg-green-50 border-green-200 text-green-800"
defp status_class(:inactive), do: "bg-gray-50 border-gray-200 text-gray-500"
defp status_class(_), do: "bg-white border-gray-200 text-gray-900"
```

```heex
<span class={["rounded-full px-2 py-1 text-xs font-medium", status_class(@status)]}>
  <%= @label %>
</span>
```

### ❌ 나쁜 예
```heex
<!-- ❌ 인라인 스타일 -->
<div style="display: flex; padding: 16px; background-color: #f0f0f0;">

<!-- ❌ 복잡한 조건 분기를 HEEx에 직접 -->
<div class={"p-4 " <> if(@a && !@b && @c > 3, do: "bg-red-100", else: if(@d, do: "bg-blue-100", else: "bg-white"))}>
```
