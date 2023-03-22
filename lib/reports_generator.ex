defmodule ReportsGenerator do
  # Usado pra dar apelido pra função, agora é só usar o Parser
  alias ReportsGenerator.Parser

  @available_foods [
    "açaí",
    "churrasco",
    "esfirra",
    "hambúrguer",
    "pastel",
    "pizza",
    "prato_feito",
    "sushi"
  ]

  @options ["foods", "users"]

  def build(filename) do
    # Opção usando case
    # case File.read("reports/#{filename}") do
    #   {:ok, result} -> result
    #   {:error, reason} -> reason
    # end

    filename
    |> Parser.parse_file()
    |> Enum.reduce(report_acc(), fn line, report -> sum_values(line, report) end)
  end

  def build_from_many(filenames) when not is_list(filenames) do
    {:error, "Please provide a list of strings"}
  end

  def build_from_many(filenames) do
    result =
      filenames
      |> Task.async_stream(&build/1)
      |> Enum.reduce(report_acc(), fn {:ok, result}, report -> sum_reports(report, result) end)

    {:ok, result}
  end

  # Somente executar a função quando a opção escolhida existir dentro de @options
  def fetch_higher_cost(report, option) when option in @options do
    {:ok, Enum.max_by(report[option], fn {_key, value} -> value end)}
  end

  def fetch_higher_cost(_report, _option), do: {:error, "Invalid option!"}

  defp sum_values([id, food_name, price], %{"users" => users, "foods" => foods}) do
    users = Map.put(users, id, users[id] + price)
    foods = Map.put(foods, food_name, foods[food_name] + 1)

    build_report(foods, users)
  end

  defp sum_reports(%{"foods" => foods1, "users" => users1}, %{
         "foods" => foods2,
         "users" => users2
       }) do
    foods = merge_maps(foods1, foods2)
    users = merge_maps(users1, users2)

    build_report(foods, users)
  end

  defp merge_maps(map1, map2) do
    Map.merge(map1, map2, fn _key, value1, value2 -> value1 + value2 end)
  end

  defp report_acc do
    foods = Enum.into(@available_foods, %{}, &{&1, 0})
    users = Enum.into(1..30, %{}, &{Integer.to_string(&1), 0})
    build_report(foods, users)
  end

  defp build_report(foods, users) do
    # Duas formas de atualizar o report
    # 1
    # report
    # |> Map.put("users", users)
    # |> Map.put("foods", foods)
    # 2
    %{"foods" => foods, "users" => users}
  end
end
