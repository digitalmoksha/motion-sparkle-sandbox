# frozen_string_literal: true

require_relative 'spec_utils'

describe 'motion-sparkle-sandbox package' do
  before do
    @config = App.config
    @config.sparkle = nil
    @config.project_dir = SpecUtils::TemporaryDirectory.directory.to_s
    @config.instance_eval do
      sparkle do
        release :base_url, 'http://example.com/'
        publish :package_filename, 'test.zip'
      end
    end

    @sparkle = @config.sparkle
    @sign_update = "#{@sparkle.vendored_sparkle_path}/bin/sign_update"

    allow(App).to receive(:info)
    allow(Open3).to receive(:capture2e).and_return(['', nil])
  end

  describe 'sign_package' do
    it 'signs with the default keychain account' do
      @sparkle.sign_package

      expect(Open3).to have_received(:capture2e)
        .with(@sign_update, '--account=ed25519', a_string_ending_with('/test.zip'))
    end

    it 'signs with a custom keychain account' do
      @sparkle.publish(:account, 'my.custom.account')
      @sparkle.sign_package

      expect(Open3).to have_received(:capture2e)
        .with(@sign_update, '--account=my.custom.account', a_string_ending_with('/test.zip'))
    end

    context 'with an exported private key' do
      before do
        FileUtils.mkdir_p(@sparkle.private_key_path.dirname)
        FileUtils.touch(@sparkle.private_key_path)
      end

      after do
        FileUtils.rm_f(@sparkle.private_key_path)
      end

      it 'signs with the private key file instead of the keychain account' do
        @sparkle.publish(:account, 'my.custom.account')
        @sparkle.publish(:use_exported_private_key, true)
        @sparkle.sign_package

        expect(Open3).to have_received(:capture2e)
          .with(@sign_update, "--ed-key-file=#{@sparkle.private_key_path}", a_string_ending_with('/test.zip'))
      end

      it 'uses the keychain account when use_exported_private_key is not set' do
        @sparkle.sign_package

        expect(Open3).to have_received(:capture2e)
          .with(@sign_update, '--account=ed25519', a_string_ending_with('/test.zip'))
      end
    end
  end
end
