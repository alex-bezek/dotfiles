# See https://docs.getchef.com/config_rb_knife.html for more information on knife configuration options

current_dir = File.dirname(__FILE__)
log_level                :info
log_location             STDOUT
node_name                'as027811'
client_key               "#{current_dir}/as027811.pem"
validation_client_name   'main-validator'
validation_key           "#{current_dir}/main-validator.pem"
chef_server_url          'https://chef.devcerner.com/organizations/main'
cookbook_path            ["#{current_dir}/../cookbooks"]
