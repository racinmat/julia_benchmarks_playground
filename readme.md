Compilation and run times in julia 1.5.4, 1.6.6, 1.7.3 and 1.8.0-rc1 of some edge case bottlenecks.

It contains `main.jl` with the original edge-case and the `main_faster.jl`, which has some optimizations to be more type stable.

```
C:\Projects\something\julia_1_6_benchmarks>"C:\Users\racinsky\AppData\Local\Programs\Julia 1.5.4\bin\julia.exe" mill.jl
 Activating environment at `C:\Projects\something\julia_1_6_benchmarks\Project.toml`
Precompiling project...
  0.000046 seconds (24 allocations: 1.632 KiB)
  0.000017 seconds (24 allocations: 1.570 KiB)
  1.550057 seconds (4.05 M allocations: 199.554 MiB, 5.43% gc time)
 36.474896 seconds (65.37 M allocations: 3.300 GiB, 3.87% gc time)
  1.646 ms (16788 allocations: 1.23 MiB)
  638.922 ns (4 allocations: 320 bytes)
  102.000 μs (308 allocations: 12.67 KiB)

C:\Projects\something\julia_1_6_benchmarks>C:\Users\racinsky\AppData\Local\Programs\Julia-1.6.0\bin\julia.exe mill.jl
┌ Warning: The Pkg REPL interface is intended for interactive use, use with caution from scripts.
└ @ Pkg.REPLMode C:\buildbot\worker\package_win64\build\usr\share\julia\stdlib\v1.6\Pkg\src\REPLMode\REPLMode.jl:378
  Activating environment at `C:\Projects\something\julia_1_6_benchmarks\Project.toml`
  0.000029 seconds (996 allocations: 73.896 KiB, 7380.00% compilation time)
  0.000019 seconds (27 allocations: 1.602 KiB)
  1.839924 seconds (7.39 M allocations: 394.749 MiB, 5.32% gc time, 58.76% compilation time)
 38.952194 seconds (78.32 M allocations: 4.474 GiB, 4.13% gc time, 57.67% compilation time)
  1.534 ms (16802 allocations: 1.24 MiB)
  548.128 ns (4 allocations: 320 bytes)
  52.100 μs (323 allocations: 17.14 KiB)
```

compilation is slower, but runtime is faster in 1.6.
