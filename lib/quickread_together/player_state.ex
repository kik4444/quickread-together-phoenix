defmodule QuickreadTogether.PlayerState do
  @moduledoc false

  alias QuickreadTogether.TextChunk

  @derive {Inspect, except: [:parsed_text]}
  defstruct raw_text: "Welcome to Quickread Together. Press play to begin reading quickly.",
            playing: false,
            textarea_locked: false,
            words_per_minute: 300,
            chunk_size: 1,
            parsed_text: {%TextChunk{}},
            current_index: 0,
            # Derived from words_per_minute and chunk_size,
            # but kept separate to avoid re-calculating it
            speed: 200
end
