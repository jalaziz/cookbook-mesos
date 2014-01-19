# encoding: utf-8

require 'spec_helper'

describe 'mesos::slave' do
  include_context 'setup context'

  shared_examples_for 'a slave recipe' do
    it 'creates deploy env template' do
      expect(chef_run).to create_template '/usr/local/var/mesos/deploy/mesos-deploy-env.sh'
    end

    it 'creates mesos slave env template' do
      expect(chef_run).to create_template '/usr/local/var/mesos/deploy/mesos-slave-env.sh'
    end
  end

  context 'when installed from mesosphere' do
    let :chef_run do
      ChefSpec::Runner.new do |node|
        node.set[:mesos][:type] = 'mesosphere'
        node.set[:mesos][:slave][:master] = 'test-master'
        node.set[:mesos][:mesosphere][:with_zookeeper] = true
      end.converge(described_recipe)
    end

    it_behaves_like 'an installation from mesosphere'
    it_behaves_like 'a slave recipe'

    context '/etc/mesos/zk' do
      it 'creates it' do
        expect(chef_run).to create_template '/etc/mesos/zk'
      end

      it 'contains configured zk string' do
        expect(chef_run).to render_file('/etc/mesos/zk').with_content(/^test-master$/)
      end
    end

    describe '/etc/default/mesos-slave' do
      it 'creates it' do
        expect(chef_run).to create_template '/etc/default/mesos-slave'
      end

      it 'contains MASTER variable' do
        expect(chef_run).to render_file('/etc/default/mesos-slave')
          .with_content(/^MASTER=`cat \/etc\/mesos\/zk`$/)
      end

      it 'contains ISOLATION variable' do
        expect(chef_run).to render_file('/etc/default/mesos-slave')
          .with_content(/^ISOLATION=cgroups$/)
      end
    end

    it 'creates /etc/mesos-slave' do
      expect(chef_run).to create_directory '/etc/mesos-slave'
    end

    it 'run a bash cleanup script' do
      expect(chef_run).to run_bash('cleanup /etc/mesos-slave/')
    end

    context 'configuration options in /etc/mesos-slave' do
      pending
    end

    it 'restarts mesos-slave service' do
      expect(chef_run).to restart_service 'mesos-slave'
    end
  end

  context 'when installed from source' do
    let :chef_run do
      ChefSpec::Runner.new do |node|
        node.set[:mesos][:type] = 'source'
        node.set[:mesos][:slave][:master] = 'test-master'
      end.converge(described_recipe)
    end

    it_behaves_like 'an installation from source'
    it_behaves_like 'a slave recipe'
  end
end
