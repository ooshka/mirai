# frozen_string_literal: true

require_relative "../app/services/patch_parser"

RSpec.describe PatchParser do
  let(:parser) { described_class.new }

  it "parses a valid single-file unified diff into structured hunks" do
    patch = <<~'PATCH'
      --- a/notes/today.md
      +++ b/notes/today.md
      @@ -1 +1 @@
      -alpha
      \ No newline at end of file
      +beta
      \ No newline at end of file
    PATCH

    result = parser.parse(patch)

    expect(result[:path]).to eq("notes/today.md")
    expect(result[:hunks]).to eq(
      [
        {
          old_start: 1,
          old_count: 1,
          new_start: 1,
          new_count: 1,
          raw_lines: [
            "-alpha",
            "\\ No newline at end of file",
            "+beta",
            "\\ No newline at end of file"
          ]
        }
      ]
    )
  end

  it "rejects malformed patch headers" do
    expect { parser.parse("bad patch") }
      .to raise_error(PatchParser::ParseError, "invalid patch header")
  end

  it "rejects malformed hunk headers" do
    patch = <<~PATCH
      --- a/notes/today.md
      +++ b/notes/today.md
      @@ bad @@
      -alpha
      +beta
    PATCH

    expect { parser.parse(patch) }
      .to raise_error(PatchParser::ParseError, "invalid hunk header")
  end
end
