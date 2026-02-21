# Script for populating the database with demo data.
# Run: mix run priv/repo/seeds.exs

alias LiveviewGrid.{Repo, DemoUser}

departments = ["개발", "디자인", "마케팅", "영업", "인사", "재무", "기획", "CS"]
statuses = ["재직", "휴직", "퇴직"]

first_names = [
  "김민수", "이영희", "박철수", "정미영", "최준호",
  "강서연", "조현우", "윤하나", "임동현", "한지은",
  "오승민", "서예진", "장태윤", "송민지", "류현석",
  "권나영", "배성훈", "홍수진", "문재원", "이다은",
  "김태호", "박소영", "정현기", "최유리", "강지훈",
  "조은서", "윤석민", "임수빈", "한승우", "오다연",
  "서진우", "장하영", "송현준", "류미선", "권도현",
  "배서희", "홍태양", "문지영", "신동욱", "이서윤",
  "김하준", "박지민", "정수아", "최민호", "강예린",
  "조태현", "윤서영", "임정훈", "한미래", "오건우"
]

# Generate 1000 users
now = DateTime.utc_now() |> DateTime.truncate(:second)

users =
  for i <- 1..1000 do
    name = Enum.random(first_names)
    dept = Enum.random(departments)
    status = if :rand.uniform(100) <= 85, do: "재직", else: Enum.random(statuses)
    age = 22 + :rand.uniform(40)
    salary = (3000 + :rand.uniform(7000)) * 10000
    year = 2015 + :rand.uniform(10)
    month = :rand.uniform(12) |> Integer.to_string() |> String.pad_leading(2, "0")
    day = :rand.uniform(28) |> Integer.to_string() |> String.pad_leading(2, "0")

    %{
      name: name,
      email: "user#{i}@example.com",
      department: dept,
      age: age,
      salary: salary,
      status: status,
      join_date: "#{year}-#{month}-#{day}",
      inserted_at: now,
      updated_at: now
    }
  end

# Bulk insert in chunks of 100
users
|> Enum.chunk_every(100)
|> Enum.each(fn chunk ->
  Repo.insert_all(DemoUser, chunk)
end)

IO.puts("✅ Seeded #{length(users)} demo users")
