require 'spec_helper'

module Punchblock
  module Component
    module Tropo
      describe Ask do
        it 'registers itself' do
          RayoNode.class_from_registration(:ask, 'urn:xmpp:tropo:ask:1').should == Ask
        end

        describe "when setting options in initializer" do
          subject do
            Ask.new :choices        => {:value => '[5 DIGITS]', :content_type => 'application/grammar+custom'},
                    :prompt         => {:text => 'Please enter your postal code.', :voice => 'kate'},
                    :bargein        => true,
                    :min_confidence => 0.3,
                    :mode           => :speech,
                    :recognizer     => 'en-US',
                    :terminator     => '#',
                    :timeout        => 12000
          end


          its(:choices)         { should == Ask::Choices.new(:value => '[5 DIGITS]', :content_type => 'application/grammar+custom') }
          its(:prompt)          { should == Ask::Prompt.new(:voice => 'kate', :text => 'Please enter your postal code.') }
          its(:bargein)         { should == true }
          its(:min_confidence)  { should == 0.3 }
          its(:mode)            { should == :speech }
          its(:recognizer)      { should == 'en-US' }
          its(:terminator)      { should == '#' }
          its(:timeout)         { should == 12000 }
        end

        describe Ask::Choices do
          describe "when not passing a grammar" do
            subject { Ask::Choices.new :value => '[5 DIGITS]' }
            its(:content_type) { should == 'application/grammar+grxml' }
          end

          describe 'with a simple grammar' do
            subject { Ask::Choices.new :value => '[5 DIGITS]', :content_type => 'application/grammar+custom' }

            let(:expected_message) { "<![CDATA[ [5 DIGITS] ]]>" }

            it "should wrap grammar in CDATA" do
              subject.child.to_xml.should == expected_message.strip
            end
          end

          describe 'with a GRXML grammar' do
            subject { Ask::Choices.new :value => grxml, :content_type => 'application/grammar+grxml' }

            let :grxml do
              <<-GRXML
<grammar xmlns="http://www.w3.org/2001/06/grammar" root="MAINRULE">
  <rule id="MAINRULE">
    <one-of>
      <item>
        <item repeat="0-1"> need a</item>
        <item repeat="0-1"> i need a</item>
          <one-of>
            <item> clue </item>
          </one-of>
        <tag> out.concept = "clue";</tag>
      </item>
      <item>
        <item repeat="0-1"> have an</item>
        <item repeat="0-1"> i have an</item>
          <one-of>
            <item> answer </item>
          </one-of>
        <tag> out.concept = "answer";</tag>
      </item>
    </one-of>
  </rule>
</grammar>
              GRXML
            end

            let(:expected_message) { "<![CDATA[ #{grxml} ]]>" }

            it "should wrap GRXML in CDATA" do
              subject.child.to_xml.should == expected_message.strip
            end
          end
        end

        describe "actions" do
          let(:mock_client) { mock 'Client' }
          let(:command) { Ask.new :choices => '[5 DIGITS]' }

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
                lambda { command.stop! }.should raise_error(InvalidActionError, "Cannot stop a Ask that is not executing")
              end
            end
          end
        end

        describe Ask::Complete::Success do
          let :stanza do
            <<-MESSAGE
<complete xmlns='urn:xmpp:rayo:ext:1'>
  <success mode="speech" confidence="0.45" xmlns='urn:xmpp:tropo:ask:complete:1'>
    <interpretation>1234</interpretation>
    <utterance>one two three four</utterance>
  </success>
</complete>
            MESSAGE
          end

          subject { RayoNode.import(parse_stanza(stanza).root).reason }

          it { should be_instance_of Ask::Complete::Success }

          its(:name)            { should == :success }
          its(:mode)            { should == :speech }
          its(:confidence)      { should == 0.45 }
          its(:interpretation)  { should == '1234' }
          its(:utterance)       { should == 'one two three four' }
        end

        describe Ask::Complete::NoMatch do
          let :stanza do
            <<-MESSAGE
<complete xmlns='urn:xmpp:rayo:ext:1'>
  <nomatch xmlns='urn:xmpp:tropo:ask:complete:1' />
</complete>
            MESSAGE
          end

          subject { RayoNode.import(parse_stanza(stanza).root).reason }

          it { should be_instance_of Ask::Complete::NoMatch }

          its(:name) { should == :nomatch }
        end

        describe Ask::Complete::NoInput do
          let :stanza do
            <<-MESSAGE
<complete xmlns='urn:xmpp:rayo:ext:1'>
  <noinput xmlns='urn:xmpp:tropo:ask:complete:1' />
</complete>
            MESSAGE
          end

          subject { RayoNode.import(parse_stanza(stanza).root).reason }

          it { should be_instance_of Ask::Complete::NoInput }

          its(:name) { should == :noinput }
        end
      end
    end
  end
end # Punchblock
