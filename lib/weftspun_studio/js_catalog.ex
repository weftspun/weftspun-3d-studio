defmodule WeftspunStudio.JsCatalog do
  @moduledoc """
  Reads the model ids out of the JavaScript catalog.

  This module is the seam of the strangler fig in RFD 0019. Phase 1
  compares the Elixir inventory against the JavaScript catalog and
  reports a difference. It changes nothing, because
  `thirdparty/3d_studio/src/library/aiModelsCatalog.js` stays
  authoritative until phase 2. RFD 0060 moved that file's parent tree
  under `thirdparty/`; the path here follows it.

  The parser is deliberately narrow. It reads `value: '...'` entries
  from the catalog and nothing else. A real JavaScript parser would
  be a larger dependency than the check justifies.
  """

  @default_path "thirdparty/3d_studio/src/library/aiModelsCatalog.js"

  # Matches `value: 'some_model_id'` and `value: "some_model_id"`.
  @value_re ~r/(?:^|[\s{,])value:\s*['"]([a-z0-9_]+)['"]/m

  @doc "Path to the JavaScript catalog, relative to the project root."
  @spec default_path() :: String.t()
  def default_path, do: @default_path

  @doc """
  Reads every model id declared in the JavaScript catalog.

  Returns `{:ok, ids}` with the ids sorted and de-duplicated, or
  `{:error, reason}` when the file cannot be read.
  """
  @spec ids(String.t()) :: {:ok, [String.t()]} | {:error, term()}
  def ids(path \\ @default_path) do
    with {:ok, source} <- File.read(path) do
      ids =
        @value_re
        |> Regex.scan(source, capture: :all_but_first)
        |> List.flatten()
        |> Enum.uniq()
        |> Enum.sort()

      {:ok, ids}
    end
  end

  @doc """
  Compares the Elixir inventory against the JavaScript catalog.

  Component ids are excluded. They describe the internals of the
  See-Through pipeline and never appear in the client picker.

  Returns a map with:

    * `:only_in_elixir` - ids this project records but the client does not
    * `:only_in_js` - ids the client offers but this project does not record
    * `:both` - ids present in each place
  """
  @spec diff(String.t()) ::
          {:ok, %{only_in_elixir: [String.t()], only_in_js: [String.t()], both: [String.t()]}}
          | {:error, term()}
  def diff(path \\ @default_path) do
    with {:ok, js_ids} <- ids(path) do
      elixir_ids =
        WeftspunStudio.Inventory.all()
        |> Enum.reject(&(&1.group == :component))
        |> Enum.map(& &1.id)
        |> MapSet.new()

      js = MapSet.new(js_ids)

      {:ok,
       %{
         only_in_elixir: elixir_ids |> MapSet.difference(js) |> Enum.sort(),
         only_in_js: js |> MapSet.difference(elixir_ids) |> Enum.sort(),
         both: elixir_ids |> MapSet.intersection(js) |> Enum.sort()
       }}
    end
  end

  @doc "True when neither side holds an id the other side lacks."
  @spec in_parity?(String.t()) :: boolean()
  def in_parity?(path \\ @default_path) do
    case diff(path) do
      {:ok, %{only_in_elixir: [], only_in_js: []}} -> true
      _ -> false
    end
  end
end
