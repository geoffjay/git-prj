# frozen_string_literal: true

RSpec.describe Prj do
  it 'has a version number' do
    expect(Prj::VERSION).not_to be nil
  end
end
