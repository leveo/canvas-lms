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

require_relative "../church4christ/configuration"

namespace :church4christ do
  desc "Apply the Church4Christ Theme Editor theme and AGPL source Help link to a root account"
  task configure: :environment do
    account = if ENV["C4C_ROOT_ACCOUNT_ID"].present?
                Account.find(ENV.fetch("C4C_ROOT_ACCOUNT_ID"))
              else
                Account.default
              end

    raise ArgumentError, "C4C_ROOT_ACCOUNT_ID must identify a root account" unless account.root_account?

    brand_config = Church4Christ::Configuration.new.apply_to!(account)
    puts "Configured Church4Christ theme and source link for root account #{account.id} (#{brand_config.md5})."
  end
end
