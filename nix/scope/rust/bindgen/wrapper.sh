#!@runtimeShell@

args=( "$@" )

sep='--'
cxx=

while (( "$#" )); do
    arg="$1"
    shift
    case "$arg" in
        --)
            sep=
            break
            ;;
    esac
done

while (( "$#" )); do
    arg="$1"
    shift
    case "$arg" in
        -x)
            arg="$1"
            shift
            case "$arg" in
                c++)
                  cxx=1
                  ;;
            esac
            ;;
        -xc++|-std=c++*)
          cxx=1
          ;;
    esac
done


# if [ -n "$cxx" ]; then
#     cxxflags="$NIX_CXXSTDLIB_COMPILE"
# fi

if [ -n "$NIX_DEBUG" ]; then
    set -x
fi

export LIBCLANG_PATH="@libclang@/lib"
exec -a "$0" @out@/bin/.bindgen-wrapped "${args[@]}" $sep $cxxflags $NIX_CFLAGS_COMPILE
