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

require "ipaddr"
require "uri"

module Church4Christ
  class Configuration
    HELP_LINK_ID = "church4christ_corresponding_source"
    USER_TYPES = %w[user student teacher admin observer unenrolled].freeze
    DEFAULT_PRIMARY_COLOR = "#1d5c3a"
    DEFAULT_NAV_BACKGROUND_COLOR = "#143d29"
    NON_PUBLIC_SOURCE_NETWORKS = %w[
      0.0.0.0/8
      10.0.0.0/8
      100.64.0.0/10
      127.0.0.0/8
      169.254.0.0/16
      172.16.0.0/12
      192.0.0.0/24
      192.168.0.0/16
      198.18.0.0/15
      224.0.0.0/4
      240.0.0.0/4
      ::/128
      ::1/128
      fc00::/7
      fe80::/10
      ff00::/8
    ].map { |network| IPAddr.new(network) }.freeze
    LOCAL_SOURCE_HOSTNAME_SUFFIXES = %w[localhost local internal test invalid].freeze

    def initialize(environment: ENV)
      @environment = environment
    end

    def theme_variables
      primary = color("C4C_THEME_PRIMARY", DEFAULT_PRIMARY_COLOR)
      nav_background = color("C4C_THEME_NAV_BACKGROUND", DEFAULT_NAV_BACKGROUND_COLOR)

      {
        "ic-brand-primary" => primary,
        "ic-link-color" => primary,
        "ic-brand-button--primary-bgd" => primary,
        "ic-brand-global-nav-bgd" => nav_background,
        "ic-brand-global-nav-logo-bgd" => nav_background
      }
    end

    def corresponding_source_help_link
      {
        id: HELP_LINK_ID,
        type: "custom",
        text: "Church4Christ Learning — Source Code & License",
        subtext: "Corresponding Source under GNU AGPL v3. Canvas LMS is developed by Instructure, Inc.; Church4Christ Learning is not endorsed by Instructure, Inc.",
        url: corresponding_source_url,
        available_to: USER_TYPES,
        is_featured: true,
        is_new: false,
        feature_headline: "Church4Christ Learning source and license"
      }
    end

    # Creates a supported Canvas Theme Editor BrandConfig and uses Canvas's
    # account-level Help Links setting for the AGPL §13 source offer.
    def apply_to!(account)
      corresponding_source_url
      brand_config = account.create_brand_config!(variables: existing_theme_variables(account).merge(theme_variables))
      account.settings[:custom_help_links] = configured_help_links(account.settings[:custom_help_links])
      account.settings[:new_custom_help_links] = true
      account.save!
      brand_config.save_all_files!
      brand_config
    end

    private

    def corresponding_source_url
      value = @environment["C4C_CORRESPONDING_SOURCE_URL"].to_s.strip
      uri = URI.parse(value)
      return value if public_source_url?(uri)

      raise ArgumentError, "C4C_CORRESPONDING_SOURCE_URL must be a public HTTPS URL"
    rescue URI::InvalidURIError
      raise ArgumentError, "C4C_CORRESPONDING_SOURCE_URL must be a public HTTPS URL"
    end

    def public_source_url?(uri)
      uri.scheme == "https" && uri.userinfo.nil? && uri.fragment.nil? && public_source_host?(uri.hostname || uri.host)
    end

    def public_source_host?(host)
      return false if host.nil? || host.empty?

      normalized_host = host.downcase.delete_suffix(".")
      return false if local_source_hostname?(normalized_host)

      ip_address = IPAddr.new(normalized_host)
      NON_PUBLIC_SOURCE_NETWORKS.none? { |network| network.include?(ip_address) }
    rescue IPAddr::InvalidAddressError
      normalized_host.include?(".")
    end

    def local_source_hostname?(host)
      host == "localhost" || LOCAL_SOURCE_HOSTNAME_SUFFIXES.any? { |suffix| host.end_with?(".#{suffix}") }
    end

    def color(key, default)
      value = @environment.fetch(key, default).to_s.strip
      return value if value.match?(/\A#[0-9a-fA-F]{6}\z/)

      raise ArgumentError, "#{key} must be a six-digit hex color"
    end

    def existing_theme_variables(account)
      account.brand_config&.variables&.deep_dup || {}
    end

    def configured_help_links(existing_links)
      links = Array(existing_links).map { |link| link.with_indifferent_access.deep_dup }
      links.reject! { |link| link[:id].to_s == HELP_LINK_ID }
      links.each { |link| link[:is_featured] = false if link[:is_featured] }
      links << corresponding_source_help_link
    end
  end
end
