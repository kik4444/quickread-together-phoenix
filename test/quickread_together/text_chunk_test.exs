defmodule QuickreadTogether.TextChunkTest do
  use ExUnit.Case
  alias QuickreadTogether.TextChunk

  test "empty input" do
    assert TextChunk.parse("", 1) == [%TextChunk{}]
  end

  test "only whitespace" do
    assert TextChunk.parse("  \n\n\n  　\n") == [%TextChunk{}]
  end

  test "one chunk" do
    assert TextChunk.parse(~s(Welcome to "Quick Reader". Press start to begin reading quickly.)) ==
             [
               %TextChunk{
                 chunk: "Welcome",
                 start_offset: 0,
                 stop_offset: 7
               },
               %TextChunk{
                 chunk: "to",
                 start_offset: 8,
                 stop_offset: 10
               },
               %TextChunk{
                 chunk: "\"Quick",
                 start_offset: 11,
                 stop_offset: 17
               },
               %TextChunk{
                 chunk: "Reader\".",
                 start_offset: 18,
                 stop_offset: 26
               },
               %TextChunk{
                 chunk: "Press",
                 start_offset: 27,
                 stop_offset: 32
               },
               %TextChunk{
                 chunk: "start",
                 start_offset: 33,
                 stop_offset: 38
               },
               %TextChunk{
                 chunk: "to",
                 start_offset: 39,
                 stop_offset: 41
               },
               %TextChunk{
                 chunk: "begin",
                 start_offset: 42,
                 stop_offset: 47
               },
               %TextChunk{
                 chunk: "reading",
                 start_offset: 48,
                 stop_offset: 55
               },
               %TextChunk{
                 chunk: "quickly.",
                 start_offset: 56,
                 stop_offset: 64
               }
             ]
  end

  test "two chunks" do
    parsed =
      TextChunk.parse(
        ~s(Welcome to "Quick Reader". Press start to begin reading quickly.),
        2
      )

    assert parsed == [
             %TextChunk{
               chunk: "Welcome to",
               start_offset: 0,
               stop_offset: 10
             },
             %TextChunk{
               chunk: "\"Quick Reader\".",
               start_offset: 11,
               stop_offset: 26
             },
             %TextChunk{
               chunk: "Press start",
               start_offset: 27,
               stop_offset: 38
             },
             %TextChunk{
               chunk: "to begin",
               start_offset: 39,
               stop_offset: 47
             },
             %TextChunk{
               chunk: "reading quickly.",
               start_offset: 48,
               stop_offset: 64
             }
           ]
  end

  test "mixed unicode" do
    assert TextChunk.parse("こんにちは world и　皆さん") == [
             %TextChunk{
               chunk: "こんにちは",
               start_offset: 0,
               stop_offset: 5
             },
             %TextChunk{
               chunk: "world",
               start_offset: 6,
               stop_offset: 11
             },
             %TextChunk{
               chunk: "и",
               start_offset: 12,
               stop_offset: 13
             },
             %TextChunk{
               chunk: "皆さん",
               start_offset: 14,
               stop_offset: 17
             }
           ]
  end

  test "two-chunk mixed unicode" do
    assert TextChunk.parse("こんにちは world и　皆さん", 2) == [
             %TextChunk{
               chunk: "こんにちは world",
               start_offset: 0,
               stop_offset: 11
             },
             %TextChunk{
               chunk: "и 皆さん",
               start_offset: 12,
               stop_offset: 17
             }
           ]
  end

  test "three-chunk mixed unicode" do
    assert TextChunk.parse("こんにちは world и　皆さん", 3) == [
             %TextChunk{
               chunk: "こんにちは world и",
               start_offset: 0,
               stop_offset: 13
             },
             %TextChunk{
               chunk: "皆さん",
               start_offset: 14,
               stop_offset: 17
             }
           ]
  end

  test "unicode with newlines" do
    assert TextChunk.parse("こんにちは world и　皆さん\n\n and ! everyone else") == [
             %TextChunk{
               chunk: "こんにちは",
               start_offset: 0,
               stop_offset: 5
             },
             %TextChunk{
               chunk: "world",
               start_offset: 6,
               stop_offset: 11
             },
             %TextChunk{
               chunk: "и",
               start_offset: 12,
               stop_offset: 13
             },
             %TextChunk{
               chunk: "皆さん",
               start_offset: 14,
               stop_offset: 17
             },
             %TextChunk{
               chunk: "and",
               start_offset: 20,
               stop_offset: 23
             },
             %TextChunk{
               chunk: "!",
               start_offset: 24,
               stop_offset: 25
             },
             %TextChunk{
               chunk: "everyone",
               start_offset: 26,
               stop_offset: 34
             },
             %TextChunk{
               chunk: "else",
               start_offset: 35,
               stop_offset: 39
             }
           ]
  end
end
