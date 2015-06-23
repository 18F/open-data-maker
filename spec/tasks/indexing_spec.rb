require 'spec_helper'
require 'bundler/setup'
require 'padrino-core/cli/rake'

describe 'elastic search index management tasks' do
  before do
    PadrinoTasks.init
    ENV['DATA_PATH'] = nil
  end

  it { expect { Rake::Task['delete:all'].invoke }.not_to raise_exception }
  it { expect { Rake::Task['import'].invoke }.not_to raise_exception }

end
