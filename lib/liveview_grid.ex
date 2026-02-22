defmodule LiveviewGrid do
  @moduledoc """
  LiveView Grid - Phoenix LiveView 기반 상용 그리드 컴포넌트

  ## 개요

  LiveView Grid는 Phoenix LiveView 위에서 동작하는 풀 피처 데이터 그리드입니다.
  서버 사이드 상태 관리, 실시간 WebSocket 동기화, 다양한 데이터 소스를 지원합니다.

  ## Quick Start

      # 1. Grid 생성
      grid = LiveViewGrid.Grid.new(
        data: [%{id: 1, name: "Alice", age: 30}],
        columns: [
          %{field: :id, label: "ID", width: 60},
          %{field: :name, label: "이름", sortable: true, filterable: true},
          %{field: :age, label: "나이", sortable: true, formatter: :number}
        ],
        options: %{page_size: 20}
      )

      # 2. LiveView mount에서 assign
      {:ok, assign(socket, grid: grid)}

      # 3. HEEx 템플릿에서 GridComponent 사용
      <.live_component module={LiveviewGridWeb.GridComponent}
        id={@grid.id}
        grid={@grid} />

  ## 핵심 모듈

  | 모듈 | 설명 |
  |------|------|
  | `LiveViewGrid.Grid` | Grid 인스턴스 생성/관리 (정렬, 필터, 페이지네이션, CRUD, 검증) |
  | `LiveViewGrid.Formatter` | 셀 값 포맷터 (숫자, 통화, 날짜, 퍼센트 등 16종) |
  | `LiveViewGrid.Renderers` | 셀 커스텀 렌더러 (프로그레스바, 뱃지, 링크, 이미지 등) |
  | `LiveViewGrid.Export` | Excel/CSV 내보내기 |

  ## 데이터 소스

  | 소스 | 설명 |
  |------|------|
  | `LiveViewGrid.DataSource.InMemory` | 인메모리 리스트 (기본) |
  | `LiveViewGrid.DataSource.Ecto` | Ecto 쿼리 기반 DB 연동 |
  | `LiveViewGrid.DataSource.Rest` | REST API 원격 데이터 |

  ## 고급 기능

  | 모듈 | 설명 |
  |------|------|
  | `LiveViewGrid.Grouping` | 다중 필드 그룹핑 + 집계 (sum, avg, count, min, max) |
  | `LiveViewGrid.Tree` | 계층 트리 그리드 (parent_id 기반, expand/collapse) |
  | `LiveViewGrid.Pivot` | 피벗 테이블 (행/열 차원 + 동적 컬럼 생성) |

  ## 컬럼 옵션

      %{
        field: :name,           # 필수 - 데이터 필드명
        label: "이름",           # 필수 - 헤더 표시 텍스트
        width: 150,             # 컬럼 너비 (px 또는 :auto)
        sortable: true,         # 정렬 가능 여부
        filterable: true,       # 필터 가능 여부
        filter_type: :text,     # 필터 타입 (:text, :number, :select, :date)
        editable: true,         # 셀 편집 가능 여부
        editor_type: :text,     # 에디터 타입 (:text, :number, :select, :textarea, :date)
        editor_options: [],     # select 에디터 옵션 리스트
        validators: [],         # 검증 함수 리스트
        formatter: :currency,   # 값 포맷터 (atom, tuple, function)
        renderer: :progress,    # 커스텀 렌더러 (atom, tuple, function)
        align: :right           # 텍스트 정렬 (:left, :center, :right)
      }

  ## Grid 옵션

      %{
        page_size: 20,          # 페이지당 행 수
        selection_mode: :single, # 선택 모드 (:none, :single, :multi)
        row_height: 36,         # 행 높이 (px)
        header_height: 40,      # 헤더 높이 (px)
        frozen_columns: 0,      # 고정 컬럼 수
        show_row_numbers: true, # 행번호 표시
        theme: "default",       # 테마 ("default", "dark", "compact", "striped")
        export_enabled: true    # 내보내기 활성화
      }
  """
end
