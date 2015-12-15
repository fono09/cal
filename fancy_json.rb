
require 'json'

class Object
	def to_fj
		obj = self
		buff = ''
		if obj.is_a?(Array) then
			buff += '['
			last = obj.length - 1
			obj.each.with_index do |child_obj,i|
				buff += child_obj.to_fj
				buff += ',' unless last == i
			end
			buff += ']'
		elsif obj.is_a?(FalseClass)
			buff += 'false'
		elsif obj.is_a?(Hash)
			buff += obj.to_json
		elsif obj.is_a?(NilClass)
			buff += 'null'
		elsif obj.is_a?(Numeric)
			buff += obj.to_json
		elsif obj.is_a?(String)
			buff += obj.to_json
		elsif obj.is_a?(Time)
			buff += obj.to_json
		elsif obj.is_a?(TrueClass)
			buff += 'true'
		else
			vars = obj.instance_variables
			buff += '{'
			last = vars.length - 1;
			temp = 0
			vars.each.with_index do |var,i|
				var = var.to_s
				var.gsub!(/\@/,'')
				buff += var.to_json + ':'
				buff += eval('obj.'+var).to_fj
				buff += ',' unless last == i
				temp = i
			end
			buff += '}'
		end
		return buff
	end
end
