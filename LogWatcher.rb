require 'file/tail'

class LogWatcher

  def initialize(filename)
    @filename = filename
    @triggers = []
  end

  # Add a new Trigger
  def add_trigger(trigger)
    @triggers << trigger
  end

  # Read the log file passed in.
  # Check each line for a trigger match.
  def watch
    File::Tail::Logfile.open(@filename, :backward => 0) do |log|
      log.tail do |line|
        @triggers.each do |m|
          m.match line
        end
      end
    end
  end

end

class Trigger

  # Create a new Trigger with a regex and a block
  def initialize(regex, block)
    @regex = Regexp.new regex
    @block = block
  end

  def match(line)
    m = @regex.match(line)
    begin
      @block.call(line, m) if m != nil
    rescue => e
      puts "#{e.backtrace}: #{e.message} (#{e.class})"
    end
  end
end

def trigger(regex, &block)
  if block_given?
    $log_watcher.add_trigger Trigger.new(regex, block)
  else
    $log_watcher.add_trigger Trigger.new(regex, lambda { |l, m| puts "Found: #{l}" })
  end
end

# Parse command line options

if ARGV.length != 2
  puts "Missing argument. Usage: #$0 SERVERNAME FILENAME"
  exit 0
end

$server_name = ARGV.shift
$log_file_name = ARGV.shift

# Load triggers and start watching

$log_watcher = LogWatcher.new($log_file_name)

load('LogWatcherCfg.rb')

$log_watcher.watch
