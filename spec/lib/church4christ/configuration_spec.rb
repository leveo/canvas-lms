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

describe Church4Christ::Configuration do
  let(:source_url) { "https://source.example.org/church4christ/canvas" }
  let(:environment) do
    {
      "C4C_CORRESPONDING_SOURCE_URL" => source_url,
      "C4C_THEME_PRIMARY" => "#1d5c3a",
      "C4C_THEME_NAV_BACKGROUND" => "#143d29"
    }
  end

  subject(:configuration) { described_class.new(environment: environment) }

  it "builds supported theme variables and a prominent all-user source link" do
    expect(configuration.theme_variables).to include(
      "ic-brand-primary" => "#1d5c3a",
      "ic-brand-global-nav-bgd" => "#143d29"
    )

    expect(configuration.corresponding_source_help_link).to include(
      id: "church4christ_corresponding_source",
      type: "custom",
      text: "Church4Christ Learning — Source Code & License",
      url: source_url,
      available_to: %w[user student teacher admin observer unenrolled],
      is_featured: true
    )
    expect(configuration.corresponding_source_help_link[:subtext]).to include("GNU AGPL v3", "Instructure, Inc.", "not endorsed")
  end

  it "rejects a missing corresponding-source URL" do
    environment.delete("C4C_CORRESPONDING_SOURCE_URL")

    expect { configuration }.to raise_error(ArgumentError, /C4C_CORRESPONDING_SOURCE_URL/)
  end
end
