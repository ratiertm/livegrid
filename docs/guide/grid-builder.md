# Grid Builder

UI에서 그리드를 동적으로 생성하는 빌더 도구입니다.

## Overview

Grid Builder는 코드를 작성하지 않고도 그리드를 설계할 수 있는 3탭 UI입니다. 그리드 정보 입력 → 컬럼 설정 → 미리보기 순서로 진행됩니다. DB 스키마 자동 감지도 지원합니다.

## Accessing Grid Builder

독립 페이지(`/builder`)로 접근하거나, 모달로 사용할 수 있습니다:

```heex
<%# 모달 방식 %>
<.live_component
  module={LiveViewGridWeb.Components.GridBuilder.BuilderModal}
  id="grid_builder"
/>

<%# 독립 페이지: /builder 라우트 %>
```

## Tabs

### 1. Grid Info (그리드 정보)

| 설정 | 설명 |
|------|------|
| Grid Name | 그리드 이름 |
| Grid ID | 고유 식별자 |
| Virtual Scroll | 가상 스크롤 사용 여부 |
| Page Size | 페이지당 행 수 |
| Theme | 테마 선택 |
| Data Source | `sample` / `schema` / `table` |

### 2. Columns (컬럼 설정)

각 컬럼별로 설정 가능한 항목:

| 속성 | 설명 |
|------|------|
| Field | 필드명 (atom) |
| Label | 표시 라벨 |
| Type | string / integer / float / boolean / date / datetime |
| Width | 컬럼 너비 (px) |
| Align | left / center / right |
| Formatter | 16종 포맷터 중 선택 |
| Validator | required, min, max, pattern 등 |
| Renderer | badge, link, progress 중 선택 |

### 3. Preview (미리보기)

샘플 데이터로 그리드를 미리 확인하고, 설정이 완료되면 그리드를 생성합니다.

## Formatter Options

```
(없음), 숫자, 통화(원화), 통화(달러), 백분율, 날짜, 날짜+시간,
시간, 상대시간, 불리언, 파일크기, 말줄임, 대문자, 소문자, 마스킹
```

## Validator Types

```
필수 입력, 최솟값, 최댓값, 최소 길이, 최대 길이, 패턴(정규식)
```

## Validation

```elixir
# 빌더 입력값 검증
BuilderHelpers.validate_builder(assigns)
# => {:ok, validated} | {:error, errors}

# GridDefinition 파라미터 생성
BuilderHelpers.build_definition_params(assigns)
# => %{columns: [...], options: %{...}}
```

## Related

- [Config Modal](./config-modal.md) — 기존 그리드 설정 변경
- [Column Definitions](./column-definitions.md) — 컬럼 정의 상세
- [Data Sources](./data-sources.md) — 데이터소스 설정
- [Getting Started](./getting-started.md) — 코드 기반 그리드 생성
