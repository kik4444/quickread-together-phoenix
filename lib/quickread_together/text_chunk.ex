defmodule QuickreadTogether.TextChunk do
  @moduledoc false

  @type t :: %__MODULE__{
          chunk: String.t(),
          start_offset: non_neg_integer(),
          stop_offset: non_neg_integer()
        }

  defstruct chunk: "", start_offset: 0, stop_offset: 0

  @spec parse(binary(), pos_integer()) :: tuple()
  def parse(text, chunk_size \\ 1)

  def parse("", _), do: {%__MODULE__{}}

  def parse(text, chunk_size) when is_binary(text) and chunk_size in 1..10 do
    String.graphemes(text)
    # The current logic misbehaves if we start with prev_whitespace = false
    |> Enum.reduce([{0, 0, 0, true}], &split/2)
    |> Enum.reduce([], fn {start, stop, _, _}, acc ->
      chunk = String.slice(text, start, stop - start)

      if chunk == "" do
        acc
      else
        text_chunk = %__MODULE__{chunk: chunk, start_offset: start, stop_offset: stop}

        [text_chunk | acc]
      end
    end)
    |> then(&if &1 == [], do: [%__MODULE__{}], else: &1)
    |> Enum.chunk_every(chunk_size)
    |> Enum.map(fn chunks ->
      Enum.reduce(chunks, fn %__MODULE__{} = curr, %__MODULE__{} = prev ->
        %__MODULE__{
          chunk: prev.chunk <> " " <> curr.chunk,
          start_offset: prev.start_offset,
          stop_offset: curr.stop_offset
        }
      end)
    end)
    |> List.to_tuple()
  end

  defp split(char, [{start, stop, index, prev_whitespace} | tail] = acc) do
    index = index + 1
    curr_whitespace = String.trim(char) == ""

    case {prev_whitespace, curr_whitespace} do
      {false, false} -> [{start, stop + 1, index, curr_whitespace} | tail]
      {false, true} -> [{start, stop, index, curr_whitespace} | tail]
      {true, true} -> [{start, stop, index, curr_whitespace} | tail]
      {true, false} -> [{index - 1, index, index, curr_whitespace} | acc]
    end
  end
end
