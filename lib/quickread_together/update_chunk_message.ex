defmodule QuickreadTogether.UpdateChunkMsg do
  @moduledoc """
  Used to easily encapsulate messages from the Player to ReaderLive to update chunks.
  """

  alias QuickreadTogether.TextChunk

  defstruct text_chunk: %TextChunk{},
            index: 0,
            duration: "",
            focus: false
end
