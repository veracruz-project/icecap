# Getting started

The easiest way to start building and hacking on IceCap is using Docker. If you
encounter problems, please raise an issue or reach out to [Nick Spinale
&lt;nick.spinale@arm.com&gt;](mailto:nick.spinale@arm.com).

First, clone this respository and its submodules:

```
git clone --recursive https://gitlab.com/arm-research/security/icecap/icecap
cd icecap
```

Next, build, run, and enter a Docker container for development:

```
make -C docker run && make -C docker exec
```
