require_relative "utils"
require_relative "hello_workflow"

workflow_client = AWS::Flow.workflow_client(@swf.client, @domain) do
  { from_class: "HelloWorkflow" }
end


if __FILE__ == $0
  STDOUT.sync = true
  puts "Firing Workflow..."
  workflow_client.start_execution("just an argument string")
end
