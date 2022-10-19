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

Floating point ops seem slower for outside normal range.