https://www.goodreads.com/en/book/show/57850403-understanding-software-dynamics

## Chapter 2

```
> zig build-exe mystery1-fixed.zig -OReleaseFast && sudo benchmark ./mystery1-fixed
cset: --> last message, executed args into cpuset "/user", new pid is: 26911
64x unrolled, 16 iterations
.add 	   1253 cycles 	   1.22 cycles/iteration 	 total=3075
.mul 	   4914 cycles 	   4.80 cycles/iteration 	 total=2959831043
.imul 	   3691 cycles 	   3.60 cycles/iteration 	 total=2959831043
.div 	  14562 cycles 	  14.22 cycles/iteration 	 total=0
.idiv 	  14566 cycles 	  14.22 cycles/iteration 	 total=0
.fmul 	   5044 cycles 	   4.93 cycles/iteration 	 total=7.98369218e+04
.fdiv 	  19751 cycles 	  19.29 cycles/iteration 	 total=3.15215270e+02
```

For alder lake https://www.uops.info/table.html gives:

* add => 1
* mul/imul => 3:4
* div/idiv => 10:15
* fmul => no data (5 for haswell)
* fdiv => no data (15 for amd zen)

If we crank the iterations to 1<<20:

```
> zig build-exe mystery1-fixed.zig -OReleaseFast && sudo benchmark ./mystery1-fixed
cset: --> last message, executed args into cpuset "/user", new pid is: 26953
64x unrolled, 16384 iterations
.add 	 1249209 cycles 	   1.19 cycles/iteration 	 total=3145731
.mul 	 5015783 cycles 	   4.78 cycles/iteration 	 total=2915041283
.imul 	 3758952 cycles 	   3.58 cycles/iteration 	 total=2915041283
.div 	 14921922 cycles 	  14.23 cycles/iteration 	 total=0
.idiv 	 15039220 cycles 	  14.34 cycles/iteration 	 total=0
.fmul 	 477845056 cycles 	 455.71 cycles/iteration 	 total=inf
.fdiv 	 33096288 cycles 	  31.56 cycles/iteration 	 total=1.40129846e-45
```

Floating point ops are slower for denormals. But why?

https://stackoverflow.com/questions/60969892/performance-penalty-denormalized-numbers-versus-branch-mis-predictions says it's because it takes a slow path through microcode and we can detect this with the perf counter fp_assist.any

```
> perf list | grep fp

```

Uh oh.

https://perfmon-events.intel.com/index.html?pltfrm=ahybrid.html&evnt=ASSISTS.FP. Call to perf looks like `perf stat -e 'cpu_core/event=0xc1,umask=0x02,name=assists.fp/'. Make sure to look at the p-core counters since I'm pinning to cpu0.

```
> zig build-exe mystery1-fixed.zig -OReleaseFast && sudo benchmark ./mystery1-fixed
cset: --> last message, executed args into cpuset "/user", new pid is: 40117
64x unrolled, 16384 iterations
.add 	 1249183 cycles 	   1.19 cycles/iteration 	 total=3145731
.mul 	 5014811 cycles 	   4.78 cycles/iteration 	 total=2915041283
.imul 	 3759143 cycles 	   3.58 cycles/iteration 	 total=2915041283
.div 	 15016554 cycles 	  14.32 cycles/iteration 	 total=0
.idiv 	 14923433 cycles 	  14.23 cycles/iteration 	 total=0
.fmul 	 477859070 cycles 	 455.72 cycles/iteration 	 total=inf
.fdiv 	 33081541 cycles 	  31.55 cycles/iteration 	 total=1.40129846e-45

 Performance counter stats for './mystery1-fixed':

                 0      assists.fp

       0.221352884 seconds time elapsed

       0.220471000 seconds user
       0.000997000 seconds sys
```

So no assists?

But...

```
> zig build-exe mystery1-fixed.zig -OReleaseFast && sudo benchmark ./mystery1-fixed
cset: --> last message, executed args into cpuset "/user", new pid is: 40511
64x unrolled, 16384 iterations
.add 	 1250076 cycles 	   1.19 cycles/iteration 	 total=3145731
.mul 	 5009548 cycles 	   4.78 cycles/iteration 	 total=2915041283
.imul 	 3761845 cycles 	   3.59 cycles/iteration 	 total=2915041283
.div 	 15005696 cycles 	  14.31 cycles/iteration 	 total=0
.idiv 	 14932811 cycles 	  14.24 cycles/iteration 	 total=0
.fmul 	 477881973 cycles 	 455.74 cycles/iteration 	 total=inf
.fdiv 	 33025838 cycles 	  31.50 cycles/iteration 	 total=1.40129846e-45

 Performance counter stats for './mystery1-fixed':

                 0      assists.fp
       278,755,331      dq.ms_uops

       0.221398606 seconds time elapsed

       0.220493000 seconds user
       0.000997000 seconds sys


[17:10:34] jamie@vessel /home/jamie/understanding-software-dynamics
> zig build-exe mystery1-fixed.zig -OReleaseFast && sudo benchmark ./mystery1-fixed
cset: --> last message, executed args into cpuset "/user", new pid is: 40553
64x unrolled, 16384 iterations
.add 	 1263566 cycles 	   1.21 cycles/iteration 	 total=3145731
.mul 	 5009554 cycles 	   4.78 cycles/iteration 	 total=2915041283
.imul 	 3753727 cycles 	   3.58 cycles/iteration 	 total=2915041283
.div 	 14927291 cycles 	  14.24 cycles/iteration 	 total=0
.idiv 	 15097844 cycles 	  14.40 cycles/iteration 	 total=0

 Performance counter stats for './mystery1-fixed':

                 0      assists.fp
            46,198      dq.ms_uops

       0.016917669 seconds time elapsed

       0.016012000 seconds user
       0.001000000 seconds sys
```

Most of the microcode uops are issued only when fmul/fdiv paths are enabled.

I am confused.