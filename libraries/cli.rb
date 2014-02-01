require 'chef/mixin/shell_out'

module Cacti
  module Cli
    # wrapper to add_device.php
    # @returns true if device is added, false if device already exists, exception otherwise
    def add_device(params)
      command = %Q[#{cli_path}/add_device.php]
      command << params

      match = /This host already exists in the database \(.*?\) device-id: \(.*\)/
      run_cmd_with_match(command, match)
    end

    # wrapper to add_graphs.php
    # @returns true if graph is added, false if graph already exists, exception otherwise
    def add_graphs(params)
      command = %Q[#{cli_path}/add_graphs.php]
      command << params

      match = /NOTE: Not Adding Graph - this graph already exists - graph-id: \(.*?\) - data-source-id: \(.*?\)/
      run_cmd_with_match(command, match)
    end

    # wrapper to add_tree.php
    # @returns true if tree is added, false if tree already exists, exception otherwise
    def add_tree(params)
      command = %Q[#{cli_path}/add_tree.php]
      command << params

      match = /ERROR: Not adding tree - it already exists - tree-id: \(.*?\)/
      run_cmd_with_match(command, match)
    end

    # resolve template id from template name
    def get_device_template_id(template)
      return template if template.kind_of?(Integer)
      command = "#{cli_path}/add_device.php --list-host-templates"
      get_id_from_output(command, template) or fail "Failed to Find template_id for #{template}"
    end

    # resolve host id from host name
    def get_host_id(host)
      return host if host.kind_of?(Integer)
      command = "#{cli_path}/add_graphs.php --list-hosts"
      get_id_from_output(command, host, 3) or fail "Failed to Find host_id for #{host}"
    end

    # resolve graph template_id from template name
    # TODO: host specific list support
    def get_graph_template_id(template)
      return template if template.kind_of?(Integer)
      command = "#{cli_path}/add_graphs.php --list-graph-templates"
      get_id_from_output(command, template) or fail "Failed to Find template_id for #{template}"
    end

    # param: snmp_query_id or snmp_query_name
    # TODO: be host specific to catch errors early
    def get_snmp_query(snmp_query_id)
      return snmp_query_id if snmp_query_id.kind_of?(Integer)
      command = "#{cli_path}/add_graphs.php --list-snmp-queries"
      get_id_from_output(command, snmp_query_id) or fail "Failed to get snmp_query_id #{snmp_query_id}"
    end

    # get snmp_query_type_id for query_id matching param
    def get_snmp_query_type(query_id, param)
      return param if param.kind_of?(Integer)
      command = "#{cli_path}/add_graphs.php --snmp-query-id=#{query_id} --list-query-types"
      get_id_from_output(command, param)
    end

    # get tree id
    def get_tree_id(tree_id)
      return tree_id if tree_id.kind_of?(Integer)
      command = "#{cli_path}/add_tree.php --list-trees"
      get_id_from_output(command, tree_id, 2)
    end

    # get node id in a tree
    def get_tree_node_id(tree_id, node_id)
      return node_id if node_id.kind_of?(Integer)
      command = "#{cli_path}/add_tree.php --tree-id=#{tree_id} --list-nodes"
      get_id_from_output(command, node_id, 3, 1) or fail "Failed to get tree node_id for #{node_id} in #{tree_id}"
    end

    # get RRA id
    def get_rra_id(rra_id)
      return rra_id if rra_id.kind_of?(Integer)
      command = "#{cli_path}/add_tree.php --list-rras"
      get_id_from_output(command, rra_id, 5) or fail "Failed to get rra_id for '#{rra_id}'"
    end

    # get Graph id for host_id
    def get_graph_id(host_id, graph_id, index = 1)
      return graph_id if graph_id.kind_of?(Integer)
      command = "#{cli_path}/add_tree.php --host-id=#{host_id} --list-graphs"
      get_id_from_output(command, graph_id, index) or fail "Failed to get graph_id of '#{graph_id}' for host '#{host_id}'"
    end

    # return true if device named 'device' exists
    def device_exists?(device)
      begin
        get_host_id(device)
        return true
      rescue
        return false
      end
    end

    def graph_exists?(host, graph)
      begin
        get_graph_id(host, graph, 2)
        return true
      rescue => e
        return false
      end
    end

    def tree_exists?(tree)
      false
    end

    # flatten Hash of key=value pairs for --input-fields parameter
    # [--input-fields="[data-template-id:]field-name=value ..."]
    def flatten_fields(fields)
      res = ''
      fields.each do |k, v|
        res << %Q[#{k}="#{v}" ]
      end

      res.chop
    end

    private

    # get match for id from typical --list-something
    # first line is ignored, as it's header
    # offset is column where to match a string
    def get_id_from_output(command, match, offset = 1, column = 0)
      shell_out(command).stdout.split(/\n/).drop(1).map do |t|
        l = t.split(/\t/)
        return l[column] if l[offset] == match
      end
      nil
    end

    # run command
    # return true if exit 0, return false if exit 1 and has a match, throw otherwise
    def run_cmd_with_match(command, match)
      cmd = shell_out(command)
      if cmd.exitstatus == 0
        return true
      elsif cmd.exitstatus == 1
        return false if cmd.stdout.match(match)
      end

      fail "rc: #{cmd.exitstatus}, stdout: #{cmd.stdout}, stderr: #{cmd.stderr}"
    end

    # path to directory where cli tools are
    def cli_path
      "#{node['cacti']['cacti_dir']}/cli"
    end
  end
end
