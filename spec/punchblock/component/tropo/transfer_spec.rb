require 'spec_helper'

module Punchblock
  module Component
    module Tropo
      describe Transfer do
        it 'registers itself' do
          RayoNode.class_from_registration(:transfer, 'urn:xmpp:tropo:transfer:1').should == Transfer
        end

        describe 'when setting options in initializer' do
          subject do
            Transfer.new :to              => 'tel:+14045551212',
                         :from            => 'tel:+14155551212',
                         :terminator      => '*',
                         :timeout         => 120000,
                         :answer_on_media => true,
                         :media           => :direct,
                         :ring            => {:voice => 'allison', :text => "Welcome to Rayo", :url => "http://it.doesnt.matter.does.it/?"}
          end

          its(:to)              { should == %w{tel:+14045551212} }
          its(:from)            { should == 'tel:+14155551212' }
          its(:terminator)      { should == '*' }
          its(:timeout)         { should == 120000 }
          its(:answer_on_media) { should == true }
          its(:media)           { should == :direct }
          its(:ring)            { should == Transfer::Ring.new(:voice => 'allison', :text => "Welcome to Rayo", :url => "http://it.doesnt.matter.does.it/?") }
        end

        it_should_behave_like 'command_headers'
      end

      describe "actions" do
        let(:mock_client) { mock 'Client' }
        let(:command) { Transfer.new :to => 'tel:+14045551212', :from => 'tel:+14155551212' }

        before do
          command.component_id = 'abc123'
          command.call_id = '123abc'
          command.client = mock_client
        end

        describe '#stop_action' do
          subject { command.stop_action }

          its(:to_xml) { should == '<stop xmlns="urn:xmpp:rayo:1"/>' }
          its(:component_id) { should == 'abc123' }
          its(:call_id) { should == '123abc' }
        end

        describe '#stop!' do
          describe "when the command is executing" do
            before do
              command.request!
              command.execute!
            end

            it "should send its command properly" do
              mock_client.expects(:execute_command).with(command.stop_action, :call_id => '123abc', :component_id => 'abc123')
              command.stop!
            end
          end

          describe "when the command is not executing" do
            it "should raise an error" do
              lambda { command.stop! }.should raise_error(InvalidActionError, "Cannot stop a Transfer that is not executing")
            end
          end
        end
      end

      describe Transfer::Complete::Success do
        let :stanza do
          <<-MESSAGE
<complete xmlns='urn:xmpp:rayo:ext:1'>
  <success xmlns='urn:xmpp:tropo:transfer:complete:1' />
</complete>
          MESSAGE
        end

        subject { RayoNode.import(parse_stanza(stanza).root).reason }

        it { should be_instance_of Transfer::Complete::Success }

        its(:name) { should == :success }
      end

      describe Transfer::Complete::Timeout do
        let :stanza do
          <<-MESSAGE
<complete xmlns='urn:xmpp:rayo:ext:1'>
  <timeout xmlns='urn:xmpp:tropo:transfer:complete:1' />
</complete>
          MESSAGE
        end

        subject { RayoNode.import(parse_stanza(stanza).root).reason }

        it { should be_instance_of Transfer::Complete::Timeout }

        its(:name) { should == :timeout }
      end

      describe Transfer::Complete::Terminator do
        let :stanza do
          <<-MESSAGE
<complete xmlns='urn:xmpp:rayo:ext:1'>
  <terminator xmlns='urn:xmpp:tropo:transfer:complete:1' />
</complete>
          MESSAGE
        end

        subject { RayoNode.import(parse_stanza(stanza).root).reason }

        it { should be_instance_of Transfer::Complete::Terminator }

        its(:name) { should == :terminator }
      end

      describe Transfer::Complete::Busy do
        let :stanza do
          <<-MESSAGE
<complete xmlns='urn:xmpp:rayo:ext:1'>
  <busy xmlns='urn:xmpp:tropo:transfer:complete:1' />
</complete>
          MESSAGE
        end

        subject { RayoNode.import(parse_stanza(stanza).root).reason }

        it { should be_instance_of Transfer::Complete::Busy }

        its(:name) { should == :busy }
      end

      describe Transfer::Complete::Reject do
        let :stanza do
          <<-MESSAGE
<complete xmlns='urn:xmpp:rayo:ext:1'>
  <reject xmlns='urn:xmpp:tropo:transfer:complete:1' />
</complete>
          MESSAGE
        end

        subject { RayoNode.import(parse_stanza(stanza).root).reason }

        it { should be_instance_of Transfer::Complete::Reject }

        its(:name) { should == :reject }
      end
    end
  end
end # Punchblock
