require 'pony'

class Notifier

  def initialize()
    @last_mail_time = Time.at(0)
    @messages = []

    Thread.new do
      while true do
        # Sleep 24 hours
        sleep 86400
        # Then send status update
        send_mail('LogWatcher on server ' + $server_name + '/' + $log_file_name, 'Still running...')
      end
    end
  end

  def on_error(message)
    @messages << message
    # Send an email if at least 15 minutes have passed
    if (Time.now - @last_mail_time > 900)
      send_mail('Errors on server ' + $server_name + '/' + $log_file_name, @messages.join("\n"))
      @messages.clear
    end
  end

  def send_mail(subject, body)
    Pony.mail({
                  :to => 'RECIPIENT EMAIL ADDRESS',
                  :subject => subject,
                  :body => body,
                  :via => :smtp,
                  :via_options => {
                      :address => 'smtp.gmail.com',
                      :port => '587',
                      :enable_starttls_auto => true,
                      :user_name => 'SET USERNAME HERE',
                      :password => 'SET PASSWORD HERE',
                      :authentication => :plain, # :plain, :login, :cram_md5, no auth by default
                      :domain => "localhost.localdomain" # the HELO domain provided by the client to the server
                  }
              })

    @last_mail_time = Time.now
  end

end

notifier = Notifier.new

trigger "Errno" do |line, match|
  notifier.on_error(line)
end

trigger "Error" do |line, match|
  notifier.on_error(line)
end

trigger "error" do |line, match|
  notifier.on_error(line)
end

trigger "Exception" do |line, match|
  notifier.on_error(line)
end
