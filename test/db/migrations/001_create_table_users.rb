PG::Schema.migration do
  up do
    execute <<~SQL
      CREATE TABLE users (
        id         integer,
        name       varchar(30),
        created_at timestamp
      )
    SQL
  end

  down do
    execute <<~SQL
      DROP TABLE users
    SQL
  end
end
