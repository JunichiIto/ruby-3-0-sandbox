Warning[:deprecated] = true
b = proc{}
p lambda(&b).lambda?

def foo(&b)
  lambda(&b).lambda?
end
p foo{}

puts '-' * 20
b = lambda{}
p lambda(&b)
p foo(&b)
