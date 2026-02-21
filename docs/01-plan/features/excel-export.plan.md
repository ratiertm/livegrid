# F-510: Excel Export 기능 계획서

> **기능 코드**: F-510
> **우선순위**: P0 (Enterprise)
> **작성일**: 2026-02-21
> **예상 기간**: 1일

---

## 1. 목표

그리드 데이터를 **Excel (.xlsx) 파일**로 다운로드하는 기능 구현.
기존 CSV Export를 확장하여 Excel 형식을 추가한다.

---

## 2. 요구사항

### 2.1 기능 요구사항

| ID | 요구사항 | 우선순위 |
|----|---------|---------|
| R-01 | 전체 데이터 Excel 다운로드 | P0 필수 |
| R-02 | 필터 적용된 데이터만 Excel 다운로드 | P0 필수 |
| R-03 | 선택된 행만 Excel 다운로드 | P1 권장 |
| R-04 | 컬럼 헤더(label) 포함 | P0 필수 |
| R-05 | 한글 지원 (깨짐 없음) | P0 필수 |
| R-06 | 헤더 스타일 (굵게, 배경색) | P1 권장 |
| R-07 | 컬럼 너비 자동 조절 | P2 선택 |
| R-08 | 날짜/시간 파일명 자동 생성 | P0 필수 |

### 2.2 비기능 요구사항

| ID | 요구사항 | 기준 |
|----|---------|------|
| NR-01 | 1,000행 Export 시간 | < 2초 |
| NR-02 | 10,000행 Export 시간 | < 10초 |
| NR-03 | 기존 기능 영향 없음 | 161개 테스트 통과 유지 |
| NR-04 | 외부 라이브러리 의존성 최소화 | 1개 라이브러리만 추가 |

---

## 3. 기술 접근

### 3.1 라이브러리 선택

**선택: [Elixlsx](https://github.com/xou/elixlsx)**

| 항목 | Elixlsx | 순수 CSV |
|------|---------|----------|
| 파일 형식 | .xlsx (Excel 네이티브) | .csv |
| 한글 지원 | UTF-8 기본 | BOM 필요 |
| 스타일링 | 가능 (헤더 색상, 굵게) | 불가 |
| 라이브러리 | `{:elixlsx, "~> 0.6"}` | 없음 (내장) |
| 사용처 | 정식 Export | 간단 Export |

### 3.2 데이터 흐름

```
사용자 "Excel 다운로드" 클릭
  ↓
GridComponent → handle_event("export_excel", %{"type" => type})
  ↓
send(self(), {:grid_export_excel, type})
  ↓
Parent LiveView → handle_info(:grid_export_excel)
  ↓
LiveViewGrid.Export.to_xlsx(data, columns, opts)
  ↓
Elixlsx 워크북 생성 → 바이너리
  ↓
push_event(socket, "download_file", %{content: base64, filename: "..."})
  ↓
JavaScript로 파일 다운로드
```

### 3.3 구현 범위

1. **Export 모듈** (`lib/liveview_grid/export.ex`) - 핵심 Excel 생성 로직
2. **GridComponent 이벤트** - `export_excel` 이벤트 핸들러 추가
3. **UI 버튼** - Export 버튼을 GridComponent toolbar에 추가
4. **JS Hook** - 파일 다운로드 처리
5. **Demo 페이지** - Excel Export 버튼 추가

---

## 4. 구현 단계

| Step | 작업 | 예상 시간 |
|------|------|----------|
| 1 | Elixlsx 의존성 추가 + 컴파일 | 5분 |
| 2 | Export 모듈 구현 (to_xlsx) | 30분 |
| 3 | GridComponent에 export 이벤트 핸들러 추가 | 20분 |
| 4 | GridComponent render에 Export 버튼 추가 | 15분 |
| 5 | JS Hook으로 파일 다운로드 구현 | 15분 |
| 6 | Demo 페이지에 Excel Export 버튼 추가 | 15분 |
| 7 | 컴파일 + 테스트 + 브라우저 검증 | 20분 |

---

## 5. 리스크

| 리스크 | 대응 |
|--------|------|
| Elixlsx가 Elixir 1.14와 호환되지 않을 수 있음 | 호환성 확인 후 대안: 순수 CSV 유지 |
| 대용량(10,000+) 데이터 Export 시 메모리 문제 | 스트리밍 방식 검토, 최대 행 제한 |
| JavaScript base64 인코딩 크기 제한 | blob URL 방식으로 다운로드 |

---

## 6. 성공 기준

- [ ] 전체/필터 데이터 Excel 다운로드 동작
- [ ] 한글 컬럼명 + 한글 데이터 깨짐 없음
- [ ] 헤더에 스타일 적용 (굵게 + 배경색)
- [ ] 기존 161개 테스트 모두 통과
- [ ] 브라우저에서 실제 다운로드 검증
