# frozen_string_literal: true

module Multiwoven::Integrations::Source
  module AmazonS3
    include Multiwoven::Integrations::Core
    class Client < SourceConnector
      DISCOVER_QUERY = "SELECT * FROM S3Object LIMIT 1;"

      def check_connection(connection_config)
        connection_config = connection_config.with_indifferent_access
        client = config_aws(connection_config)
        client.get_bucket_policy_status({ bucket: connection_config[:bucket] })
        ConnectionStatus.new(status: ConnectionStatusType["succeeded"]).to_multiwoven_message
      rescue StandardError => e
        ConnectionStatus.new(status: ConnectionStatusType["failed"], message: e.message).to_multiwoven_message
      end

      def discover(connection_config)
        connection_config = connection_config.with_indifferent_access
        conn = create_connection(connection_config)
        # If pulling from multiple files, all files must have the same schema
        path = build_path(connection_config[:path])
        full_path = "s3://#{connection_config[:bucket]}/#{path}*.#{connection_config[:file_type]}"
        records = get_results(conn, "DESCRIBE SELECT * FROM '#{full_path}';")
        columns = build_discover_columns(records)
        streams = [Multiwoven::Integrations::Protocol::Stream.new(name: full_path, action: StreamAction["fetch"], json_schema: convert_to_json_schema(columns))]
        catalog = Catalog.new(streams: streams)
        catalog.to_multiwoven_message
      rescue StandardError => e
        handle_exception(e, { context: "AMAZONS3:DISCOVER:EXCEPTION", type: "error" })
      end

      def read(sync_config)
        connection_config = sync_config.source.connection_specification.with_indifferent_access
        conn = create_connection(connection_config)
        query = sync_config.model.query
        query = batched_query(query, sync_config.limit, sync_config.offset) unless sync_config.limit.nil? && sync_config.offset.nil?
        query(conn, query)
      rescue StandardError => e
        handle_exception(e, {
                           context: "AMAZONS3:READ:EXCEPTION",
                           type: "error",
                           sync_id: sync_config.sync_id,
                           sync_run_id: sync_config.sync_run_id
                         })
      end

      private

      # DuckDB
      def create_connection(connection_config)
        conn = DuckDB::Database.open.connect
        # Set up S3 configuration
        secret_query = "
              CREATE SECRET amazons3_source (
              TYPE S3,
              KEY_ID '#{connection_config[:access_id]}',
              SECRET '#{connection_config[:secret_access]}',
              REGION '#{connection_config[:region]}'
          );
        "
        get_results(conn, secret_query)
        conn
      end

      def build_path(path)
        path = "#{path}/" if !path.to_s.strip.empty? && path[-1] != "/"
        path
      end

      def get_results(conn, query)
        results = conn.query(query)
        hash_array_values(results)
      end

      def query(conn, query)
        records = get_results(conn, query)
        records.map do |row|
          RecordMessage.new(data: row, emitted_at: Time.now.to_i).to_multiwoven_message
        end
      end

      def hash_array_values(describe)
        keys = describe.columns.map(&:name)
        describe.map do |row|
          Hash[keys.zip(row)]
        end
      end

      def build_discover_columns(describe_results)
        describe_results.map do |row|
          type = column_schema_helper(row["column_type"])
          {
            column_name: row["column_name"],
            type: type
          }
        end
      end

      def column_schema_helper(column_type)
        case column_type
        when "VARCHAR", "BIT", "DATE", "TIME", "TIMESTAMP", "UUID"
          "string"
        when "DOUBLE"
          "number"
        when "BIGINT", "HUGEINT", "INTEGER", "SMALLINT"
          "integer"
        when "BOOLEAN"
          "boolean"
        end
      end

      # AWS SDK
      def config_aws(config)
        config = config.with_indifferent_access
        Aws.config.update({
                            region: config[:region],
                            credentials: Aws::Credentials.new(config[:access_id], config[:secret_access])
                          })
        config.with_indifferent_access
        Aws::S3::Client.new
      end

      def build_select_content_options(config, query)
        config = config.with_indifferent_access
        bucket_name = config[:bucket]
        file_key = config[:file_key]
        file_type = config[:file_type]
        options = {
          bucket: bucket_name,
          key: file_key,
          expression_type: "SQL",
          expression: query,
          output_serialization: {
            json: {}
          }
        }
        if file_type == "parquet"
          options[:input_serialization] = {
            parquet: {}
          }
        elsif file_type == "csv"
          options[:input_serialization] = {
            csv: { file_header_info: "USE" }
          }
        end
        options
      end
    end
  end
end
