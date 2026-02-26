# Git 컨벤션

## 커밋 메시지 형식
```
<type>(<scope>): <description>

예시:
feat(contents): 게시글 발행 기능 추가
fix(live): PostLive.Index 페이지네이션 오류 수정
refactor(accounts): 사용자 인증 Context 분리
```

## 타입 목록
| 타입 | 용도 |
|------|------|
| feat | 새 기능 |
| fix | 버그 수정 |
| refactor | 리팩토링 (기능 변화 없음) |
| test | 테스트 추가/수정 |
| docs | 문서, @doc, @moduledoc |
| chore | mix.exs, config, CI 등 |
| migration | DB 마이그레이션 |

## MUST
- 커밋 단위는 하나의 논리적 변경사항
- 마이그레이션은 별도 커밋으로 분리
- 리팩토링과 기능 추가를 같은 커밋에 섞지 말 것
- 커밋 메시지는 한글로 작성
