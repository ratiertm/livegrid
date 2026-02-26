# LiveView & 웹 레이어 스킬 목차

> 이 목차를 먼저 읽고, 현재 작업에 해당하는 챕터만 펴보세요.

## 챕터 목록

| 챕터 | 파일 | 언제 읽나 |
|------|------|-----------|
| LiveView 규칙 | `liveview-rules.md` | LiveView 모듈 생성/수정 시 |
| 컴포넌트 규칙 | `component-rules.md` | Phoenix Component 작업 시 |
| 스타일 가이드 | `styling-guide.md` | HEEx 템플릿, TailwindCSS 작업 시 |

## 전체 적용 규칙 (항상)
- LiveView에서 직접 Repo/DB 호출 금지 → 반드시 Context 모듈 통해 접근
- 이벤트 핸들러(`handle_event`)는 가볍게 유지 — 비즈니스 로직은 Context로 위임
- 컴포넌트는 `content_flow_web/components/` 에 배치
- `assign`과 `socket` 조작은 LiveView 모듈 안에서만
- HEEx 템플릿에 복잡한 로직 금지 — 헬퍼 함수나 assign으로 미리 계산
