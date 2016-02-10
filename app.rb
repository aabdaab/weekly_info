require 'httparty'
require 'date'
require 'whenever'

def load_settings
	@user = "XXXXX"
	@slack_url = "XXXXXXXXXXXXXXXX"
	@url = "https://api.github.com/users/#{@user}/repos"
	@message = "Here's some information about your repos from the last week.\n"
	@repos_names = []
end

def list_repos
	repos = HTTParty.get(@url, :headers => {'User-Agent' => @user})
	repos = repos.parsed_response
		
	unless !repos.kind_of?(Array)
 		repos.each do |repo|
			@repos_names.push repo["name"]
		end
	end
	@message << "User @#{@user} has #{repos.count} repos.\n"
end
	
def get_repos_names
	@repos_names
end
	
def get_pulls
	repos = get_repos_names
	repos_pulls = []

	repos.each do |repo|
		repos_pulls.push({"name" => "#{repo}", "url" => "https://api.github.com/repos/#{@user}/#{repo}/pulls"})
	end

	repos_pulls.each do |repo_pulls|
		pulls = HTTParty.get(repo_pulls["url"], :headers => {'User-Agent' => @user})
		pulls = pulls.parsed_response

		filtered_pulls = pulls.find_all {|pull| (Date.today - Date.parse(pull["updated_at"])).to_i <= 7}
		open_pulls = filtered_pulls.find_all {|pull| pull['state'] == 'open'}.count
		closed_pulls = filtered_pulls.find_all {|pull| pull['state'] == 'closed'}.count

		@message << "In repository #{repo_pulls["name"]} there are #{open_pulls} open pull requests and #{closed_pulls} closed pull requests.\n"
	end

end

	
def get_issues
	repos = get_repos_names
	repos_issues = []

	repos.each do |repo|
		repos_issues.push({"name" => "#{repo}", "url" => "https://api.github.com/repos/#{@user}/#{repo}/issues"})
	end

	repos_issues.each do |repo_issues|
		issues = HTTParty.get(repo_issues["url"], :headers => {'User-Agent' => @user})
		issues = issues.parsed_response

		filtered_issues = issues.find_all {|issue| (Date.today - Date.parse(issue["updated_at"])).to_i <= 7}
		open_issues = filtered_issues.find_all {|issue| issue['state'] == 'open'}.count
		closed_issues = filtered_issues.find_all {|issue| issue['state'] == 'closed'}.count

		@message << "In repository #{repo_issues["name"]} there are #{open_issues} open issues and #{closed_issues} closed issues.\n"
	end
end

def get_commits
	repos = get_repos_names
	repos.each do |repo|
		commits = HTTParty.get("https://api.github.com/repos/#{@user}/#{repo}/commits", :headers => {'User-Agent' => @user})
		commits = commits.parsed_response
			
		commits_count = 0
			
		if commits.kind_of?(Array)
			filtered_commits = commits.find_all {|commit| (Date.today - Date.parse(commit["commit"]["author"]["date"])).to_i <= 7}
			commits_count = filtered_commits.count
		end

		@message << "In repository #{repo} there are #{commits_count} commits.\n"
	end
end

def get_commiters
	repos = get_repos_names
	commiters = {}

	repos.each do |repo|
		commits = HTTParty.get("https://api.github.com/repos/#{@user}/#{repo}/commits", :headers => {'User-Agent' => @user})
		commits = commits.parsed_response

		if commits.kind_of?(Array)
			filtered_commits = commits.find_all {|commit| (Date.today - Date.parse(commit["commit"]["author"]["date"])).to_i <= 7}
			filtered_commits.each do |commit|
				author = commit["author"]["login"]
				if commiters[author].nil?
					commiters[author] = 1
				else
					commiters[author] += 1
				end
			end			
		end
	end

	desc_commiters = commiters.sort_by {|author, commits| commits}.reverse
	desc_commiters.each do |commiter|
		@message << "Commiter @#{commiter[0]} has commited #{commiter[1]} commits.\n"	
	end
end

def post_message
	HTTParty.post(@slack_url, :body => {:text => @message}.to_json, :headers => { 'Content-Type' => 'application/json' })
end

def execute
	load_settings
	list_repos
	get_pulls
	get_issues
	get_commits
	get_commiters
	
	post_message
end
