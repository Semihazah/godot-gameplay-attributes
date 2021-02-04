extends AttributeInjector

export(Dictionary) var attributes

func inject_attribute(attr_set:AttributeSet, add_data = {}):
	for attr in attributes.keys():
		attr = attr as Attribute
		if attr and typeof(attributes[attr]) == TYPE_REAL:
#			print("Injecting attribute %s" % attr.attribute_id)
			attr_set.add_attribute_file(attr, attributes[attr])
			
#	attr_set.add_attribute("res://Data/Attributes/Health.tres", 20)
#	attr_set.add_attribute("res://Data/Attributes/HealthDamage.tres", 0)
#	attr_set.add_attribute("res://Data/Attributes/HealthMax.tres", 15)
#	attr_set.add_attribute("res://Data/Attributes/HealthRegen.tres", 0)
