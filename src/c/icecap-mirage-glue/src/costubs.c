#include <assert.h>

#include <caml/alloc.h>
#include <caml/callback.h>
#include <caml/memory.h>
#include <caml/mlvalues.h>

#include <icecap-mirage-glue.h>

void costub_startup(void)
{
    caml_startup((char_os*[]){"mirage", NULL});
}

void costub_alloc(size_t size, size_t *handle, char **buf)
{
    value val = caml_alloc_string(size);
    *handle = (size_t)val; // according to caml/mlvalues.h, this is sound
    *buf = (char *)Bytes_val(val);
}

int costub_run_main(size_t handle)
{
    value arg = (value)handle;
    value *func = caml_named_value("main");
    assert(func != NULL);
    return Int_val(caml_callback(*func, arg));
}
