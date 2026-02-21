# F-300: DBMS Integration - Plan

> **Feature Code**: F-300
> **Version**: v0.3
> **Created**: 2026-02-21
> **Status**: Do (Implementation)

---

## 1. Goal

DataSource behaviour pattern을 도입하여 Grid의 데이터 백엔드를 교체 가능하게 한다.
- InMemory (기본): 기존 Enum 파이프라인 (하위호환)
- Ecto: SQL 기반 정렬/필터/페이지네이션 (신규)

## 2. Background

v0.2까지 Grid는 모든 데이터를 `data: [%{...}]` 리스트로 받아 Elixir Enum으로 처리.
이는 소규모 데이터에는 적합하나 DB 연동 시 비효율적.
SQL 레벨에서 WHERE/ORDER BY/LIMIT OFFSET을 수행하면 대용량 데이터 지원 가능.

## 3. Scope

### In Scope
- DataSource behaviour definition
- InMemory adapter (기존 로직 래핑)
- Ecto adapter + QueryBuilder
- SQLite demo (1000건 사용자 데이터)
- DBMS demo LiveView page
- 단위 테스트

### Out of Scope
- PostgreSQL/MySQL 지원 (구조는 동일, 별도 테스트 필요)
- Custom DataSource 작성 가이드 (문서화)
- DataSource hot-swap (런타임 전환)

## 4. Success Criteria

| Criteria | Target |
|----------|--------|
| Existing tests | 168건 전부 PASS |
| New tests | 50건+ 추가 |
| Demo page | /dbms-demo에서 CRUD 정상 동작 |
| Backward compatibility | 기존 InMemory Grid 100% 호환 |
