Gem::Specification.new do |s|
  s.name          = "pg-schema-migration"
  s.version       = "0.0.1"
  s.summary       = "PG Schema Migration"
  s.description   = "Simple schema migrations for PostgreSQL, which runs pure SQL."
  s.authors       = ["Alfredo Ramírez"]
  s.email         = ["alfredormz@gmail.com"]
  s.homepage      = "http://github.com/alfredormz/pg-schema-migration"
  s.license       = "MIT"
  s.require_paths = ["lib"]
  s.files         = `git ls-files`.split("\n")

  s.add_runtime_dependency "pg"
end
