--struct {name = "struct_b",
--        fields = {{name = "a", type = "double"},
--                  {name = "b", type = "string"}
--        }
--}

interface {name = "interface_a",
           methods = {
               foo = {
                   resulttype = "double",
                   args = {{direction = "in", type = "double"},
                           {direction = "in", type = "int"},
                   }
               },
           }
}
