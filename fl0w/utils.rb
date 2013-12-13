require "aws/decider"

$DOMAIN_NAME = "RichsTestDomain"
$WORKFLOW_TASK_LIST = "RichsTestWorkflowTaskList"
$ACTIVITY_TASK_LIST = "RichsTestActivityTaskList"

# AWS creds come out of the usual env vars
@swf = AWS::SimpleWorkflow.new

begin
  @domain = @swf.domains[$DOMAIN_NAME]
  @domain.status
rescue AWS::SimpleWorkflow::Errors::UnknownResourceFault => e
                                              # retention period, days
  @domain = @swf.domains.create($DOMAIN_NAME, 10)
end
