# 보안 체크리스트 (Elixir / Phoenix)

## 라우트/엔드포인트 추가 시 필수 확인
- [ ] 인증 plug 적용 여부 (`:require_authenticated_user` 등)
- [ ] 인가 확인 (해당 사용자가 이 리소스에 접근 권한이 있는지)
- [ ] 입력 유효성 검증 (Ecto Changeset으로 처리)
- [ ] SQL Injection 방어 (Ecto 쿼리 사용 — 문자열 보간 쿼리 금지)
- [ ] XSS 방어 (HEEx는 기본 이스케이프, `raw/1` 사용 시 각별히 주의)
- [ ] CSRF 보호 (Phoenix 기본 제공, 비활성화하지 않았는지 확인)
- [ ] Rate Limiting 적용 여부

## Ecto 보안
- Changeset `cast/4`로 허용 필드 명시적 지정 — mass assignment 방지
- `Repo.get!` + 소유권 확인 패턴:
  ```elixir
  # ✅ 소유권 확인
  def get_owned_post!(user, post_id) do
    Repo.get_by!(Post, id: post_id, author_id: user.id)
  end
  ```
- 절대 사용자 입력을 `Ecto.Query.fragment`에 직접 보간하지 말 것

## 민감 데이터 처리
- 비밀번호: `Bcrypt.hash_pwd_salt/1` (comeonin/bcrypt_elixir)
- 토큰: `Phoenix.Token` 또는 JWT — 만료 시간 반드시 설정
- 환경변수: `config/runtime.exs`에서 `System.get_env` 사용
- 코드에 시크릿 하드코딩 절대 금지
- 로그: `Logger`에 비밀번호, 토큰, 개인정보 출력 금지
  ```elixir
  # ✅ 민감 필드 로깅 방지
  @derive {Inspect, except: [:password, :password_hash]}
  ```

## LiveView 보안
- `mount/3`에서 사용자 인증 상태 반드시 확인
- `handle_event`에서 현재 사용자 권한 항상 재확인 (세션 위변조 방지)
- PubSub 토픽에 사용자별 격리 적용 (다른 사용자 데이터 노출 금지)
