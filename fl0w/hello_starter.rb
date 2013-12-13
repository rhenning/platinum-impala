require_relative "utils"
require_relative "hello_workflow"

workflow_client = AWS::Flow.workflow_client(@swf.client, @domain) do
  { from_class: "HelloWorkflow" }
end

puts "Firing Workflow..."
e = workflow_client.start_execution("an argument string")
