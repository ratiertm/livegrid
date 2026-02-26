# Ecto 패턴 (스키마 / 체인지셋 / 쿼리 / 마이그레이션)

## 스키마 규칙

### MUST
- 모든 스키마에 `@type t()` 정의
- `timestamps()` 반드시 포함
- 관계(associations)는 스키마에 명시, 실제 로딩은 Context에서 `preload`로

### 패턴
```elixir
defmodule ContentFlow.Contents.Post do
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  schema "posts" do
    field :title, :string
    field :body, :string
    field :status, Ecto.Enum, values: [:draft, :published, :archived], default: :draft
    field :published_at, :utc_datetime

    belongs_to :author, ContentFlow.Accounts.User
    has_many :comments, ContentFlow.Contents.Comment

    timestamps()
  end

  @required_fields ~w(title body author_id)a
  @optional_fields ~w(status published_at)a

  @doc "기본 changeset"
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(post, attrs) do
    post
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_length(:title, min: 1, max: 200)
    |> validate_length(:body, min: 1)
    |> foreign_key_constraint(:author_id)
  end

  @doc "발행용 changeset (추가 검증)"
  @spec publish_changeset(t(), map()) :: Ecto.Changeset.t()
  def publish_changeset(post, attrs) do
    post
    |> changeset(attrs)
    |> put_change(:status, :published)
    |> put_change(:published_at, DateTime.utc_now() |> DateTime.truncate(:second))
  end
end
```

## 체인지셋 규칙

### MUST
- 용도별 changeset 함수 분리 (생성용, 수정용, 상태변경용 등)
- `validate_required`, `validate_length`, `validate_format` 적극 활용
- 외래키 제약은 `foreign_key_constraint` 반드시 추가
- 유니크 제약은 `unique_constraint` 반드시 추가

### NEVER
- changeset 밖에서 수동 유효성 검증 금지
- `Repo.insert(%Post{title: "..."})` 처럼 changeset 없이 직접 삽입 금지
- changeset 안에서 DB 조회 금지 → Context 레벨에서 처리

## 쿼리 패턴

### MUST
- 복잡한 쿼리는 Query 모듈로 분리 (`Contents.Queries.PostQuery`)
- 조합 가능한 쿼리 함수로 작성 (composable queries)
- N+1 방지: 필요한 관계는 `preload`로 명시적 로딩

### 패턴
```elixir
defmodule ContentFlow.Contents.Queries.PostQuery do
  import Ecto.Query

  alias ContentFlow.Contents.Post

  def base, do: from(p in Post, as: :post)

  def filter(query, opts) do
    Enum.reduce(opts, query, fn
      {:status, status}, q -> where(q, [post: p], p.status == ^status)
      {:author_id, id}, q -> where(q, [post: p], p.author_id == ^id)
      {:search, term}, q -> where(q, [post: p], ilike(p.title, ^"%#{term}%"))
      _other, q -> q
    end)
  end

  def paginate(query, opts) do
    page = Keyword.get(opts, :page, 1)
    per_page = Keyword.get(opts, :per_page, 20)

    query
    |> limit(^per_page)
    |> offset(^((page - 1) * per_page))
  end

  def with_author(query) do
    from(q in query, preload: [:author])
  end

  def order_by_recent(query) do
    from(q in query, order_by: [desc: q.inserted_at])
  end
end
```

## 마이그레이션 규칙

### MUST
- 마이그레이션에 반드시 인덱스 포함 (자주 조회하는 외래키, 상태 컬럼 등)
- `up/down` 또는 `change` 중 하나 일관되게 사용
- 컬럼 추가 시 기본값 설정 고려 (기존 데이터 호환)

### NEVER
- 기존 마이그레이션 파일 절대 수정 금지 → 새 마이그레이션 생성
- `drop table`은 극도로 신중하게 — 데이터 백업 확인 필수
- 프로덕션에서 `Repo.rollback` 없이 파괴적 마이그레이션 금지

### 패턴
```elixir
defmodule ContentFlow.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  def change do
    create table(:posts) do
      add :title, :string, null: false
      add :body, :text, null: false
      add :status, :string, null: false, default: "draft"
      add :published_at, :utc_datetime
      add :author_id, references(:users, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:posts, [:author_id])
    create index(:posts, [:status])
    create index(:posts, [:published_at])
  end
end
```
