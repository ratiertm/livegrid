# LiveView Grid API 명세서

> **버전**: v0.5
> **기본 URL**: `http://localhost:5001/api/v1`
> **인증**: Bearer Token (`Authorization: Bearer {API_KEY}`)

---

## 목차

1. [Grid 설정](#1-grid-설정)
2. [CRUD 작업](#2-crud-작업)
3. [테마](#3-테마)
4. [정렬 / 페이징 / Virtual Scroll](#4-정렬--페이징--virtual-scroll)
5. [DBMS 연동](#5-dbms-연동)
6. [커스텀 셀 렌더러](#6-커스텀-셀-렌더러)

---

## 인증

모든 API 요청에는 헤더에 API Key가 필요합니다:

```
Authorization: Bearer lvg_xxxxxxxxxxxxxxxxxxxx
```

API Key는 `/api-keys` 페이지에서 관리합니다. 권한 종류: `read`, `read_write`, `admin`.

---

## 1. Grid 설정

Grid는 `LiveViewGrid.Grid.new/1`로 초기화하고 `GridComponent`를 통해 렌더링합니다.

### 1.1 Grid 인스턴스 생성

**Elixir API**:
```elixir
grid = LiveViewGrid.Grid.new(
  id: "users-grid",
  columns: columns,
  data: data,           # 선택 (기본값 [])
  options: options,      # 선택 (기본값 %{})
  data_source: source    # 선택 (기본값 nil)
)
```

### 1.2 GET /api/v1/grid/config

Grid 설정 스키마를 조회합니다.

**응답** `200 OK`:
```json
{
  "grid": {
    "id": "string (생략 시 자동 생성)",
    "columns": "array<Column>",
    "options": "GridOptions",
    "data_source": "DataSourceConfig | null"
  }
}
```

### 1.3 컬럼 정의

| 필드 | 타입 | 필수 | 기본값 | 설명 |
|------|------|------|--------|------|
| `field` | string | 예 | - | 데이터 키 (예: `"name"`, `"age"`) |
| `label` | string | 예 | - | 헤더 표시 텍스트 |
| `width` | integer \| "auto" | 아니오 | `"auto"` | 컬럼 너비 (px) |
| `sortable` | boolean | 아니오 | `false` | 정렬 활성화 |
| `filterable` | boolean | 아니오 | `false` | 컬럼 필터 활성화 |
| `filter_type` | string | 아니오 | `"text"` | `"text"` \| `"number"` |
| `editable` | boolean | 아니오 | `false` | 인라인 편집 활성화 |
| `editor_type` | string | 아니오 | `"text"` | `"text"` \| `"number"` \| `"select"` |
| `editor_options` | array | 아니오 | `[]` | select 에디터용 `[{"label": "서울", "value": "Seoul"}, ...]` |
| `validators` | array | 아니오 | `[]` | 유효성 검사 규칙 (1.5 참조) |
| `renderer` | string | 아니오 | `null` | 내장 렌더러명 또는 커스텀 (6장 참조) |
| `align` | string | 아니오 | `"left"` | `"left"` \| `"center"` \| `"right"` |
| `frozen` | boolean | 아니오 | `false` | 좌측 고정 컬럼 |

**예시**:
```json
{
  "columns": [
    {
      "field": "id",
      "label": "ID",
      "width": 80,
      "sortable": true
    },
    {
      "field": "name",
      "label": "이름",
      "width": 150,
      "sortable": true,
      "filterable": true,
      "editable": true,
      "validators": [
        {"type": "required", "message": "이름은 필수입니다"}
      ]
    },
    {
      "field": "status",
      "label": "상태",
      "width": 120,
      "editable": true,
      "editor_type": "select",
      "editor_options": [
        {"label": "활성", "value": "active"},
        {"label": "비활성", "value": "inactive"}
      ],
      "renderer": "badge",
      "renderer_options": {
        "colors": {"active": "green", "inactive": "red"}
      }
    }
  ]
}
```

### 1.4 Grid 옵션

| 필드 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `page_size` | integer | `20` | 페이지당 행 수 (50, 100, 200, 300, 400, 500) |
| `show_header` | boolean | `true` | 컬럼 헤더 표시 |
| `show_footer` | boolean | `true` | 페이지네이션 포함 푸터 표시 |
| `virtual_scroll` | boolean | `false` | Virtual Scrolling 활성화 |
| `virtual_buffer` | integer | `5` | 뷰포트 위/아래 버퍼 행 수 |
| `row_height` | integer | `40` | 행 높이 (px, Virtual Scroll 계산용) |
| `viewport_height` | integer | `600` | 뷰포트 높이 (px) |
| `frozen_columns` | integer | `0` | 좌측 고정 컬럼 수 |
| `debug` | boolean | `false` | 디버그 패널 표시 |
| `theme` | string | `"light"` | `"light"` \| `"dark"` \| `"custom"` |
| `custom_css_vars` | object | `{}` | CSS 변수 오버라이드 (3장 참조) |

**예시**:
```json
{
  "options": {
    "page_size": 100,
    "virtual_scroll": true,
    "row_height": 40,
    "frozen_columns": 1,
    "theme": "dark"
  }
}
```

### 1.5 유효성 검사기

| 타입 | 매개변수 | 설명 |
|------|----------|------|
| `required` | `message` | 값이 nil이거나 빈 문자열이면 실패 |
| `min` | `value`, `message` | 숫자 >= value |
| `max` | `value`, `message` | 숫자 <= value |
| `min_length` | `value`, `message` | 문자열 길이 >= value |
| `max_length` | `value`, `message` | 문자열 길이 <= value |
| `pattern` | `regex`, `message` | 정규식 매치 |
| `custom` | `function`, `message` | 커스텀 함수 true/false 반환 |

```json
{
  "validators": [
    {"type": "required", "message": "필수 입력 항목입니다"},
    {"type": "min", "value": 0, "message": "0 이상이어야 합니다"},
    {"type": "max", "value": 150, "message": "최대 150"},
    {"type": "pattern", "regex": "^[a-zA-Z]+$", "message": "영문자만 입력 가능"}
  ]
}
```

---

## 2. CRUD 작업

### 2.1 GET /api/v1/grid/{grid_id}/data

서버사이드 필터링, 정렬, 페이지네이션을 적용하여 Grid 데이터를 조회합니다.

**쿼리 파라미터**:

| 파라미터 | 타입 | 기본값 | 설명 |
|----------|------|--------|------|
| `page` | integer | `1` | 페이지 번호 |
| `page_size` | integer | `20` | 페이지당 행 수 |
| `sort` | string | - | 정렬 필드명 |
| `order` | string | `"asc"` | `"asc"` \| `"desc"` |
| `q` | string | - | 글로벌 검색 쿼리 |
| `filters` | JSON string | - | 컬럼 필터 `{"name":"Kim","age":">30"}` |

**응답** `200 OK`:
```json
{
  "data": [
    {"id": 1, "name": "홍길동", "email": "hong@example.com", "age": 32},
    {"id": 2, "name": "김철수", "email": "kim@example.com", "age": 28}
  ],
  "meta": {
    "total": 1000,
    "filtered": 50,
    "page": 1,
    "page_size": 20,
    "total_pages": 3
  }
}
```

### 2.2 POST /api/v1/grid/{grid_id}/rows

단건 행을 생성합니다.

**요청 본문**:
```json
{
  "row": {
    "name": "새 사용자",
    "email": "new@example.com",
    "age": 25,
    "status": "active"
  }
}
```

**응답** `201 Created`:
```json
{
  "data": {
    "id": 1001,
    "name": "새 사용자",
    "email": "new@example.com",
    "age": 25,
    "status": "active"
  },
  "message": "행이 생성되었습니다"
}
```

### 2.3 POST /api/v1/grid/{grid_id}/rows/batch

여러 행을 한 번에 생성합니다.

**요청 본문**:
```json
{
  "rows": [
    {"name": "사용자 A", "email": "a@example.com", "age": 30},
    {"name": "사용자 B", "email": "b@example.com", "age": 25}
  ]
}
```

**응답** `201 Created`:
```json
{
  "data": [
    {"id": 1001, "name": "사용자 A", "email": "a@example.com", "age": 30},
    {"id": 1002, "name": "사용자 B", "email": "b@example.com", "age": 25}
  ],
  "created": 2,
  "message": "2건이 생성되었습니다"
}
```

### 2.4 PUT /api/v1/grid/{grid_id}/rows/{row_id}

단건 행을 전체 수정합니다.

**요청 본문**:
```json
{
  "row": {
    "name": "수정된 이름",
    "email": "updated@example.com"
  }
}
```

**응답** `200 OK`:
```json
{
  "data": {
    "id": 1,
    "name": "수정된 이름",
    "email": "updated@example.com",
    "age": 32,
    "status": "active"
  },
  "message": "행이 수정되었습니다"
}
```

### 2.5 PATCH /api/v1/grid/{grid_id}/rows/{row_id}

특정 필드만 부분 수정합니다.

**요청 본문**:
```json
{
  "changes": {
    "age": 33
  }
}
```

**응답** `200 OK`:
```json
{
  "data": {
    "id": 1,
    "name": "홍길동",
    "email": "hong@example.com",
    "age": 33,
    "status": "active"
  },
  "message": "행이 부분 수정되었습니다"
}
```

### 2.6 PUT /api/v1/grid/{grid_id}/rows/batch

여러 행을 한 번에 수정합니다.

**요청 본문**:
```json
{
  "rows": [
    {"id": 1, "changes": {"status": "inactive"}},
    {"id": 2, "changes": {"status": "inactive"}}
  ]
}
```

**응답** `200 OK`:
```json
{
  "updated": 2,
  "message": "2건이 수정되었습니다"
}
```

### 2.7 DELETE /api/v1/grid/{grid_id}/rows/{row_id}

단건 행을 삭제합니다.

**응답** `200 OK`:
```json
{
  "message": "행이 삭제되었습니다",
  "deleted_id": 1
}
```

### 2.8 DELETE /api/v1/grid/{grid_id}/rows/batch

여러 행을 한 번에 삭제합니다.

**요청 본문**:
```json
{
  "row_ids": [1, 2, 3]
}
```

**응답** `200 OK`:
```json
{
  "deleted": 3,
  "message": "3건이 삭제되었습니다"
}
```

### 2.9 POST /api/v1/grid/{grid_id}/save

모든 대기 중인 변경사항을 일괄 저장합니다. N(신규)/U(수정)/D(삭제) 상태의 행을 전송합니다.

**요청 본문**:
```json
{
  "changes": [
    {"row": {"id": -1, "name": "신규"}, "status": "new"},
    {"row": {"id": 5, "name": "변경됨"}, "status": "updated"},
    {"row": {"id": 10}, "status": "deleted"}
  ]
}
```

**응답** `200 OK`:
```json
{
  "inserted": 1,
  "updated": 1,
  "deleted": 1,
  "message": "변경사항이 저장되었습니다"
}
```

---

## 3. 테마

### 3.1 GET /api/v1/themes

사용 가능한 모든 테마를 조회합니다.

**응답** `200 OK`:
```json
{
  "themes": [
    {
      "name": "light",
      "type": "built-in",
      "description": "기본 라이트 테마"
    },
    {
      "name": "dark",
      "type": "built-in",
      "description": "다크 모드 테마"
    },
    {
      "name": "ocean",
      "type": "custom",
      "description": "블루 오션 테마"
    }
  ]
}
```

### 3.2 GET /api/v1/themes/{theme_name}

특정 테마의 전체 CSS 변수 값을 조회합니다.

**응답** `200 OK`:
```json
{
  "name": "light",
  "type": "built-in",
  "variables": {
    "--lv-grid-primary": "#2196f3",
    "--lv-grid-primary-dark": "#1976d2",
    "--lv-grid-primary-light": "#e3f2fd",
    "--lv-grid-bg": "#ffffff",
    "--lv-grid-bg-secondary": "#fafafa",
    "--lv-grid-text": "#333333",
    "--lv-grid-text-secondary": "#555555",
    "--lv-grid-text-muted": "#999999",
    "--lv-grid-border": "#e0e0e0",
    "--lv-grid-hover": "#f5f5f5",
    "--lv-grid-selected": "#e3f2fd",
    "--lv-grid-danger": "#f44336",
    "--lv-grid-success": "#4caf50",
    "--lv-grid-warning": "#ff9800",
    "--lv-grid-font-family": "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif",
    "--lv-grid-font-size-sm": "13px",
    "--lv-grid-font-size-md": "14px"
  }
}
```

### 3.3 POST /api/v1/themes

커스텀 테마를 생성합니다.

**요청 본문**:
```json
{
  "name": "corporate",
  "description": "기업 브랜드 테마",
  "base": "light",
  "overrides": {
    "--lv-grid-primary": "#e65100",
    "--lv-grid-primary-dark": "#bf360c",
    "--lv-grid-primary-light": "#fff3e0",
    "--lv-grid-bg": "#fffaf5",
    "--lv-grid-selected": "#fff3e0"
  }
}
```

**응답** `201 Created`:
```json
{
  "name": "corporate",
  "type": "custom",
  "variables": {
    "--lv-grid-primary": "#e65100",
    "--lv-grid-bg": "#fffaf5"
  },
  "message": "테마가 생성되었습니다"
}
```

### 3.4 PUT /api/v1/grid/{grid_id}/theme

특정 Grid에 테마를 적용합니다.

**요청 본문**:
```json
{
  "theme": "dark",
  "custom_css_vars": {
    "--lv-grid-primary": "#00bcd4"
  }
}
```

**응답** `200 OK`:
```json
{
  "grid_id": "users-grid",
  "theme": "dark",
  "custom_css_vars": {"--lv-grid-primary": "#00bcd4"},
  "message": "테마가 적용되었습니다"
}
```

### 3.5 CSS 변수 참조표

| 카테고리 | 변수 | Light 기본값 | Dark 기본값 |
|----------|------|-------------|------------|
| **Primary** | `--lv-grid-primary` | `#2196f3` | `#64b5f6` |
| | `--lv-grid-primary-dark` | `#1976d2` | `#42a5f5` |
| | `--lv-grid-primary-light` | `#e3f2fd` | `#1a237e` |
| **배경** | `--lv-grid-bg` | `#ffffff` | `#1e1e1e` |
| | `--lv-grid-bg-secondary` | `#fafafa` | `#252525` |
| | `--lv-grid-bg-tertiary` | `#f8f9fa` | `#2d2d2d` |
| **텍스트** | `--lv-grid-text` | `#333333` | `#e0e0e0` |
| | `--lv-grid-text-secondary` | `#555555` | `#bdbdbd` |
| | `--lv-grid-text-muted` | `#999999` | `#757575` |
| **테두리** | `--lv-grid-border` | `#e0e0e0` | `#424242` |
| **인터랙티브** | `--lv-grid-hover` | `#f5f5f5` | `#333333` |
| | `--lv-grid-selected` | `#e3f2fd` | `#1a237e` |
| **시맨틱** | `--lv-grid-danger` | `#f44336` | `#ef5350` |
| | `--lv-grid-success` | `#4caf50` | `#66bb6a` |
| | `--lv-grid-warning` | `#ff9800` | `#ffa726` |

---

## 4. 정렬 / 페이징 / Virtual Scroll

### 4.1 PUT /api/v1/grid/{grid_id}/sort

정렬 설정을 변경합니다.

**요청 본문**:
```json
{
  "field": "name",
  "direction": "asc"
}
```

**응답** `200 OK`:
```json
{
  "sort": {"field": "name", "direction": "asc"},
  "message": "정렬이 적용되었습니다"
}
```

정렬 해제:
```json
{
  "field": null,
  "direction": null
}
```

### 4.2 PUT /api/v1/grid/{grid_id}/pagination

페이지네이션 설정을 변경합니다.

**요청 본문**:
```json
{
  "page": 3,
  "page_size": 50
}
```

**응답** `200 OK`:
```json
{
  "pagination": {
    "current_page": 3,
    "page_size": 50,
    "total_rows": 1000,
    "total_pages": 20
  }
}
```

### 4.3 PUT /api/v1/grid/{grid_id}/virtual-scroll

Virtual Scrolling을 활성화/설정합니다.

**요청 본문**:
```json
{
  "enabled": true,
  "row_height": 40,
  "buffer": 5,
  "viewport_height": 600
}
```

**응답** `200 OK`:
```json
{
  "virtual_scroll": {
    "enabled": true,
    "row_height": 40,
    "buffer": 5,
    "viewport_height": 600,
    "visible_rows": 15,
    "total_rows": 1000
  }
}
```

### 4.4 PUT /api/v1/grid/{grid_id}/filter

필터를 설정합니다.

**요청 본문**:
```json
{
  "global_search": "Kim",
  "column_filters": {
    "age": ">30",
    "status": "active"
  },
  "advanced_filters": {
    "logic": "and",
    "conditions": [
      {"field": "department", "operator": "equals", "value": "Engineering"},
      {"field": "age", "operator": "gte", "value": "25"}
    ]
  }
}
```

**필터 연산자**:

| 타입 | 연산자 | 설명 |
|------|--------|------|
| 텍스트 | `contains` | 부분 문자열 매치 (대소문자 무관) |
| 텍스트 | `equals` | 정확히 일치 |
| 텍스트 | `starts_with` | 접두사 매치 |
| 텍스트 | `ends_with` | 접미사 매치 |
| 텍스트 | `is_empty` | null 또는 빈 문자열 |
| 텍스트 | `is_not_empty` | null이 아니고 비어있지 않음 |
| 숫자 | `eq` | 같음 (=) |
| 숫자 | `neq` | 같지 않음 (!=) |
| 숫자 | `gt` | 초과 (>) |
| 숫자 | `lt` | 미만 (<) |
| 숫자 | `gte` | 이상 (>=) |
| 숫자 | `lte` | 이하 (<=) |

**응답** `200 OK`:
```json
{
  "filtered_count": 42,
  "total_count": 1000,
  "message": "필터가 적용되었습니다"
}
```

---

## 5. DBMS 연동

### 5.1 GET /api/v1/datasources

사용 가능한 DataSource 어댑터를 조회합니다.

**응답** `200 OK`:
```json
{
  "adapters": [
    {
      "type": "in_memory",
      "description": "클라이언트 사이드 인메모리 데이터 처리",
      "config_schema": {
        "data": "array<object> (필수)"
      }
    },
    {
      "type": "ecto",
      "description": "Ecto/Repo 기반 SQL 데이터베이스 연동",
      "supported_databases": ["SQLite", "PostgreSQL", "MySQL", "MSSQL", "Oracle"],
      "config_schema": {
        "repo": "module (필수) - Ecto Repo 모듈",
        "schema": "module (필수) - Ecto 스키마 모듈",
        "base_query": "Ecto.Query (선택) - 사전 필터링된 쿼리"
      }
    },
    {
      "type": "rest",
      "description": "외부 REST API 데이터 소스",
      "config_schema": {
        "base_url": "string (필수)",
        "endpoint": "string (선택, 기본값: '')",
        "headers": "object (선택)",
        "response_mapping": "object (선택)",
        "query_mapping": "object (선택)",
        "request_opts": "object (선택)"
      }
    }
  ]
}
```

### 5.2 POST /api/v1/grid/{grid_id}/datasource

Grid에 DataSource를 연결합니다.

**요청 본문 (Ecto)**:
```json
{
  "type": "ecto",
  "config": {
    "repo": "LiveviewGrid.Repo",
    "schema": "LiveviewGrid.DemoUser"
  }
}
```

**요청 본문 (REST)**:
```json
{
  "type": "rest",
  "config": {
    "base_url": "https://api.example.com",
    "endpoint": "/users",
    "headers": {
      "Authorization": "Bearer token123"
    },
    "response_mapping": {
      "data_key": "data",
      "total_key": "total",
      "filtered_key": "filtered"
    },
    "query_mapping": {
      "page": "page",
      "page_size": "per_page",
      "sort_field": "sort_by",
      "sort_direction": "sort_order",
      "search": "search",
      "filters": "filters"
    },
    "request_opts": {
      "timeout": 10000,
      "retry": 3,
      "retry_delay": 1000
    }
  }
}
```

**응답** `200 OK`:
```json
{
  "grid_id": "users-grid",
  "datasource": {
    "type": "ecto",
    "connected": true,
    "config": {
      "repo": "LiveviewGrid.Repo",
      "schema": "LiveviewGrid.DemoUser"
    }
  },
  "message": "DataSource가 연결되었습니다"
}
```

### 5.3 GET /api/v1/grid/{grid_id}/datasource

현재 DataSource 설정을 조회합니다.

**응답** `200 OK`:
```json
{
  "type": "ecto",
  "connected": true,
  "config": {
    "repo": "LiveviewGrid.Repo",
    "schema": "LiveviewGrid.DemoUser"
  },
  "stats": {
    "total_rows": 1000,
    "last_fetched_at": "2026-02-22T10:30:00Z"
  }
}
```

### 5.4 DELETE /api/v1/grid/{grid_id}/datasource

DataSource 연결을 해제합니다 (인메모리 모드로 전환).

**응답** `200 OK`:
```json
{
  "message": "DataSource 연결이 해제되었습니다",
  "mode": "in_memory"
}
```

### 5.5 Ecto 어댑터 - 서버사이드 작업

Ecto 어댑터 사용 시 모든 작업이 SQL로 최적화됩니다:

| 작업 | SQL 변환 |
|------|----------|
| 글로벌 검색 | `WHERE field1 LIKE '%q%' OR field2 LIKE '%q%' OR ...` |
| 컬럼 필터 (텍스트) | `WHERE field LIKE '%value%'` |
| 컬럼 필터 (숫자) | `WHERE field > 30` (`>`, `<`, `>=`, `<=`, `=`, `!=` 지원) |
| 고급 필터 (AND) | `WHERE cond1 AND cond2 AND cond3` |
| 고급 필터 (OR) | `WHERE cond1 OR cond2 OR cond3` |
| 정렬 | `ORDER BY field ASC/DESC` |
| 페이지네이션 | `LIMIT page_size OFFSET (page-1)*page_size` |

### 5.6 REST 어댑터 - 쿼리 매핑

REST 어댑터는 Grid 상태를 API 쿼리 파라미터로 매핑합니다:

| Grid 상태 | 기본 파라미터 | 커스터마이징 |
|-----------|-------------|-------------|
| 페이지 번호 | `page` | `query_mapping.page` |
| 페이지 크기 | `page_size` | `query_mapping.page_size` |
| 정렬 필드 | `sort` | `query_mapping.sort_field` |
| 정렬 방향 | `order` | `query_mapping.sort_direction` |
| 글로벌 검색 | `q` | `query_mapping.search` |
| 컬럼 필터 | `filters` (JSON) | `query_mapping.filters` |

**재시도 설정**:

| 설정 | 기본값 | 설명 |
|------|--------|------|
| `timeout` | 10,000ms | 요청 타임아웃 |
| `retry` | 3 | 최대 재시도 횟수 |
| `retry_delay` | 1,000ms | 기본 지연 (지수 백오프: `delay * (attempt+1)`) |
| 재시도 대상 상태 코드 | 408, 429, 500, 502, 503, 504 | 해당 HTTP 코드에서 자동 재시도 |

---

## 6. 커스텀 셀 렌더러

### 6.1 GET /api/v1/renderers

사용 가능한 모든 셀 렌더러를 조회합니다.

**응답** `200 OK`:
```json
{
  "renderers": [
    {
      "name": "badge",
      "description": "범주형 값에 대한 컬러 배지",
      "options": {
        "colors": "object - 값-색상 매핑",
        "default_color": "string (기본값: 'gray')"
      },
      "available_colors": ["blue", "green", "red", "yellow", "gray", "purple"],
      "example": {
        "renderer": "badge",
        "renderer_options": {
          "colors": {"active": "green", "inactive": "red", "pending": "yellow"},
          "default_color": "gray"
        }
      }
    },
    {
      "name": "link",
      "description": "클릭 가능한 하이퍼링크",
      "options": {
        "prefix": "string - URL 접두사 (예: 'mailto:', 'https://')",
        "target": "string - 링크 타겟 (예: '_blank')",
        "href": "function(row, column) - 커스텀 URL 빌더"
      },
      "example": {
        "renderer": "link",
        "renderer_options": {
          "prefix": "mailto:",
          "target": "_blank"
        }
      }
    },
    {
      "name": "progress",
      "description": "숫자 값에 대한 프로그레스 바",
      "options": {
        "max": "number (기본값: 100)",
        "color": "string (기본값: 'blue')",
        "show_value": "boolean (기본값: true)"
      },
      "available_colors": ["blue", "green", "red", "yellow"],
      "example": {
        "renderer": "progress",
        "renderer_options": {
          "max": 60,
          "color": "green",
          "show_value": true
        }
      }
    }
  ]
}
```

### 6.2 GET /api/v1/renderers/{renderer_name}

특정 렌더러의 상세 설정 스키마를 조회합니다.

**응답** `200 OK`:
```json
{
  "name": "badge",
  "description": "범주형 값에 대한 컬러 배지",
  "options_schema": {
    "colors": {
      "type": "object",
      "description": "데이터 값과 색상명의 매핑",
      "example": {"active": "green", "inactive": "red"}
    },
    "default_color": {
      "type": "string",
      "default": "gray",
      "enum": ["blue", "green", "red", "yellow", "gray", "purple"]
    }
  },
  "css_classes": [
    ".lv-grid__badge",
    ".lv-grid__badge--blue",
    ".lv-grid__badge--green",
    ".lv-grid__badge--red",
    ".lv-grid__badge--yellow",
    ".lv-grid__badge--gray",
    ".lv-grid__badge--purple"
  ]
}
```

### 6.3 PUT /api/v1/grid/{grid_id}/columns/{field}/renderer

특정 컬럼에 렌더러를 적용합니다.

**요청 본문**:
```json
{
  "renderer": "badge",
  "renderer_options": {
    "colors": {
      "active": "green",
      "inactive": "red",
      "pending": "yellow"
    },
    "default_color": "gray"
  }
}
```

**응답** `200 OK`:
```json
{
  "field": "status",
  "renderer": "badge",
  "renderer_options": {
    "colors": {"active": "green", "inactive": "red", "pending": "yellow"},
    "default_color": "gray"
  },
  "message": "'status' 컬럼에 렌더러가 적용되었습니다"
}
```

### 6.4 커스텀 렌더러 (Elixir 함수)

고급 사용 시 커스텀 렌더러 함수를 직접 정의할 수 있습니다:

```elixir
# 컬럼 정의에서
%{
  field: :email,
  label: "이메일",
  renderer: fn row, column, _assigns ->
    value = Map.get(row, column.field)
    assigns = %{value: value}
    ~H"""
    <a href={"mailto:#{@value}"} class="lv-grid__link">
      <%= @value %>
    </a>
    """
  end
}
```

**렌더러 함수 시그니처**:
```
fn(row :: map(), column :: map(), assigns :: map()) -> Phoenix.LiveView.Rendered.t()
```

렌더러에서 예외가 발생하면 `to_string(value)`로 폴백합니다.

### 6.5 DELETE /api/v1/grid/{grid_id}/columns/{field}/renderer

커스텀 렌더러를 제거합니다 (기본 텍스트 표시로 복원).

**응답** `200 OK`:
```json
{
  "field": "status",
  "renderer": null,
  "message": "'status' 컬럼의 렌더러가 제거되었습니다"
}
```

---

## 에러 응답

모든 엔드포인트는 일관된 에러 형식을 반환합니다:

### 400 Bad Request
```json
{
  "error": "invalid_request",
  "message": "필수 필드가 누락되었습니다: name",
  "details": {"field": "name"}
}
```

### 401 Unauthorized
```json
{
  "error": "unauthorized",
  "message": "유효하지 않거나 누락된 API Key입니다"
}
```

### 403 Forbidden
```json
{
  "error": "forbidden",
  "message": "권한이 부족합니다. 필요 권한: read_write"
}
```

### 404 Not Found
```json
{
  "error": "not_found",
  "message": "ID 999에 해당하는 행을 찾을 수 없습니다"
}
```

### 422 Unprocessable Entity
```json
{
  "error": "validation_failed",
  "message": "유효성 검사 오류",
  "details": {
    "name": ["이름은 필수입니다"],
    "age": ["0 이상이어야 합니다"]
  }
}
```

### 500 Internal Server Error
```json
{
  "error": "internal_error",
  "message": "예기치 않은 오류가 발생했습니다"
}
```

---

## 이벤트 시스템 (LiveView WebSocket)

LiveView 클라이언트에서는 REST 대신 이벤트로 통신합니다:

### 클라이언트 -> 서버 이벤트

| 이벤트 | 페이로드 | 설명 |
|--------|----------|------|
| `grid_sort` | `{field, direction}` | 컬럼 정렬 |
| `grid_filter` | `{field, value}` | 컬럼 필터 설정 |
| `grid_global_search` | `{value}` | 글로벌 검색 |
| `grid_page_change` | `{page}` | 페이지 변경 |
| `grid_page_size_change` | `{page_size}` | 페이지 크기 변경 |
| `grid_scroll` | `{scroll_top}` | Virtual Scroll 위치 |
| `grid_column_resize` | `{field, width}` | 컬럼 크기 변경 |
| `grid_column_reorder` | `{order: [fields]}` | 컬럼 순서 변경 |
| `cell_edit_start` | `{row_id, field}` | 셀 편집 시작 |
| `cell_edit_save` | `{row_id, field, value}` | 셀 편집 저장 |
| `grid_add_row` | `{}` | 새 행 추가 |
| `grid_delete_selected` | `{}` | 선택된 행 삭제 |
| `grid_save` | `{}` | 모든 변경사항 저장 |
| `grid_discard` | `{}` | 모든 변경사항 취소 |

### 서버 -> 부모 LiveView 메시지

| 메시지 | 페이로드 | 설명 |
|--------|----------|------|
| `{:grid_cell_updated, row_id, field, value}` | ids, atom, any | 셀 값 변경됨 |
| `{:grid_row_added, row}` | map | 새 행 추가됨 |
| `{:grid_rows_deleted, row_ids}` | list | 행 삭제됨 |
| `{:grid_save_requested, changed_rows}` | list of `{row, status}` | 저장 요청됨 |
| `{:grid_save_blocked, error_count}` | integer | 오류로 저장 차단됨 |
| `:grid_discard_requested` | - | 취소 요청됨 |
| `{:grid_download_file, payload}` | map | 파일 내보내기 준비 완료 |

---

## API 엔드포인트 요약표

| 메서드 | 엔드포인트 | 설명 |
|--------|----------|------|
| **Grid 설정** | | |
| GET | `/api/v1/grid/config` | Grid 설정 스키마 |
| **CRUD** | | |
| GET | `/api/v1/grid/{id}/data` | 데이터 조회 (필터/정렬/페이징) |
| POST | `/api/v1/grid/{id}/rows` | 행 생성 |
| POST | `/api/v1/grid/{id}/rows/batch` | 일괄 생성 |
| PUT | `/api/v1/grid/{id}/rows/{row_id}` | 전체 수정 |
| PATCH | `/api/v1/grid/{id}/rows/{row_id}` | 부분 수정 |
| PUT | `/api/v1/grid/{id}/rows/batch` | 일괄 수정 |
| DELETE | `/api/v1/grid/{id}/rows/{row_id}` | 행 삭제 |
| DELETE | `/api/v1/grid/{id}/rows/batch` | 일괄 삭제 |
| POST | `/api/v1/grid/{id}/save` | 변경사항 일괄 저장 |
| **테마** | | |
| GET | `/api/v1/themes` | 테마 목록 |
| GET | `/api/v1/themes/{name}` | 테마 상세 |
| POST | `/api/v1/themes` | 커스텀 테마 생성 |
| PUT | `/api/v1/grid/{id}/theme` | 테마 적용 |
| **정렬/페이징/필터** | | |
| PUT | `/api/v1/grid/{id}/sort` | 정렬 설정 |
| PUT | `/api/v1/grid/{id}/pagination` | 페이지네이션 설정 |
| PUT | `/api/v1/grid/{id}/virtual-scroll` | Virtual Scroll 설정 |
| PUT | `/api/v1/grid/{id}/filter` | 필터 설정 |
| **DataSource** | | |
| GET | `/api/v1/datasources` | 어댑터 목록 |
| POST | `/api/v1/grid/{id}/datasource` | DataSource 연결 |
| GET | `/api/v1/grid/{id}/datasource` | DataSource 조회 |
| DELETE | `/api/v1/grid/{id}/datasource` | DataSource 연결 해제 |
| **렌더러** | | |
| GET | `/api/v1/renderers` | 렌더러 목록 |
| GET | `/api/v1/renderers/{name}` | 렌더러 상세 |
| PUT | `/api/v1/grid/{id}/columns/{field}/renderer` | 렌더러 적용 |
| DELETE | `/api/v1/grid/{id}/columns/{field}/renderer` | 렌더러 제거 |
