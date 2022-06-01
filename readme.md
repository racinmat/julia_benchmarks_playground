Compilation and run times in julia 1.5.4, 1.6.6, 1.7.3 and 1.8.0-rc1 of some edge case bottlenecks.

It contains `main.jl` with the original edge-case and the `main_faster.jl`, which has some optimizations to be more type stable.

benchmark on windows:
```
C:\Projects\something\julia_1_6_benchmarks>"C:\Users\racinsky\AppData\Local\Programs\Julia 1.5.4\bin\julia.exe" main.jl
 Activating environment at `C:\Projects\something\julia_1_6_benchmarks\Project.toml`
Precompiling project...
  0.976723 seconds (1.76 M allocations: 91.809 MiB, 2.17% gc time)
  3.925 μs (55 allocations: 3.19 KiB)

C:\Projects\something\julia_1_6_benchmarks>C:\Users\racinsky\AppData\Local\Programs\Julia-1.6.6\bin\julia.exe main.jl 
┌ Warning: The Pkg REPL interface is intended for interactive use, use with caution from scripts.
└ @ Pkg.REPLMode C:\buildbot\worker\package_win64\build\usr\share\julia\stdlib\v1.6\Pkg\src\REPLMode\REPLMode.jl:378
  Activating environment at `C:\Projects\something\julia_1_6_benchmarks\Project.toml`
 45.713816 seconds (28.93 M allocations: 1.645 GiB, 1.13% gc time, 99.99% compilation time)
  19.100 μs (115 allocations: 6.62 KiB)

C:\Projects\something\julia_1_6_benchmarks>C:\Users\racinsky\AppData\Local\Programs\Julia-1.7.3\bin\julia.exe main.jl 
┌ Warning: The Pkg REPL mode is intended for interactive use only, and should not be used from scripts. It is recommended to use the functional API instead.
└ @ Pkg.REPLMode C:\buildbot\worker\package_win64\build\usr\share\julia\stdlib\v1.7\Pkg\src\REPLMode\REPLMode.jl:377
  Activating project at `C:\Projects\something\julia_1_6_benchmarks`
┌ Warning: The active manifest file is an older format with no julia version entry. Dependencies may have been resolved with a different julia version.
└ @ C:\Projects\something\julia_1_6_benchmarks\Manifest.toml:0
  4.995483 seconds (15.85 M allocations: 880.757 MiB, 5.52% gc time, 99.98% compilation time)
  18.800 μs (126 allocations: 5.91 KiB)

C:\Projects\something\julia_1_6_benchmarks>C:\Users\racinsky\AppData\Local\Programs\Julia-1.8.0-rc1\bin\julia.exe main.jl 
┌ Warning: The Pkg REPL mode is intended for interactive use only, and should not be used from scripts. It is recommended to use the functional API instead.
└ @ Pkg.REPLMode C:\buildbot\worker\package_win64\build\usr\share\julia\stdlib\v1.8\Pkg\src\REPLMode\REPLMode.jl:379
  Activating project at `C:\Projects\something\julia_1_6_benchmarks`
┌ Warning: The active manifest file is an older format with no julia version entry. Dependencies may have been resolved with a different julia version.
└ @ C:\Projects\something\julia_1_6_benchmarks\Manifest.toml:0
 11.176450 seconds (44.51 M allocations: 2.458 GiB, 4.22% gc time, 99.99% compilation time)
  14.600 μs (122 allocations: 6.73 KiB)

C:\Projects\something\julia_1_6_benchmarks>"C:\Users\racinsky\AppData\Local\Programs\Julia 1.5.4\bin\julia.exe" main_faster.jl 
 Activating environment at `C:\Projects\something\julia_1_6_benchmarks\Project.toml`
Precompiling project...
  0.295835 seconds (552.14 k allocations: 28.622 MiB, 5.01% gc time)
  1.820 μs (37 allocations: 2.25 KiB)

C:\Projects\something\julia_1_6_benchmarks>C:\Users\racinsky\AppData\Local\Programs\Julia-1.6.6\bin\julia.exe main_faster.jl 
┌ Warning: The Pkg REPL interface is intended for interactive use, use with caution from scripts.
└ @ Pkg.REPLMode C:\buildbot\worker\package_win64\build\usr\share\julia\stdlib\v1.6\Pkg\src\REPLMode\REPLMode.jl:378
  Activating environment at `C:\Projects\something\julia_1_6_benchmarks\Project.toml`
  0.345328 seconds (341.13 k allocations: 20.247 MiB, 99.96% compilation time)
  2.411 μs (44 allocations: 2.91 KiB)

C:\Projects\something\julia_1_6_benchmarks>C:\Users\racinsky\AppData\Local\Programs\Julia-1.7.3\bin\julia.exe main_faster.jl 
┌ Warning: The Pkg REPL mode is intended for interactive use only, and should not be used from scripts. It is recommended to use the functional API instead.
└ @ Pkg.REPLMode C:\buildbot\worker\package_win64\build\usr\share\julia\stdlib\v1.7\Pkg\src\REPLMode\REPLMode.jl:377
  Activating project at `C:\Projects\something\julia_1_6_benchmarks`
┌ Warning: The active manifest file is an older format with no julia version entry. Dependencies may have been resolved with a different julia version.
└ @ C:\Projects\something\julia_1_6_benchmarks\Manifest.toml:0
  0.412821 seconds (317.98 k allocations: 17.305 MiB, 99.97% compilation time)
  2.862 μs (44 allocations: 2.19 KiB)

C:\Projects\something\julia_1_6_benchmarks>C:\Users\racinsky\AppData\Local\Programs\Julia-1.8.0-rc1\bin\julia.exe main_faster.jl 
┌ Warning: The Pkg REPL mode is intended for interactive use only, and should not be used from scripts. It is recommended to use the functional API instead.
└ @ Pkg.REPLMode C:\buildbot\worker\package_win64\build\usr\share\julia\stdlib\v1.8\Pkg\src\REPLMode\REPLMode.jl:379
  Activating project at `C:\Projects\something\julia_1_6_benchmarks`
┌ Warning: The active manifest file is an older format with no julia version entry. Dependencies may have been resolved with a different julia version.
└ @ C:\Projects\something\julia_1_6_benchmarks\Manifest.toml:0
  1.903831 seconds (1.73 M allocations: 89.415 MiB, 3.67% gc time, 99.99% compilation time)
  3.775 μs (44 allocations: 2.08 KiB)
```

