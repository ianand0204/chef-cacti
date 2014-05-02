settings = Cacti.settings(node)

if node['platform_family'] == 'debian'
  group node['cacti']['group'] do
    action :create
  end

  user node['cacti']['user'] do
    action :create
    system true
    gid node['cacti']['group']
  end
end



template node['cacti']['db_file'] do
  source 'db.php.erb'
  owner node['cacti']['user']
  group node['cacti']['group']
  mode 00640
  variables(
    :database => settings['database']
  )
end
