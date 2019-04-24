struct {
	name = "vec3",
	fields = {
		{name = "x", type = "double"},
		{name = "y", type = "double"},
		{name = "z", type = "double"},
	}
}
struct {
	name = "color",
	fields = {
		{name = "name", type = "string"},
		{name = "rgb", type = "vec3"},
	}
}

interface {
	name = "colors",
	methods = {
		add = {
			resulttype = "void",
			args = {{direction = "in", type = "color"}}
		},
		get = {
			resulttype = "vec3",
			args = {{direction = "inout", type = "string"}} -- name
		}
	}
}

interface {
	name = "numbers",
	methods = {
		add = {
			resulttype = "double",
			args = {
				{direction = "in", type = "double"},
				{direction = "in", type = "double"},
			}
		},
		dup = {
			resulttype = "double",
			args = {
				{direction = "in", type = "double"},
				{direction = "out", type = "double"},
			}
		},
		swap = {
			resulttype = "void",
			args = {
				{direction = "inout", type = "double"},
				{direction = "inout", type = "double"},
			}
		}
	}
}
