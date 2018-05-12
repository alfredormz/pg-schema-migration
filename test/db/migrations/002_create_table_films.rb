PG::Schema.migration do
  up do
    execute <<~SQL
      CREATE TABLE films (
        code  varchar(5),
        title varchar(30)
      )
    SQL

    execute <<~SQL
      ALTER TABLE users ADD COLUMN email varchar(40)
    SQL
  end

  down do
    execute "DROP TABLE films"
    execute "ALTER TABLE users DROP COLUMN email"
  end
end
