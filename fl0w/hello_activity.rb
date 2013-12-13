require_relative "utils"

class HelloActivity
  extend AWS::Flow::Activities

  FLOW_VERSION = "0.23"
  TASK_TIMEOUT = 30
  ZZZ_TIME = 45

  random_activities = 10.times.collect { |i| "true_random_activity_#{i}".to_sym }  

  my_activities = :true_activity,
                  :another_true_activity,
                  :false_activity,
                  :true_slow_activity,
                  :false_slow_activity,
                  :exceptional_activity,
                  *random_activities

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

  random_activities.each do |meth|
    define_method meth do |args|
      puts "#{__method__}>> fired"
      puts "#{__method__}>> allotted runtime #{TASK_TIMEOUT}"
      puts "#{__method__}>> args: #{args.inspect}"
      puts "#{__method__}>> sleeping for #{args}s"
      sleep args
      true
    end
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
)

if __FILE__ == $0
  STDOUT.sync = true
  puts "Starting the activity worker..."
  activity_worker.start
end
