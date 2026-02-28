# Data Sources

Grid는 3가지 데이터 소스 어댑터를 지원합니다: InMemory, Ecto (Database), REST API.

## Overview

데이터 소스는 Grid 생성 시 `data_source` 옵션으로 지정합니다. 미지정 시 InMemory 모드로 동작합니다.

## InMemory (기본)

클라이언트 사이드에서 정렬, 필터, 페이지네이션을 처리합니다:

```elixir
grid = Grid.new(
  data: users,
  columns: columns,
  options: %{page_size: 20}
)
```

- **장점**: 설정 없이 즉시 사용, 빠른 응답
- **제한**: 대용량 데이터(10,000행+) 시 메모리 부담
- **용도**: 데모, 소규모 데이터, 프로토타이핑

## Ecto (Database)

서버사이드에서 SQL 쿼리로 정렬, 필터, 페이지네이션을 처리합니다:

```elixir
grid = Grid.new(
  columns: columns,
  data_source: {LiveViewGrid.DataSource.Ecto,
    %{repo: MyApp.Repo, query: from(u in User)}}
)
```

### Configuration

| 옵션 | 타입 | 설명 |
|------|------|------|
| `repo` | module | Ecto Repo 모듈 |
| `query` | `Ecto.Query.t()` | 기본 쿼리 |

### CRUD Operations

Ecto 어댑터는 Changeset 기반 CRUD를 지원합니다:

```elixir
# 행 추가 → INSERT
# 행 수정 → UPDATE
# 행 삭제 → DELETE
# "저장" 버튼 → 트랜잭션으로 일괄 처리
```

### 서버사이드 처리

| 기능 | SQL 변환 |
|------|----------|
| 정렬 | `ORDER BY field ASC/DESC` |
| 텍스트 필터 | `WHERE field ILIKE '%value%'` |
| 숫자 필터 | `WHERE field >= value` |
| 페이지네이션 | `LIMIT page_size OFFSET offset` |

## REST API

HTTP 기반 원격 데이터 소스입니다:

```elixir
grid = Grid.new(
  columns: columns,
  data_source: {LiveViewGrid.DataSource.Rest,
    %{
      base_url: "https://api.example.com/users",
      headers: %{"Authorization" => "Bearer #{api_key}"}
    }}
)
```

### Configuration

| 옵션 | 타입 | 설명 |
|------|------|------|
| `base_url` | string | API 엔드포인트 URL |
| `headers` | map | HTTP 헤더 (인증 토큰 등) |

### HTTP Mapping

| Grid 작업 | HTTP Method | Endpoint |
|-----------|-------------|----------|
| 데이터 조회 | `GET` | `/users?page=1&page_size=20&sort=name&order=asc` |
| 행 추가 | `POST` | `/users` |
| 행 수정 | `PUT` | `/users/:id` |
| 부분 수정 | `PATCH` | `/users/:id` |
| 행 삭제 | `DELETE` | `/users/:id` |

### Error Handling

- 연결 실패 시 자동 재시도 (exponential backoff)
- HTTP 4xx/5xx 에러 메시지 표시
- 네트워크 오류 시 로컬 상태 유지

## Raw Table (v0.7)

스키마 없이 데이터베이스 테이블에 직접 접근합니다:

```elixir
grid = Grid.new(
  columns: columns,
  data_source: {LiveViewGrid.DataSource.RawTable,
    %{repo: MyApp.Repo, table_name: "legacy_users"}}
)
```

- **용도**: Grid Builder에서 임의의 테이블 탐색
- **특징**: 컬럼 자동 감지, Ecto 스키마 불필요

## DataSource Behaviour

커스텀 데이터 소스를 구현할 수 있습니다:

```elixir
defmodule MyDataSource do
  @behaviour LiveViewGrid.DataSource

  @impl true
  def fetch_data(config, state, options, columns) do
    # {rows, total_count, filtered_count} 반환
  end

  @impl true
  def insert_row(config, row_data) do
    # {:ok, inserted_row} 또는 {:error, reason}
  end

  @impl true
  def update_row(config, id, changes) do
    # {:ok, updated_row} 또는 {:error, reason}
  end

  @impl true
  def delete_row(config, id) do
    # :ok 또는 {:error, reason}
  end
end
```

## Related

- [Row Data](./row-data.md) — 데이터 크기별 권장 모드
- [CRUD Operations](./crud-operations.md) — DataSource별 저장 동작
- [Pagination](./pagination.md) — 서버사이드 페이지네이션
