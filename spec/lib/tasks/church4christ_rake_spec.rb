# frozen_string_literal: true

#
# Copyright (C) 2026 Church4Christ contributors
#
# This file is part of Church4Christ Learning — Canvas Edition.
#
# Church4Christ Learning — Canvas Edition is a modified version of Canvas LMS,
# developed by Instructure, Inc., and is licensed under the GNU Affero General
# Public License, version 3. See LICENSE and CHURCH4CHRIST_NOTICE.md.
#

describe "church4christ:configure" do
  before do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
    Rake::Task["church4christ:configure"].reenable
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("C4C_ROOT_ACCOUNT_ID").and_return(nil)
  end

  after { Rake::Task["church4christ:configure"].reenable }

  let(:task) { Rake::Task["church4christ:configure"] }
  let(:account) { instance_double("Account", id: 42, root_account?: true) }
  let(:brand_config) { instance_double("BrandConfig", md5: "church4christ-theme") }
  let(:configuration) { instance_double(Church4Christ::Configuration, apply_to!: brand_config) }

  it "uses the default root account and the supported configuration service" do
    allow(Account).to receive(:default).and_return(account)
    allow(Church4Christ::Configuration).to receive(:new).and_return(configuration)

    expect { task.invoke }
      .to output(/Configured Church4Christ theme and source link for root account 42/).to_stdout
    expect(configuration).to have_received(:apply_to!).with(account)
  end

  it "rejects a non-root account before applying configuration" do
    allow(Account).to receive(:default).and_return(instance_double("Account", root_account?: false))

    expect { task.invoke }.to raise_error(ArgumentError, /must identify a root account/)
  end

  it "rejects an invalid source URL before mutating the root account" do
    invalid_configuration = Church4Christ::Configuration.new(
      environment: { "C4C_CORRESPONDING_SOURCE_URL" => "https://127.0.0.1/source" }
    )
    allow(Account).to receive(:default).and_return(account)
    allow(Church4Christ::Configuration).to receive(:new).and_return(invalid_configuration)

    expect { task.invoke }.to raise_error(ArgumentError, /public HTTPS URL/)
  end
end
