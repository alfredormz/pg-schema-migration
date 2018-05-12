require 'pg'
require 'logger'

module PG
  module Schema
    @@migrations = []

    MigrationNotFoundError = Class.new(Exception)

    def self.migrations
      @@migrations
    end

    def self.migration(&block)
      MigrationDSL.new(&block).migration.tap do |migration|
        @@migrations << migration
      end
    end

    def self.get_migration_by_version(version)
      migration_position = version - 1

      raise MigrationNotFoundError, "can't find migration with version #{version}" unless @@migrations[migration_position]

      @@migrations[migration_position]
    end

    class Migration
      attr_accessor :up, :down

      def initialize
        @up   = []
        @down = []
      end
    end

    class MigrationDSL < BasicObject
      attr_reader :migration

      def initialize(&block)
        @migration = Migration.new
        instance_eval(&block)
      end

      def up(&block)
        @commands     = []
        @migration.up = block.call
      end

      def down(&block)
        @commands       = []
        @migration.down = block.call
      end

      def execute(command)
        @commands << command
      end
    end

    class Migrator
      attr_accessor :connection, :directory

      MIGRATION_FILE_REGEX = /^(\d+)_.+\.rb/i

      def initialize(db:, directory: nil, log: Logger.new(STDOUT))
        @db        = db
        @directory = directory
        @log       = log

        load_migration_files
        generate_schema_migration_table!
      end

      def run!(version: nil)
        migrations       = PG::Schema.migrations
        _current_version = current_version

        version||= migrations.count

        if version == _current_version || migrations.empty?
          @log.info "Nothing to do."
          return
        end

        t = Time.now
        @log.info "Migrationg from #{_current_version} to version #{version}"
        if version > _current_version
          (_current_version + 1).upto(version) do |target|
            apply(target, :up)
          end
        else
          (_current_version).downto(version + 1) do |target|
            apply(target, :down)
          end
        end

        @log.info "Finished applying migration #{version}, took #{sprintf('%0.6f', Time.now - t)} seconds"
        @log.info "Done!"
      end

      def apply(version, direction)
        migration = PG::Schema.get_migration_by_version(version)
        commands  = migration.public_send(direction)

        commands.reverse! if direction == :down

        @db.transaction do
          commands.each do |command|
            @db.exec(command)
          end
        end

        update_version(direction == :up ? version : version - 1)
      rescue => error
        @log.error error.message
        @log.info  "The migration failed. Current version #{current_version}"
        raise
      end

      def load_migration_files
        files = []

        if directory
          Dir.new(directory).sort.each do |file|
            next unless file.match(MIGRATION_FILE_REGEX)
            file = File.join(directory, file)
            files << file
            load(file)
          end
        end

        files
      end

      def generate_schema_migration_table!
        @db.exec <<~SQL
          CREATE TABLE IF NOT EXISTS schema_information (
            version INTEGER DEFAULT 0 NOT NULL
          )
        SQL

        if @db.exec("SELECT * FROM schema_information").ntuples.zero?
          @db.exec <<~SQL
            INSERT INTO schema_information DEFAULT VALUES
          SQL
        end
      end

      def update_version(version)
        @db.exec("UPDATE schema_information SET version = $1", [version])
      end

      def current_version
        res = @db.exec <<~SQL
          SELECT version FROM schema_information
        SQL

        raise "Schema information has multiple values" if res.ntuples > 1

        res.field_values("version").first.to_i
      end
    end
  end
end
