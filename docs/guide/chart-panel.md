# Chart Panel

Grid 데이터를 SVG 차트로 시각화하는 패널입니다.

## Overview

Chart Panel은 Grid의 숫자 데이터를 시각적 차트로 표시하는 기능입니다. SVG 기반으로 별도 차트 라이브러리 없이 동작합니다.

## Supported Chart Types

| 차트 | 설명 | 적합한 데이터 |
|------|------|--------------|
| Bar | 가로/세로 막대 차트 | 카테고리별 비교 |
| Line | 꺾은선 차트 | 시계열 추세 |
| Pie | 원형 차트 | 비율/구성비 |

## Behavior

- Grid의 **선택된 데이터** 또는 **전체 데이터**를 기반으로 차트를 생성합니다
- SVG로 렌더링되어 외부 의존성이 없습니다
- 데이터 변경 시 차트가 자동 업데이트됩니다
- 숫자 컬럼만 차트 대상으로 사용 가능합니다

## CSS Classes

| 클래스 | 적용 대상 |
|--------|----------|
| `.lv-grid__chart-panel` | 차트 패널 컨테이너 |
| `.lv-grid__chart-bar` | 막대 차트 요소 |
| `.lv-grid__chart-line` | 라인 차트 요소 |

## Related

- [Selection](./selection.md) — 데이터 선택 (차트 데이터 소스)
- [Formatters](./formatters.md) — 숫자 포맷
- [Summary Row](./summary-row.md) — 집계 데이터
- [Grid Options](./grid-options.md) — 차트 패널 설정