In `main.jl`, the 1.5 is fastest, and the compilation in 1.7 is second fastest one.
In `main_faster.jl`, the difference is negligible compared to the `main.jl`, but the 1.5 is still fastest. 
The slowdown in 1.8.0-rc1 is a bit troublesome.

On linux (research cluster):
```
 Activating environment at `~/projects/something/julia_1_6_benchmarks/Project.toml`
Precompiling project...
  0.646932 seconds (1.76 M allocations: 91.680 MiB, 2.85% gc time)
  2.127 μs (55 allocations: 3.19 KiB)
┌ Warning: The Pkg REPL interface is intended for interactive use, use with caution from scripts.
└ @ Pkg.REPLMode /buildworker/worker/package_linux64/build/usr/share/julia/stdlib/v1.6/Pkg/src/REPLMode/REPLMode.jl:378
  Activating environment at `~/projects/something/julia_1_6_benchmarks/Project.toml`
Precompiling project...
  1 dependency successfully precompiled in 3 seconds (3 already precompiled)
 19.852102 seconds (28.22 M allocations: 1.606 GiB, 2.16% gc time, 99.99% compilation time)
  8.405 μs (115 allocations: 6.62 KiB)
┌ Warning: The Pkg REPL mode is intended for interactive use only, and should not be used from scripts. It is recommended to use the functional API instead.
└ @ Pkg.REPLMode /buildworker/worker/package_linux64/build/usr/share/julia/stdlib/v1.7/Pkg/src/REPLMode/REPLMode.jl:377
  Activating project at `~/projects/something/julia_1_6_benchmarks`
┌ Warning: The active manifest file is an older format with no julia version entry. Dependencies may have been resolved with a different julia version.
└ @ ~/projects/something/julia_1_6_benchmarks/Manifest.toml:0
Precompiling project...
  4 dependencies successfully precompiled in 4 seconds
  3.253920 seconds (15.23 M allocations: 853.214 MiB, 5.08% gc time, 99.98% compilation time)
  11.720 μs (126 allocations: 5.91 KiB)
┌ Warning: The Pkg REPL mode is intended for interactive use only, and should not be used from scripts. It is recommended to use the functional API instead.
└ @ Pkg.REPLMode /buildworker/worker/package_linux64/build/usr/share/julia/stdlib/v1.8/Pkg/src/REPLMode/REPLMode.jl:379
  Activating project at `~/projects/something/julia_1_6_benchmarks`
┌ Warning: The active manifest file is an older format with no julia version entry. Dependencies may have been resolved with a different julia version.
└ @ ~/projects/something/julia_1_6_benchmarks/Manifest.toml:0
Precompiling project...
  4 dependencies successfully precompiled in 5 seconds
  8.273876 seconds (44.31 M allocations: 2.471 GiB, 7.61% gc time, 99.99% compilation time)
  9.329 μs (122 allocations: 6.73 KiB)
 Activating environment at `~/projects/something/julia_1_6_benchmarks/Project.toml`
Precompiling project...
  0.237452 seconds (551.86 k allocations: 28.630 MiB, 3.51% gc time)
  1.183 μs (37 allocations: 2.25 KiB)
┌ Warning: The Pkg REPL interface is intended for interactive use, use with caution from scripts.
└ @ Pkg.REPLMode /buildworker/worker/package_linux64/build/usr/share/julia/stdlib/v1.6/Pkg/src/REPLMode/REPLMode.jl:378
  Activating environment at `~/projects/something/julia_1_6_benchmarks/Project.toml`
  0.226717 seconds (341.13 k allocations: 20.252 MiB, 4.47% gc time, 99.96% compilation time)
  1.516 μs (44 allocations: 2.91 KiB)
┌ Warning: The Pkg REPL mode is intended for interactive use only, and should not be used from scripts. It is recommended to use the functional API instead.
└ @ Pkg.REPLMode /buildworker/worker/package_linux64/build/usr/share/julia/stdlib/v1.7/Pkg/src/REPLMode/REPLMode.jl:377
  Activating project at `~/projects/something/julia_1_6_benchmarks`
┌ Warning: The active manifest file is an older format with no julia version entry. Dependencies may have been resolved with a different julia version.
└ @ ~/projects/something/julia_1_6_benchmarks/Manifest.toml:0
  0.207087 seconds (318.21 k allocations: 17.358 MiB, 99.97% compilation time)
  1.396 μs (44 allocations: 2.19 KiB)
┌ Warning: The Pkg REPL mode is intended for interactive use only, and should not be used from scripts. It is recommended to use the functional API instead.
└ @ Pkg.REPLMode /buildworker/worker/package_linux64/build/usr/share/julia/stdlib/v1.8/Pkg/src/REPLMode/REPLMode.jl:379
  Activating project at `~/projects/something/julia_1_6_benchmarks`
┌ Warning: The active manifest file is an older format with no julia version entry. Dependencies may have been resolved with a different julia version.
└ @ ~/projects/something/julia_1_6_benchmarks/Manifest.toml:0
  0.436401 seconds (1.70 M allocations: 87.828 MiB, 7.99% gc time, 99.98% compilation time)
  1.540 μs (44 allocations: 2.08 KiB)
```

On linux it seems the times are very similar, just the 1.8 takes more memory.