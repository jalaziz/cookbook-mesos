# encoding: utf-8

require 'spec_helper'

describe 'mesos::master' do
  include_context 'setup context'

  shared_examples_for 'a master recipe' do
    it 'creates masters file in deploy directory' do
      expect(chef_run).to create_template '/usr/local/var/mesos/deploy/masters'
    end

    it 'creates slaves file in deploy directory' do
      expect(chef_run).to create_template '/usr/local/var/mesos/deploy/slaves'
    end

    it 'creates deploy env template' do
      expect(chef_run).to create_template '/usr/local/var/mesos/deploy/mesos-deploy-env.sh'
    end

    it 'creates mesos master env template' do
      expect(chef_run).to create_template '/usr/local/var/mesos/deploy/mesos-master-env.sh'
    end
  end

  context 'when installed from mesosphere' do
    let :chef_run do
      ChefSpec::Runner.new do |node|
        node.set[:mesos][:type] = 'mesosphere'
        node.set[:mesos][:master][:zk] = 'zk-string'
        node.set[:mesos][:mesosphere][:with_zookeeper] = true
      end.converge(described_recipe)
    end

    it_behaves_like 'an installation from mesosphere'
    it_behaves_like 'a master recipe'

    context '/etc/mesos/zk' do
      it 'creates it' do
        expect(chef_run).to create_template '/etc/mesos/zk'
      end

      it 'contains configured zk string' do
        expect(chef_run).to render_file('/etc/mesos/zk').with_content(/^zk-string$/)
      end
    end

    context '/etc/default/mesos' do
      it 'creates it' do
        expect(chef_run).to create_template('/etc/default/mesos')
      end

      it 'contains LOGS variable' do
        expect(chef_run).to render_file('/etc/default/mesos').with_content(/^LOGS=\/var\/log\/mesos$/)
      end

      it 'contains ULIMIT variable' do
        expect(chef_run).to render_file('/etc/default/mesos').with_content(/^ULIMIT="-n 8192"$/)
      end
    end

    context '/etc/default/mesos-master' do
      it 'creates it' do
        expect(chef_run).to create_template '/etc/default/mesos-master'
      end

      it 'contains PORT variable' do
        expect(chef_run).to render_file('/etc/default/mesos-master')
          .with_content(/^PORT=5050$/)
      end

      it 'contains ZK variable' do
        expect(chef_run).to render_file('/etc/default/mesos-master')
          .with_content(/^ZK=`cat \/etc\/mesos\/zk`$/)
      end
    end

    it 'creates /etc/mesos-master' do
      expect(chef_run).to create_directory '/etc/mesos-master'
    end

    it 'runs a cleanup of /etc/mesos-master/*' do
      expect(chef_run).to run_bash('cleanup /etc/mesos-master/')
    end

    describe 'configuration options in /etc/mesos-master' do
      pending
    end

    it 'restart mesos-master service' do
      expect(chef_run).to restart_service('mesos-master')
    end
  end

  context 'when installed from source' do
    let :chef_run do
      ChefSpec::Runner.new do |node|
        node.set[:mesos][:type] = 'source'
        node.set[:mesos][:mesosphere][:with_zookeeper] = true
      end.converge(described_recipe)
    end

    it_behaves_like 'an installation from source'
    it_behaves_like 'a master recipe'
  end
end
