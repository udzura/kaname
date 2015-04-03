require 'fog'
require 'thor'
require 'hashdiff'

module Kaname
  class CLI < Thor
    class_option :verbose, type: :boolean, aliases: "-V", default: false

    desc 'apply', 'Commands about configuration apply'
    def apply
      if Kaname::Resource.yaml
        begin
          accounts = File.open('accounts.csv', 'w+')
          Kaname::Resource.yaml.each do |user,h|
            id = begin
                   user = Kaname::Resource.users.find_by_name(user)
                   user.id
                 rescue Fog::Identity::OpenStack::NotFound
                   password = Kaname::Generator.password
                   accounts.write("#{user},#{password}¥n")
                   response = Fog::Identity[:openstack].create_user(user, password, h["email"])
                   response.data[:body]["user"]["id"]
                 end

            h["tenants"].each do |tenant, role|
              tenant = Kaname::Resource.tenants.find{|t| t.name == tenant}
              role = Kaname::Resource.roles.find{|r| r.name == role}
              Fog::Identity[:openstack].create_user_role(tenant.id, id, role.id)
            end
          ensure
            accounts.close
          end
        end
      else
        puts "Please put you keystone configuration file named keystone.yml to current directory."
      end
    end

    desc 'diff', 'Commands about show diffs from your openstack'
    def diff
      diff = HashDiff.diff(Kaname::Resource.users_hash, Kaname::Resource.yaml)
      p diff
    end
  end
end
