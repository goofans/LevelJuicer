	# Utility for reading XML files
class_name XML_FINDER


		# - FUNCTIONS -
	# MAIN
static func find_xml_value(xml: XMLParser, item_name: String) -> String:
	var node_name: String
	var id_prefix: String
	
	xml.seek(0)
	while xml.read() != ERR_FILE_EOF: # Read the XML and compare attributes
		if xml.get_node_type() == XMLParser.NODE_ELEMENT:
			node_name = xml.get_node_name()
			if node_name == "SetDefaults":
				id_prefix = xml.get_named_attribute_value("idprefix")
			if node_name == "Image":
				node_name = item_name.replace(id_prefix, "")
				for idx: int in range(xml.get_attribute_count()):
					if xml.get_attribute_value(idx) == node_name:
						return xml.get_attribute_value(idx + 1)
	
	return ""
