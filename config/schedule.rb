every :monday, at: "9:00am" do
  rake 'tasks:send_info_to_slack'
end