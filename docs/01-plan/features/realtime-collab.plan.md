# F-500: Realtime Collaboration (실시간 협업)

> **Version**: v0.8
> **Priority**: P0
> **Status**: Plan

---

## 목표

Phoenix PubSub 기반으로 같은 Grid를 보고 있는 여러 사용자 간 **실시간 데이터 동기화**를 구현합니다.

## 요구사항

1. **변경사항 브로드캐스트**: 한 사용자의 셀 편집/행 추가/삭제가 다른 사용자에게 실시간 반영
2. **사용자 Presence 표시**: 현재 접속 중인 사용자 목록 + 수 표시
3. **편집 중 표시**: 다른 사용자가 편집 중인 셀에 시각적 표시 (잠금은 아님)
4. **Optimistic UI**: 로컬 변경 즉시 반영 + 서버 동기화

## 아키텍처

```
User A (LiveView)  ──> PubSub Topic: "grid:{grid_id}"  <── User B (LiveView)
        │                       │                              │
        └── Presence ──────────────────────── Presence ────────┘
```

### PubSub 토픽
- `"grid:{grid_id}"` - Grid별 변경사항 브로드캐스트

### 메시지 타입
1. `:cell_updated` - 셀 값 변경
2. `:row_added` - 행 추가
3. `:row_deleted` - 행 삭제
4. `:rows_saved` - 일괄 저장 완료
5. `:user_editing` - 사용자 편집 중 위치

## 구현 범위

### Phase 1: PubSub 브로드캐스트
- `LiveViewGrid.PubSubBridge` 모듈 생성
- Grid 이벤트 발생 시 PubSub으로 브로드캐스트
- 수신 측에서 Grid 상태 업데이트

### Phase 2: Presence
- `LiveViewGrid.GridPresence` 모듈 (Phoenix.Presence)
- 접속 사용자 수 표시 (Grid 툴바)
- 편집 중인 셀 위치 공유

## 구현 순서

1. `PubSubBridge` 모듈 (subscribe/broadcast)
2. GridComponent에서 편집 이벤트 시 broadcast 호출
3. GridComponent handle_info로 다른 사용자 변경 수신
4. `GridPresence` 모듈 생성
5. 접속자 수 UI 표시
6. 편집 중 셀 표시 (CSS + Presence tracking)
7. 테스트
