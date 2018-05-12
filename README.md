# PG Schema Migration

Simple schema migrations for PostgreSQL, which runs pure SQL. Inspired by [Sequel](https://github.com/jeremyevans/sequel) and [Cassandra Schema](https://github.com/tarolandia/cassandra-schema).

## Installation

```
gem install pg-schema-migration
```

## Usage

PG::Schema uses a DSL via the `PG::Schema.migration` method, a migration must have an `up` block with the changes you want to apply to the schema, and a `down` block reversing the change made by `up`.

### A basic Migration

Use `execute` inside `up` and `down` blocks to run the queries that will modify the schema. Here is a fairly basic `PG::Schema` migration. 

```ruby
PG:Schema.migration do
  up do
    execute <<~SQL
      CREATE TABLE products (
        name VARCHAR(30),
        price NUMERIC
      )
    SQL
    
    execute "CREATE TRIGGER..."
  end
  
  down do
    execute "DROP TABLE products"
    execute "DROP TRIGGER..."
  end
end
```
If there is an error while running a migration, it will rollback the previous schema changes made by the migration.

### Running migrations

```ruby
require 'pg/schema-migration'
require 'pg'

@db = PG.connect(ENV.fetch("DATABASE_URL"))

PG::Schema.migration {...}
PG::Schema.migration {...}

migrator = PG::Schema::Migrator.new(
  db:        @db,                   # a PG connection
  directory: 'path/to/migrations',  # default: nil
  log:       Logger.new('/dev/nul') # default: Logger.new(STDOUT)
)
```
Migrate to the latest version

```ruby
migrator.run!
```
Migrate to an specific version

```ruby
migrator.run!(version: 1)
```
### Migration files

`PG::Schemas::Migrator` expects that each migration file will be in a specific directory. For example:

```ruby
PG::Schema::Migrator.new(db: @conn, directory: 'db/migrations').run!
```

`PG::Schema::Migrator` will look in the `db/migrations` folder relative to the current directory, and run unapplied migrations on the database.

The migration files must be specified as follows:

```bash
version_name.rb
```

where `version` is an integer and `name` is a string which should be a very brief description of what the migration does. Examples:
```bash
001_create_films.rb
002_add_director_to_films.rb
...
015_foo.rb
016_bar.rb
```
This guide is based on https://github.com/jeremyevans/sequel/blob/master/doc/migration.rdoc

# License
Copyright (c) 2018 Alfredo Ramírez.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
