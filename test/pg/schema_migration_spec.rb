require 'minitest/autorun'
require_relative '../../lib/pg/schema-migration'

describe "PG::Schema" do
  before do
    PG::Schema.migrations.clear
  end

  describe "PG::Schema.migrations" do
    it "returns an empty migrations array" do
      assert_equal [], PG::Schema.migrations
    end

    it "should include migration instances created by migration DSL" do
      migration = PG::Schema.migration {}

      assert_equal PG::Schema::Migration, migration.class
      assert_equal [migration],           PG::Schema.migrations
    end

    it "should return migrations in order of creation" do
      i1 = PG::Schema.migration {}
      i2 = PG::Schema.migration {}
      i3 = PG::Schema.migration {}

      assert_equal [i1, i2, i3], PG::Schema.migrations
    end

    it "should get a singular migration by the version number" do
      i1 = PG::Schema.migration {}
      i2 = PG::Schema.migration {}
      i3 = PG::Schema.migration {}

      assert_equal i1, PG::Schema.get_migration_by_version(1)
      assert_equal i2, PG::Schema.get_migration_by_version(2)
      assert_equal i3, PG::Schema.get_migration_by_version(3)

      assert_raises PG::Schema::MigrationNotFoundError do
        PG::Schema.get_migration_by_version(4)
      end
    end
  end

  describe "DSL" do
    it "should have default up and down that do nothing" do
      m = PG::Schema.migration {}

      assert_equal [], m.up
      assert_equal [], m.down
    end

    it "should create migration with up and down commands" do
      PG::Schema.migration do
        up do
          execute "SQL sentence #1"
          execute "SQL sentence #2"
        end

        down do
          execute "Revert SQL sentence #1"
          execute "Revert SQL sentence #2"
        end
      end

      migration = PG::Schema.migrations.first

      assert_equal(
        [
          "SQL sentence #1",
          "SQL sentence #2",
        ],
        migration.up,
      )

      assert_equal(
        [
          "Revert SQL sentence #1",
          "Revert SQL sentence #2",
        ],
        migration.down,
      )
    end
  end

  describe "PG::Schema::Migrator" do
    before do
      @conn = PG.connect(ENV['DATABASE_URL'])

      # Disable PostgreSQL notice messages
      @conn.set_notice_receiver {}

      @conn.exec("DROP TABLE IF EXISTS schema_information")
      @conn.exec("DROP TABLE IF EXISTS users")
      @conn.exec("DROP TABLE IF EXISTS films")

      @migrator = PG::Schema::Migrator.new(
        db:        @conn,
        directory: 'test/db/migrations',
        log:       Logger.new('/dev/null'),
      )
    end

    it "should find and sort the migration files" do
      assert_equal(
        [
          "test/db/migrations/001_create_table_users.rb",
          "test/db/migrations/002_create_table_films.rb",
          "test/db/migrations/015_empty_migration.rb",
        ],
        @migrator.load_migration_files,
      )
    end

    it "should have '0' as current version" do
      assert_equal 0, @migrator.current_version
    end

    it "should load the migration files as migrations" do
      assert_equal 2, PG::Schema.migrations.size

      # Add a new empty migration
      PG::Schema.migration {}

      assert_equal 3, PG::Schema.migrations.size
    end

    describe "migrating up" do
      it "should migrates to the last version " do
        @migrator.run!
        assert_equal 2, @migrator.current_version
      end

      it "should executes the first migration" do
        @migrator.run!(version: 1)
        assert_equal 1, @migrator.current_version
      end

      it "should executes the 2nd migration" do
        @migrator.run!(version: 2)
        assert_equal 2, @migrator.current_version
      end

      it "should raise an exception if the version doen't exist" do
        assert_raises PG::Schema::MigrationNotFoundError do
          @migrator.run!(version: 4)
        end
      end

      it "should not raise an exception with multiple runs " do
        @migrator.run!
        @migrator.run!
        @migrator.run!

        assert_equal 2, @migrator.current_version
      end

      it "should rollback the migration if a command failed" do
        PG::Schema.migration do
          up do
            execute "CREATE TABLE test_users AS TABLE users"
            execute "SOME FAULTY SQL"
          end
        end

        assert_raises PG::SyntaxError do
          @migrator.run!
        end

        assert_equal 3, PG::Schema.migrations.count
        assert_equal 2, @migrator.current_version
      end
    end

    describe "migrating down" do
      before do
        @migrator.run!
      end

      it "should migrates to the first version " do
        @migrator.run!(version: 1)
        assert_equal 1, @migrator.current_version
      end

      it "should reset the schema when the version is 0" do
        @migrator.run!(version: 0)
        assert_equal 0, @migrator.current_version
      end
    end
  end
end
