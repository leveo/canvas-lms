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

require "delayed/testing"

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

  it "accepts canonical public DNS, IPv4, and IPv6 corresponding-source URLs" do
    [
      "https://source.example.org/church4christ/canvas",
      "https://8.8.8.8/church4christ/canvas",
      "https://[2001:4860:4860::8888]/church4christ/canvas"
    ].each do |public_url|
      environment["C4C_CORRESPONDING_SOURCE_URL"] = public_url

      expect(configuration.corresponding_source_help_link[:url]).to eq(public_url)
    end
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
      "https://127.1/source",
      "https://127.0.1/source",
      "https://0177.0.0.1/source",
      "https://0x7f.0.0.1/source",
      "https://2130706433/source",
      "https://0x7f000001/source",
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
    let(:persisted_brand_config) do
      instance_double(
        "BrandConfig",
        md5: "church4christ-theme",
        variables: existing_theme_variables.merge(configuration.theme_variables),
        save_unless_dup!: true,
        save_and_sync_to_s3!: true
      )
    end

    before do
      allow(account).to receive(:brand_config).and_return(existing_brand_config)
      allow(account).to receive(:brand_config_md5).and_return("church4christ-theme")
      allow(account).to receive(:help_links).and_return(existing_links)
      allow(account).to receive(:save!)
      allow(BrandConfig).to receive(:for).and_return(persisted_brand_config)
    end

    it "reuses the supported persisted BrandConfig and keeps one featured source link" do
      configuration.apply_to!(account)
      configuration.apply_to!(account)

      expect(persisted_brand_config.variables).to include(
        "ic-brand-font-color-dark" => "#273540",
        "ic-brand-primary" => "#1d5c3a",
        "ic-brand-global-nav-bgd" => "#143d29"
      )
      expect(persisted_brand_config).to have_received(:save_unless_dup!).twice
      expect(persisted_brand_config).to have_received(:save_and_sync_to_s3!).twice
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
      expect(BrandConfig).not_to have_received(:for)
      expect(account).not_to have_received(:save!)
    end
  end

  describe "#configured_help_links" do
    let(:stored_default_link) { { type: "default", id: :search_the_canvas_guides, text: "Canvas Guides" } }
    let(:account) do
      instance_double(
        "Account",
        help_links: [
          stored_default_link.merge(is_featured: true),
          { id: "other", text: "Other", is_featured: true },
          { id: described_class::HELP_LINK_ID, text: "Old source", url: "https://old.example.org", is_featured: true }
        ]
      )
    end

    it "normalizes effective default featured links before reserving the source-link slot" do
      expect(stored_default_link).not_to have_key(:is_featured)

      links = configuration.send(:configured_help_links, account)

      expect(links.count { |link| link[:id] == described_class::HELP_LINK_ID }).to eq(1)
      expect(links.find { |link| link[:id] == "other" }).to include(text: "Other", is_featured: false)
      expect(links.find { |link| link[:id] == :search_the_canvas_guides }).to include(is_featured: false)
      expect(links.count { |link| link[:is_featured] }).to eq(1)
    end
  end

  describe "#apply_to! with Canvas persistence" do
    let(:root_account) { account_model }
    let(:old_root_brand_config) { BrandConfig.for(variables: { "ic-brand-primary" => "#aa0000" }) }
    let(:child_account) { Account.create!(parent_account: root_account, name: "Church4Christ child") }
    let(:child_brand_config) do
      BrandConfig.for(
        variables: { "ic-brand-global-nav-bgd" => "#111111" },
        parent_md5: old_root_brand_config.md5
      )
    end

    before do
      old_root_brand_config.save!
      root_account.update!(brand_config: old_root_brand_config)
      child_brand_config.save!
      child_account.update!(brand_config: child_brand_config)
    end

    it "publishes a deduplicated root theme and regenerates branded descendants" do
      configuration.apply_to!(root_account)
      Delayed::Testing.drain

      applied_brand_config = root_account.reload.brand_config
      expect(applied_brand_config.variables).to include("ic-brand-primary" => "#1d5c3a")
      expect(child_account.reload.brand_config.parent).to eq(applied_brand_config)

      expect do
        configuration.apply_to!(root_account)
        Delayed::Testing.drain
      end.not_to change(BrandConfig, :count)
      expect(root_account.reload.brand_config).to eq(applied_brand_config)
    end
  end

  describe "#apply_to! asset publication" do
    let(:account) do
      instance_double(
        "Account",
        brand_config: instance_double("BrandConfig", variables: {}),
        brand_config_md5: "old-brand-config",
        help_links: [],
        settings: {}
      )
    end
    let(:brand_config) do
      instance_double(
        "BrandConfig",
        md5: "new-brand-config",
        save_unless_dup!: true
      )
    end

    before do
      allow(BrandConfig).to receive(:for).and_return(brand_config)
      allow(BrandConfigRegenerator).to receive(:process)
      allow(account).to receive(:save!)
      allow(brand_config).to receive(:save_and_sync_to_s3!).and_raise("asset publication failed")
    end

    it "does not activate a theme or update help links when asset publication fails" do
      expect { configuration.apply_to!(account) }.to raise_error("asset publication failed")

      expect(account).not_to have_received(:save!)
      expect(BrandConfigRegenerator).not_to have_received(:process)
    end
  end
end
