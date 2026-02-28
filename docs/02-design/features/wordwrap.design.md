# F-911 Wordwrap - Design

## 구현 단계

### Step 1: CSS 스타일 추가 (body.css)

```css
/* 5.12 Wordwrap (F-911) */
.lv-grid__cell--wordwrap-char {
  white-space: normal;
  word-break: break-all;
  overflow-wrap: break-word;
  overflow: visible;
  text-overflow: clip;
  align-items: flex-start;
  padding-top: 6px;
  padding-bottom: 6px;
}

.lv-grid__cell--wordwrap-word {
  white-space: normal;
  word-wrap: break-word;
  overflow-wrap: break-word;
  overflow: visible;
  text-overflow: clip;
  align-items: flex-start;
  padding-top: 6px;
  padding-bottom: 6px;
}

.lv-grid__cell-value--wordwrap {
  white-space: normal;
  overflow: visible;
  text-overflow: clip;
}
```

### Step 2: RenderHelpers 함수 추가 (render_helpers.ex)

```elixir
@spec wordwrap_class(column :: map()) :: String.t()
def wordwrap_class(%{wordwrap: :char}), do: "lv-grid__cell--wordwrap-char"
def wordwrap_class(%{wordwrap: :word}), do: "lv-grid__cell--wordwrap-word"
def wordwrap_class(_column), do: ""
```

### Step 3: grid_component.ex Body 렌더링 수정

셀 div에 wordwrap_class 추가:
```heex
<div class={"lv-grid__cell #{wordwrap_class(column)} ..."}>
```

셀 값 span에 wordwrap 클래스 추가:
```heex
<span class={"lv-grid__cell-value #{if Map.get(column, :wordwrap) in [:char, :word], do: "lv-grid__cell-value--wordwrap"}"}>
```

### Step 4: 데모 적용 (demo_live.ex)

email 컬럼에 `wordwrap: :word` 추가하여 긴 이메일이 줄바꿈되는 것을 확인.

### Step 5: 테스트 (grid_test.exs)

- wordwrap 옵션이 컬럼에 포함되는지 확인
- RenderHelpers.wordwrap_class/1 반환값 테스트

## 검증 체크리스트
- [ ] wordwrap: :char 적용 시 글자 단위 줄바꿈
- [ ] wordwrap: :word 적용 시 단어 단위 줄바꿈
- [ ] wordwrap 미지정 컬럼은 기존 nowrap + ellipsis 유지
- [ ] 행 높이가 콘텐츠에 맞게 자동 확장
- [ ] 445+ 기존 테스트 통과
