require './app.rb'

namespace :tasks do 
	desc 'send info to slack'
	task :send_info_to_slack do
	  execute()
	end
end
