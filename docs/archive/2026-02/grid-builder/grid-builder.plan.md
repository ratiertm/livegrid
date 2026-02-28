# PDCA Plan - Grid Builder (그리드 정의 UI)

## Context

**User Request:** 코드가 아닌 UI로 그리드를 정의하는 기능. 그리드명 지정, 컬럼 정의, Validator 설정, Formatter 설정을 시각적으로 수행.

**현재 문제:**
- 그리드 생성은 Elixir 코드로만 가능 (`demo_live.ex`에서 columns 맵 리스트를 직접 작성)
- 컬럼 추가/삭제가 코드 수정 없이는 불가
- Validator/Formatter 설정이 코드 지식을 요구 (튜플 문법, Regex 등)
- Config Modal은 "기존 그리드 수정"만 가능, "새 그리드 생성"은 불가
- 비개발자가 그리드를 정의할 수 없음

**현재 구현 상태:**
- `GridDefinition` struct: 불변 Blueprint (field, label, type, validators, formatter 등 29개 속성)
- `Grid.new/1`: 코드 기반 그리드 생성
- Config Modal: 기존 그리드의 컬럼 속성/순서/숨김/포맷터/벨리데이터 수정
- Formatter: 16종 내장 (number, currency, date, percent, mask 등)
- Validator: 7종 내장 (required, min, max, min_length, max_length, pattern, custom)
- Renderer: 3종 내장 (badge, link, progress)

---

## 목표

코드 작성 없이 UI만으로 `GridDefinition`을 생성하고, 즉시 그리드를 렌더링할 수 있는 Grid Builder 제공.

---

## 기능 범위

### F-001: Grid Builder 모달

Config Modal과 별도의 "Grid Builder" 모달. 새 그리드 정의를 위한 전용 UI.

| 항목 | 설명 |
|------|------|
| 진입점 | 데모 페이지 상단 "+ 새 그리드 만들기" 버튼 |
| 모달 크기 | 전체 화면 또는 대형 모달 (컬럼 정의 테이블이 넓음) |
| 탭 구성 | 3탭: 기본 설정 / 컬럼 정의 / 미리보기 |

### F-002: Tab 1 - 기본 설정 (Grid Info)

| 필드 | 타입 | 설명 | 필수 |
|------|------|------|------|
| 그리드 이름 | text | Grid 식별자 (예: "사용자 목록") | O |
| 그리드 ID | text (auto) | 영문 snake_case 자동 생성 (수동 편집 가능) | O |
| 페이지 크기 | select | 10, 20, 50, 100 | O |
| 테마 | select | light, dark | - |
| 행번호 표시 | checkbox | show_row_number | - |
| Virtual Scroll | checkbox | 대용량 데이터 모드 | - |
| Frozen Columns | number | 고정 컬럼 수 | - |

### F-003: Tab 2 - 컬럼 정의 (Column Builder)

그리드의 핵심 - 컬럼을 추가/삭제/편집하는 인터페이스.

#### 컬럼 목록 테이블
| 항목 | 타입 | 설명 | 기본값 |
|------|------|------|--------|
| Field Name | text | atom으로 변환될 필드명 (영문) | - |
| Label | text | 표시 라벨 (한글 가능) | Field Name |
| Type | select | string, integer, float, boolean, date, datetime | string |
| Width | number | 컬럼 너비 (px) | auto |
| Align | select | left, center, right | left |
| Sortable | checkbox | 정렬 가능 | false |
| Filterable | checkbox | 필터 가능 | false |
| Editable | checkbox | 편집 가능 | false |
| Editor Type | select | text, number, select, checkbox, date | text |

#### 컬럼 행 동작
- [+ 컬럼 추가] 버튼: 빈 행 추가
- [x 삭제] 버튼: 컬럼 제거
- Drag 핸들: 컬럼 순서 변경 (ConfigSortable 재사용)
- 컬럼 클릭 시 "상세 설정" 패널 확장 (Formatter, Validator, Renderer)

#### 컬럼 상세 설정 (확장 패널)
클릭한 컬럼의 고급 설정:

**Formatter 설정:**
| Formatter | UI | 옵션 |
|-----------|-----|------|
| (없음) | - | 기본 텍스트 |
| number | select | precision, separator |
| currency | select | symbol (₩, $, €), precision |
| percent | select | precision, multiplier |
| date | select | format (YYYY-MM-DD 등) |
| datetime | select | format |
| boolean | select | true_label, false_label |
| filesize | select | - |
| truncate | select | max_length |
| mask | select | auto, phone, email, card |
| uppercase/lowercase | select | - |

**Validator 설정:**
| Validator | UI 입력 | 파라미터 |
|-----------|---------|----------|
| required | checkbox + 메시지 입력 | message |
| min | number input + 메시지 | min_value, message |
| max | number input + 메시지 | max_value, message |
| min_length | number input + 메시지 | length, message |
| max_length | number input + 메시지 | length, message |
| pattern | regex input + 메시지 | regex_string, message |

