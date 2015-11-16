require 'spec_helper'
require 'brainstem/api_docs/abstract_collection'

module Brainstem
  module ApiDocs
    describe AbstractCollection do
      let(:member) { Object.new }


      describe "#last" do
        it "retrieves the last member"
      end


      describe "#<<" do
        it "adds a member to the collection" do
          subject << member
          expect(subject.count).to eq 1
        end
      end


      describe "#each" do
        it "iterates over each member"
      end


      describe "iteration" do
        before do
          subject << member
        end


        describe "#formatted" do
          it "maps all its members" do
            mock(member).formatted_as(:markdown, {}) { "blah" }
            expect(subject.formatted(:markdown)).to eq [ "blah" ]
          end

          it "passes options on to the formatter" do
            mock(member).formatted_as(:markdown, blah: true) { "blah" }
            subject.formatted(:markdown, blah: true)
          end
        end


        describe "#formatted_with_filename" do
          it "maps all its members and filenames" do
            mock(member).formatted_as(:markdown, {}) { "blah" }
            mock(member).suggested_filename(:markdown) { "member.markdown" }

            expect(subject.formatted_with_filename(:markdown)).to eq [ [ "blah", "member.markdown" ] ]
          end

          it "passes options on to the formatter" do
            mock(member).formatted_as(:markdown, blah: true) { "blah" }
            stub(member).suggested_filename(:markdown) { "member.markdown" }

            subject.formatted_with_filename(:markdown, blah: true)
          end
        end


        describe "#each_formatted" do
          it "maps all its controllers and yields each in turn" do
            mock(member).formatted_as(:markdown, {}) { "blah" }
            expect { |block| subject.each_formatted(:markdown, &block) }.to \
              yield_with_args("blah")
          end

          it "passes options on to the formatter" do
            mock(member).formatted_as(:markdown, blah: true) { "blah" }

            subject.each_formatted(:markdown, blah: true) {|_, _| nil }
          end
        end


        describe "#each_formatted_with_filename" do
          it "maps all its controllers and filenames and yields each in turn" do
            mock(member).formatted_as(:markdown, {}) { "blah" }
            mock(member).suggested_filename(:markdown) { "member.markdown" }

            expect { |block| subject.each_formatted_with_filename(:markdown, &block) }.to \
              yield_with_args("blah", "member.markdown")
          end

          it "passes options on to the formatter" do
            mock(member).formatted_as(:markdown, blah: true) { "blah" }
            stub(member).suggested_filename(:markdown) { "member.markdown" }

            subject.each_formatted_with_filename(:markdown, blah: true) {|_, _| nil }
          end
        end
      end


      describe ".with_members" do
        subject { described_class.with_members(member) }

        it "creates a new instance with passed members" do
          expect(subject).to be_a described_class
          expect(subject.send(:members)).to eq [ member ]
        end

      end


    end
  end
end