# frozen_string_literal: true

require "tmpdir"
require "fileutils"
require_relative "../../../app/services/mcp/workflow_draft_patch_action"

RSpec.describe Mcp::WorkflowDraftPatchAction do
  it "returns edit intent with a mutation-free dry-run trace" do
    Dir.mktmpdir("notes-root") do |notes_root|
      FileUtils.mkdir_p(File.join(notes_root, "notes"))
      File.write(File.join(notes_root, "notes/today.md"), "alpha\n")

      drafter = instance_double("Llm::WorkflowPatchDrafter")
      expect(drafter).to receive(:draft_patch).with(
        instruction: "add beta",
        path: "notes/today.md",
        content: "alpha\n",
        context: {"source" => "planner"}
      ).and_return(
        {
          path: "notes/today.md",
          operation: "replace_content",
          content: "alpha\nbeta\n"
        }
      )

      action = described_class.new(
        notes_root: notes_root,
        drafter: drafter,
        trace_metadata: {provider: "openai", model: "gpt-4.1-mini"}
      )

      expect(
        action.call(
          instruction: "add beta",
          path: "notes/today.md",
          context: {"source" => "planner"}
        )
      ).to eq(
        {
          edit_intent: {
            path: "notes/today.md",
            operation: "replace_content",
            content: "alpha\nbeta\n"
          },
          trace: {
            provider: "openai",
            model: "gpt-4.1-mini",
            target: {
              path: "notes/today.md",
              content_bytes: 6
            },
            context: {"source" => "planner"},
            validation: {
              status: "valid",
              path: "notes/today.md",
              hunk_count: 1,
              net_line_delta: 1
            },
            apply_ready: true,
            audit: {
              patch: <<~PATCH
                --- a/notes/today.md
                +++ b/notes/today.md
                @@ -1,1 +1,2 @@
                -alpha
                +alpha
                +beta
              PATCH
            }
          }
        }
      )

      expect(File.read(File.join(notes_root, "notes/today.md"))).to eq("alpha\n")
    end
  end
end
