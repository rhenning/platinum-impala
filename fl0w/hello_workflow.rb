require_relative "utils"
require_relative "hello_activity"

class HelloWorkflow
  extend AWS::Flow::Workflows

  FLOW_VERSION = "0.26"
  MAX_ASYNC_JOBS = 10
  MAX_ASYNC_TIME = 15

  workflow :simple_async_workflow do |opts|
    opts.version = FLOW_VERSION
    opts.task_list = $WORKFLOW_TASK_LIST
    opts.execution_start_to_close_timeout = 3600
  end

  def workflow_to_completion(args)
    puts "#{__method__}>> fired"
    hello_activities.true_activity(args)
    hello_activities.another_true_activity(args)
    puts "#{__method__}>> completed"
  end

  def workflow_with_false_activity(args)
    puts "#{__method__}>> fired"
    hello_activities.true_activity(args)
    hello_activities.false_activity(args)
    hello_activities.true_activity(args)
    puts "#{__method__}>> completed"
  end

  def workflow_with_timeout(args)
    puts "#{__method__}>> fired"
    hello_activities.true_activity(args)
    hello_activities.true_slow_activity(args)
    hello_activities.true_activity
    puts "#{__method__}>> completed"
  end

  def workflow_with_raise(args)
    puts "#{__method__}>> fired"
    hello_activities.true_activity(args)
    hello_activities.exceptional_activity(args)
    hello_activities.true_activity(args)
    puts "#{__method__}>> completed"
  end

  def simple_async_workflow(args)
    puts "#{__method__}>> fired"

    puts "#{__method__}>> send_sync: true_zzz_activity(#{args.inspect})"
    hello_activities.true_zzz_activity(args)

    zzz_times = [ 5, 7, 2, 13, 3, 11, 1 ]

    futures = zzz_times.collect do |zzz|
      puts "#{__method__}>> send_async: true_zzz_activity(#{zzz.inspect})"
      hello_activities.send_async(:true_zzz_activity, zzz)
    end

    puts "#{__method__}>> waiting for futures..."
    wait_for_all(futures)

    puts "#{__method__}>> send_sync: true_zzz_activity(#{args.inspect})"
    hello_activities.true_zzz_activity(args)

    puts "#{__method__}>> completed"
  end

  activity_client(:hello_activities) do
    { from_class: "HelloActivity" }
  end
end

workflow_worker = AWS::Flow::WorkflowWorker.new(
  @swf.client, @domain, $WORKFLOW_TASK_LIST, HelloWorkflow
)

if __FILE__ == $0
  STDOUT.sync = true
  puts "Starting the workflow worker..."
  workflow_worker.start
end
