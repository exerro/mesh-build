
tasks["mesh:copy"] = function(self)
	print_info("Copying from '" .. tostring(self.config.from) .. "' to '" .. tostring(self.config.to) .. "'")
	self.config.from.copy_to(self.config.to)
end

tasks["mesh:copy"].config {
	from = MESH_ROOT_PATH / "src",
	to = MESH_ROOT_PATH / "build/src",
}

--------------------------------------------------------------------------------

tasks["mesh:clean"] = function(self)
	print_info("Cleaning '" .. tostring(self.config.path) .. "'")
	self.config.path.delete()
end

tasks["mesh:clean"].config {
	path = MESH_ROOT_PATH / "build",
}
