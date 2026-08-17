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

  it "accepts a public HTTPS corresponding-source URL" do
    expect(configuration.corresponding_source_help_link[:url]).to eq(source_url)
  end

  it "rejects non-public or non-HTTPS corresponding-source URLs" do
    invalid_urls = [
      "http://source.example.org/church4christ/canvas",
      "https://localhost/source",
      "https://app.localhost/source",
      "https://source.local/source",
      "https://source.internal/source",
      "https://127.0.0.1/source",
      "https://10.1.2.3/source",
      "https://172.16.1.2/source",
      "https://192.168.1.2/source",
      "https://169.254.1.2/source",
      "https://[::1]/source",
      "https://[fc00::1]/source",
      "https://[fe80::1]/source",
      "https://user:password@source.example.org/source",
      "https://source.example.org/source#fragment"
    ]

    invalid_urls.each do |invalid_url|
      environment["C4C_CORRESPONDING_SOURCE_URL"] = invalid_url

      expect { configuration.corresponding_source_help_link }
        .to raise_error(ArgumentError, /public HTTPS URL/), invalid_url
    end
  end

  describe "#apply_to!" do
    let(:existing_theme_variables) { { "ic-brand-font-color-dark" => "#273540" } }
    let(:existing_brand_config) { instance_double("BrandConfig", variables: existing_theme_variables) }
    let(:existing_links) do
      [
        { "id" => "support", "text" => "Support", "url" => "https://support.example.org", "is_featured" => true },
        { "id" => described_class::HELP_LINK_ID, "text" => "Old source", "url" => "https://old.example.org", "is_featured" => true }
      ]
    end
    let(:settings) { { custom_help_links: existing_links, new_custom_help_links: true } }
    let(:account) { instance_double("Account", settings: settings) }
    let(:created_brand_configs) { [] }

    before do
      current_brand_config = existing_brand_config
      allow(account).to receive(:brand_config) { current_brand_config }
      allow(account).to receive(:create_brand_config!) do |variables:|
        brand_config = instance_double("BrandConfig", variables: variables, md5: "church4christ-theme", save_all_files!: true)
        created_brand_configs << brand_config
        current_brand_config = brand_config
        brand_config
      end
      allow(account).to receive(:save!)
    end

    it "persists supported theme variables and one featured source link without replacing unrelated links" do
      configuration.apply_to!(account)
      configuration.apply_to!(account)

      expect(created_brand_configs.last.variables).to include(
        "ic-brand-font-color-dark" => "#273540",
        "ic-brand-primary" => "#1d5c3a",
        "ic-brand-global-nav-bgd" => "#143d29"
      )
      expect(created_brand_configs).to all(have_received(:save_all_files!))
      expect(account).to have_received(:save!).twice

      links = settings[:custom_help_links]
      expect(links.count { |link| link[:id] == described_class::HELP_LINK_ID }).to eq(1)
      expect(links.find { |link| link[:id] == "support" }).to include(text: "Support", url: "https://support.example.org")
      expect(links.count { |link| link[:is_featured] }).to eq(1)
      expect(links.find { |link| link[:id] == described_class::HELP_LINK_ID }).to include(url: source_url, is_featured: true)
    end

    it "does not mutate an account when the corresponding-source URL is invalid" do
      environment["C4C_CORRESPONDING_SOURCE_URL"] = "https://127.0.0.1/source"

      expect { configuration.apply_to!(account) }.to raise_error(ArgumentError, /public HTTPS URL/)
      expect(account).not_to have_received(:create_brand_config!)
      expect(account).not_to have_received(:save!)
    end
  end

  describe "#configured_help_links" do
    it "replaces only the previous source link and reserves the featured slot" do
      links = configuration.send(:configured_help_links, [
        { id: "other", text: "Other", is_featured: true },
        { id: described_class::HELP_LINK_ID, text: "Old source", url: "https://old.example.org", is_featured: true }
      ])

      expect(links.count { |link| link[:id] == described_class::HELP_LINK_ID }).to eq(1)
      expect(links.find { |link| link[:id] == "other" }).to include(text: "Other", is_featured: false)
      expect(links.count { |link| link[:is_featured] }).to eq(1)
    end
  end
end
