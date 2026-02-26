# 네이밍 컨벤션 (Elixir / Phoenix)

## 모듈 & 파일명
| 대상 | 규칙 | 예시 |
|------|------|------|
| Context | PascalCase (도메인명) | `ContentFlow.Contents` |
| Schema | PascalCase (단수) | `ContentFlow.Contents.Post` |
| LiveView | `.Live.` 포함 | `ContentFlowWeb.PostLive.Index` |
| Component | PascalCase | `ContentFlowWeb.Components.Card` |
| Query 모듈 | `.Queries.` 포함 | `ContentFlow.Contents.Queries.PostQuery` |
| 파일명 | snake_case | `post_live/index.ex` |
| 테스트 | `_test.exs` 접미사 | `contents_test.exs` |

## 함수명
| 대상 | 규칙 | 예시 |
|------|------|------|
| 공개 함수 | snake_case + 동사 | `list_posts`, `create_user` |
| private 함수 | snake_case + `defp` | `defp do_publish(post)` |
| Boolean 반환 | `?` 접미사 | `published?`, `active?` |
| 위험한 함수 | `!` 접미사 (raise 가능) | `get_post!`, `create_post!` |
| Guard 함수 | `is_` 접두사 | `is_admin(user)` |
| Changeset | `changeset` 또는 용도명 | `changeset`, `publish_changeset` |

## 변수명
| 대상 | 규칙 | 예시 |
|------|------|------|
| 변수 | snake_case | `current_user`, `post_count` |
| 모듈 속성 | `@` + snake_case | `@required_fields`, `@max_retries` |
| Atom | snake_case | `:ok`, `:not_found`, `:draft` |
| 상수 (module attr) | `@` + snake_case | `@page_size 20` |

## NEVER
- CamelCase 변수명 금지 (Elixir 컨벤션 위반)
- 한 글자 변수 금지 (`Enum.map(list, fn x -> ... end)` 에서 x 정도는 허용)
- 축약어 금지 (`usr` → `user`, `btn` → `button`)
- 의미 없는 이름 금지 (`data`, `info`, `temp`, `result`)
