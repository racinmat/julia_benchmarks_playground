compilation and run times in julia 1.5.4 a 1.6.0

```
C:\Projects\something\julia_1_6_benchmarks>"C:\Users\racinsky\AppData\Local\Programs\Julia 1.5.4\bin\julia.exe" mill.jl
 Activating environment at `C:\Projects\something\julia_1_6_benchmarks\Project.toml`
Precompiling project...
  0.000033 seconds (24 allocations: 1.632 KiB)
  0.000041 seconds (24 allocations: 1.570 KiB)
  1.202349 seconds (4.05 M allocations: 199.554 MiB, 5.84% gc time)
 31.718584 seconds (65.37 M allocations: 3.300 GiB, 3.87% gc time)
  1.622 ms (16788 allocations: 1.23 MiB)
  65.301 μs (308 allocations: 12.67 KiB)

C:\Projects\something\julia_1_6_benchmarks>C:\Users\racinsky\AppData\Local\Programs\Julia-1.6.0\bin\julia.exe mill.jl
┌ Warning: The Pkg REPL interface is intended for interactive use, use with caution from scripts.
└ @ Pkg.REPLMode C:\buildbot\worker\package_win64\build\usr\share\julia\stdlib\v1.6\Pkg\src\REPLMode\REPLMode.jl:378
  Activating environment at `C:\Projects\something\julia_1_6_benchmarks\Project.toml`
  0.000024 seconds (996 allocations: 73.896 KiB, 8398.76% compilation time)
  0.001499 seconds (27 allocations: 1.602 KiB)
  1.680281 seconds (7.39 M allocations: 394.749 MiB, 5.56% gc time, 59.10% compilation time)
 36.514278 seconds (78.32 M allocations: 4.474 GiB, 4.00% gc time, 58.01% compilation time)
  1.517 ms (16802 allocations: 1.24 MiB)
  51.400 μs (323 allocations: 17.14 KiB)
```

compilation is slower, but runtime is faster.