**Renderer 설정:**
| Renderer | UI 입력 | 파라미터 |
|----------|---------|----------|
| (없음) | - | 기본 텍스트 |
| badge | 색상 매핑 입력 | value:color 쌍 |
| link | prefix, target | prefix (mailto: 등), target (_blank 등) |
| progress | max, color | max_value, color |

### F-004: Tab 3 - 미리보기 (Preview)

- 정의한 컬럼으로 샘플 데이터 자동 생성 (3~5행)
- 실제 GridComponent로 렌더링하여 결과 미리보기
- Formatter/Renderer 적용 상태 확인
- "생성" 버튼: GridDefinition 생성 → 그리드 렌더링

### F-005: 생성 결과

Grid Builder에서 "생성" 클릭 시:
1. `GridDefinition.new(columns, options)` 호출
2. 샘플 데이터 또는 빈 데이터로 `Grid.new/1` 실행
3. 페이지에 새 GridComponent 렌더링
4. (선택) 정의를 Elixir 코드로 내보내기 (Copy to Clipboard)

---

## 아키텍처

```
┌─────────────────────────────────────────────────────┐
│  Grid Builder Modal (새 LiveComponent)               │
│  ┌───────────┬──────────────┬──────────────┐        │
│  │ Tab 1     │ Tab 2        │ Tab 3        │        │
│  │ 기본 설정  │ 컬럼 정의     │ 미리보기      │        │
│  └───────────┴──────────────┴──────────────┘        │
│                     │                                │
│                     ▼                                │
│  GridDefinition.new(columns, options)                │
│                     │                                │
│                     ▼                                │
│  Grid.new(columns: ..., options: ..., data: sample)  │
│                     │                                │
│                     ▼                                │
│  GridComponent 렌더링                                │
└─────────────────────────────────────────────────────┘
```

### 파일 구조

```
lib/liveview_grid_web/components/grid_builder/
├── builder_modal.ex      # Grid Builder LiveComponent
├── grid_info_tab.ex      # Tab 1: 기본 설정
├── column_builder_tab.ex # Tab 2: 컬럼 정의
└── preview_tab.ex        # Tab 3: 미리보기

lib/liveview_grid/
├── grid_definition.ex    # (기존) Blueprint struct
├── grid.ex               # (기존) Grid 생성
└── sample_data.ex        # (신규) 타입별 샘플 데이터 생성기
```

---

## 구현 순서

### Step 1: Builder Modal 셸 + Tab 1
- LiveComponent 생성 (builder_modal.ex)
- 3탭 UI 프레임
- Tab 1: 그리드 이름, ID, 기본 옵션 입력

### Step 2: Tab 2 - 컬럼 정의 기본
- 컬럼 추가/삭제 UI
- 기본 속성 입력 (field, label, type, width, align)
- 체크박스 (sortable, filterable, editable)
- Drag-to-reorder (ConfigSortable 재사용)

### Step 3: Tab 2 - 컬럼 상세 설정
- 확장 패널 (Formatter 선택 + 옵션)
- Validator 추가/삭제 UI
- Renderer 선택 + 옵션
- Editor Type 연동

### Step 4: Tab 3 - 미리보기 + 생성
- 타입별 샘플 데이터 생성기
- GridComponent로 실시간 미리보기
- "생성" 버튼 → 부모 LiveView에 이벤트 전달
- (선택) Elixir 코드 내보내기

### Step 5: 데모 페이지 통합
- demo_live.ex에 "+ 새 그리드 만들기" 버튼
- 동적 그리드 목록 관리
- 생성된 그리드 삭제/수정

---

## 기술 고려사항

### 재사용 가능 요소
- `ConfigSortable` Hook: 컬럼 Drag-to-reorder에 재사용
- Config Modal의 Formatter/Validator 선택 UI: 패턴 참고
- `GridDefinition.new/2`: 이미 검증 로직 포함

### 주의사항
- Field Name → Atom 변환: `String.to_atom/1`은 atom leak 위험 → `String.to_existing_atom/1` 우선, 새 atom은 화이트리스트 검증
- Regex 입력: 사용자 입력 regex는 `Regex.compile/1`로 검증 후 사용
- Renderer 함수: UI에서 함수를 직접 정의할 수 없음 → 내장 preset만 선택 가능

### Scope Out (이번 범위 밖)
- DB에 GridDefinition 저장/로드 (추후 기능)
- 커스텀 Renderer 코드 작성 UI
- Data Source 연결 UI (Ecto, REST)
- 다중 그리드 레이아웃 편집기

---

## 예상 산출물

| 산출물 | 파일 |
|--------|------|
| Builder Modal | `grid_builder/builder_modal.ex` |
| Tab 1 컴포넌트 | `grid_builder/grid_info_tab.ex` |
| Tab 2 컴포넌트 | `grid_builder/column_builder_tab.ex` |
| Tab 3 컴포넌트 | `grid_builder/preview_tab.ex` |
| 샘플 데이터 생성기 | `sample_data.ex` |
| 데모 페이지 수정 | `demo_live.ex` |
| 테스트 | `test/liveview_grid_web/components/grid_builder_test.exs` |
