require_relative "utils"

class HelloActivity
  extend AWS::Flow::Activities

  FLOW_VERSION = "0.26"
  TASK_TIMEOUT = 60
  ZZZ_TIME = 120

  my_activities = :true_activity,
                  :another_true_activity,
                  :false_activity,
                  :true_zzz_activity,
                  :true_slow_activity,
                  :false_slow_activity,
                  :exceptional_activity

  activity *my_activities do |opts|
    opts.version = FLOW_VERSION
    opts.default_task_list = $ACTIVITY_TASK_LIST
    opts.default_task_schedule_to_start_timeout = 300
    opts.default_task_start_to_close_timeout = TASK_TIMEOUT
  end

  # activity :some_other_activity_with_different_opts do |opts|
  #   etc...
  # end

  def true_activity(args)
    puts "#{__method__}>> fired"
    puts "#{__method__}>> allotted runtime #{TASK_TIMEOUT}"
    puts "#{__method__}>> args: #{args.inspect}"
    true
  end

  def another_true_activity(args)
    puts "#{__method__}>> fired"
    puts "#{__method__}>> allotted runtime #{TASK_TIMEOUT}"
    puts "#{__method__}>> args: #{args.inspect}"
    true
  end

  def false_activity(args)
    puts "#{__method__}>> fired"
    puts "#{__method__}>> allotted runtime #{TASK_TIMEOUT}"
    puts "#{__method__}>> args: #{args.inspect}"
    false
  end

  def true_zzz_activity(args)
    puts "#{__method__}>> fired"
    puts "#{__method__}>> allotted runtime #{TASK_TIMEOUT}"
    puts "#{__method__}>> args: #{args.inspect}"
    puts "#{__method__}>> sleeping for #{args}s"
    sleep args
    true
  end

  def true_slow_activity(args)
    puts "#{__method__}>> fired"
    puts "#{__method__}>> allotted runtime #{TASK_TIMEOUT}"
    puts "#{__method__}>> args: #{args.inspect}"
    puts "#{__method__}>> sleeping for #{ZZZ_TIME}s"
    sleep ZZZ_TIME
    true
  end

  def false_slow_activity(args)
    puts "#{__method__}>> fired"
    puts "#{__method__}>> allotted runtime #{TASK_TIMEOUT}"
    puts "#{__method__}>> args: #{args.inspect}"
    puts "#{__method__}>> sleeping for #{ZZZ_TIME}s"
    sleep ZZZ_TIME
    false
  end

  def exceptional_activity(args)
    puts "#{__method__}>> fired"
    puts "#{__method__}>> allotted runtime #{TASK_TIMEOUT}"
    puts "#{__method__}>> args: #{args.inspect}"
    puts "#{__method__}>> throwing an exception"
    raise "kablooey!"
    true
  end
end

activity_worker = AWS::Flow::ActivityWorker.new(
  @swf.client, @domain, $ACTIVITY_TASK_LIST, HelloActivity
) do |opts|
  opts.use_forking = false
end

if __FILE__ == $0
  STDOUT.sync = true
  puts "Starting the activity worker..."
  activity_worker.start
end
