# Require all helpers in the helpers folder
Dir.glob("#{$app.path}/helpers/*.rb").each { |helper| require("#{helper}") }
