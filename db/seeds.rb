User.find_or_create_by!(email: "admin@nomina.com") do |user|
  user.password = "password123"
  user.password_confirmation = "password123"
end

puts "Usuario seed creado: admin@nomina.com / password123"

company = Company.find_or_create_by!(nit: "901234567-1") do |c|
  c.name = "IUSTUM A&G S.A.S"
end

Employee.find_or_create_by!(company: company, document_number: "1098765432") do |e|
  e.document_type = 13
  e.first_surname = "GUTIERREZ"
  e.second_surname = "MESA"
  e.first_name = "LUIS"
  e.other_names = "ALEJANDRO"
  e.position = "OPERARIO"
  e.basic_salary = 1423500
  e.hire_date = Date.new(2024, 3, 1)
  e.contract_type = 3
  e.department = 11
  e.municipality = 11001
  e.address = "BOGOTA"
  e.integral_salary = false
end

puts "Empresa y empleado seed creados"
