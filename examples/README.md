# Guided introduction (WIP)

```
git clone --recursive https://gitlab.com/arm-research/security/icecap/icecap
cd icecap
```

```
make -C docker/ run && make -C docker/ exec
```

```
nix-build examples/ -A minimal-root.run
./result/run
```

`TODO`
