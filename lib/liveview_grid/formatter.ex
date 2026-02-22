defmodule LiveViewGrid.Formatter do
  @moduledoc """
  Grid 셀 값 포맷터

  컬럼 정의에서 `formatter` 옵션으로 셀 값의 표시 형식을 지정합니다.
  renderer(HTML 구조 변경)와 달리 formatter는 텍스트 값만 변환합니다.

  ## 사용법

      # 컬럼 정의에서 formatter 지정
      %{field: :salary, label: "급여", formatter: :currency}
      %{field: :rate, label: "비율", formatter: :percent}
      %{field: :created_at, label: "생성일", formatter: :date}
      %{field: :price, label: "가격", formatter: {:currency, symbol: "$"}}
      %{field: :score, label: "점수", formatter: {:number, precision: 2}}
      %{field: :custom, label: "커스텀", formatter: fn val -> "★ \#{val}" end}

  ## 지원 포맷터

  - `:number` - 천 단위 구분자 (75000000 → "75,000,000")
  - `:currency` - 원화 포맷 (75000000 → "₩75,000,000")
  - `:dollar` - 달러 포맷 (1500.5 → "$1,500.50")
  - `:percent` - 백분율 (0.856 → "85.6%")
  - `:date` - 날짜 (Date/DateTime/NaiveDateTime → "2026-02-22")
  - `:datetime` - 날짜시간 (DateTime → "2026-02-22 14:30:00")
  - `:time` - 시간 (Time/DateTime → "14:30:00")
  - `:relative_time` - 상대 시간 (DateTime → "3일 전")
  - `:boolean` - 불리언 (true → "예", false → "아니오")
  - `:filesize` - 파일 크기 (1048576 → "1.0 MB")
  - `:truncate` - 텍스트 말줄임 (긴 텍스트 → "긴 텍스트...")
  - `:uppercase` / `:lowercase` / `:capitalize` - 대소문자 변환
  - `:mask` - 마스킹 ("01012345678" → "010-****-5678")
  - `{:number, opts}` - 옵션 지정 숫자 포맷
  - `{:currency, opts}` - 옵션 지정 통화 포맷
  - `{:date, format}` - 날짜 포맷 문자열
  - `{:truncate, max_length}` - 최대 길이 지정 말줄임
  - `{:mask, pattern}` - 마스킹 패턴
  - `fn value -> ... end` - 커스텀 함수
  """

  @doc """
  셀 값을 포맷합니다.

  ## Parameters
  - `value` - 원본 값
  - `formatter` - 포맷터 지정 (atom, tuple, function, nil)

  ## Returns
  포맷된 문자열
  """
  @spec format(value :: any(), formatter :: any()) :: String.t()
  def format(value, nil), do: to_string_safe(value)
  def format(nil, _formatter), do: ""
  def format("", _formatter), do: ""

  # ── Atom 포맷터 ──

  def format(value, :number), do: format_number(value, %{})
  def format(value, :currency), do: format_currency(value, %{symbol: "₩", precision: 0})
  def format(value, :dollar), do: format_currency(value, %{symbol: "$", precision: 2})
  def format(value, :percent), do: format_percent(value, %{})
  def format(value, :date), do: format_date(value, "YYYY-MM-DD")
  def format(value, :datetime), do: format_datetime(value, "YYYY-MM-DD HH:mm:ss")
  def format(value, :time), do: format_time(value)
  def format(value, :relative_time), do: format_relative_time(value)
  def format(value, :boolean), do: format_boolean(value, %{})
  def format(value, :filesize), do: format_filesize(value)
  def format(value, :truncate), do: format_truncate(value, 50)
  def format(value, :uppercase), do: String.upcase(to_string_safe(value))
  def format(value, :lowercase), do: String.downcase(to_string_safe(value))
  def format(value, :capitalize), do: format_capitalize(value)
  def format(value, :mask), do: format_mask(value, :auto)

  # ── Tuple 포맷터 (옵션 지정) ──

  def format(value, {:number, opts}) when is_list(opts), do: format_number(value, Map.new(opts))
  def format(value, {:number, opts}) when is_map(opts), do: format_number(value, opts)

  def format(value, {:currency, opts}) when is_list(opts) do
    opts_map = Map.new(opts)
    format_currency(value, Map.merge(%{symbol: "₩", precision: 0}, opts_map))
  end
  def format(value, {:currency, opts}) when is_map(opts) do
    format_currency(value, Map.merge(%{symbol: "₩", precision: 0}, opts))
  end

  def format(value, {:dollar, opts}) when is_list(opts) do
    opts_map = Map.new(opts)
    format_currency(value, Map.merge(%{symbol: "$", precision: 2}, opts_map))
  end

  def format(value, {:percent, opts}) when is_list(opts), do: format_percent(value, Map.new(opts))
  def format(value, {:percent, opts}) when is_map(opts), do: format_percent(value, opts)

  def format(value, {:date, format_str}) when is_binary(format_str), do: format_date(value, format_str)
  def format(value, {:datetime, format_str}) when is_binary(format_str), do: format_datetime(value, format_str)

  def format(value, {:boolean, opts}) when is_list(opts), do: format_boolean(value, Map.new(opts))
  def format(value, {:boolean, opts}) when is_map(opts), do: format_boolean(value, opts)

  def format(value, {:truncate, max_len}) when is_integer(max_len), do: format_truncate(value, max_len)

  def format(value, {:mask, pattern}), do: format_mask(value, pattern)

  def format(value, {:pad_leading, len, char}) when is_integer(len) and is_binary(char) do
    to_string_safe(value) |> String.pad_leading(len, char)
  end

  def format(value, {:pad_trailing, len, char}) when is_integer(len) and is_binary(char) do
    to_string_safe(value) |> String.pad_trailing(len, char)
  end

  # ── 커스텀 함수 ──

  def format(value, formatter) when is_function(formatter, 1) do
    try do
      formatter.(value) |> to_string_safe()
    rescue
      _ -> to_string_safe(value)
    end
  end

  # Fallback
  def format(value, _), do: to_string_safe(value)

  # ══════════════════════════════════════════════
  # 포맷 구현
  # ══════════════════════════════════════════════

  # ── 숫자 포맷 ──

  defp format_number(value, opts) when is_number(value) do
    precision = Map.get(opts, :precision, nil)
    separator = Map.get(opts, :separator, ",")
    delimiter = Map.get(opts, :delimiter, ".")

    {integer_part, decimal_part} = split_number(value, precision)
    formatted_integer = add_thousands_separator(integer_part, separator)

    if decimal_part == "" do
      formatted_integer
    else
      "#{formatted_integer}#{delimiter}#{decimal_part}"
    end
  end
  defp format_number(value, _opts) do
    case parse_number(value) do
      {:ok, num} -> format_number(num, %{})
      :error -> to_string_safe(value)
    end
  end

  # ── 통화 포맷 ──

  defp format_currency(value, opts) when is_number(value) do
    symbol = Map.get(opts, :symbol, "₩")
    precision = Map.get(opts, :precision, 0)
    separator = Map.get(opts, :separator, ",")
    position = Map.get(opts, :position, :prefix)

    {integer_part, decimal_part} = split_number(abs(value), precision)
    formatted = add_thousands_separator(integer_part, separator)

    formatted = if decimal_part == "" do
      formatted
    else
      "#{formatted}.#{decimal_part}"
    end

    sign = if value < 0, do: "-", else: ""

    case position do
      :prefix -> "#{sign}#{symbol}#{formatted}"
      :suffix -> "#{sign}#{formatted}#{symbol}"
    end
  end
  defp format_currency(value, opts) do
    case parse_number(value) do
      {:ok, num} -> format_currency(num, opts)
      :error -> to_string_safe(value)
    end
  end

  # ── 백분율 포맷 ──

  defp format_percent(value, opts) when is_number(value) do
    precision = Map.get(opts, :precision, 1)
    multiplier = Map.get(opts, :multiplier, 100)

    percent_value = value * multiplier
    :erlang.float_to_binary(percent_value / 1, decimals: precision) <> "%"
  end
  defp format_percent(value, opts) do
    case parse_number(value) do
      {:ok, num} -> format_percent(num, opts)
      :error -> to_string_safe(value)
    end
  end

  # ── 날짜 포맷 ──

  defp format_date(%Date{} = date, format_str) do
    apply_date_format(date.year, date.month, date.day, format_str)
  end
  defp format_date(%DateTime{} = dt, format_str) do
    apply_date_format(dt.year, dt.month, dt.day, format_str)
  end
  defp format_date(%NaiveDateTime{} = dt, format_str) do
    apply_date_format(dt.year, dt.month, dt.day, format_str)
  end
  defp format_date(value, _format_str) when is_binary(value) do
    # ISO 8601 문자열 파싱 시도
    case Date.from_iso8601(value) do
      {:ok, date} -> format_date(date, "YYYY-MM-DD")
      _ ->
        case NaiveDateTime.from_iso8601(value) do
          {:ok, dt} -> format_date(dt, "YYYY-MM-DD")
          _ -> value
        end
    end
  end
  defp format_date(value, _format_str), do: to_string_safe(value)

  defp format_datetime(%DateTime{} = dt, format_str) do
    date_part = apply_date_format(dt.year, dt.month, dt.day, format_str)
    time_part = apply_time_format(dt.hour, dt.minute, dt.second, format_str)
    if String.contains?(format_str, "HH") do
      date_str = format_str
        |> String.replace("HH:mm:ss", "")
        |> String.replace("HH:mm", "")
        |> String.trim()
      apply_date_format(dt.year, dt.month, dt.day, date_str) <> " " <> time_part
    else
      date_part
    end
  end
  defp format_datetime(%NaiveDateTime{} = dt, format_str) do
    if String.contains?(format_str, "HH") do
      date_str = format_str
        |> String.replace("HH:mm:ss", "")
        |> String.replace("HH:mm", "")
        |> String.trim()
      time_str = if String.contains?(format_str, "ss") do
        apply_time_format(dt.hour, dt.minute, dt.second, "HH:mm:ss")
      else
        apply_time_format(dt.hour, dt.minute, dt.second, "HH:mm")
      end
      apply_date_format(dt.year, dt.month, dt.day, date_str) <> " " <> time_str
    else
      apply_date_format(dt.year, dt.month, dt.day, format_str)
    end
  end
  defp format_datetime(value, _format_str) when is_binary(value) do
    case NaiveDateTime.from_iso8601(value) do
      {:ok, dt} -> format_datetime(dt, "YYYY-MM-DD HH:mm:ss")
      _ -> value
    end
  end
  defp format_datetime(value, _format_str), do: to_string_safe(value)

  defp format_time(%Time{} = t) do
    apply_time_format(t.hour, t.minute, t.second, "HH:mm:ss")
  end
  defp format_time(%DateTime{} = dt) do
    apply_time_format(dt.hour, dt.minute, dt.second, "HH:mm:ss")
  end
  defp format_time(%NaiveDateTime{} = dt) do
    apply_time_format(dt.hour, dt.minute, dt.second, "HH:mm:ss")
  end
  defp format_time(value), do: to_string_safe(value)

  # ── 상대 시간 ──

  defp format_relative_time(%DateTime{} = dt) do
    now = DateTime.utc_now()
    diff = DateTime.diff(now, dt, :second)
    relative_from_seconds(diff)
  end
  defp format_relative_time(%NaiveDateTime{} = dt) do
    now = NaiveDateTime.utc_now()
    diff = NaiveDateTime.diff(now, dt, :second)
    relative_from_seconds(diff)
  end
  defp format_relative_time(value), do: to_string_safe(value)

  defp relative_from_seconds(diff) when diff < 0, do: "미래"
  defp relative_from_seconds(diff) when diff < 60, do: "방금 전"
  defp relative_from_seconds(diff) when diff < 3600 do
    minutes = div(diff, 60)
    "#{minutes}분 전"
  end
  defp relative_from_seconds(diff) when diff < 86400 do
    hours = div(diff, 3600)
    "#{hours}시간 전"
  end
  defp relative_from_seconds(diff) when diff < 2_592_000 do
    days = div(diff, 86400)
    "#{days}일 전"
  end
  defp relative_from_seconds(diff) when diff < 31_536_000 do
    months = div(diff, 2_592_000)
    "#{months}개월 전"
  end
  defp relative_from_seconds(diff) do
    years = div(diff, 31_536_000)
    "#{years}년 전"
  end

  # ── 불리언 포맷 ──

  defp format_boolean(value, opts) do
    true_label = Map.get(opts, :true_label, "예")
    false_label = Map.get(opts, :false_label, "아니오")

    cond do
      value == true -> true_label
      value == false -> false_label
      value in ["true", "1", "yes", "Y"] -> true_label
      value in ["false", "0", "no", "N"] -> false_label
      true -> to_string_safe(value)
    end
  end

  # ── 파일 크기 포맷 ──

  defp format_filesize(value) when is_number(value) do
    cond do
      value < 1024 ->
        "#{value} B"
      value < 1024 * 1024 ->
        "#{:erlang.float_to_binary(value / 1024, decimals: 1)} KB"
      value < 1024 * 1024 * 1024 ->
        "#{:erlang.float_to_binary(value / (1024 * 1024), decimals: 1)} MB"
      true ->
        "#{:erlang.float_to_binary(value / (1024 * 1024 * 1024), decimals: 2)} GB"
    end
  end
  defp format_filesize(value), do: to_string_safe(value)

  # ── 텍스트 말줄임 ──

  defp format_truncate(value, max_len) do
    str = to_string_safe(value)
    if String.length(str) > max_len do
      String.slice(str, 0, max_len) <> "..."
    else
      str
    end
  end

  # ── 대문자 변환 ──

  defp format_capitalize(value) do
    str = to_string_safe(value)
    case String.split(str, " ", trim: true) do
      [] -> str
      words ->
        words
        |> Enum.map(fn word ->
          {first, rest} = String.split_at(word, 1)
          String.upcase(first) <> rest
        end)
        |> Enum.join(" ")
    end
  end

  # ── 마스킹 ──

  defp format_mask(value, :auto) do
    str = to_string_safe(value)
    len = String.length(str)
    cond do
      # 전화번호 패턴 (010-1234-5678 또는 01012345678)
      Regex.match?(~r/^01[016789]\d{7,8}$/, String.replace(str, "-", "")) ->
        format_mask(str, :phone)
      # 이메일
      String.contains?(str, "@") ->
        format_mask(str, :email)
      # 기본: 가운데 마스킹
      len > 4 ->
        visible = div(len, 4)
        first = String.slice(str, 0, visible)
        last = String.slice(str, len - visible, visible)
        masked = String.duplicate("*", len - visible * 2)
        "#{first}#{masked}#{last}"
      true -> str
    end
  end
  defp format_mask(value, :phone) do
    digits = String.replace(to_string_safe(value), ~r/[^\d]/, "")
    cond do
      String.length(digits) == 11 ->
        "#{String.slice(digits, 0, 3)}-****-#{String.slice(digits, 7, 4)}"
      String.length(digits) == 10 ->
        "#{String.slice(digits, 0, 3)}-***-#{String.slice(digits, 6, 4)}"
      true -> to_string_safe(value)
    end
  end
  defp format_mask(value, :email) do
    str = to_string_safe(value)
    case String.split(str, "@", parts: 2) do
      [local, domain] ->
        visible = min(2, String.length(local))
        masked_local = String.slice(local, 0, visible) <> String.duplicate("*", max(0, String.length(local) - visible))
        "#{masked_local}@#{domain}"
      _ -> str
    end
  end
  defp format_mask(value, :card) do
    digits = String.replace(to_string_safe(value), ~r/[^\d]/, "")
    if String.length(digits) >= 13 do
      first4 = String.slice(digits, 0, 4)
      last4 = String.slice(digits, -4, 4)
      middle_len = String.length(digits) - 8
      "#{first4}-#{String.duplicate("*", middle_len)}-#{last4}"
    else
      to_string_safe(value)
    end
  end
  defp format_mask(value, _), do: to_string_safe(value)

  # ══════════════════════════════════════════════
  # 내부 헬퍼
  # ══════════════════════════════════════════════

  defp to_string_safe(nil), do: ""
  defp to_string_safe(value) when is_binary(value), do: value
  defp to_string_safe(value), do: to_string(value)

  defp parse_number(value) when is_number(value), do: {:ok, value}
  defp parse_number(value) when is_binary(value) do
    cleaned = String.replace(value, ~r/[,₩$%\s]/, "")
    case Float.parse(cleaned) do
      {num, ""} -> {:ok, num}
      {num, _} -> {:ok, num}
      :error ->
        case Integer.parse(cleaned) do
          {num, ""} -> {:ok, num}
          _ -> :error
        end
    end
  end
  defp parse_number(_), do: :error

  defp split_number(value, nil) when is_integer(value), do: {Integer.to_string(value), ""}
  defp split_number(value, nil) when is_float(value) do
    if value == Float.floor(value) do
      {Integer.to_string(trunc(value)), ""}
    else
      str = :erlang.float_to_binary(value, decimals: 10)
      # 뒤의 0 제거
      str = String.trim_trailing(str, "0") |> String.trim_trailing(".")
      case String.split(str, ".") do
        [int_part] -> {int_part, ""}
        [int_part, dec_part] -> {int_part, dec_part}
      end
    end
  end
  defp split_number(value, precision) when is_integer(precision) and precision >= 0 do
    float_val = value / 1
    str = :erlang.float_to_binary(float_val, decimals: precision)
    case String.split(str, ".") do
      [int_part] -> {int_part, ""}
      [int_part, dec_part] -> {int_part, dec_part}
    end
  end

  defp add_thousands_separator(integer_str, separator) do
    # 음수 부호 분리
    {sign, digits} = if String.starts_with?(integer_str, "-") do
      {"-", String.slice(integer_str, 1..-1//1)}
    else
      {"", integer_str}
    end

    formatted = digits
    |> String.reverse()
    |> String.to_charlist()
    |> Enum.chunk_every(3)
    |> Enum.map(&to_string/1)
    |> Enum.join(separator)
    |> String.reverse()

    sign <> formatted
  end

  defp apply_date_format(year, month, day, format_str) do
    format_str
    |> String.replace("YYYY", Integer.to_string(year))
    |> String.replace("YY", String.slice(Integer.to_string(year), -2, 2))
    |> String.replace("MM", String.pad_leading(Integer.to_string(month), 2, "0"))
    |> String.replace("DD", String.pad_leading(Integer.to_string(day), 2, "0"))
    |> String.replace("M", Integer.to_string(month))
    |> String.replace("D", Integer.to_string(day))
  end

  defp apply_time_format(hour, minute, second, format_str) do
    result = format_str
    |> String.replace("HH", String.pad_leading(Integer.to_string(hour), 2, "0"))
    |> String.replace("mm", String.pad_leading(Integer.to_string(minute), 2, "0"))
    |> String.replace("ss", String.pad_leading(Integer.to_string(second), 2, "0"))

    # 날짜 부분이 포함된 경우 시간 부분만 반환
    cond do
      String.contains?(format_str, "HH:mm:ss") ->
        hh = String.pad_leading(Integer.to_string(hour), 2, "0")
        mm = String.pad_leading(Integer.to_string(minute), 2, "0")
        ss = String.pad_leading(Integer.to_string(second), 2, "0")
        "#{hh}:#{mm}:#{ss}"
      String.contains?(format_str, "HH:mm") ->
        hh = String.pad_leading(Integer.to_string(hour), 2, "0")
        mm = String.pad_leading(Integer.to_string(minute), 2, "0")
        "#{hh}:#{mm}"
      true -> result
    end
  end
end
