# frozen_string_literal: true

module Multiwoven
  module Integrations::Core
    class DestinationConnector < BaseConnector
      # Records are transformed json payload send it to the destination
      # SyncConfig is the Protocol::SyncConfig object
      def write(_sync_config, _records, _action = "destination_insert")
        raise "Not implemented"
        # return Protocol::TrackingMessage
      end
    end
  end
end
