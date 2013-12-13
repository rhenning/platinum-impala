require_relative "utils"
require_relative "hello_activity"

class HelloWorkflow
  extend AWS::Flow::Workflows

  FLOW_VERSION = "0.23"
  MAX_ASYNC_JOBS = 10
  MAX_ASYNC_TIME = 15

  workflow :async_workflow_to_completion do |opts|
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

  ### i thought something like this would work, but it causes a race and blows up.
  ### best i can tell,  it's getting confused about running parallel copies of the
  ### same activity.  this has real use cases...what if a subactivity has some un-
  ### known number of similar parts that can be processed in parallel?
  #
  # futures = rand(1..MAX_ASYNC_JOBS).times.collect do
  #   hello_activities.send_async(:true_random_activity, rand(1..MAX_ASYNC_TIME))
  # end

  ### a more elaborate but still broken version w/ err handling
  #
  # futures = []
  # rand(1..MAX_ASYNC_JOBS).times do
  #   error_handler do |t|
  #     t.begin do
  #       futures << hello_activities.send_async(:true_random_activity, rand(1..MAX_ASYNC_TIME))
  #     end
  #     t.rescue Exception do |e|
  #       puts "Caught exception #{e.class}: #{e.message}"
  #       puts e.backtrace.inspect
  #     end
  #     t.ensure do
  #       #cleanup
  #     end
  #   end
  # end

  ### backtrace from aforementioned issue for reference:

  # 01:28:30 workflow_worker.1 | async_workflow_to_completion>> fired
  # 01:28:30 workflow_worker.1 | /Users/rhenning/.rbenv/versions/1.9.3-p125/lib/ruby/gems/1.9.1/gems/aws-flow-1.0.5/lib/aws/decider/async_decider.rb:378:in `handle_activity_task_scheduled': undefined method `consume' for nil:NilClass (NoMethodError)
  # 01:28:30 workflow_worker.1 |  from /Users/rhenning/.rbenv/versions/1.9.3-p125/lib/ruby/gems/1.9.1/gems/aws-flow-1.0.5/lib/aws/decider/async_decider.rb:654:in `process_event'
  # 01:28:30 workflow_worker.1 |  from /Users/rhenning/.rbenv/versions/1.9.3-p125/lib/ruby/gems/1.9.1/gems/aws-flow-1.0.5/lib/aws/decider/async_decider.rb:252:in `block in decide_impl'
  # 01:28:30 workflow_worker.1 |  from /Users/rhenning/.rbenv/versions/1.9.3-p125/lib/ruby/gems/1.9.1/gems/aws-flow-1.0.5/lib/aws/decider/async_decider.rb:248:in `each'
  # 01:28:30 workflow_worker.1 |  from /Users/rhenning/.rbenv/versions/1.9.3-p125/lib/ruby/gems/1.9.1/gems/aws-flow-1.0.5/lib/aws/decider/async_decider.rb:248:in `decide_impl'
  # 01:28:30 workflow_worker.1 |  from /Users/rhenning/.rbenv/versions/1.9.3-p125/lib/ruby/gems/1.9.1/gems/aws-flow-1.0.5/lib/aws/decider/async_decider.rb:226:in `decide'
  # 01:28:30 workflow_worker.1 |  from /Users/rhenning/.rbenv/versions/1.9.3-p125/lib/ruby/gems/1.9.1/gems/aws-flow-1.0.5/lib/aws/decider/task_handler.rb:47:in `handle_decision_task'
  # 01:28:30 workflow_worker.1 |  from /Users/rhenning/.rbenv/versions/1.9.3-p125/lib/ruby/gems/1.9.1/gems/aws-flow-1.0.5/lib/aws/decider/task_poller.rb:65:in `poll_and_process_single_task'
  # 01:28:30 workflow_worker.1 |  from /Users/rhenning/.rbenv/versions/1.9.3-p125/lib/ruby/gems/1.9.1/gems/aws-flow-1.0.5/lib/aws/decider/worker.rb:199:in `run_once'
  # 01:28:30 workflow_worker.1 |  from /Users/rhenning/.rbenv/versions/1.9.3-p125/lib/ruby/gems/1.9.1/gems/aws-flow-1.0.5/lib/aws/decider/worker.rb:185:in `block in start'
  # 01:28:30 workflow_worker.1 |  from /Users/rhenning/.rbenv/versions/1.9.3-p125/lib/ruby/gems/1.9.1/gems/aws-flow-1.0.5/lib/aws/decider/worker.rb:184:in `loop'
  # 01:28:30 workflow_worker.1 |  from /Users/rhenning/.rbenv/versions/1.9.3-p125/lib/ruby/gems/1.9.1/gems/aws-flow-1.0.5/lib/aws/decider/worker.rb:184:in `start'
  # 01:28:30 workflow_worker.1 |  from hello_workflow.rb:66:in `<main>'
  # 01:28:30 workflow_worker.1 | exited with code 1

  def async_workflow_to_completion(args)
    puts "#{__method__}>> fired"
    hello_activities.true_activity(args)

    futures = MAX_ASYNC_JOBS.times.collect do |i|
      puts "#{__method__}>> send_async: true_random_activity_#{i}"
      hello_activities.send_async("true_random_activity_#{i}".to_sym, rand(1..MAX_ASYNC_TIME))
    end

    wait_for_all(futures)
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
