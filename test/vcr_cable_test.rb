require 'test_helper'

class VcrCableTest < ActiveSupport::TestCase
  setup { VcrCable.reset_config }

  test 'is disabled by default' do
    assert !VcrCable.enabled?
  end

  test 'is enabled when config enables it' do
    VcrCable.stubs(:config).returns({'enable_vcr_cable' => true})
    assert VcrCable.enabled?
  end

  test 'is not enabled when config disables it' do
    VcrCable.stubs(:config).returns({'enable_vcr_cable' => false})
    assert !VcrCable.enabled?
  end

  test 'is enabled when ENABLE_VCR_CABLE is present in ENV and set to true' do
    ENV['ENABLE_VCR_CABLE'] = 'true'
    assert VcrCable.enabled?
  end

  test 'is not enabled when ENABLE_VCR_CABLE is present in ENV and set to false' do
    ENV['ENABLE_VCR_CABLE'] = 'false'
    assert !VcrCable.enabled?
  end

  test 'erb is not enabled when config disables it' do
    VcrCable.stubs(:config).returns({'enable_erb' => false})
    assert !VcrCable.config['enable_erb']
  end

  test 'erb is enabled when config enables it' do
    VcrCable.stubs(:config).returns({'enable_erb' => true})
    assert VcrCable.config['enable_erb']
  end

  test 'allow_playback_repeats is not enabled when config disables it' do
    VcrCable.stubs(:config).returns({'allow_playback_repeats' => false})
    assert !VcrCable.config['allow_playback_repeats']
  end

  test 'allow_playback_repeats is enabled when config enables it' do
    VcrCable.stubs(:config).returns({'allow_playback_repeats' => true})
    assert VcrCable.config['allow_playback_repeats']
  end

  test 'match_requests_on default will set to uri' do
    VcrCable.stubs(:config).returns({'match_requests_on' => [:uri]})
    assert VcrCable.config['match_requests_on'] == [:uri]
  end

  test 'match_requests_on is overidden when config sets it' do
    VcrCable.stubs(:config).returns({'match_requests_on' => [:uri, :body]})
    assert VcrCable.config['match_requests_on'] == [:uri, :body]
  end

  test 'loads FakeWeb or WebMock based on which is installed' do
    VcrCable.stubs(:env).returns('development')
    assert_equal :fakeweb, VcrCable.config['hook_into']
  end

  test 'raises an error when no mocking library is available' do
    VcrCable.stubs(:env).returns('development')
    VcrCable.stubs(:gem_available?).returns(false)
    assert_raises(VcrCable::InvalidMockingLibraryError) { VcrCable.config['hook_into'] }
  end

  test 'has no config when the current env has no configuration' do
    assert !VcrCable.config.present?
  end

  test 'loads config from config/vcr_cable.yml over default values' do
    VcrCable.stubs(:env).returns('development')
    VcrCable.configure_vcr
    assert_match /custom_named_cassettes$/, VCR.configuration.cassette_library_dir
  end

  test 'loads default values when not specified in config/vcr_cable.yml' do
    VcrCable.stubs(:env).returns('development')
    VcrCable.configure_vcr
    assert VcrCable.config['allow_http_connections_when_no_cassette']
  end

  test 'adds VCR::Middleware::Rack to the middleware stack' do
    list = Dir.chdir(Rails.root) {`bundle exec rake middleware RAILS_ENV=development ENABLE_VCR_CABLE=true`}
    assert_match /VCR::Middleware::Rack/, list
  end

  test 'it does not add VCR::Middleware::Rack to environments that are not enabled' do
    assert !Rails.configuration.middleware.any? {|name| name == 'VCR::Middleware::Rack'}
  end
end
