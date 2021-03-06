require 'spec_helper'
require 'howitzer/web/page_validator'
require 'howitzer/web/element_dsl'

RSpec.describe Howitzer::Web::PageValidator do
  describe '.validations' do
    it { expect(subject.validations).to be_a(Hash) }
  end

  let(:web_page_class) do
    Class.new do
      include Howitzer::Web::ElementDsl
      include Howitzer::Web::PageValidator
      def self.name
        'TestWebPageClass'
      end
    end
  end
  let(:web_page) { web_page_class.new }
  describe '#check_validations_are_defined!' do
    subject { web_page.check_validations_are_defined! }
    context 'when no validation specified' do
      it do
        expect { subject }.to raise_error(
          Howitzer::NoValidationError,
          "No any page validation was found for 'TestWebPageClass' page"
        )
      end
    end
    context 'when title validation is specified' do
      before do
        web_page.class.validate :title, /Foo/
      end
      it { expect { subject }.to_not raise_error }
    end
    context 'when url validation is specified' do
      before do
        web_page.class.validate :url, /Foo/
      end
      it { expect { subject }.to_not raise_error }
    end
    context 'when element_presence validation is specified' do
      context 'when simple selector' do
        before do
          web_page.class.validate :element_presence, :test_locator
        end
        it { expect { subject }.to_not raise_error }
      end

      context 'when lambda selector' do
        before do
          web_page.class.validate :element_presence, :test_locator, 'some_text'
        end
        it { expect { subject }.to_not raise_error }
      end
    end
  end

  describe '.validate' do
    before do
      described_class.validations[web_page.class] = nil
    end
    let(:additional_value) { nil }
    subject { web_page.class.validate(name, *[value, additional_value].compact) }
    context 'when name = :url' do
      context 'as string' do
        let(:name) { 'url' }
        context '(as string)' do
          let(:value) { /foo/ }
          it do
            is_expected.to be_a(Proc)
            expect(described_class.validations[web_page.class][:url]).to be_a Proc
          end
        end
        context '(as symbol)' do
          let(:value) { /foo/ }
          it do
            is_expected.to be_a(Proc)
            expect(described_class.validations[web_page.class][:url]).to be_a Proc
          end
        end
      end
      context 'as symbol' do
        let(:name) { :url }
        let(:value) { /foo/ }
        it do
          is_expected.to be_a(Proc)
          expect(described_class.validations[web_page.class][:url]).to be_a Proc
        end
      end
    end
    context 'when name = :element_presence' do
      let(:name) { :element_presence }
      context '(as string)' do
        let(:value) { 'test_locator' }
        let(:additional_value) { 'some string' }
        it do
          is_expected.to be_a(Proc)
          expect(described_class.validations[web_page.class][:element_presence]).to eql(subject)
        end
      end
      context '(as symbol)' do
        let(:value) { :test_locator }
        it do
          is_expected.to be_a(Proc)
          expect(described_class.validations[web_page.class][:element_presence]).to eql(subject)
        end
      end
    end
    context 'when name = :title' do
      let(:name) { :title }
      context '(as string)' do
        let(:value) { /foo/ }
        it do
          is_expected.to be_a(Proc)
          expect(described_class.validations[web_page.class][:title]).to be_a Proc
        end
      end
      context '(as symbol)' do
        let(:value) { /foo/ }
        it do
          is_expected.to be_a(Proc)
          expect(described_class.validations[web_page.class][:title]).to be_a Proc
        end
      end
    end
    context 'when other name' do
      let(:name) { :unknown }
      let(:value) { '' }
      it do
        expect { subject }.to raise_error(Howitzer::UnknownValidationError, "unknown 'unknown' validation type")
      end
    end
  end

  describe '.opened?' do
    context 'when no one validation is defined' do
      subject { web_page_class.opened? }
      it do
        expect { subject }.to raise_error(
          Howitzer::NoValidationError,
          "No any page validation was found for 'TestWebPageClass' page"
        )
      end
    end
    context 'when all validations are defined' do
      context 'when sync is default' do
        subject { web_page_class.opened? }
        before do
          web_page_class.class_eval do
            include Singleton
            element :login, '#id'
            validate :url, /foo/
            validate :title, /Foo page/
            validate :element_presence, :login
          end
        end
        context 'when all matches' do
          before do
            allow(web_page_class.instance).to receive(:current_url) { 'http://test.com/foo' }
            allow(web_page_class.instance).to receive(:has_title?) { 'Foo page' }
            allow(web_page_class.instance).to receive(:has_login_element?).with(no_args) { true }
          end
          it { is_expected.to be_truthy }
        end
        context 'when first validation fails' do
          before do
            expect(web_page_class.instance).to receive(:current_url).once { 'http://test.com/bar' }
            expect(web_page_class.instance).to receive(:has_title?).never
            allow(web_page_class).to receive(:has_login_element?).with(no_args).never
          end
          it { is_expected.to be_falsey }
        end
      end

      context 'when sync is true' do
        subject { web_page_class.opened?(sync: true) }
        before do
          web_page_class.class_eval do
            include Singleton
            element :login, '#id'
            validate :url, /foo/
            validate :title, /Foo page/
            validate :element_presence, :login
          end
        end
        context 'when all matches' do
          before do
            allow(web_page_class.instance).to receive(:current_url) { 'http://test.com/foo' }
            allow(web_page_class.instance).to receive(:has_title?) { 'Foo page' }
            allow(web_page_class.instance).to receive(:has_login_element?).with(no_args) { true }
          end
          it { is_expected.to be_truthy }
        end
        context 'when first validation fails' do
          before do
            expect(web_page_class.instance).to receive(:current_url).once { 'http://test.com/bar' }
            expect(web_page_class.instance).to receive(:has_title?).never
            allow(web_page_class).to receive(:has_login_element?).with(no_args).never
          end
          it { is_expected.to be_falsey }
        end
      end

      context 'when sync is false' do
        subject { web_page_class.opened?(sync: false) }
        before do
          web_page_class.class_eval do
            include Singleton
            element :login, '#id'
            validate :url, /foo/
            validate :title, /Foo page/
            validate :element_presence, :login
          end
        end
        context 'when all matches' do
          before do
            allow(web_page_class.instance).to receive(:current_url) { 'http://test.com/foo' }
            allow(web_page_class.instance).to receive(:title) { 'Foo page' }
            allow(web_page_class.instance).to receive(:has_no_login_element?).with(no_args) { false }
          end
          it { is_expected.to be_truthy }
        end
        context 'when first validation fails' do
          before do
            expect(web_page_class.instance).to receive(:current_url).once { 'http://test.com/bar' }
            expect(web_page_class.instance).to receive(:title).never
            allow(web_page_class).to receive(:has_no_login_element?).with(no_args).never
          end
          it { is_expected.to be_falsey }
        end
      end
    end
  end

  describe 'web_page.validations' do
    it { expect(web_page_class.validations).to be_a(Hash) }
  end

  describe '#matched_pages' do
    let!(:web_page1_class) do
      Class.new do
        include Howitzer::Web::PageValidator
      end
    end
    let!(:web_page2_class) do
      Class.new do
        include Howitzer::Web::PageValidator
      end
    end
    subject { web_page2_class.matched_pages }
    before do
      allow(Howitzer::Web::PageValidator).to receive(:validations).with(no_args) do
        { web_page1_class => 1, web_page2_class => 2 }
      end
      expect(web_page1_class).to receive(:opened?).with(sync: false) { true }
      expect(web_page2_class).to receive(:opened?).with(sync: false) { false }
    end
    it { is_expected.to eq([web_page1_class]) }
  end
end
