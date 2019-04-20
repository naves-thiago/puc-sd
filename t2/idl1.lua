struct {name = "struct_a",
        fields = {{name = "nome", type = "string"},
                  {name = "peso", type = "double"},
                  {name = "idade", type = "int"},
        }
}

struct {name = "struct_b",
        fields = {{name = "a", type = "double"},
                  {name = "b", type = "struct_a"}
        }
}

interface {name = "interface_a",
           methods = {
               foo = {
                   resulttype = "double",
                   args = {{direction = "in", type = "double"},
                           {direction = "in", type = "string"},
                           {direction = "in", type = "struct_a"},
                           {direction = "inout", type = "int"}
                   }
               },
               bar = {
                   resulttype = "struct_b",
                   args = {{direction = "in", type = "double"},
                           {direction = "in", type = "string"}
                   }
               },
               derp = {
                   resulttype = "void",
                   args = {{direction = "in", type = "struct_b"},
                   }
               },
           }
}
